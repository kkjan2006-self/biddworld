-- Bounded, searchable member sponsor genealogy. Source-only until Production
-- migration history and live RPC contracts are reconciled and explicitly approved.
create or replace function public.get_my_mlm_dashboard_page(
 p_limit integer default 50,
 p_offset integer default 0,
 p_search text default null,
 p_depth integer default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_main uuid;
 v_result jsonb;
 v_limit integer;
 v_offset integer;
 v_search text:=nullif(trim(coalesce(p_search,'')),'');
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if p_limit is null or p_limit<1 or p_limit>100 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 if p_depth is not null and (p_depth<1 or p_depth>20) then
  raise exception 'Invalid genealogy level' using errcode='22023';
 end if;
 v_limit:=p_limit; v_offset:=p_offset;
 select main_member_id into v_main from public.profiles where id=v_uid;
 if v_main is null then raise exception 'Main Member ID is not available' using errcode='22023'; end if;
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
 ), member_data as (
  select d.member_id,d.parent_id,d.depth,mi.member_code,
   coalesce(nullif(p.display_name,''),'Member') display_name,mi.status,mi.created_at,parent.member_code sponsor_code
  from downline d
  join public.member_ids mi on mi.id=d.member_id
  join public.profiles p on p.id=mi.owner_user_id
  left join public.member_ids parent on parent.id=d.parent_id
 ), filtered as (
  select * from member_data md
  where (p_depth is null or md.depth=p_depth)
   and (v_search is null or (md.member_code||' '||md.display_name||' '||coalesce(md.sponsor_code,'')) ilike '%'||replace(replace(replace(v_search,'\\','\\\\'),'%','\\%'),'_','\\_')||'%' escape '\\')
 ), page_rows as (
  select * from filtered order by depth,created_at desc,member_code limit v_limit offset v_offset
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
  'tree_total',(select count(*) from filtered),
  'has_more',(select count(*)>v_offset+v_limit from filtered),
  'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',member_code,'display_name',display_name,'status',status,'created_at',created_at,'depth',depth,'sponsor_code',sponsor_code) order by depth,created_at desc,member_code),'[]'::jsonb) from page_rows)
 ) into v_result;
 return v_result;
end;
$function$;
revoke all on function public.get_my_mlm_dashboard_page(integer,integer,text,integer) from public,anon;
grant execute on function public.get_my_mlm_dashboard_page(integer,integer,text,integer) to authenticated;
