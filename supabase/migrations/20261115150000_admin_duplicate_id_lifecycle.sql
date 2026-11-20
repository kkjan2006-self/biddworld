-- Admin-only Duplicate ID lifecycle. Duplicate IDs stay attached to the existing owner/Main ID
-- and do not create a new profile, person count, package activation, commission or wallet balance.
create or replace function public.admin_list_duplicate_ids()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',d.id,'member_code',d.member_code,'status',d.status,'created_at',d.created_at,
    'main_member_id',m.id,'main_member_code',m.member_code,
    'display_name',p.display_name,'phone',p.phone
  ) order by d.created_at desc),'[]'::jsonb)
  into v_result
  from public.member_ids d
  join public.member_ids m on m.id=d.main_member_id and m.id_type='main'
  left join public.profiles p on p.id=d.owner_user_id
  where d.id_type='duplicate';
  return v_result;
end;
$function$;

create or replace function public.admin_create_duplicate_member_id(p_main_member_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_main public.member_ids%rowtype;
  v_code text;
  v_id uuid;
  v_enabled boolean;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled
  from public.app_settings where setting_key='duplicate_ids_enabled';
  if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled in Platform Settings'; end if;
  select * into v_main from public.member_ids
  where upper(member_code)=upper(trim(p_main_member_code)) and id_type='main' and status='active'
  for update;
  if not found then raise exception 'Active Main ID not found'; end if;
  loop
    v_code := 'BWD' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,9));
    exit when not exists(select 1 from public.member_ids where member_code=v_code);
  end loop;
  insert into public.member_ids(owner_user_id,main_member_id,member_code,id_type,status)
  values(v_main.owner_user_id,v_main.id,v_code,'duplicate','pending')
  returning id into v_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_created','member_ids',v_id,
    jsonb_build_object('member_code',v_code,'main_member_id',v_main.id,'main_member_code',v_main.member_code,'status','pending'));
  return jsonb_build_object('id',v_id,'member_code',v_code,'main_member_code',v_main.member_code,'status','pending');
end;
$function$;

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
  update public.member_ids set status=p_status where id=p_duplicate_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_status_changed','member_ids',p_duplicate_id,
    jsonb_build_object('member_code',v_row.member_code,'main_member_id',v_row.main_member_id,'old_status',v_old_status,'new_status',p_status));
  return jsonb_build_object('id',p_duplicate_id,'member_code',v_row.member_code,'old_status',v_old_status,'status',p_status);
end;
$function$;

revoke all on function public.admin_list_duplicate_ids() from public,anon;
grant execute on function public.admin_list_duplicate_ids() to authenticated;
revoke all on function public.admin_create_duplicate_member_id(text) from public,anon;
grant execute on function public.admin_create_duplicate_member_id(text) to authenticated;
revoke all on function public.admin_set_duplicate_id_status(uuid,text) from public,anon;
grant execute on function public.admin_set_duplicate_id_status(uuid,text) to authenticated;
