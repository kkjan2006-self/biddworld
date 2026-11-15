-- BiddWorld member support ticket workflow.
-- Additive and non-financial. Apply only through the reviewed deployment process;
-- this file is not executed against Production by this commit.

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null check (char_length(btrim(subject)) between 4 and 120),
  message text not null check (char_length(btrim(message)) between 10 and 5000),
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  admin_response text check (admin_response is null or char_length(admin_response) <= 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists support_tickets_user_updated_idx
  on public.support_tickets(user_id, updated_at desc);
create index if not exists support_tickets_status_updated_idx
  on public.support_tickets(status, updated_at desc);

alter table public.support_tickets enable row level security;
revoke all on public.support_tickets from public, anon, authenticated;
grant select on public.support_tickets to authenticated;
grant insert (user_id, subject, message) on public.support_tickets to authenticated;
grant update (status, admin_response) on public.support_tickets to authenticated;

drop policy if exists support_tickets_read_owner_or_admin on public.support_tickets;
create policy support_tickets_read_owner_or_admin
on public.support_tickets for select to authenticated
using (
  user_id = (select auth.uid())
  or coalesce((select auth.jwt()->'app_metadata'->>'role'),'') = 'admin'
);

drop policy if exists support_tickets_insert_owner on public.support_tickets;
create policy support_tickets_insert_owner
on public.support_tickets for insert to authenticated
with check (
  user_id = (select auth.uid())
  and status = 'open'
  and admin_response is null
);

drop policy if exists support_tickets_update_admin on public.support_tickets;
create policy support_tickets_update_admin
on public.support_tickets for update to authenticated
using (coalesce((select auth.jwt()->'app_metadata'->>'role'),'') = 'admin')
with check (coalesce((select auth.jwt()->'app_metadata'->>'role'),'') = 'admin');

create or replace function public.support_tickets_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

drop trigger if exists support_tickets_updated_at on public.support_tickets;
create trigger support_tickets_updated_at
before update on public.support_tickets
for each row execute function public.support_tickets_set_updated_at();

create or replace function public.support_tickets_audit_admin_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if coalesce((select auth.jwt()->'app_metadata'->>'role'),'') = 'admin' then
    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
    values (
      auth.uid(),
      'support_ticket_updated',
      'support_tickets',
      new.id,
      jsonb_build_object(
        'old_status', old.status,
        'new_status', new.status,
        'response_changed', old.admin_response is distinct from new.admin_response
      )
    );
  end if;
  return new;
end;
$function$;

revoke all on function public.support_tickets_set_updated_at() from public, anon, authenticated;
revoke all on function public.support_tickets_audit_admin_update() from public, anon, authenticated;

drop trigger if exists support_tickets_admin_audit on public.support_tickets;
create trigger support_tickets_admin_audit
after update on public.support_tickets
for each row execute function public.support_tickets_audit_admin_update();
