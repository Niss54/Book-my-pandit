-- Phase 1: webhook dedupe and replay protection

create table if not exists public.payment_webhook_events (
  id bigserial primary key,
  event_id text not null,
  event_type text not null,
  payload jsonb not null,
  signature text,
  payload_hash text,
  status text not null default 'received' check (status in ('received', 'processed', 'failed', 'duplicate')),
  error_message text,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

create unique index if not exists uq_payment_webhook_events_event_id
on public.payment_webhook_events(event_id);

create unique index if not exists uq_payment_webhook_events_payload_hash_non_null
on public.payment_webhook_events(payload_hash)
where payload_hash is not null;

create index if not exists idx_payment_webhook_events_received_at
on public.payment_webhook_events(received_at desc);

alter table public.payment_webhook_events enable row level security;

create or replace function public.register_payment_webhook_event(
  p_event_id text,
  p_event_type text,
  p_payload jsonb,
  p_signature text,
  p_payload_hash text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer;
begin
  if p_event_id is null or length(trim(p_event_id)) = 0 then
    raise exception 'p_event_id is required';
  end if;

  insert into public.payment_webhook_events (
    event_id,
    event_type,
    payload,
    signature,
    payload_hash,
    status
  )
  values (
    p_event_id,
    coalesce(nullif(trim(p_event_type), ''), 'unknown'),
    p_payload,
    p_signature,
    nullif(trim(p_payload_hash), ''),
    'received'
  )
  on conflict (event_id) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count = 1;
end;
$$;

revoke all on function public.register_payment_webhook_event(text, text, jsonb, text, text) from public;
grant execute on function public.register_payment_webhook_event(text, text, jsonb, text, text) to service_role;
