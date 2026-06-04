import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-razorpay-signature',
};

function toHex(bytes: ArrayBuffer): string {
  return Array.from(new Uint8Array(bytes))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
  return toHex(signature);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const webhookSecret = Deno.env.get('RAZORPAY_WEBHOOK_SECRET') ?? '';

  if (supabaseUrl.isEmpty || serviceRoleKey.isEmpty || webhookSecret.isEmpty) {
    return new Response(JSON.stringify({ error: 'Function secrets are not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const signature = req.headers.get('x-razorpay-signature')?.trim() ?? '';
  if (signature.isEmpty) {
    return new Response(JSON.stringify({ error: 'Missing webhook signature' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const rawBody = await req.text();
  const expectedSignature = await hmacSha256Hex(webhookSecret, rawBody);
  if (expectedSignature.toLowerCase() !== signature.toLowerCase()) {
    return new Response(JSON.stringify({ error: 'Invalid webhook signature' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const payload = JSON.parse(rawBody) as Record<string, unknown>;
  const eventType = String(payload.event ?? 'unknown');
  const payloadObj = payload.payload as Record<string, unknown> | undefined;
  const paymentObj = payloadObj?['payment'] as Record<string, unknown> | undefined;
  const paymentEntity = paymentObj?['entity'] as Record<string, unknown> | undefined;
  const paymentId = String(paymentEntity?['id'] ?? '').trim();

  const createdAt = String(payload.created_at ?? '0');
  const eventId = `${eventType}:${paymentId}:${createdAt}`;

  const payloadHashBuffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(rawBody));
  const payloadHash = toHex(payloadHashBuffer);

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const registerResult = await supabase.rpc('register_payment_webhook_event', {
    p_event_id: eventId,
    p_event_type: eventType,
    p_payload: payload,
    p_signature: signature,
    p_payload_hash: payloadHash,
  });

  if (registerResult.error != null) {
    return new Response(JSON.stringify({ error: 'Unable to register webhook event' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const isFreshEvent = registerResult.data === true;
  if (!isFreshEvent) {
    return new Response(JSON.stringify({ ok: true, duplicate: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (eventType === 'payment.captured' && paymentId.isNotEmpty) {
    await supabase
      .from('bookings')
      .update({ payment_verified_at: new Date().toISOString() })
      .eq('payment_reference', paymentId)
      .is('payment_verified_at', null);
  }

  await supabase
    .from('payment_webhook_events')
    .update({ status: 'processed', processed_at: new Date().toISOString() })
    .eq('event_id', eventId);

  return new Response(JSON.stringify({ ok: true, duplicate: false }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
