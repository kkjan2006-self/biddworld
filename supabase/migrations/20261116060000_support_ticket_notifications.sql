-- Notify members in-app when an administrator updates their support ticket.
-- Non-financial, additive; requires the support and notification migrations first.
create or replace function public.notify_member_on_support_ticket_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_message text;
begin
  if coalesce((select auth.jwt()->'app_metadata'->>'role'), '') <> 'admin' then
    return new;
  end if;

  if old.status is distinct from new.status
     or old.admin_response is distinct from new.admin_response then
    v_message := left(
      concat_ws(
        E'\n\n',
        'Your support request status is now: ' || replace(new.status, '_', ' '),
        case
          when nullif(btrim(new.admin_response), '') is not null
          then 'Support response: ' || new.admin_response
          else null
        end
      ),
      2000
    );

    insert into public.member_notifications(user_id, title, message, category)
    values (new.user_id, 'Support request updated', v_message, 'support');
  end if;

  return new;
end;
$function$;

revoke all on function public.notify_member_on_support_ticket_update() from public, anon, authenticated;

drop trigger if exists support_ticket_notify_member on public.support_tickets;
create trigger support_ticket_notify_member
after update on public.support_tickets
for each row
execute function public.notify_member_on_support_ticket_update();
