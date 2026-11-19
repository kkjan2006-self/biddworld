-- Separate placement depth from commission depth, then enforce automatic
-- Duplicate-ID placement and the second approved package activation prerequisite.
-- Source-only: apply only after canonical TEST migration rehearsal.

alter table public.matrix_plan_versions
  add column if not exists placement_depth integer not null default 5
  check (placement_depth between 1 and 50);

-- The old four-argument save RPC is replaced so every new plan records all
-- three independent controls: width, placement depth and commission depth.
drop function if exists public.admin_save_matrix_plan_draft(uuid,integer,integer,jsonb);

create or replace function public.admin_save_matrix_plan_draft(
  p_package_id uuid,
  p_matrix_width integer,
  p_placement_depth integer,
  p_matrix_depth integer,
  p_rules jsonb
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_package public.packages%rowtype;
  v_version integer;
  v_plan_id uuid;
  v_rule jsonb;
  v_level integer;
  v_type text;
  v_value numeric;
  v_enabled boolean;
  v_count integer:=0;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if p_matrix_width not between 2 and 100 then raise exception 'Matrix width must be between 2 and 100' using errcode='22023'; end if;
  if p_placement_depth not between 1 and 50 then raise exception 'Placement depth must be between 1 and 50' using errcode='22023'; end if;
  if p_matrix_depth not between 1 and 50 then raise exception 'Commission depth must be between 1 and 50' using errcode='22023'; end if;
  if jsonb_typeof(p_rules) is distinct from 'array' or jsonb_array_length(p_rules)<>p_matrix_depth then
    raise exception 'Provide exactly one commission rule for every configured commission level' using errcode='22023';
  end if;
  select * into v_package from public.packages where id=p_package_id for update;
  if not found then raise exception 'Package not found' using errcode='P0002'; end if;
  if v_package.is_active then raise exception 'Matrix plan drafts can only be changed before package publication' using errcode='55000'; end if;
  select coalesce(max(version_number),0)+1 into v_version from public.matrix_plan_versions where package_id=p_package_id;
  insert into public.matrix_plan_versions(package_id,version_number,matrix_width,placement_depth,matrix_depth,is_active,created_by)
  values(p_package_id,v_version,p_matrix_width,p_placement_depth,p_matrix_depth,false,v_uid)
  returning id into v_plan_id;
  for v_rule in select value from jsonb_array_elements(p_rules) loop
    v_level:=(v_rule->>'level')::integer;
    v_type:=v_rule->>'reward_type';
    v_value:=coalesce((v_rule->>'reward_value')::numeric,0);
    v_enabled:=coalesce((v_rule->>'enabled')::boolean,false);
    if v_level is null or v_level<>v_count+1 then raise exception 'Commission levels must be sequential from 1 to %',p_matrix_depth using errcode='22023'; end if;
    if v_type not in ('fixed','percentage') then raise exception 'Reward type must be fixed or percentage' using errcode='22023'; end if;
    if v_value<0 or (v_type='percentage' and v_value>100) or (v_type='fixed' and v_value>10000000) then raise exception 'Reward value is outside the allowed range' using errcode='22023'; end if;
    insert into public.matrix_level_rules(plan_version_id,level_number,is_enabled,reward_type,reward_value,eligibility_rule)
    values(v_plan_id,v_level,v_enabled,v_type,v_value,coalesce(v_rule->'eligibility_rule','{}'::jsonb));
    v_count:=v_count+1;
  end loop;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'matrix_plan_draft_created','matrix_plan_versions',v_plan_id,
    jsonb_build_object('package_id',p_package_id,'version_number',v_version,'matrix_width',p_matrix_width,
      'placement_depth',p_placement_depth,'commission_depth',p_matrix_depth,'rules',p_rules));
  return jsonb_build_object('plan_id',v_plan_id,'version_number',v_version,'matrix_width',p_matrix_width,
    'placement_depth',p_placement_depth,'matrix_depth',p_matrix_depth,'is_active',false);
end;
$function$;

create or replace function public.admin_list_matrix_plans(p_package_id uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_result jsonb;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'package_id',p.package_id,'version_number',p.version_number,'matrix_width',p.matrix_width,
    'placement_depth',p.placement_depth,'matrix_depth',p.matrix_depth,'is_active',p.is_active,'created_at',p.created_at,
    'levels',coalesce((select jsonb_agg(jsonb_build_object('level',r.level_number,'enabled',r.is_enabled,
      'reward_type',r.reward_type,'reward_value',r.reward_value,'eligibility_rule',r.eligibility_rule)
      order by r.level_number) from public.matrix_level_rules r where r.plan_version_id=p.id),'[]'::jsonb)
  ) order by p.version_number desc),'[]'::jsonb) into v_result
  from public.matrix_plan_versions p where p.package_id=p_package_id;
  return v_result;
end;
$function$;

revoke all on function public.admin_save_matrix_plan_draft(uuid,integer,integer,integer,jsonb) from public,anon;
grant execute on function public.admin_save_matrix_plan_draft(uuid,integer,integer,integer,jsonb) to authenticated;
revoke all on function public.admin_list_matrix_plans(uuid) from public,anon;
grant execute on function public.admin_list_matrix_plans(uuid) to authenticated;

-- One-argument RPC: Under ID is never accepted from the client.
drop function if exists public.admin_create_duplicate_member_id(text,text);
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
      cross join lateral generate_series(1,v_plan.matrix_width) as slot(position)
     where not exists(
       select 1 from public.member_ids child
        where child.placement_parent_id=t.member_id
          and (child.placement_position=slot.position::text
            or (slot.position=1 and child.placement_position is not null and child.placement_position !~ '^[0-9]+$'))
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

revoke all on function public.admin_create_duplicate_member_id(text) from public,anon;
grant execute on function public.admin_create_duplicate_member_id(text) to authenticated;
