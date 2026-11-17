-- Allow Admin-configurable referral plan depth.
-- This replaces the legacy five-level-only draft RPC. It creates inactive versions only;
-- it does not activate plans, calculate commissions, or move wallet funds.

create or replace function public.admin_save_referral_plan_draft(
  p_package_id uuid,
  p_rules jsonb
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_package public.packages%rowtype;
  v_version integer;
  v_plan_id uuid;
  v_rule jsonb;
  v_level integer;
  v_type text;
  v_value numeric;
  v_max_depth integer := 0;
  v_rule_count integer := 0;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;

  if jsonb_typeof(p_rules) is distinct from 'array' or jsonb_array_length(p_rules) < 1 then
    raise exception 'Provide at least one referral level rule' using errcode='22023';
  end if;
  if jsonb_array_length(p_rules) > 20 then
    raise exception 'Referral plans cannot exceed 20 levels' using errcode='22023';
  end if;

  select * into v_package
  from public.packages
  where id = p_package_id
  for update;

  if not found then
    raise exception 'Package not found' using errcode='P0002';
  end if;
  if v_package.is_active then
    raise exception 'Referral plan drafts can only be changed for inactive packages' using errcode='55000';
  end if;

  select coalesce(max(version_number), 0) + 1
    into v_version
  from public.referral_plan_versions
  where package_id = p_package_id;

  insert into public.referral_plan_versions(package_id, version_number, is_active, created_by)
  values (p_package_id, v_version, false, v_uid)
  returning id into v_plan_id;

  for v_rule in select value from jsonb_array_elements(p_rules)
  loop
    v_level := (v_rule->>'level')::integer;
    v_type := v_rule->>'reward_type';
    v_value := (v_rule->>'reward_value')::numeric;

    if v_level is null or v_level < 1 or v_level > 20 then
      raise exception 'Each referral level must be between 1 and 20' using errcode='22023';
    end if;
    if v_level <> v_rule_count + 1 then
      raise exception 'Referral levels must be sequential starting at level 1' using errcode='22023';
    end if;
    if v_type is distinct from 'fixed' and v_type is distinct from 'percentage' then
      raise exception 'Reward type must be fixed or percentage' using errcode='22023';
    end if;
    if v_value is null or v_value <= 0 or v_value > 100000 then
      raise exception 'Reward value must be greater than zero and at most 100000' using errcode='22023';
    end if;
    if exists (
      select 1 from public.referral_level_rules
      where plan_version_id = v_plan_id and level_number = v_level
    ) then
      raise exception 'Duplicate referral level: %', v_level using errcode='22023';
    end if;

    insert into public.referral_level_rules(
      plan_version_id, level_number, reward_type, reward_value, eligibility_rule
    ) values (
      v_plan_id, v_level, v_type, v_value,
      jsonb_build_object('requires_active_main_id', true, 'max_depth', v_level)
    );

    v_rule_count := v_rule_count + 1;
    v_max_depth := greatest(v_max_depth, v_level);
  end loop;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (
    v_uid, 'referral_plan_draft_created', 'referral_plan_versions', v_plan_id,
    jsonb_build_object(
      'package_id', p_package_id,
      'version_number', v_version,
      'rule_count', v_rule_count,
      'max_depth', v_max_depth,
      'rules', p_rules
    )
  );

  return jsonb_build_object(
    'plan_id', v_plan_id,
    'version_number', v_version,
    'is_active', false,
    'rule_count', v_rule_count,
    'max_depth', v_max_depth
  );
end;
$function$;

revoke all on function public.admin_save_referral_plan_draft(uuid, jsonb) from public, anon;
grant execute on function public.admin_save_referral_plan_draft(uuid, jsonb) to authenticated;
