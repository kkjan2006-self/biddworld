-- Return only each account's canonical, profile-linked Main ID in Admin notification recipient lookup.
-- Owners may retain historical Main ID rows; profiles.main_member_id identifies the canonical account Main ID.
create or replace function public.admin_lookup_notification_recipients(
 p_search text
) returns table(user_id uuid,member_code text,display_name text,phone text)
language plpgsql stable security definer set search_path=''
as $function$
declare v_search text:=btrim(coalesce(p_search,''));
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if length(v_search)<2 or length(v_search)>120 then
  raise exception 'Search must contain 2 to 120 characters' using errcode='22023';
 end if;
 return query
 select p.id,m.member_code,coalesce(p.display_name,''),coalesce(p.phone,'')
 from public.profiles p
 join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id and m.id_type='main'
 where position(lower(v_search) in lower(m.member_code))>0
    or position(lower(v_search) in lower(coalesce(p.display_name,'')))>0
    or position(lower(v_search) in lower(coalesce(p.phone,'')))>0
 order by m.created_at desc,m.id desc limit 25;
end;
$function$;
revoke all on function public.admin_lookup_notification_recipients(text) from public,anon;
grant execute on function public.admin_lookup_notification_recipients(text) to authenticated;
