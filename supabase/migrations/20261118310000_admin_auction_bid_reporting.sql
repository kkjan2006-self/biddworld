-- Bounded, Admin-only auction bid reporting.
-- Deliberately excludes the internal idempotency key from all result fields.

create or replace function public.admin_list_auction_bids_page(
  p_search text default null,
  p_auction_id uuid default null,
  p_status text default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 100,
  p_offset integer default 0
) returns table(
  bid_id uuid,
  auction_id uuid,
  auction_title text,
  currency text,
  member_code text,
  member_name text,
  bid_amount numeric,
  bid_wallet_debit numeric,
  income_wallet_debit numeric,
  status text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_search text := nullif(btrim(coalesce(p_search,'')),'');
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if v_search is not null and length(v_search)>100 then
  raise exception 'Search text must be at most 100 characters' using errcode='22023';
 end if;
 if p_status is not null and length(p_status)>32 then
  raise exception 'Status filter is too long' using errcode='22023';
 end if;
 if p_from is not null and p_to is not null and p_from>p_to then
  raise exception 'Date range is invalid' using errcode='22023';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100
    or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;

 return query
 select b.id,a.id,a.title,a.currency::text,m.member_code,
        coalesce(p.display_name,''),b.bid_amount,b.bid_wallet_debit,
        b.income_wallet_debit,b.status,b.created_at
 from public.bids b
 join public.auctions a on a.id=b.auction_id
 join public.member_ids m on m.id=b.member_id
 left join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where (p_auction_id is null or b.auction_id=p_auction_id)
   and (p_status is null or b.status=p_status)
   and (p_from is null or b.created_at>=p_from)
   and (p_to is null or b.created_at<=p_to)
   and (
     v_search is null
     or position(lower(v_search) in lower(concat_ws(' ',m.member_code,coalesce(p.display_name,''),a.title)))>0
   )
 order by b.created_at desc,b.id desc
 limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_list_auction_bids_page(text,uuid,text,timestamptz,timestamptz,integer,integer) from public,anon;
grant execute on function public.admin_list_auction_bids_page(text,uuid,text,timestamptz,timestamptz,integer,integer) to authenticated;

comment on function public.admin_list_auction_bids_page(text,uuid,text,timestamptz,timestamptz,integer,integer) is
 'Admin-only paginated auction bid report; returns public-safe member/auction/bid fields and never exposes idempotency keys.';
