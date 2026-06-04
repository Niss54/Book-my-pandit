-- Phase 4: Observability (Audit Logging)

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid, -- Optional, can be null for system actions
  action text NOT NULL,
  target_id uuid,
  payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Secure the audit_logs table (only service_role can read/write)
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "audit_logs_service_only" ON public.audit_logs;
CREATE POLICY "audit_logs_service_only" 
  ON public.audit_logs
  FOR ALL
  USING (current_user = 'service_role')
  WITH CHECK (current_user = 'service_role');
