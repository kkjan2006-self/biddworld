-- Authenticated member placement tree.
-- Placement genealogy is separate from sponsor/referral genealogy.
-- Duplicate IDs are traversed as structural links when necessary, but only
-- Main IDs are returned to the member-facing tree.
create or replace function public.get_my_placement_tree()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_root_id uuid;
  v_root_code text;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select p.main_member_id
    into v_root_id
  from public.profiles p
  where p.id = v_uid;

  if v_root_id is null then
    raise exception 'Main Member ID is not available' using errcode = 'P0002';
  end if;

  select m.member_code
    into v_root_code
  from public.member_ids m
  where m.id = v_root_id
    and m.owner_user_id = v_uid
    and m.id_type = 'main';

  if not found then
    raise exception 'Member Main ID could not be verified' using errcode = '42501';
  end if;

  with recursive placement_nodes(id, depth, path) as (
    select v_root_id, 0, array[v_root_id]
    union all
    select child.id, parent.depth + 1, parent.path || child.id
    from placement_nodes parent
    join public.member_ids child
      on child.placement_parent_id = parent.id
    where parent.depth < 100
      and not child.id = any(parent.path)
  ),
  visible_main_ids as (
    select m.id, m.member_code, m.status, m.placement_position,
           m.created_at, n.depth, p.display_name
    from placement_nodes n
    join public.member_ids m on m.id = n.id
    join public.profiles p on p.id = m.owner_user_id
    where m.id_type = 'main'
  )
  select jsonb_build_object(
    'root_member_code', v_root_code,
    'tree', coalesce(
      jsonb_agg(
        jsonb_build_object(
          'member_code', member_code,
          'display_name', coalesce(nullif(display_name, ''), 'Member'),
          'status', status,
          'depth', depth,
          'placement_position', placement_position,
          'created_at', created_at
        )
        order by depth, created_at, member_code
      ),
      '[]'::jsonb
    )
  )
  into v_result
  from visible_main_ids;

  return v_result;
end;
$function$;

revoke all on function public.get_my_placement_tree() from public, anon;
grant execute on function public.get_my_placement_tree() to authenticated;
