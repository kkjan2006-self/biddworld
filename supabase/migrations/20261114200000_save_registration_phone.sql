-- Persist registration phone without regressing the sponsor validation and
-- referral linking introduced by the earlier production sponsor migration.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member_id uuid;
  v_member_code text;
  v_sponsor_id uuid;
  v_sponsor_code text;
  v_default text;
  v_requested text;
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

  v_requested := nullif(trim(coalesce(new.raw_user_meta_data ->> 'sponsor_referral_id', '')), '');
  if v_requested is not null then
    select id, member_code into v_sponsor_id, v_sponsor_code
      from public.member_ids
     where upper(member_code) = upper(v_requested)
       and id_type = 'main'
       and status = 'active';
    if v_sponsor_id is null then
      raise exception 'Invalid Sponsor Referral ID';
    end if;
  else
    select setting_value #>> '{}' into v_default
      from public.app_settings
     where setting_key = 'default_sponsor_member_id';

    if v_default is not null then
      v_sponsor_id := v_default::uuid;
      select member_code into v_sponsor_code
        from public.member_ids
       where id = v_sponsor_id
         and id_type = 'main'
         and status = 'active';
      if v_sponsor_code is null then
        raise exception 'Default administrator sponsor is not configured correctly';
      end if;
    else
      -- Bootstrap exception: first account precedes the Admin Main ID setup.
      if exists (
        select 1 from public.member_ids
         where id_type = 'main' and status = 'active'
      ) then
        raise exception 'Default administrator sponsor has not been configured';
      end if;
    end if;
  end if;

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

    if v_sponsor_id is not null then
      insert into public.referrals (referred_member_id, referrer_member_id, source_member_id)
      values (v_member_id, v_sponsor_id, v_sponsor_id)
      on conflict (referred_member_id) do nothing;
    end if;
  end if;

  return new;
end;
$function$;

revoke all on function private.handle_new_auth_user() from public, anon, authenticated;
