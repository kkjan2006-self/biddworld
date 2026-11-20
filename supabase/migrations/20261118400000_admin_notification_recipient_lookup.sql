-- Admin-only recipient lookup for in-app notifications.
-- Auth user IDs are exposed only to trusted Admins; the general member directory
-- deliberately omits account UUIDs.
create or replace function public.admin_lookup_notification_recipients(
 p_search text
) returns table(
 user_id uuid,
 member_code text,
 display_name text,
 phone text
)
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_search text := btrim(coalesce(p_search,''));
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if length(v_search)<2 or length(v_search)>120 then
  raise exception 'Search must contain 2 to 120 characters' using errcode='22023';
 end if;
 return query
 select p.id,m.member_code,coalesce(p.display_name,''),coalesce(p.phone,'')
 from public.member_ids m
 join public.profiles p on p.id=m.owner_user_id
 where m.id_type='main'
   and (
    position(lower(v_search) in lower(m.member_code))>0
    or position(lower(v_search) in lower(coalesce(p.display_name,'')))>0
    or position(lower(v_search) in lower(coalesce(p.phone,'')))>0
   )
 order by m.created_at desc,m.id desc
 limit 25;
end;
$function$;
revoke all on function public.admin_lookup_notification_recipients(text) from public,anon;
grant execute on function public.admin_lookup_notification_recipients(text) to authenticated;
