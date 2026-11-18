-- Member-owned identity list used by the Account portal.
-- Exposes only the authenticated user's own Main and Duplicate IDs.
-- The previous migration returned an additional main_member_code column. PostgreSQL
-- cannot change a RETURNS TABLE row type through CREATE OR REPLACE, so drop the
-- exact zero-argument function before installing this canonical seven-column shape.
drop function if exists public.member_list_my_ids();

create or replace function public.member_list_my_ids()
returns table(
 id uuid,
 member_code text,
 id_type text,
 status text,
 created_at timestamptz,
 placement_position text,
 placement_parent_code text
)
language sql
stable
security definer
set search_path=''
as $function$
 select m.id,m.member_code,m.id_type,m.status,m.created_at,m.placement_position,parent.member_code
 from public.member_ids m
 left join public.member_ids parent on parent.id=m.placement_parent_id
 where m.owner_user_id=(select auth.uid())
 order by case when m.id_type='main' then 0 else 1 end,m.created_at,m.id;
$function$;

revoke all on function public.member_list_my_ids() from public,anon;
grant execute on function public.member_list_my_ids() to authenticated;

comment on function public.member_list_my_ids() is
 'Returns only the authenticated user own Main and Duplicate ID records for the member Account portal.';
