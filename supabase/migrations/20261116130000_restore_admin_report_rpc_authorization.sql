-- Production drift correction: restore trusted Admin authorization on
-- read-only Admin member structure and MLM overview RPCs.
-- Prepared from the reviewed source definitions; NOT applied to Production.
-- Apply only after owner approval and after verifying the live schema.
create or replace function public.admin_get_member_structure()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;

  with recursive sponsor_tree(member_id, depth, path) as (
    select r.referred_member_id, 1, array[r.referrer_member_id, r.referred_member_id]
    from public.referrals r
    join public.member_ids m on m.id = r.referred_member_id and m.id_type = 'main'
    where exists (
      select 1 from public.member_ids root
      where root.id = r.referrer_member_id and root.id_type = 'main'
        and root.main_member_id is null
    )
    union all
    select r.referred_member_id, st.depth + 1, st.path || r.referred_member_id
    from sponsor_tree st
    join public.referrals r on r.referrer_member_id = st.member_id
    join public.member_ids m on m.id = r.referred_member_id and m.id_type = 'main'
    where st.depth < 20 and not r.referred_member_id = any(st.path)
  ),
  ids as (
    select mi.id, mi.member_code, mi.id_type, mi.status, mi.created_at,
      owner.display_name,
      main.member_code as main_member_code,
      parent.member_code as placement_parent_code,
      mi.placement_position
    from public.member_ids mi
    left join public.profiles owner on owner.id = mi.owner_user_id
    left join public.member_ids main on main.id = coalesce(mi.main_member_id, mi.id)
    left join public.member_ids parent on parent.id = mi.placement_parent_id
  ),
  levels as (
    select depth, count(*)::integer as member_count
    from sponsor_tree group by depth
  )
  select jsonb_build_object(
    'total_ids', (select count(*) from ids),
    'main_ids', (select count(*) from ids where id_type = 'main'),
    'duplicate_ids', (select count(*) from ids where id_type = 'duplicate'),
    'placement_assigned', (select count(*) from ids where placement_parent_code is not null and placement_position is not null),
    'ids', coalesce((select jsonb_agg(to_jsonb(i) order by i.created_at, i.member_code) from ids i), '[]'::jsonb),
    'sponsor_levels', coalesce((select jsonb_agg(jsonb_build_object('level', depth, 'members', member_count) order by depth) from levels), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$function$;

revoke all on function public.admin_get_member_structure() from public, anon;
grant execute on function public.admin_get_member_structure() to authenticated;

create or replace function public.admin_get_mlm_overview()
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  return jsonb_build_object(
    'total_members',(select count(*) from public.member_ids where id_type='main'),
    'active_members',(select count(*) from public.member_ids where id_type='main' and status='active'),
    'direct_relationships',(select count(*) from public.referrals),
    'pending_activations',(select count(*) from public.package_activations where payment_status='pending'),
    'verified_activations',(select count(*) from public.package_activations where payment_status='approved'),
    'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where status='credited'),
    'withdrawal_pending',(select count(*) from public.withdrawal_requests where status='pending'),
    'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',m.member_code,'display_name',coalesce(nullif(p.display_name,''),'Member'),'status',m.status,'created_at',m.created_at,'sponsor_code',s.member_code) order by m.created_at desc),'[]'::jsonb)
      from public.member_ids m join public.profiles p on p.id=m.owner_user_id
      left join public.referrals r on r.referred_member_id=m.id
      left join public.member_ids s on s.id=r.referrer_member_id
      where m.id_type='main' limit 500)
  );
end;
$function$;

revoke all on function public.admin_get_mlm_overview() from public, anon;
grant execute on function public.admin_get_mlm_overview() to authenticated;
