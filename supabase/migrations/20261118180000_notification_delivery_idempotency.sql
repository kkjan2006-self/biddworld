-- Idempotent in-app notification delivery with Admin authorization and audit logging.
-- Email/SMS delivery remains separate from this in-app channel.

alter table public.member_notifications
 add column if not exists idempotency_key text;
create unique index if not exists member_notifications_user_idempotency_uidx
 on public.member_notifications(user_id,idempotency_key)
 where idempotency_key is not null;

create or replace function public.admin_send_member_notification(
 p_user_id uuid,p_title text,p_message text,p_category text,p_idempotency_key text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_key text:=btrim(coalesce(p_idempotency_key,'')); v_id uuid;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_user_id is null or not exists(select 1 from auth.users where id=p_user_id) then
  raise exception 'Select an existing member account' using errcode='22023';
 end if;
 if length(trim(coalesce(p_title,'')))<3 or length(p_title)>120 then
  raise exception 'Notification title must contain 3 to 120 characters' using errcode='22023';
 end if;
 if length(trim(coalesce(p_message,'')))<5 or length(p_message)>2000 then
  raise exception 'Notification message must contain 5 to 2,000 characters' using errcode='22023';
 end if;
 if p_category is null or p_category not in ('general','account','support','security') then
  raise exception 'Choose a supported notification category' using errcode='22023';
 end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid notification request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text||':'||v_key,0));
 select id into v_id from public.member_notifications where user_id=p_user_id and idempotency_key=v_key;
 if v_id is not null then return jsonb_build_object('success',true,'notification_id',v_id,'replayed',true); end if;
 insert into public.member_notifications(user_id,title,message,category,idempotency_key)
 values(p_user_id,trim(p_title),trim(p_message),p_category,v_key)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'notification.sent','member_notifications',v_id,
  jsonb_build_object('target_user_id',p_user_id,'category',p_category,'title',trim(p_title)));
 return jsonb_build_object('success',true,'notification_id',v_id,'replayed',false);
end;
$function$;
revoke all on function public.admin_send_member_notification(uuid,text,text,text,text) from public,anon;
grant execute on function public.admin_send_member_notification(uuid,text,text,text,text) to authenticated;
