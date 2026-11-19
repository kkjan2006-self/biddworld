-- Bound the restricted Admin/Staff Main Wallet funding review queue.
-- Stable keyset ordering avoids loading an unbounded pending queue into one response.
create or replace function public.admin_list_pending_wallet_fund_requests_page(
 p_limit integer default 50,
 p_cursor_created_at timestamptz default null,
 p_cursor_id uuid default null
) returns jsonb
language plpgsql stable security definer set search_path=''
as $function$
declare
 v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_items jsonb;
 v_has_more boolean:=false;
 v_next_created_at timestamptz;
 v_next_id uuid;
begin
 if auth.uid() is null or not (
  v_role='admin'
  or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review')
 ) then
  raise exception 'Wallet funding review permission required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if (p_cursor_created_at is null)<>(p_cursor_id is null) then
  raise exception 'Both cursor values must be supplied together' using errcode='22023';
 end if;

 with candidates as (
  select r.id,r.created_at,m.member_code,p.display_name as member_name,r.amount,r.currency,
   r.payment_reference,r.receipt_path
  from public.wallet_fund_requests r
  join public.member_ids m on m.id=r.member_id
  left join public.profiles p on p.id=r.submitted_by
  where r.status='pending'
   and (p_cursor_created_at is null or (r.created_at,r.id)>(p_cursor_created_at,p_cursor_id))
  order by r.created_at asc,r.id asc
  limit p_limit+1
 ), numbered as (
  select c.*,row_number() over(order by c.created_at asc,c.id asc) as rn,
   count(*) over() as total_rows
  from candidates c
 ), page_rows as (
  select * from numbered where rn<=p_limit
 )
 select
  coalesce(jsonb_agg(jsonb_build_object(
   'id',id,'created_at',created_at,'member_code',member_code,'member_name',member_name,
   'amount',amount,'currency',currency,'payment_reference',payment_reference,'receipt_path',receipt_path
  ) order by created_at asc,id asc),'[]'::jsonb),
  coalesce(max(total_rows)>p_limit,false),
  (array_agg(created_at order by rn) filter(where rn<=p_limit))[p_limit],
  (array_agg(id order by rn) filter(where rn<=p_limit))[p_limit]
 into v_items,v_has_more,v_next_created_at,v_next_id
 from page_rows;

 return jsonb_build_object(
  'items',v_items,'has_more',v_has_more,
  'next_created_at',case when v_has_more then v_next_created_at else null end,
  'next_id',case when v_has_more then v_next_id else null end
 );
end;
$function$;

revoke all on function public.admin_list_pending_wallet_fund_requests_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.admin_list_pending_wallet_fund_requests_page(integer,timestamptz,uuid) to authenticated;
