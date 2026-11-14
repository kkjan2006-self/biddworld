-- Persist the mobile number collected by the public registration form.
-- Sponsor referral IDs are retained in Auth user metadata pending the
-- separately validated referral-linking workflow.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member_id uuid;
  v_member_code text;
begin
  insert into public.profiles (id, display_name, phone, status)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    'active'
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        phone = excluded.phone;

  v_member_code := 'BW' || upper(substr(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.member_ids (owner_user_id, member_code, id_type, status)
  values (new.id, v_member_code, 'main', 'active')
  on conflict do nothing
  returning id into v_member_id;

  if v_member_id is null then
    select id into v_member_id
      from public.member_ids
     where owner_user_id = new.id and id_type = 'main'
     limit 1;
  end if;

  if v_member_id is not null then
    update public.profiles
       set main_member_id = v_member_id
     where id = new.id;

    insert into public.wallet_accounts (member_id, wallet_type, balance)
    values (v_member_id, 'bid', 0), (v_member_id, 'income', 0)
    on conflict (member_id, wallet_type) do nothing;
  end if;

  return new;
end;
$function$;

revoke all on function private.handle_new_auth_user() from public, anon, authenticated;
