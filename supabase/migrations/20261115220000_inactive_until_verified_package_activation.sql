-- Registration and package activation lifecycle:
-- every new Main ID starts inactive; a verified, approved package top-up activates it.
-- This migration is prepared on the development branch only. Do not apply to Production
-- until the owner has approved the package economics, funding and legal/compliance model.

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
    'inactive'
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
      -- First-account bootstrap only. Later signups require a valid active
      -- sponsor or a configured active default sponsor.
      if exists (
        select 1 from public.member_ids
         where id_type = 'main'
      ) then
        raise exception 'Default administrator sponsor has not been configured';
      end if;
    end if;
  end if;

  v_member_code := 'BW' || upper(substr(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.member_ids (owner_user_id, member_code, id_type, status)
  values (new.id, v_member_code, 'main', 'inactive')
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

-- Allow an inactive Main ID to submit a package top-up request. It remains
-- inactive until the existing Admin approval RPC verifies the payment.
create or replace function private.submit_package_activation(
  p_package_id uuid,
  p_payment_reference text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_package public.packages%rowtype;
  v_activation_id uuid;
  v_activation_number integer;
  v_reference text := btrim(coalesce(p_payment_reference, ''));
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if length(v_reference) < 6 or length(v_reference) > 80
     or v_reference !~ '^[A-Za-z0-9./_-]+$' then
    raise exception 'Enter a valid payment reference (6 to 80 letters or numbers)';
  end if;

  select id into v_member_id
    from public.member_ids
   where owner_user_id = v_uid and id_type = 'main'
   for update;
  if v_member_id is null then
    raise exception 'A Main ID is required to request package activation';
  end if;

  select * into v_package from public.packages
   where id = p_package_id and is_active = true for share;
  if not found then raise exception 'This package is not available'; end if;

  if exists (select 1 from public.package_activations
      where lower(btrim(payment_reference)) = lower(v_reference)) then
    raise exception 'This payment reference has already been submitted';
  end if;

  select coalesce(max(activation_number), 0) + 1 into v_activation_number
    from public.package_activations where member_id = v_member_id;

  insert into public.package_activations
    (member_id, package_id, activation_number, amount_paid, currency,
     bid_wallet_credit, payment_status, activation_status, payment_reference, submitted_at)
  values
    (v_member_id, v_package.id, v_activation_number, v_package.price, v_package.currency,
     v_package.bid_wallet_credit, 'pending', 'pending', v_reference, now())
  returning id into v_activation_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (v_uid, 'package_activation_submitted', 'package_activation', v_activation_id,
    jsonb_build_object('package_id', v_package.id, 'member_id', v_member_id,
      'payment_reference', v_reference, 'amount', v_package.price,
      'bid_wallet_credit', v_package.bid_wallet_credit, 'currency', v_package.currency));

  return jsonb_build_object('success', true, 'activation_id', v_activation_id,
    'activation_number', v_activation_number, 'payment_status', 'pending',
    'activation_status', 'pending');
end;
$function$;

revoke all on function private.submit_package_activation(uuid, text)
  from public, anon, authenticated;

-- Existing public RPC remains the narrow SECURITY DEFINER wrapper and keeps
-- its authenticated-only EXECUTE grant from the prior migration.

create or replace function private.activate_member_after_verified_topup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.payment_status = 'approved' and new.activation_status = 'active'
     and (old.payment_status is distinct from new.payment_status
       or old.activation_status is distinct from new.activation_status) then
    update public.member_ids
       set status = 'active'
     where id = new.member_id
       and id_type = 'main'
       and status = 'inactive';

    update public.profiles p
       set status = 'active'
      from public.member_ids m
     where m.id = new.member_id
       and m.owner_user_id = p.id
       and p.status = 'inactive';
  end if;
  return new;
end;
$function$;

revoke all on function private.activate_member_after_verified_topup()
  from public, anon, authenticated;

drop trigger if exists activate_member_after_verified_topup
  on public.package_activations;
create trigger activate_member_after_verified_topup
after update of payment_status, activation_status
on public.package_activations
for each row
execute function private.activate_member_after_verified_topup();

-- Existing account statuses are intentionally not bulk-updated by this migration.
-- Historical reconciliation requires a separately reviewed, owner-approved plan.
