-- Public, paginated product catalogue search.
-- SECURITY INVOKER preserves the caller's existing products RLS policy.
-- Draft and unpublished products are never returned.
create or replace function public.public_list_active_products_page(
 p_search text default null,
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 id uuid,
 name text,
 description text,
 image_path text,
 category text,
 status text,
 has_more boolean
)
language plpgsql
stable
security invoker
set search_path=''
as $function$
declare
 v_search text:=nullif(trim(coalesce(p_search,'')),'');
 v_limit integer:=coalesce(p_limit,100);
 v_offset integer:=coalesce(p_offset,0);
 v_total bigint:=0;
begin
 if v_search is not null and length(v_search)>100 then
  raise exception 'Search text must be at most 100 characters' using errcode='22023';
 end if;
 if v_limit<1 or v_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if v_offset<0 or v_offset>1000000 then
  raise exception 'Page offset is out of range' using errcode='22023';
 end if;
 select count(*) into v_total
 from public.products p
 where p.status='published'
  and (v_search is null
   or position(lower(v_search) in lower(coalesce(p.name,'')))>0
   or position(lower(v_search) in lower(coalesce(p.category,'')))>0
   or position(lower(v_search) in lower(coalesce(p.description,'')))>0);
 return query
 select p.id,p.name,p.description,p.image_path,p.category,p.status,
        (v_offset+v_limit<v_total)
 from public.products p
 where p.status='published'
  and (v_search is null
   or position(lower(v_search) in lower(coalesce(p.name,'')))>0
   or position(lower(v_search) in lower(coalesce(p.category,'')))>0
   or position(lower(v_search) in lower(coalesce(p.description,'')))>0)
 order by p.name,p.id
 limit v_limit offset v_offset;
end;
$function$;
revoke all on function public.public_list_active_products_page(text,integer,integer) from public;
grant execute on function public.public_list_active_products_page(text,integer,integer) to anon,authenticated;
