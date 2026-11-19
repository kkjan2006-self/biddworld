-- Stable keyset pagination for the Admin notification history.
-- Keep the previous offset RPC for older clients; the current UI uses this bounded cursor API.
create or replace function public.admin_list_member_notifications_keyset_page(
 p_limit integer default 101,
 p_cursor_created_at timestamptz default null,
 p_cursor_id uuid default null,
 p_category text default 'all'
) returns table(
 id uuid,
 user_id uuid,
 recipient_member_code text,
 recipient_name text,
 title text,
 message text,
 category text,
 read_at timestamptz,
 created_at timestamptz
)
language plpgsql
stable
security definer
set search_path=''
as $function$
begin
 if auth.uid() is null
  or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<2 or p_limit>101
  or (p_cursor_created_at is null)<>(p_cursor_id is null)
  or p_category is null or p_category not in ('all','general','account','support','security') then
  raise exception 'Notification cursor or page size is invalid' using errcode='22023';
 end if;
 return query
 select n.id,n.user_id,
  coalesce(member.member_code,'No Main ID'),
  coalesce(nullif(profile.display_name,''),'Member'),
  n.title,n.message,n.category,n.read_at,n.created_at
 from public.member_notifications n
 left join public.profiles profile on profile.id=n.user_id
 left join lateral(
  select m.member_code from public.member_ids m
  where m.owner_user_id=n.user_id and m.id_type='main'
  order by m.created_at,m.id limit 1
 ) member on true
 where (p_category='all' or n.category=p_category)
  and (p_cursor_created_at is null or
   (n.created_at,n.id)<(p_cursor_created_at,p_cursor_id))
 order by n.created_at desc,n.id desc
 limit p_limit;
end;
$function$;
revoke all on function public.admin_list_member_notifications_keyset_page(integer,timestamptz,uuid,text) from public,anon;
grant execute on function public.admin_list_member_notifications_keyset_page(integer,timestamptz,uuid,text) to authenticated;
