-- Admin-only, bounded pagination for the Main ID directory.
-- Keeps the existing read-only directory contract; no member records are changed.
create or replace function public.admin_list_members_sponsors_page(
 p_search text default null,
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 member_code text,
 display_name text,
 phone text,
 sponsor_code text,
 created_at timestamptz
)
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_search text := trim(coalesce(p_search,''));
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200
    or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select m.member_code,coalesce(p.display_name,''),coalesce(p.phone,''),
        coalesce(s.member_code,''),m.created_at
 from public.member_ids m
 join public.profiles p on p.id=m.owner_user_id
 left join public.referrals r on r.referred_member_id=m.id
 left join public.member_ids s on s.id=r.referrer_member_id
 where m.id_type='main'
   and (
    v_search=''
    or m.member_code ilike '%'||replace(replace(v_search,'%','\\%'),'_','\\_')||'%' escape '\\'
    or coalesce(p.display_name,'') ilike '%'||replace(replace(v_search,'%','\\%'),'_','\\_')||'%' escape '\\'
    or coalesce(p.phone,'') ilike '%'||replace(replace(v_search,'%','\\%'),'_','\\_')||'%' escape '\\'
    or coalesce(s.member_code,'') ilike '%'||replace(replace(v_search,'%','\\%'),'_','\\_')||'%' escape '\\'
   )
 order by m.created_at desc,m.id desc
 limit p_limit offset p_offset;
end;
$function$;
revoke all on function public.admin_list_members_sponsors_page(text,integer,integer) from public,anon;
grant execute on function public.admin_list_members_sponsors_page(text,integer,integer) to authenticated;
