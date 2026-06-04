-- Phase 1 security hardening migration
-- Focus: duplicate prevention, stricter booking mutation rules, and production indexes.

alter table if exists public.bookings
add column if not exists idempotency_key text;

alter table if exists public.bookings
add column if not exists payment_verified_at timestamptz;

create unique index if not exists uq_bookings_payment_reference_non_null
on public.bookings(payment_reference)
where payment_reference is not null;

create unique index if not exists uq_bookings_user_idempotency_non_null
on public.bookings(user_id, idempotency_key)
where idempotency_key is not null;

create index if not exists idx_bookings_user_created_desc
on public.bookings(user_id, created_at desc);

create index if not exists idx_bookings_pandit_date
on public.bookings(pandit_id, date);

create or replace function public.guard_booking_mutations()
returns trigger
language plpgsql
as $$
begin
  -- service_role bypasses client-side restrictions and is reserved for trusted backend paths
  if current_user = 'service_role' then
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if old.user_id <> new.user_id then
      raise exception 'user_id is immutable';
    end if;

    if old.pandit_id <> new.pandit_id then
      raise exception 'pandit_id is immutable';
    end if;

    if old.amount <> new.amount then
      raise exception 'amount is immutable';
    end if;

    if old.date <> new.date then
      raise exception 'date is immutable';
    end if;

    if coalesce(old.payment_reference, '') <> coalesce(new.payment_reference, '') then
      raise exception 'payment_reference can only be written by trusted backend';
    end if;

    if coalesce(old.payment_verified_at, 'epoch'::timestamptz)
      <> coalesce(new.payment_verified_at, 'epoch'::timestamptz) then
      raise exception 'payment_verified_at can only be written by trusted backend';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_booking_mutations on public.bookings;
create trigger trg_guard_booking_mutations
before update on public.bookings
for each row execute function public.guard_booking_mutations();

drop policy if exists "bookings_update_own" on public.bookings;
create policy "bookings_update_own"
on public.bookings
for update
to authenticated
using (
  auth.uid() = user_id
  and status in ('pending', 'confirmed')
)
with check (
  auth.uid() = user_id
  and status = 'cancelled'
);

drop policy if exists "bookings_delete_own" on public.bookings;
