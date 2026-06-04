-- Phase 2: RBAC and Data Validation

-- 1. Create app_role ENUM and RBAC tables
DO $$ BEGIN
    CREATE TYPE public.app_role AS ENUM ('customer', 'admin', 'pandit', 'support');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, role)
);

CREATE TABLE IF NOT EXISTS public.admin_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  can_manage_pandits boolean NOT NULL DEFAULT false,
  can_manage_bookings boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- Trigger to assign 'customer' role on user creation
CREATE OR REPLACE FUNCTION public.assign_default_role()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'customer');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_user_created_assign_role ON public.users;
CREATE TRIGGER on_user_created_assign_role
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.assign_default_role();

-- 2. Data Validation constraints
-- Add check constraint for email
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS valid_email;
ALTER TABLE public.users
  ADD CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Add check bounds on booking amount
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS valid_amount_bounds;
ALTER TABLE public.bookings
  ADD CONSTRAINT valid_amount_bounds CHECK (amount > 0 AND amount <= 500000);

-- 3. Tighten RLS Policies

-- For user_roles and admin_permissions
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_permissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own roles" ON public.user_roles;
CREATE POLICY "Users can read own roles"
  ON public.user_roles FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admin can manage user roles" ON public.user_roles;
CREATE POLICY "Admin can manage user roles"
  ON public.user_roles FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
    )
  );

-- Tighten booking insert policy (Only allow inserting 'pending' status)
DROP POLICY IF EXISTS "bookings_insert_own" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert_own_pending_only" ON public.bookings;
CREATE POLICY "bookings_insert_own_pending_only"
  ON public.bookings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Tighten pandit update policy (Only admins can update/insert/delete pandits)
DROP POLICY IF EXISTS "pandits_write_admin" ON public.pandits;
CREATE POLICY "pandits_write_admin"
  ON public.pandits
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_roles ur 
      WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
    )
  );
