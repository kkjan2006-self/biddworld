-- Fail closed if a profile's Main-ID pointer is missing, stale, or owned by another account.
-- The recursive tree may include Main and Duplicate descendants, but its root must
-- always be the authenticated user's own Main ID.
create or replace function public.get_my_placement_tree()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_main uuid;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select m.id into v_main
  from public.profiles p
  join public.member_ids m
    on m.id = p.main_member_id
   and m.owner_user_id = p.id
   and m.id_type = 'main'
  where p.id = v_uid;

  if v_main is null then
    raise exception 'An owned Main Member ID is not available' using errcode = '42501';
  end if;

  with recursive placement(member_id, parent_id, depth, path) as (
    select mi.id, mi.placement_parent_id, 0, array[mi.id]
    from public.member_ids mi
    where mi.id = v_main and mi.id_type = 'main'
    union all
    select child.id, child.placement_parent_id, parent.depth + 1, parent.path || child.id
    from placement parent
    join public.member_ids child on child.placement_parent_id = parent.member_id
    where child.id_type in ('main','duplicate')
      and parent.depth < 20
      and not child.id = any(parent.path)
  )
  select jsonb_build_object(
    'root_member_code', (select member_code from public.member_ids where id = v_main),
    'tree', coalesce((
      select jsonb_agg(jsonb_build_object(
        'member_code', mi.member_code,
        'id_type', mi.id_type,
        'main_member_code', main.member_code,
        'display_name', coalesce(nullif(p.display_name, ''), 'Member'),
        'status', mi.status,
        'depth', pl.depth,
        'placement_position', mi.placement_position,
        'created_at', mi.created_at
      ) order by pl.depth, mi.placement_position nulls last, mi.created_at, mi.id)
      from placement pl
      join public.member_ids mi on mi.id = pl.member_id
      join public.profiles p on p.id = mi.owner_user_id
      left join public.member_ids main on main.id = coalesce(mi.main_member_id,mi.id)
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$function$;

revoke all on function public.get_my_placement_tree() from public, anon;
grant execute on function public.get_my_placement_tree() to authenticated, service_role;
