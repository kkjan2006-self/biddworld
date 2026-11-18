-- Bounded, Admin-only Fixed Bid campaign entry reporting.
-- Deliberately excludes internal idempotency keys from all result fields.

create or replace function public.admin_list_fixed_bid_entries_page(
  p_search text default null,
  p_campaign_id uuid default null,
  p_status text default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 100,
  p_offset integer default 0
) returns table(
  entry_id uuid,
  campaign_id uuid,
  campaign_title text,
  campaign_status text,
  member_code text,
  member_name text,
  entry_amount numeric,
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
 select fb.id,c.id,c.title,c.status,m.member_code,coalesce(p.display_name,''),
        fb.bid_amount,fb.status,fb.created_at
 from public.fixed_bids fb
 join public.fixed_bid_campaigns c on c.id=fb.campaign_id
 join public.member_ids m on m.id=fb.member_id and m.id_type='main'
 left join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where (p_campaign_id is null or fb.campaign_id=p_campaign_id)
   and (p_status is null or fb.status=p_status)
   and (p_from is null or fb.created_at>=p_from)
   and (p_to is null or fb.created_at<=p_to)
   and (
     v_search is null
     or position(lower(v_search) in lower(concat_ws(' ',m.member_code,coalesce(p.display_name,''),c.title)))>0
   )
 order by fb.created_at desc,fb.id desc
 limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_list_fixed_bid_entries_page(text,uuid,text,timestamptz,timestamptz,integer,integer) from public,anon;
grant execute on function public.admin_list_fixed_bid_entries_page(text,uuid,text,timestamptz,timestamptz,integer,integer) to authenticated;

comment on function public.admin_list_fixed_bid_entries_page(text,uuid,text,timestamptz,timestamptz,integer,integer) is
 'Admin-only paginated Fixed Bid campaign entry report; returns public-safe member/campaign/entry fields and never exposes idempotency keys.';
