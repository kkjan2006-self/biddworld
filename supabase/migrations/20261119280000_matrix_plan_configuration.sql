-- Separate package-specific Matrix plans from Sponsor Referral plans.
-- Width controls child positions; depth controls commission levels. This migration
-- creates configuration only; it does not place IDs or post any wallet credits.
create table if not exists public.matrix_plan_versions (
  id uuid primary key default gen_random_uuid(),
  package_id uuid not null references public.packages(id) on delete restrict,
  version_number integer not null check (version_number > 0),
  matrix_width integer not null check (matrix_width between 2 and 100),
  matrix_depth integer not null check (matrix_depth between 1 and 50),
  is_active boolean not null default false,
  created_by uuid,
  created_at timestamptz not null default now(),
  unique(package_id, version_number),
  unique(id, package_id)
);

create unique index if not exists matrix_plan_one_active_per_package
  on public.matrix_plan_versions(package_id) where is_active;

create table if not exists public.matrix_level_rules (
  id uuid primary key default gen_random_uuid(),
  plan_version_id uuid not null references public.matrix_plan_versions(id) on delete restrict,
  level_number integer not null check (level_number between 1 and 50),
  is_enabled boolean not null default false,
  reward_type text not null check (reward_type in ('fixed','percentage')),
  reward_value numeric(14,4) not null check (reward_value >= 0),
  eligibility_rule jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(plan_version_id, level_number),
  check (reward_type <> 'percentage' or reward_value <= 100)
);

create index if not exists matrix_level_rules_plan_level_idx
  on public.matrix_level_rules(plan_version_id, level_number);

-- Configuration rows are exposed only through the Admin-authorized RPCs below.
-- Direct Data API access is deliberately unavailable to anon/authenticated clients.
alter table public.matrix_plan_versions enable row level security;
alter table public.matrix_level_rules enable row level security;
revoke all on table public.matrix_plan_versions from public, anon, authenticated;
revoke all on table public.matrix_level_rules from public, anon, authenticated;

create or replace function public.admin_save_matrix_plan_draft(
  p_package_id uuid,
  p_matrix_width integer,
  p_matrix_depth integer,
  p_rules jsonb
) returns jsonb
language plpgsql
security definer
set search_path=''
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
  if p_matrix_width is null or p_matrix_width<2 or p_matrix_width>100 then
    raise exception 'Matrix width must be between 2 and 100' using errcode='22023';
  end if;
  if p_matrix_depth is null or p_matrix_depth<1 or p_matrix_depth>50 then
    raise exception 'Matrix depth must be between 1 and 50' using errcode='22023';
  end if;
  if jsonb_typeof(p_rules) is distinct from 'array'
     or jsonb_array_length(p_rules)<>p_matrix_depth then
    raise exception 'Provide exactly one commission rule for every configured Matrix level' using errcode='22023';
  end if;
  select * into v_package from public.packages where id=p_package_id for update;
  if not found then raise exception 'Package not found' using errcode='P0002'; end if;
  if v_package.is_active then
    raise exception 'Matrix plan drafts can only be changed before package publication' using errcode='55000';
  end if;
  select coalesce(max(version_number),0)+1 into v_version
    from public.matrix_plan_versions where package_id=p_package_id;
  insert into public.matrix_plan_versions(package_id,version_number,matrix_width,matrix_depth,is_active,created_by)
  values(p_package_id,v_version,p_matrix_width,p_matrix_depth,false,v_uid)
  returning id into v_plan_id;

  for v_rule in select value from jsonb_array_elements(p_rules)
  loop
    v_level:=(v_rule->>'level')::integer;
    v_type:=v_rule->>'reward_type';
    v_value:=coalesce((v_rule->>'reward_value')::numeric,0);
    v_enabled:=coalesce((v_rule->>'enabled')::boolean,false);
    if v_level is null or v_level<>v_count+1 then
      raise exception 'Matrix commission levels must be sequential from 1 to %',p_matrix_depth using errcode='22023';
    end if;
    if v_type not in ('fixed','percentage') then
      raise exception 'Matrix reward type must be fixed or percentage' using errcode='22023';
    end if;
    if v_value<0 or (v_type='percentage' and v_value>100) or (v_type='fixed' and v_value>10000000) then
      raise exception 'Matrix reward value is outside the allowed range' using errcode='22023';
    end if;
    insert into public.matrix_level_rules(plan_version_id,level_number,is_enabled,reward_type,reward_value,eligibility_rule)
    values(v_plan_id,v_level,v_enabled,v_type,v_value,
      coalesce(v_rule->'eligibility_rule','{}'::jsonb));
    v_count:=v_count+1;
  end loop;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'matrix_plan_draft_created','matrix_plan_versions',v_plan_id,
    jsonb_build_object('package_id',p_package_id,'version_number',v_version,
      'matrix_width',p_matrix_width,'matrix_depth',p_matrix_depth,'rules',p_rules));
  return jsonb_build_object('plan_id',v_plan_id,'version_number',v_version,
    'matrix_width',p_matrix_width,'matrix_depth',p_matrix_depth,'is_active',false);
end;
$function$;

create or replace function public.admin_activate_matrix_plan(
  p_package_id uuid,
  p_plan_version_id uuid
) returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_package public.packages%rowtype;
  v_plan public.matrix_plan_versions%rowtype;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  select * into v_package from public.packages where id=p_package_id for update;
  if not found then raise exception 'Package not found' using errcode='P0002'; end if;
  if v_package.is_active then
    raise exception 'Matrix plans can only be activated before package publication' using errcode='55000';
  end if;
  select * into v_plan from public.matrix_plan_versions
    where id=p_plan_version_id and package_id=p_package_id for update;
  if not found then raise exception 'Matrix plan version does not belong to this package' using errcode='P0002'; end if;
  if (select count(*) from public.matrix_level_rules where plan_version_id=v_plan.id)<>v_plan.matrix_depth then
    raise exception 'Matrix plan is incomplete' using errcode='23514';
  end if;
  update public.matrix_plan_versions set is_active=false where package_id=p_package_id and is_active;
  update public.matrix_plan_versions set is_active=true where id=v_plan.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'matrix_plan_activated','matrix_plan_versions',v_plan.id,
    jsonb_build_object('package_id',p_package_id,'matrix_width',v_plan.matrix_width,'matrix_depth',v_plan.matrix_depth));
  return jsonb_build_object('success',true,'plan_id',v_plan.id,'matrix_width',v_plan.matrix_width,'matrix_depth',v_plan.matrix_depth);
end;
$function$;

create or replace function public.admin_list_matrix_plans(p_package_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_result jsonb;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'package_id',p.package_id,'version_number',p.version_number,
    'matrix_width',p.matrix_width,'matrix_depth',p.matrix_depth,'is_active',p.is_active,
    'created_at',p.created_at,
    'levels',coalesce((select jsonb_agg(jsonb_build_object(
      'level',r.level_number,'enabled',r.is_enabled,'reward_type',r.reward_type,
      'reward_value',r.reward_value,'eligibility_rule',r.eligibility_rule
    ) order by r.level_number) from public.matrix_level_rules r where r.plan_version_id=p.id),'[]'::jsonb)
  ) order by p.version_number desc),'[]'::jsonb)
  into v_result from public.matrix_plan_versions p where p.package_id=p_package_id;
  return v_result;
end;
$function$;

revoke all on function public.admin_save_matrix_plan_draft(uuid,integer,integer,jsonb) from public,anon;
revoke all on function public.admin_activate_matrix_plan(uuid,uuid) from public,anon;
revoke all on function public.admin_list_matrix_plans(uuid) from public,anon;
grant execute on function public.admin_save_matrix_plan_draft(uuid,integer,integer,jsonb) to authenticated;
grant execute on function public.admin_activate_matrix_plan(uuid,uuid) to authenticated;
grant execute on function public.admin_list_matrix_plans(uuid) to authenticated;
