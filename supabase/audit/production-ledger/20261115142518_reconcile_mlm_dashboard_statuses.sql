-- Narrow reporting correction for live Production function drift.
-- Prepared and rollback-tested against BiddWorld-Production on 2026-11-15.
-- NOT applied to Production. Review and obtain explicit approval before deployment.
--
-- The live constraints allow package_activations.payment_status values:
-- pending, approved, rejected, refunded.
-- The live referral_commissions.status values:
-- pending, credited, reversed.
-- Keep the function authorization checks and fixed search_path unchanged.

create or replace function public.admin_get_mlm_overview()
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required';
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

create or replace function public.get_my_mlm_dashboard()
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_main uuid;
  v_result jsonb;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  select main_member_id into v_main from public.profiles where id=v_uid;
  if v_main is null then raise exception 'Main Member ID is not available'; end if;

  with recursive downline(member_id,parent_id,depth,path) as (
    select r.referred_member_id,r.referrer_member_id,1,array[v_main,r.referred_member_id]
      from public.referrals r
      join public.member_ids m on m.id=r.referred_member_id and m.id_type='main'
     where r.referrer_member_id=v_main
    union all
    select r.referred_member_id,r.referrer_member_id,d.depth+1,d.path||r.referred_member_id
      from downline d
      join public.referrals r on r.referrer_member_id=d.member_id
      join public.member_ids m on m.id=r.referred_member_id and m.id_type='main'
     where d.depth<20 and not r.referred_member_id=any(d.path)
  ),
  member_data as (
    select d.member_id,d.parent_id,d.depth,mi.member_code,
           coalesce(nullif(p.display_name,''),'Member') as display_name,
           mi.status,mi.created_at,
           parent.member_code as sponsor_code
      from downline d
      join public.member_ids mi on mi.id=d.member_id
      join public.profiles p on p.id=mi.owner_user_id
      left join public.member_ids parent on parent.id=d.parent_id
  )
  select jsonb_build_object(
    'main_member_code',(select member_code from public.member_ids where id=v_main),
    'direct_referrals',(select count(*) from member_data where depth=1),
    'total_downline',(select count(*) from member_data),
    'active_members',(select count(*) from member_data where status='active'),
    'active_activations',(select count(*) from public.package_activations pa join public.member_ids mi on mi.id=pa.member_id where mi.id=v_main and pa.payment_status='approved' and pa.activation_status='active'),
    'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where credited_main_member_id=v_main and status='credited'),
    'bid_wallet',(select coalesce(balance,0) from public.wallet_accounts where member_id=v_main and wallet_type='bid'),
    'income_wallet',(select coalesce(balance,0) from public.wallet_accounts where member_id=v_main and wallet_type='income'),
    'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',member_code,'display_name',display_name,'status',status,'created_at',created_at,'depth',depth,'sponsor_code',sponsor_code) order by depth,created_at),'[]'::jsonb) from member_data)
  ) into v_result;
  return v_result;
end;
$function$;
