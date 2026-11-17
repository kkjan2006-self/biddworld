-- Serialize Admin Duplicate ID placement creation before reading owner and placement rows.
-- The graph-wide transaction lock avoids cross-request row-lock inversion when two
-- administrators create placements with overlapping Main / Under IDs.
-- This is source-only until separately rehearsed in a disposable TEST project.

create or replace function public.admin_create_duplicate_member_id(
  p_main_member_code text,
  p_under_member_code text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_main public.member_ids%rowtype;
  v_under public.member_ids%rowtype;
  v_code text;
  v_id uuid;
  v_enabled boolean := false;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  -- Serialize this low-frequency Admin graph mutation before taking row locks.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('biddworld.admin_create_duplicate_member_id', 0)
  );

  select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled
    from public.app_settings where setting_key='duplicate_ids_enabled';
  if not coalesce(v_enabled,false) then
    raise exception 'Duplicate IDs are disabled in Platform Settings';
  end if;

  select * into v_main from public.member_ids
   where upper(member_code)=upper(trim(p_main_member_code))
     and id_type='main' and status='active'
   for update;
  if not found then raise exception 'Active owner Main ID not found'; end if;

  select * into v_under from public.member_ids
   where upper(member_code)=upper(trim(p_under_member_code))
     and id_type in ('main','duplicate') and status='active'
   for update;
  if not found then raise exception 'Selected Under ID must be an active Main ID or Duplicate ID'; end if;
  if v_under.owner_user_id = v_main.owner_user_id then
    raise exception 'A member cannot place their Duplicate ID under their own ID';
  end if;

  loop
    v_code := 'BWD' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,9));
    exit when not exists(select 1 from public.member_ids where member_code=v_code);
  end loop;

  insert into public.member_ids(
    owner_user_id,main_member_id,member_code,id_type,status,placement_parent_id,placement_position
  ) values (
    v_main.owner_user_id,v_main.id,v_code,'duplicate','pending',v_under.id,'under'
  ) returning id into v_id;

  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_created','member_ids',v_id,
    jsonb_build_object('member_code',v_code,'main_member_id',v_main.id,
      'main_member_code',v_main.member_code,'under_member_id',v_under.id,
      'under_member_code',v_under.member_code,'status','pending'));

  return jsonb_build_object('id',v_id,'member_code',v_code,
    'main_member_code',v_main.member_code,'under_member_code',v_under.member_code,
    'status','pending');
end;
$function$;

revoke all on function public.admin_create_duplicate_member_id(text,text) from public,anon;
grant execute on function public.admin_create_duplicate_member_id(text,text) to authenticated;
