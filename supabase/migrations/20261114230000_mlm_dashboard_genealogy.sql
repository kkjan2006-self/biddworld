-- MLM dashboard and sponsor genealogy read APIs.
-- Applied to BiddWorld-Production and verified separately.

create or replace function public.get_my_mlm_dashboard()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_uid uuid:=auth.uid(); v_main uuid; v_result jsonb;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 select main_member_id into v_main from public.profiles where id=v_uid;
 if v_main is null then raise exception 'Main Member ID is not available'; end if;
 with recursive downline(member_id,parent_id,depth,path) as (
  select r.referred_member_id,r.referrer_member_id,1,array[v_main,r.referred_member_id]
  from public.referrals r join public.member_ids m on m.id=r.referred_member_id and m.id_type='main'
  where r.referrer_member_id=v_main
  union all
  select r.referred_member_id,r.referrer_member_id,d.depth+1,d.path||r.referred_member_id
  from downline d join public.referrals r on r.referrer_member_id=d.member_id
  join public.member_ids m on m.id=r.referred_member_id and m.id_type='main'
  where d.depth<20 and not r.referred_member_id=any(d.path)
 ), member_data as (
  select d.member_id,d.parent_id,d.depth,mi.member_code,
   coalesce(nullif(p.display_name,''),'Member') display_name,mi.status,mi.created_at,parent.member_code sponsor_code
  from downline d join public.member_ids mi on mi.id=d.member_id
  join public.profiles p on p.id=mi.owner_user_id left join public.member_ids parent on parent.id=d.parent_id
 )
 select jsonb_build_object(
  'main_member_code',(select member_code from public.member_ids where id=v_main),
  'direct_referrals',(select count(*) from member_data where depth=1),
  'total_downline',(select count(*) from member_data),
  'active_members',(select count(*) from member_data where status='active'),
  'active_activations',(select count(*) from public.package_activations pa where pa.member_id=v_main and pa.payment_status='verified' and pa.activation_status='active'),
  'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where credited_main_member_id=v_main and status in ('credited','paid')),
  'bid_wallet',(select coalesce(balance,0) from public.wallet_accounts where member_id=v_main and wallet_type='bid'),
  'income_wallet',(select coalesce(balance,0) from public.wallet_accounts where member_id=v_main and wallet_type='income'),
  'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',member_code,'display_name',display_name,'status',status,'created_at',created_at,'depth',depth,'sponsor_code',sponsor_code) order by depth,created_at),'[]'::jsonb) from member_data)
 ) into v_result;
 return v_result;
end; $$;
revoke all on function public.get_my_mlm_dashboard() from public,anon;
grant execute on function public.get_my_mlm_dashboard() to authenticated;

create or replace function public.admin_get_mlm_overview()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required'; end if;
 return jsonb_build_object(
  'total_members',(select count(*) from public.member_ids where id_type='main'),
  'active_members',(select count(*) from public.member_ids where id_type='main' and status='active'),
  'direct_relationships',(select count(*) from public.referrals),
  'pending_activations',(select count(*) from public.package_activations where payment_status='pending'),
  'verified_activations',(select count(*) from public.package_activations where payment_status='verified'),
  'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where status in ('credited','paid')),
  'withdrawal_pending',(select count(*) from public.withdrawal_requests where status='pending')
 );
end; $$;
revoke all on function public.admin_get_mlm_overview() from public,anon;
grant execute on function public.admin_get_mlm_overview() to authenticated;
