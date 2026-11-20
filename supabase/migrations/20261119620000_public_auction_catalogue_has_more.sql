-- Return an exact has_more flag without changing the public catalogue's stable ordering.
drop function if exists public.public_list_active_auctions_page(integer,integer);
create function public.public_list_active_auctions_page(
 p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,title text,description text,image_url text,current_price numeric,minimum_increment numeric,
 expected_price numeric,target_reached_at timestamptz,starts_at timestamptz,ends_at timestamptz,
 status text,category text,currency text,has_more boolean
) language plpgsql security definer set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Page offset is out of range' using errcode='22023';end if;
 update public.auctions a set status='live',updated_at=now()
 where a.status='scheduled' and a.starts_at is not null and a.starts_at<=now()
  and exists(select 1 from public.products p where p.id=a.product_id and p.status='published');
 return query
 with page as materialized (
  select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,
   a.expected_price,a.target_reached_at,a.starts_at,a.ends_at,a.status,a.category,a.currency::text
  from public.auctions a join public.products p on p.id=a.product_id
  where p.status='published'
   and (a.ends_at is null or a.ends_at>now())
   and ((a.status='live' and a.starts_at is not null and a.starts_at<=now())
     or (a.status='scheduled' and a.starts_at is not null and a.starts_at>now()))
  order by a.starts_at asc,a.id desc
  limit p_limit+1 offset p_offset
 ), marked as (
  select page.*,count(*) over()>p_limit as has_more from page
 )
 select marked.id,marked.title,marked.description,marked.image_url,marked.current_price,marked.minimum_increment,
  marked.expected_price,marked.target_reached_at,marked.starts_at,marked.ends_at,marked.status,marked.category,marked.currency,marked.has_more
 from marked order by marked.starts_at asc,marked.id desc limit p_limit;
end;
$function$;
