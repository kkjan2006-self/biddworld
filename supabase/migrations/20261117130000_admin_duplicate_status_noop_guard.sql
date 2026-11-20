-- Avoid duplicate writes and audit events when an Admin repeats the current Duplicate ID status.
-- Lifecycle transitions and the existing closed-ID no-reactivation rule are preserved.
create or replace function public.admin_set_duplicate_id_status(p_duplicate_id uuid,p_status text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_row public.member_ids%rowtype;
  v_old_status text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  if p_status is null or p_status not in ('active','suspended','closed') then
    raise exception 'Status must be active, suspended or closed';
  end if;
  select * into v_row from public.member_ids
  where id=p_duplicate_id and id_type='duplicate'
  for update;
  if not found then raise exception 'Duplicate ID not found'; end if;
  if v_row.status='closed' and p_status<>'closed' then
    raise exception 'Closed Duplicate IDs cannot be reactivated; create a new Duplicate ID instead';
  end if;
  v_old_status:=v_row.status;
  if v_old_status=p_status then
    return jsonb_build_object('id',p_duplicate_id,'member_code',v_row.member_code,'old_status',v_old_status,'status',p_status,'changed',false);
  end if;
  update public.member_ids set status=p_status where id=p_duplicate_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_status_changed','member_ids',p_duplicate_id,
    jsonb_build_object('member_code',v_row.member_code,'main_member_id',v_row.main_member_id,'old_status',v_old_status,'new_status',p_status));
  return jsonb_build_object('id',p_duplicate_id,'member_code',v_row.member_code,'old_status',v_old_status,'status',p_status,'changed',true);
end;
$function$;


revoke all on function public.admin_set_duplicate_id_status(uuid,text) from public,anon;
grant execute on function public.admin_set_duplicate_id_status(uuid,text) to authenticated;
