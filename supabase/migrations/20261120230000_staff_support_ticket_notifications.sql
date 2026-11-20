-- Preserve the existing in-app Support notification trigger for explicitly authorized Staff reviewers.
-- The Support review RPC now accepts support_ticket_review Staff; the previous trigger
-- implementation returned early for every non-Admin JWT, silently suppressing member updates.

create or replace function public.notify_member_on_support_ticket_update()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_message text;
 v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_permissions jsonb:=coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb);
 v_notifications_enabled boolean:=false;
begin
 if auth.uid() is null or not(
  v_role='admin' or
  (v_role='admin_staff' and v_permissions ? 'support_ticket_review')
 ) then
  return new;
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_notifications_enabled
 from public.app_settings where setting_key='notifications_enabled';
 if not coalesce(v_notifications_enabled,false) then return new;end if;
 if old.status is distinct from new.status
    or old.admin_response is distinct from new.admin_response then
  v_message:=left(concat_ws(
   E'\n\n',
   'Your support request status is now: '||replace(new.status,'_',' '),
   case when nullif(btrim(new.admin_response),'') is not null
    then 'Support response: '||new.admin_response else null end
  ),2000);
  insert into public.member_notifications(user_id,title,message,category)
  values(new.user_id,'Support request updated',v_message,'support');
 end if;
 return new;
end;
$function$;
revoke all on function public.notify_member_on_support_ticket_update() from public,anon,authenticated;
