alter table if exists public.bookings
add column if not exists payment_reference text;

create index if not exists idx_bookings_payment_reference
on public.bookings(payment_reference);
