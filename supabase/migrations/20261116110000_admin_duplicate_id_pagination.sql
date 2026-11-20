-- Bounded Admin Duplicate ID directory with full-history search and continuation.
-- Source-only until reviewed and explicitly reconciled with Production.

create or replace function public.admin_list_duplicate_ids_page(
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  id uuid,
  member_code text,
  status text,
  created_at timestamptz,
  main_member_id uuid,
  main_member_code text,
  display_name text,
  phone text,
  under_member_code text,
  under_display_name text,
  total_count bigint,
  has_more boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_search text := nullif(trim(coalesce(p_search,'')),'');
  v_limit integer := coalesce(p_limit,50);
  v_offset integer := coalesce(p_offset,0);
  v_total bigint := 0;
begin
  if auth.uid() is null
     or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if v_limit < 1 or v_limit > 100 then
    raise exception 'Page size must be between 1 and 100' using errcode='22023';
  end if;
  if v_offset < 0 or v_offset > 1000000 then
    raise exception 'Page offset is out of range' using errcode='22023';
  end if;

  select count(*) into v_total
  from public.member_ids d
  join public.member_ids m on m.id=d.main_member_id and m.id_type='main'
  left join public.profiles p on p.id=d.owner_user_id
  left join public.member_ids parent on parent.id=d.placement_parent_id
  left join public.profiles under_profile on under_profile.id=parent.owner_user_id
  where d.id_type='duplicate'
    and (v_search is null
      or position(lower(v_search) in lower(coalesce(d.member_code,''))) > 0
      or position(lower(v_search) in lower(coalesce(m.member_code,''))) > 0
      or position(lower(v_search) in lower(coalesce(p.display_name,''))) > 0
      or position(lower(v_search) in lower(coalesce(p.phone,''))) > 0
      or position(lower(v_search) in lower(coalesce(parent.member_code,''))) > 0
      or position(lower(v_search) in lower(coalesce(under_profile.display_name,''))) > 0
      or position(lower(v_search) in lower(coalesce(d.status,''))) > 0);

  return query
  select d.id,d.member_code,d.status,d.created_at,m.id,m.member_code,
         p.display_name,p.phone,parent.member_code,under_profile.display_name,
         v_total,(v_offset + v_limit < v_total)
  from public.member_ids d
  join public.member_ids m on m.id=d.main_member_id and m.id_type='main'
  left join public.profiles p on p.id=d.owner_user_id
  left join public.member_ids parent on parent.id=d.placement_parent_id
  left join public.profiles under_profile on under_profile.id=parent.owner_user_id
  where d.id_type='duplicate'
    and (v_search is null
      or position(lower(v_search) in lower(coalesce(d.member_code,''))) > 0
      or position(lower(v_search) in lower(coalesce(m.member_code,''))) > 0
      or position(lower(v_search) in lower(coalesce(p.display_name,''))) > 0
      or position(lower(v_search) in lower(coalesce(p.phone,''))) > 0
      or position(lower(v_search) in lower(coalesce(parent.member_code,''))) > 0
      or position(lower(v_search) in lower(coalesce(under_profile.display_name,''))) > 0
      or position(lower(v_search) in lower(coalesce(d.status,''))) > 0)
  order by d.created_at desc,d.id desc
  limit v_limit offset v_offset;
end;
$function$;

revoke all on function public.admin_list_duplicate_ids_page(text,integer,integer) from public,anon;
grant execute on function public.admin_list_duplicate_ids_page(text,integer,integer) to authenticated;
