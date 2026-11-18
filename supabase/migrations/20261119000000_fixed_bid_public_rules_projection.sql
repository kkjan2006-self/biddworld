-- Extend the public Fixed Bid catalogue projection with the full published entry limits and refund rule.
-- Keep the restricted column projection; do not grant direct table reads.
create or replace function public.public_list_fixed_bid_campaigns_page(
  p_search text default null,
  p_status text default 'all',
  p_limit integer default 50,
  p_offset integer default 0
) returns table(
  id uuid,
  title text,
  description text,
  status text,
  created_at timestamptz,
  configuration jsonb,
  product jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
begin
  if v_search is not null and length(v_search) > 100 then
    raise exception 'Search text must be at most 100 characters' using errcode = '22023';
  end if;
  if p_status is null or p_status not in ('all', 'scheduled', 'live', 'ended') then
    raise exception 'Unsupported Fixed Bid campaign status filter' using errcode = '22023';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 50 then
    raise exception 'Page size must be between 1 and 50' using errcode = '22023';
  end if;
  if p_offset is null or p_offset < 0 or p_offset > 1000000 then
    raise exception 'Page offset is out of range' using errcode = '22023';
  end if;

  return query
  select
    c.id,
    c.title,
    c.description,
    c.status,
    c.created_at,
    jsonb_build_object(
      'entry_amount', c.configuration->'entry_amount',
      'winner_payment_amount', c.configuration->'winner_payment_amount',
      'max_entries_per_member', c.configuration->'max_entries_per_member',
      'max_entries_total', c.configuration->'max_entries_total',
      'winner_count', c.configuration->'winner_count',
      'starts_at', c.configuration->'starts_at',
      'ends_at', c.configuration->'ends_at',
      'refund_non_winners', c.configuration->'refund_non_winners'
    ) as configuration,
    jsonb_build_object(
      'name', p.name,
      'description', p.description,
      'category', p.category,
      'image_path', p.image_path
    ) as product
  from public.fixed_bid_campaigns c
  join public.products p on p.id = c.product_id
  where p.status = 'published'
    and c.status in ('scheduled', 'live', 'ended')
    and (p_status = 'all' or c.status = p_status)
    and (
      v_search is null
      or position(lower(v_search) in lower(coalesce(c.title, ''))) > 0
    )
    and case
      when c.status = 'ended' then true
      when c.status = 'scheduled' then
        nullif(c.configuration->>'starts_at', '')::timestamptz is not null
        and nullif(c.configuration->>'ends_at', '')::timestamptz is not null
        and nullif(c.configuration->>'starts_at', '')::timestamptz > now()
        and nullif(c.configuration->>'ends_at', '')::timestamptz > now()
      when c.status = 'live' then
        nullif(c.configuration->>'starts_at', '')::timestamptz is not null
        and nullif(c.configuration->>'ends_at', '')::timestamptz is not null
        and nullif(c.configuration->>'starts_at', '')::timestamptz <= now()
        and nullif(c.configuration->>'ends_at', '')::timestamptz > now()
      else false
    end
  order by c.created_at desc, c.id desc
  limit p_limit
  offset p_offset;
end;
$function$;

revoke all on function public.public_list_fixed_bid_campaigns_page(text,text,integer,integer) from public, anon, authenticated;
grant execute on function public.public_list_fixed_bid_campaigns_page(text,text,integer,integer) to anon, authenticated;
