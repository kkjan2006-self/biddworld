-- Keep payout identifiers private in the paginated member withdrawal history too.
-- The earlier non-paginated RPC already returned only the method label; this
-- later keyset RPC must preserve the same privacy contract.
create or replace function public.member_list_my_withdrawals_page(
 p_limit integer default 50,
 p_before_requested_at timestamptz default null,
 p_before_id uuid default null
) returns table(
 request_id uuid,amount numeric,currency character(3),status text,payout_details jsonb,
 requested_at timestamptz,reviewed_at timestamptz,rejection_reason text,has_more boolean
) language plpgsql stable security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_member uuid;
 v_limit integer:=coalesce(p_limit,50);
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if v_limit<1 or v_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023'; end if;
 if (p_before_requested_at is null)<>(p_before_id is null) then
  raise exception 'Both pagination cursor fields must be supplied together' using errcode='22023';
 end if;
 select main_member_id into v_member from public.profiles where id=v_uid;
 if v_member is null then return; end if;
 return query
 with page as (
  select w.id,w.amount,w.currency,w.status,
   case when w.payout_details ? 'method'
    then jsonb_build_object('method',w.payout_details->>'method')
    else '{}'::jsonb end as safe_payout_details,
   w.requested_at,w.reviewed_at,w.rejection_reason,count(*) over() as total_count
  from public.withdrawal_requests w
  where w.member_id=v_member
   and (p_before_requested_at is null or (w.requested_at,w.id)<(p_before_requested_at,p_before_id))
  order by w.requested_at desc,w.id desc
  limit v_limit+1
 )
 select page.id,page.amount,page.currency,page.status,page.safe_payout_details,
  page.requested_at,page.reviewed_at,page.rejection_reason,(page.total_count>v_limit)
 from page order by page.requested_at desc,page.id desc limit v_limit;
end;
$function$;
revoke all on function public.member_list_my_withdrawals_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.member_list_my_withdrawals_page(integer,timestamptz,uuid) to authenticated;
