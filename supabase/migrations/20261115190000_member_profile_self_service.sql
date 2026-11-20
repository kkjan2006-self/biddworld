-- Allow an authenticated member to update only their own display name and phone.
-- Identity, member IDs, sponsor, status and wallet fields remain server-controlled.
create or replace function public.member_update_my_profile(
  p_display_name text,
  p_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text := btrim(coalesce(p_display_name, ''));
  v_phone text := btrim(coalesce(p_phone, ''));
  v_old_name text;
  v_old_phone text;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if char_length(v_name) < 2 or char_length(v_name) > 100 then
    raise exception 'Name must contain between 2 and 100 characters';
  end if;

  if v_phone !~ '^\+?[0-9][0-9 ()-]{7,15}$' then
    raise exception 'Enter a valid mobile number';
  end if;

  select p.display_name, p.phone
    into v_old_name, v_old_phone
  from public.profiles p
  where p.id = v_user_id
  for update;

  if not found then
    raise exception 'Member profile not found';
  end if;

  update public.profiles
  set display_name = v_name,
      phone = v_phone,
      updated_at = now()
  where id = v_user_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (
    v_user_id,
    'member_profile_updated',
    'profile',
    v_user_id,
    jsonb_build_object(
      'changed_fields',
      to_jsonb(array_remove(array[
        case when v_old_name is distinct from v_name then 'display_name' end,
        case when v_old_phone is distinct from v_phone then 'phone' end
      ], null))
    )
  );

  return jsonb_build_object('display_name', v_name, 'phone', v_phone);
end;
$$;

revoke all on function public.member_update_my_profile(text, text) from public, anon;
grant execute on function public.member_update_my_profile(text, text) to authenticated;
