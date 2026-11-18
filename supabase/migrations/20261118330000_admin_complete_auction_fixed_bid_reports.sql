-- Complete paginated Admin exports for auction and Fixed Bid campaign catalogues.

create or replace function public.admin_list_auctions_page(
 p_search text default null,
 p_status text default 'all',
 p_limit integer default 100,
 p_offset integer default 0
) returns table(
 auction_id uuid,product_id uuid,title text,description text,image_url text,category text,
 currency text,starting_price numeric,current_price numeric,minimum_increment numeric,
 starts_at timestamptz,ends_at timestamptz,status text,product_name text
)
language plpgsql stable security definer set search_path=''
as $function$
declare v_search text:=nullif(btrim(coalesce(p_search,'')),'');
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if v_search is not null and length(v_search)>100 then
  raise exception 'Search text must be at most 100 characters' using errcode='22023';
 end if;
 if p_status is null or length(p_status)>32 then
  raise exception 'Invalid auction status filter' using errcode='22023';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select a.id,a.product_id,a.title,a.description,a.image_url,a.category,a.currency::text,
        a.starting_price,a.current_price,a.minimum_increment,a.starts_at,a.ends_at,a.status,p.name
 from public.auctions a
 join public.products p on p.id=a.product_id
 where (p_status='all' or a.status=p_status)
   and (v_search is null or position(lower(v_search) in lower(concat_ws(' ',a.title,p.name,a.category,a.status)))>0)
 order by a.created_at desc,a.id desc
 limit p_limit offset p_offset;
end;
$function$;

create or replace function public.admin_list_fixed_bid_campaigns_page(
 p_search text default null,
 p_status text default 'all',
 p_limit integer default 100,
 p_offset integer default 0
) returns table(
 campaign_id uuid,product_id uuid,product_name text,title text,description text,status text,
 configuration jsonb,created_at timestamptz,updated_at timestamptz
)
language plpgsql stable security definer set search_path=''
as $function$
declare v_search text:=nullif(btrim(coalesce(p_search,'')),'');
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if v_search is not null and length(v_search)>100 then
  raise exception 'Search text must be at most 100 characters' using errcode='22023';
 end if;
 if p_status is null or length(p_status)>32 then
  raise exception 'Invalid Fixed Bid status filter' using errcode='22023';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select c.id,c.product_id,p.name,c.title,c.description,c.status,c.configuration,c.created_at,c.updated_at
 from public.fixed_bid_campaigns c
 join public.products p on p.id=c.product_id
 where (p_status='all' or c.status=p_status)
   and (v_search is null or position(lower(v_search) in lower(concat_ws(' ',c.title,p.name,c.description,c.status)))>0)
 order by c.created_at desc,c.id desc
 limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_list_auctions_page(text,text,integer,integer) from public,anon;
grant execute on function public.admin_list_auctions_page(text,text,integer,integer) to authenticated;
revoke all on function public.admin_list_fixed_bid_campaigns_page(text,text,integer,integer) from public,anon;
grant execute on function public.admin_list_fixed_bid_campaigns_page(text,text,integer,integer) to authenticated;

comment on function public.admin_list_auctions_page(text,text,integer,integer) is
 'Admin-only paginated auction report/export; preserves the existing Admin auction projection.';
comment on function public.admin_list_fixed_bid_campaigns_page(text,text,integer,integer) is
 'Admin-only paginated Fixed Bid campaign report/export; preserves the existing Admin campaign projection.';
