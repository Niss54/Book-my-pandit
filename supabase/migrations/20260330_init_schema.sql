-- Book My Pandit initial schema
-- Run this in Supabase SQL Editor or via Supabase CLI migrations.

create extension if not exists pgcrypto;

-- -----------------------------
-- users
-- -----------------------------
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  name text not null,
  profile_picture_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- -----------------------------
-- pandits
-- -----------------------------
create table if not exists public.pandits (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  expertise text not null,
  rating numeric(2,1) not null default 0.0 check (rating >= 0 and rating <= 5),
  base_price integer not null check (base_price >= 0),
  image_url text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- -----------------------------
-- bookings
-- -----------------------------
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  pandit_id uuid not null references public.pandits(id) on delete restrict,
  date timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
  amount integer not null check (amount >= 0),
  payment_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_bookings_user_id on public.bookings(user_id);
create index if not exists idx_bookings_pandit_id on public.bookings(pandit_id);
create index if not exists idx_bookings_date on public.bookings(date);
create index if not exists idx_bookings_payment_reference on public.bookings(payment_reference);
create index if not exists idx_pandits_active on public.pandits(is_active);

-- -----------------------------
-- updated_at trigger
-- -----------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists trg_pandits_updated_at on public.pandits;
create trigger trg_pandits_updated_at
before update on public.pandits
for each row execute function public.set_updated_at();

drop trigger if exists trg_bookings_updated_at on public.bookings;
create trigger trg_bookings_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

-- -----------------------------
-- row level security
-- -----------------------------
alter table public.users enable row level security;
alter table public.pandits enable row level security;
alter table public.bookings enable row level security;

-- users: user can view/update only own profile
drop policy if exists "users_select_own" on public.users;
create policy "users_select_own"
on public.users
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own"
on public.users
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own"
on public.users
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- pandits: public read, only service role writes
drop policy if exists "pandits_read_all" on public.pandits;
create policy "pandits_read_all"
on public.pandits
for select
using (true);

-- bookings: user manages own bookings
drop policy if exists "bookings_select_own" on public.bookings;
create policy "bookings_select_own"
on public.bookings
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "bookings_insert_own" on public.bookings;
create policy "bookings_insert_own"
on public.bookings
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "bookings_update_own" on public.bookings;
create policy "bookings_update_own"
on public.bookings
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "bookings_delete_own" on public.bookings;
create policy "bookings_delete_own"
on public.bookings
for delete
to authenticated
using (auth.uid() = user_id);
