-- Public package catalogue: expose only currently published package fields.
-- Draft packages and Admin-only settings remain private.

create or replace function public.public_list_active_packages_page(
  p_limit integer default 100,
  p_offset integer default 0
) returns table(
  id uuid,
  name text,
  description text,
  price numeric,
  currency text,
  bid_wallet_credit numeric
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
  select p.id,p.name,p.description,p.price,p.currency::text,p.bid_wallet_credit
  from public.packages p
  where p.is_active = true
  order by p.price asc,p.id asc
  limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.public_list_active_packages_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_packages_page(integer,integer) to anon,authenticated;
