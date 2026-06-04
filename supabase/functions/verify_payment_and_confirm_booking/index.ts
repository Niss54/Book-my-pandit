import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type VerifyRequest = {
  user_id?: string;
  pandit_id?: string;
  scheduled_at?: string;
  payment_id?: string;
  order_id?: string;
  signature?: string;
  idempotency_key?: string;
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
  const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET') ?? '';
  const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID') ?? '';

  if (supabaseUrl.isEmpty || serviceRoleKey.isEmpty || razorpayKeySecret.isEmpty || razorpayKeyId.isEmpty) {
    return new Response(JSON.stringify({ error: 'Function secrets are not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace('Bearer ', '').trim();
  if (jwt.isEmpty) {
    return new Response(JSON.stringify({ error: 'Missing bearer token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const body = (await req.json()) as VerifyRequest;
  const userId = body.user_id?.trim();
  const panditId = body.pandit_id?.trim();
  const scheduledAt = body.scheduled_at?.trim();
  const paymentId = body.payment_id?.trim();
  const orderId = body.order_id?.trim();
  const signature = body.signature?.trim();
  const idempotencyKey = body.idempotency_key?.trim();

  if (
    userId == null || userId.isEmpty ||
    panditId == null || panditId.isEmpty ||
    scheduledAt == null || scheduledAt.isEmpty ||
    paymentId == null || paymentId.isEmpty ||
    orderId == null || orderId.isEmpty ||
    signature == null || signature.isEmpty ||
    idempotencyKey == null || idempotencyKey.isEmpty
  ) {
    return new Response(JSON.stringify({ error: 'Missing required fields' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const userResult = await supabase.auth.getUser(jwt);
  if (userResult.error != null || userResult.data.user == null || userResult.data.user.id !== userId) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const expectedSignature = await hmacSha256Hex(razorpayKeySecret, `${orderId}|${paymentId}`);
  if (expectedSignature.toLowerCase() !== signature.toLowerCase()) {
    return new Response(JSON.stringify({ error: 'Invalid signature' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const existing = await supabase
    .from('bookings')
    .select('*')
    .eq('user_id', userId)
    .eq('idempotency_key', idempotencyKey)
    .maybeSingle();

  if (existing.error == null && existing.data != null) {
    return new Response(JSON.stringify(existing.data), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const panditResult = await supabase
    .from('pandits')
    .select('id, base_price, is_active')
    .eq('id', panditId)
    .single();

  if (panditResult.error != null || panditResult.data == null || panditResult.data.is_active !== true) {
    return new Response(JSON.stringify({ error: 'Invalid pandit' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const paymentAuthToken = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);
  const paymentResponse = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
    method: 'GET',
    headers: {
      Authorization: `Basic ${paymentAuthToken}`,
      'Content-Type': 'application/json',
    },
  });

  const paymentPayload = await paymentResponse.json();
  if (!paymentResponse.ok) {
    return new Response(JSON.stringify({ error: 'Unable to validate payment' }), {
      status: 502,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (paymentPayload?.order_id !== orderId) {
    return new Response(JSON.stringify({ error: 'Payment order mismatch' }), {
      status: 409,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (paymentPayload?.status !== 'captured' && paymentPayload?.status !== 'authorized') {
    return new Response(JSON.stringify({ error: 'Payment not captured' }), {
      status: 409,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const expectedAmountInPaise = Number(panditResult.data.base_price) * 100;
  if (Number(paymentPayload?.amount) !== expectedAmountInPaise) {
    return new Response(JSON.stringify({ error: 'Amount mismatch' }), {
      status: 409,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const insertResult = await supabase
    .from('bookings')
    .insert({
      user_id: userId,
      pandit_id: panditId,
      date: scheduledAt,
      amount: Number(panditResult.data.base_price),
      status: 'confirmed',
      payment_reference: paymentId,
      payment_verified_at: new Date().toISOString(),
      idempotency_key: idempotencyKey,
    })
    .select('*')
    .single();

  if (insertResult.error != null || insertResult.data == null) {
    return new Response(JSON.stringify({ error: 'Unable to create booking' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify(insertResult.data), {
    status: 201,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
