import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type CreateOrderRequest = {
  pandit_id?: string;
  idempotency_key?: string;
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID') ?? '';
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET') ?? '';

    if (
      supabaseUrl.isEmpty ||
      serviceRoleKey.isEmpty ||
      razorpayKeyId.isEmpty ||
      razorpayKeySecret.isEmpty
    ) {
      console.error('Function secrets are not configured');
      return new Response(JSON.stringify({ code: 'CONFIG_ERROR', message: 'Function secrets are not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const authHeader = req.headers.get('Authorization') ?? '';
    const jwt = authHeader.replace('Bearer ', '').trim();
    if (jwt.isEmpty) {
      return new Response(JSON.stringify({ code: 'UNAUTHORIZED', message: 'Missing bearer token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = (await req.json()) as CreateOrderRequest;
    const panditId = body.pandit_id?.trim();
    const idempotencyKey = body.idempotency_key?.trim();

    if (panditId == null || panditId.isEmpty || idempotencyKey == null || idempotencyKey.isEmpty) {
      return new Response(JSON.stringify({ code: 'BAD_REQUEST', message: 'pandit_id and idempotency_key are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const userResult = await supabase.auth.getUser(jwt);
    if (userResult.error != null || userResult.data.user == null) {
      console.error('Unauthorized user attempt', userResult.error);
      return new Response(JSON.stringify({ code: 'UNAUTHORIZED', message: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const panditResult = await supabase
      .from('pandits')
      .select('id, base_price, is_active')
      .eq('id', panditId)
      .single();

    if (panditResult.error != null || panditResult.data == null) {
      return new Response(JSON.stringify({ code: 'NOT_FOUND', message: 'Pandit not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (panditResult.data.is_active !== true) {
      return new Response(JSON.stringify({ code: 'BAD_REQUEST', message: 'Pandit is not active' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const amountInPaise = Number(panditResult.data.base_price) * 100;
    if (!Number.isFinite(amountInPaise) || amountInPaise <= 0) {
      return new Response(JSON.stringify({ code: 'BAD_REQUEST', message: 'Invalid amount' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const authToken = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);
    const orderResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${authToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: amountInPaise,
        currency: 'INR',
        receipt: `bmp_${idempotencyKey.slice(0, 32)}`,
        notes: {
          pandit_id: panditId,
          idempotency_key: idempotencyKey,
          user_id: userResult.data.user.id,
        },
      }),
    });

    const orderPayload = await orderResponse.json();
    if (!orderResponse.ok || typeof orderPayload?.id !== 'string') {
      console.error('Failed to create Razorpay order', orderPayload);
      return new Response(JSON.stringify({ code: 'PAYMENT_GATEWAY_ERROR', message: 'Failed to create Razorpay order' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Log the creation securely
    await supabase.from('audit_logs').insert({
      user_id: userResult.data.user.id,
      action: 'create_payment_order',
      target_id: panditId,
      payload: { order_id: orderPayload.id, amount: amountInPaise }
    });

    return new Response(
      JSON.stringify({
        order_id: orderPayload.id,
        amount_in_paise: amountInPaise,
        currency: 'INR',
        idempotency_key: idempotencyKey,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (error) {
    console.error('Unhandled Exception in create_payment_order', error);
    return new Response(JSON.stringify({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
