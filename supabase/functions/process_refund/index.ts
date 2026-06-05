import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token)

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Verify admin role
    const { data: roleData, error: roleError } = await supabaseClient
      .from('user_roles')
      .select('role')
      .eq('user_id', user.id)
      .single()

    if (roleError || roleData.role !== 'admin') {
      throw new Error('Forbidden: Admin access required')
    }

    const { booking_id } = await req.json()

    // Fetch booking details
    const { data: booking, error: bookingError } = await supabaseClient
      .from('bookings')
      .select('payment_reference, amount, status')
      .eq('id', booking_id)
      .single()

    if (bookingError || !booking) {
      throw new Error('Booking not found')
    }

    if (booking.status === 'refunded') {
      throw new Error('Already refunded')
    }

    if (!booking.payment_reference) {
       // Cannot refund without a payment reference
       throw new Error('No payment reference found for this booking')
    }

    const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID')
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET')
    
    if (!razorpayKeyId || !razorpayKeySecret) {
      throw new Error('Razorpay keys not configured')
    }

    // Call Razorpay Refund API
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);
    const refundResponse = await fetch(`https://api.razorpay.com/v1/payments/${booking.payment_reference}/refund`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${basicAuth}`
        },
        body: JSON.stringify({
            amount: booking.amount // full refund
        })
    });

    if (!refundResponse.ok) {
        const errorData = await refundResponse.json();
        throw new Error(`Razorpay refund failed: ${JSON.stringify(errorData)}`);
    }

    // Update booking status to refunded
    const { error: updateError } = await supabaseClient
      .from('bookings')
      .update({ status: 'refunded' })
      .eq('id', booking_id)

    if (updateError) {
      throw new Error('Failed to update booking status')
    }

    return new Response(
      JSON.stringify({ message: 'Refund successful' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
