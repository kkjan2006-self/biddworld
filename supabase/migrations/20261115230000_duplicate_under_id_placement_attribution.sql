-- Separate Sponsor (referral attribution) from Under ID (placement attribution).
-- A Duplicate ID's placement parent determines its level-income upline chain.
-- This is a branch-only migration; it does not post commissions or move funds.

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
    'display_name',p.display_name,'phone',p.phone,
    'under_member_code',parent.member_code,'under_display_name',under_profile.display_name
  ) order by d.created_at desc),'[]'::jsonb)
  into v_result
  from public.member_ids d
  join public.member_ids m on m.id=d.main_member_id and m.id_type='main'
  left join public.profiles p on p.id=d.owner_user_id
  left join public.member_ids parent on parent.id=d.placement_parent_id
  left join public.profiles under_profile on under_profile.id=parent.owner_user_id
  where d.id_type='duplicate';
  return v_result;
end;
$function$;

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

drop function if exists public.admin_create_duplicate_member_id(text);
revoke all on function public.admin_create_duplicate_member_id(text,text) from public,anon;
grant execute on function public.admin_create_duplicate_member_id(text,text) to authenticated;

create or replace function public.member_list_my_ids()
returns table(
  id uuid, member_code text, id_type text, status text, created_at timestamptz,
  placement_position text, placement_parent_code text, main_member_code text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  return query
  select mi.id,mi.member_code,mi.id_type,mi.status,mi.created_at,
         mi.placement_position,parent.member_code,main.member_code
    from public.member_ids mi
    left join public.member_ids parent on parent.id=mi.placement_parent_id
    left join public.member_ids main on main.id=coalesce(mi.main_member_id,mi.id)
   where mi.owner_user_id=v_uid
   order by case when mi.id_type='main' then 0 else 1 end,mi.created_at;
end;
$function$;
revoke all on function public.member_list_my_ids() from public,anon;
grant execute on function public.member_list_my_ids() to authenticated;

