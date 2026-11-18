-- Public auction catalogue without anonymous table-level SELECT.
-- Return only public listing fields for live/scheduled auctions linked to published products.

create or replace function public.public_list_active_auctions_page(
  p_limit integer default 100,
  p_offset integer default 0
) returns table(
  id uuid,
  title text,
  description text,
  image_url text,
  current_price numeric,
  minimum_increment numeric,
  ends_at timestamptz,
  status text,
  category text,
  currency text
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'Page size must be between 1 and 100' using errcode = '22023';
  end if;
  if p_offset is null or p_offset < 0 or p_offset > 1000000 then
    raise exception 'Page offset is out of range' using errcode = '22023';
  end if;

  return query
  select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,
         a.ends_at,a.status,a.category,a.currency::text
  from public.auctions a
  join public.products p on p.id = a.product_id
  where p.status = 'published'
    and a.ends_at is not null
    and a.ends_at > now()
    and (
      (a.status = 'live' and a.starts_at is not null and a.starts_at <= now())
      or
      (a.status = 'scheduled' and a.starts_at is not null and a.starts_at > now())
    )
  order by a.ends_at asc,a.id desc
  limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated;
