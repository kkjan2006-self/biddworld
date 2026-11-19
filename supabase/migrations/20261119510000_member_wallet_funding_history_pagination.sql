-- Bounded, owner-scoped keyset pagination for the member Add Money request history.
create or replace function public.member_list_my_wallet_fund_requests_page(
 p_limit integer default 50,
 p_before_created_at timestamptz default null,
 p_before_id uuid default null
) returns table(
 id uuid,amount numeric,currency text,payment_reference text,status text,
 review_note text,created_at timestamptz,reviewed_at timestamptz,has_more boolean
) language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_main uuid;v_limit integer:=coalesce(p_limit,50);
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501';end if;
 if v_limit<1 or v_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if (p_before_created_at is null)<>(p_before_id is null) then
  raise exception 'Both pagination cursor fields must be supplied together' using errcode='22023';
 end if;
 select main_member_id into v_main from public.profiles where id=v_uid;
 if v_main is null then return;end if;
 return query
 with page as (
  select r.id,r.amount,r.currency,r.payment_reference,r.status,r.review_note,r.created_at,r.reviewed_at,
   count(*) over() as total_count
  from public.wallet_fund_requests r
  where r.member_id=v_main
   and (p_before_created_at is null or (r.created_at,r.id)<(p_before_created_at,p_before_id))
  order by r.created_at desc,r.id desc
  limit v_limit+1
 )
 select page.id,page.amount,page.currency,page.payment_reference,page.status,page.review_note,
  page.created_at,page.reviewed_at,(page.total_count>v_limit)
 from page order by page.created_at desc,page.id desc limit v_limit;
end;
$function$;
revoke all on function public.member_list_my_wallet_fund_requests_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.member_list_my_wallet_fund_requests_page(integer,timestamptz,uuid) to authenticated;
