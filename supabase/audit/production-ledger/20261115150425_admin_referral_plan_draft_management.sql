create or replace function public.admin_list_referral_plans()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'package_id',p.id,'package_name',p.name,'package_active',p.is_active,
  'plan_id',v.id,'version_number',v.version_number,'plan_active',v.is_active,
  'rules',coalesce((select jsonb_agg(jsonb_build_object('level',r.level_number,'reward_type',r.reward_type,'reward_value',r.reward_value,'eligibility_rule',r.eligibility_rule) order by r.level_number) from public.referral_level_rules r where r.plan_version_id=v.id),'[]'::jsonb)
 ) order by p.created_at desc,v.version_number desc),'[]'::jsonb)
 into v_result from public.packages p left join public.referral_plan_versions v on v.package_id=p.id;
 return v_result;
end;$function$;

create or replace function public.admin_save_referral_plan_draft(p_package_id uuid,p_rules jsonb)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_version integer; v_plan_id uuid; v_package public.packages%rowtype; v_rule jsonb; v_level integer; v_type text; v_value numeric;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required'; end if;
 select * into v_package from public.packages where id=p_package_id for update;
 if not found then raise exception 'Package not found'; end if;
 if v_package.is_active then raise exception 'Referral plan drafts can only be changed for inactive packages'; end if;
 if jsonb_typeof(p_rules)<>'array' or jsonb_array_length(p_rules)<>5 then raise exception 'Exactly five level rules are required'; end if;
 select coalesce(max(version_number),0)+1 into v_version from public.referral_plan_versions where package_id=p_package_id;
 insert into public.referral_plan_versions(package_id,version_number,is_active,created_by) values(p_package_id,v_version,false,v_uid) returning id into v_plan_id;
 for v_rule in select value from jsonb_array_elements(p_rules) loop
  v_level:=(v_rule->>'level')::integer; v_type:=v_rule->>'reward_type'; v_value:=(v_rule->>'reward_value')::numeric;
  if v_level not between 1 and 5 or v_type not in ('fixed','percentage') or v_value<=0 or v_value>100000 then raise exception 'Invalid level rule'; end if;
  if exists(select 1 from public.referral_level_rules where plan_version_id=v_plan_id and level_number=v_level) then raise exception 'Duplicate level'; end if;
  insert into public.referral_level_rules(plan_version_id,level_number,reward_type,reward_value,eligibility_rule)
  values(v_plan_id,v_level,v_type,v_value,jsonb_build_object('requires_active_main_id',true,'max_depth',5));
 end loop;
 if (select count(*) from public.referral_level_rules where plan_version_id=v_plan_id)<>5 then raise exception 'All five levels must be provided'; end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'referral_plan_draft_created','referral_plan_versions',v_plan_id,jsonb_build_object('package_id',p_package_id,'version_number',v_version,'rules',p_rules));
 return jsonb_build_object('plan_id',v_plan_id,'version_number',v_version,'is_active',false);
end;$function$;
revoke all on function public.admin_list_referral_plans() from public,anon;
grant execute on function public.admin_list_referral_plans() to authenticated;
revoke all on function public.admin_save_referral_plan_draft(uuid,jsonb) from public,anon;
grant execute on function public.admin_save_referral_plan_draft(uuid,jsonb) to authenticated;
