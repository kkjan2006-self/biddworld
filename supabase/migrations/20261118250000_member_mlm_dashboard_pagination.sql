-- Paginated member MLM dashboard contract used by src/components/Referrals.tsx.
-- Traverses Sponsor Referral relationships between Main IDs only; Duplicate IDs are not people.
-- Read-only RPC. No wallet, commission, referral or profile mutations.
create or replace function public.get_my_mlm_dashboard_page(
 p_limit integer default 50,
 p_offset integer default 0,
 p_search text default null,
 p_depth integer default null
) returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_main uuid;
 v_search text:=nullif(btrim(coalesce(p_search,'')),'');
 v_result jsonb;
begin
 if v_uid is null then
  raise exception 'Authentication required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100
   or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 if p_depth is not null and (p_depth<1 or p_depth>20) then
  raise exception 'Referral depth must be between 1 and 20' using errcode='22023';
 end if;
 if v_search is not null and length(v_search)>100 then
  raise exception 'Search text cannot exceed 100 characters' using errcode='22023';
 end if;

 select p.main_member_id into v_main
 from public.profiles p
 where p.id=v_uid;
 if v_main is null or not exists(
  select 1 from public.member_ids m
  where m.id=v_main and m.owner_user_id=v_uid and m.id_type='main'
 ) then
  raise exception 'Main Member ID is not available' using errcode='42501';
 end if;

 with recursive downline(member_id,parent_id,depth,path) as (
  select r.referred_member_id,r.referrer_member_id,1,array[v_main,r.referred_member_id]
  from public.referrals r
  join public.member_ids child on child.id=r.referred_member_id and child.id_type='main'
  where r.referrer_member_id=v_main
  union all
  select r.referred_member_id,r.referrer_member_id,d.depth+1,d.path||r.referred_member_id
  from downline d
  join public.referrals r on r.referrer_member_id=d.member_id
  join public.member_ids child on child.id=r.referred_member_id and child.id_type='main'
  where d.depth<20 and not r.referred_member_id=any(d.path)
 ), member_data as (
  select d.member_id,d.depth,mi.member_code,
   coalesce(nullif(p.display_name,''),'Member') as display_name,
   mi.status,mi.created_at,parent.member_code as sponsor_code
  from downline d
  join public.member_ids mi on mi.id=d.member_id
  join public.profiles p on p.id=mi.owner_user_id
  left join public.member_ids parent on parent.id=d.parent_id
 ), filtered as (
  select * from member_data m
  where (p_depth is null or m.depth=p_depth)
   and (v_search is null or m.member_code ilike '%'||v_search||'%'
    or m.display_name ilike '%'||v_search||'%'
    or coalesce(m.sponsor_code,'') ilike '%'||v_search||'%')
 ), summary as (
  select
   (select count(*) from member_data where depth=1) as direct_referrals,
   (select count(*) from member_data) as total_downline,
   (select count(*) from member_data where status='active') as active_members
 )
 select jsonb_build_object(
  'main_member_code',(select member_code from public.member_ids where id=v_main),
  'direct_referrals',summary.direct_referrals,
  'total_downline',summary.total_downline,
  'active_members',summary.active_members,
  'active_activations',(select count(*) from public.package_activations pa
    where pa.member_id=v_main and pa.payment_status='approved' and pa.activation_status='active'),
  'commission_total',(select coalesce(sum(c.amount),0) from public.referral_commissions c
    where c.credited_main_member_id=v_main and c.status='credited'),
  'bid_wallet',(select coalesce(w.balance,0) from public.wallet_accounts w
    where w.member_id=v_main and w.wallet_type='bid'),
  'income_wallet',(select coalesce(w.balance,0) from public.wallet_accounts w
    where w.member_id=v_main and w.wallet_type='income'),
  'tree_total',(select count(*) from filtered),
  'tree',(select coalesce(jsonb_agg(jsonb_build_object(
    'member_code',page.member_code,'display_name',page.display_name,
    'status',page.status,'created_at',page.created_at,
    'depth',page.depth,'sponsor_code',page.sponsor_code
   ) order by page.depth,page.created_at,page.member_code),'[]'::jsonb)
   from (select * from filtered order by depth,created_at,member_code
    limit p_limit offset p_offset) page),
  'has_more',(select count(*) from filtered)>p_offset+p_limit
 ) into v_result
 from summary;

 return v_result;
end;
$function$;

revoke all on function public.get_my_mlm_dashboard_page(integer,integer,text,integer) from public,anon;
grant execute on function public.get_my_mlm_dashboard_page(integer,integer,text,integer) to authenticated;
