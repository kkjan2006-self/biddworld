-- Ensure automatic Duplicate-ID placement selects a valid external member parent.
-- The owner Main ID and its own Duplicate IDs cannot be placement parents.
-- This aligns automatic slot selection with the approval RPC's ownership guard.

create or replace function public.admin_create_duplicate_member_id(p_main_member_code text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_main public.member_ids%rowtype;
  v_activation public.package_activations%rowtype;
  v_plan public.matrix_plan_versions%rowtype;
  v_parent_id uuid;
  v_parent_code text;
  v_position integer;
  v_code text;
  v_id uuid;
  v_enabled boolean:=false;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0));
  select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
    from public.app_settings where setting_key='duplicate_ids_enabled';
  if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled in Platform Settings' using errcode='55000'; end if;

  select * into v_main from public.member_ids
   where upper(member_code)=upper(trim(p_main_member_code)) and id_type='main' and status='active'
   for update;
  if not found then raise exception 'Active owner Main ID not found' using errcode='P0002'; end if;

  -- A second package activation must be approved and active before a Duplicate ID
  -- can be requested. The package's active Matrix plan defines its placement grid.
  select * into v_activation from public.package_activations
   where member_id=v_main.id and activation_number=2
     and payment_status='approved' and activation_status='active'
   for share;
  if not found then raise exception 'The second package activation must be approved before creating a Duplicate ID' using errcode='55000'; end if;
  select * into v_plan from public.matrix_plan_versions
   where package_id=v_activation.package_id and is_active=true
   order by version_number desc,id desc limit 1;
  if not found then raise exception 'An active Matrix plan is required for the second activated package' using errcode='55000'; end if;

  -- Breadth-first search inside this Main ID placement tree. Pending IDs reserve
  -- slots, but only active IDs may become a placement parent.
  with recursive team(member_id,depth,path) as (
    select v_main.id,0,array[v_main.id]
    union all
    select child.id,t.depth+1,t.path||child.id
      from team t join public.member_ids child on child.placement_parent_id=t.member_id
     where child.id_type in ('main','duplicate')
       and t.depth<v_plan.placement_depth
       and not child.id=any(t.path)
  ), available as (
    select t.member_id,t.depth,t.path,slot.position
      from team t
      join public.member_ids parent on parent.id=t.member_id and parent.status='active'
       and parent.owner_user_id is distinct from v_main.owner_user_id
      cross join lateral generate_series(1,v_plan.matrix_width) as slot(position)
     where t.depth<v_plan.placement_depth
       and not exists(
       select 1 from public.member_ids child
        where child.placement_parent_id=t.member_id
          and (child.placement_position=slot.position::text
            or (slot.position=1 and (child.placement_position is null or child.placement_position !~ '^[0-9]+$')))
     )
     order by t.depth,t.path,slot.position
     limit 1
  )
  select member_id,position into v_parent_id,v_position from available;
  if v_parent_id is null then raise exception 'The configured Matrix placement tree is full; increase placement depth or width in the package plan' using errcode='54000'; end if;
  select member_code into v_parent_code from public.member_ids where id=v_parent_id;

  loop
    v_code:='BWD'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,9));
    exit when not exists(select 1 from public.member_ids where member_code=v_code);
  end loop;
  insert into public.member_ids(owner_user_id,main_member_id,member_code,id_type,status,placement_parent_id,placement_position)
  values(v_main.owner_user_id,v_main.id,v_code,'duplicate','pending',v_parent_id,v_position::text)
  returning id into v_id;

  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_created','member_ids',v_id,jsonb_build_object(
    'member_code',v_code,'main_member_id',v_main.id,'main_member_code',v_main.member_code,
    'under_member_id',v_parent_id,'under_member_code',v_parent_code,'placement_position',v_position,
    'matrix_plan_id',v_plan.id,'matrix_width',v_plan.matrix_width,'placement_depth',v_plan.placement_depth,
    'second_activation_id',v_activation.id,'status','pending'));
  return jsonb_build_object('id',v_id,'member_code',v_code,'main_member_code',v_main.member_code,
    'under_member_code',v_parent_code,'placement_position',v_position,'status','pending');
end;
$function$;
