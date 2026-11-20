-- Bounded keyset pagination for the Admin pending package activation review queue.
-- Preserve the existing Admin-only authorization and receipt-path contract.
create or replace function public.admin_list_pending_activations_page(
 p_limit integer default 50,
 p_after_submitted_at timestamptz default null,
 p_after_id uuid default null
) returns jsonb
language plpgsql stable security definer set search_path=''
as $function$
declare
 v_items jsonb;
 v_has_more boolean:=false;
 v_next_submitted_at timestamptz;
 v_next_id uuid;
begin
 if auth.uid() is null or not(
  coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
   and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'package_activation_review')
 ) then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if (p_after_submitted_at is null)<>(p_after_id is null) then
  raise exception 'Both cursor values must be supplied together' using errcode='22023';
 end if;

 with candidates as (
  select a.id,a.activation_number,m.member_code,p.display_name as member_name,
   pkg.name as package_name,a.amount_paid,a.currency,a.bid_wallet_credit,
   a.payment_reference,a.receipt_path,a.submitted_at
  from public.package_activations a
  join public.member_ids m on m.id=a.member_id
  left join public.profiles p on p.id=m.owner_user_id
  join public.packages pkg on pkg.id=a.package_id
  where a.payment_status='pending' and a.activation_status='pending'
   and (p_after_submitted_at is null or (a.submitted_at,a.id)<(p_after_submitted_at,p_after_id))
  order by a.submitted_at desc,a.id desc
  limit p_limit+1
 ), numbered as (
  select c.*,row_number() over(order by c.submitted_at desc,c.id desc) as rn
  from candidates c
 ), kept as (
  select * from numbered where rn<=p_limit
 )
 select
  coalesce(jsonb_agg(jsonb_build_object(
   'id',id,'activation_number',activation_number,'member_code',member_code,
   'member_name',member_name,'package_name',package_name,'amount_paid',amount_paid,
   'currency',currency,'bid_wallet_credit',bid_wallet_credit,
   'payment_reference',payment_reference,'receipt_path',receipt_path,'submitted_at',submitted_at
  ) order by submitted_at desc,id desc),'[]'::jsonb),
  coalesce((select count(*)>p_limit from candidates),false),
  (array_agg(submitted_at order by rn))[p_limit],
  (array_agg(id order by rn))[p_limit]
 into v_items,v_has_more,v_next_submitted_at,v_next_id
 from kept;

 return jsonb_build_object(
  'items',v_items,'has_more',v_has_more,
  'next_submitted_at',case when v_has_more then v_next_submitted_at else null end,
  'next_id',case when v_has_more then v_next_id else null end
 );
end;
$function$;
revoke all on function public.admin_list_pending_activations_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.admin_list_pending_activations_page(integer,timestamptz,uuid) to authenticated;
