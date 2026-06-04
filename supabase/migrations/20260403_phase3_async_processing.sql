-- Phase 3: Scalability and Async Processing

-- 1. Queue/Worker Layer for Async Tasks
CREATE TABLE IF NOT EXISTS public.webhook_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  error_message text,
  retry_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Trigger to maintain updated_at for webhook_events
DROP TRIGGER IF EXISTS trg_webhook_events_updated_at ON public.webhook_events;
CREATE TRIGGER trg_webhook_events_updated_at
  BEFORE UPDATE ON public.webhook_events
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Secure the webhook_events table (only service_role should access it)
ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "webhook_events_service_only" ON public.webhook_events;
CREATE POLICY "webhook_events_service_only" 
  ON public.webhook_events
  FOR ALL
  USING (current_user = 'service_role')
  WITH CHECK (current_user = 'service_role');

-- 2. Rate Limiting Table
CREATE TABLE IF NOT EXISTS public.rate_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  last_request_at timestamptz NOT NULL DEFAULT now(),
  request_count integer NOT NULL DEFAULT 1,
  UNIQUE(user_id, action)
);

-- Rate Limiting RPC function
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_user_id uuid,
  p_action text,
  p_max_requests integer,
  p_window_seconds integer
) RETURNS boolean AS $$
DECLARE
  v_rate_limit public.rate_limits%ROWTYPE;
BEGIN
  -- Select existing record
  SELECT * INTO v_rate_limit
  FROM public.rate_limits
  WHERE user_id = p_user_id AND action = p_action;

  IF NOT FOUND THEN
    -- First time action, insert record
    INSERT INTO public.rate_limits (user_id, action, last_request_at, request_count)
    VALUES (p_user_id, p_action, now(), 1);
    RETURN true;
  END IF;

  -- If outside the window, reset counter
  IF v_rate_limit.last_request_at < now() - (p_window_seconds || ' seconds')::interval THEN
    UPDATE public.rate_limits
    SET request_count = 1, last_request_at = now()
    WHERE user_id = p_user_id AND action = p_action;
    RETURN true;
  END IF;

  -- Inside the window, check counter
  IF v_rate_limit.request_count >= p_max_requests THEN
    RETURN false;
  END IF;

  -- Increment counter
  UPDATE public.rate_limits
  SET request_count = request_count + 1, last_request_at = now()
  WHERE user_id = p_user_id AND action = p_action;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Secure the rate_limits table (only service_role should access it)
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rate_limits_service_only" ON public.rate_limits;
CREATE POLICY "rate_limits_service_only" 
  ON public.rate_limits
  FOR ALL
  USING (current_user = 'service_role')
  WITH CHECK (current_user = 'service_role');
