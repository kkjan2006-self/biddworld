-- BiddWorld TEST project bootstrap only.
-- Run manually in the Supabase SQL Editor for project yoaauthwejdgaevfvwpo.
-- NEVER run this script against Production. This is intentionally outside
-- supabase/migrations so it cannot be applied by the normal migration pipeline.
--
-- Before running:
--   1. Create the owner-designated account through the TEST Preview signup page
--      using Kkjan2006@gmail.com.
--   2. Confirm that the account exists in Authentication -> Users.
--   3. Verify the SQL Editor is connected to the TEST project ref above.
--
-- This script grants the trusted app_metadata role only to that exact email.
-- It does not set a password, create fake members, or credit any wallet.

begin;

do $bootstrap$
declare
  v_user_id uuid;
  v_metadata jsonb;
begin
  select id, coalesce(raw_app_meta_data, '{}'::jsonb)
    into v_user_id, v_metadata
    from auth.users
   where lower(email) = lower('Kkjan2006@gmail.com')
   for update;

  if v_user_id is null then
    raise exception
      'TEST Admin account not found. First register Kkjan2006@gmail.com in the TEST Preview, then rerun this script.';
  end if;

  update auth.users
     set raw_app_meta_data = jsonb_set(v_metadata, '{role}', '"admin"'::jsonb, true)
   where id = v_user_id;

  -- Enable the Preview feature switches in TEST only so every module can be
  -- exercised from the Admin and Member accounts. This does not create balances,
  -- transactions, packages, auctions, or payment records.
  insert into public.app_settings(setting_key, setting_value, updated_at)
  values
    ('registration_enabled', 'true'::jsonb, now()),
    ('email_verification_required', 'false'::jsonb, now()),
    ('sponsor_referrals_enabled', 'true'::jsonb, now()),
    ('duplicate_ids_enabled', 'true'::jsonb, now()),
    ('automatic_placement_enabled', 'true'::jsonb, now()),
    ('package_activations_enabled', 'true'::jsonb, now()),
    ('referral_commissions_enabled', 'true'::jsonb, now()),
    ('bid_wallet_enabled', 'true'::jsonb, now()),
    ('income_wallet_enabled', 'true'::jsonb, now()),
    ('withdrawals_enabled', 'true'::jsonb, now()),
    ('bidding_enabled', 'true'::jsonb, now()),
    ('fixed_bid_enabled', 'true'::jsonb, now()),
    ('winner_selection_configured', 'true'::jsonb, now()),
    ('winning_payment_enabled', 'true'::jsonb, now()),
    ('delivery_tracking_enabled', 'true'::jsonb, now()),
    ('notifications_enabled', 'true'::jsonb, now()),
    ('financial_model_approved', 'true'::jsonb, now())
  on conflict (setting_key) do update
    set setting_value = excluded.setting_value,
        updated_at = now();
end;
$bootstrap$;

commit;

-- After running:
--   * Sign out and sign back in to refresh the trusted Admin role claim.
--   * The TEST Supabase Auth provider's Email Confirm setting is separate from
--     app_settings.email_verification_required. For convenient TEST signup,
--     disable Email Confirm in TEST only (Authentication -> Providers -> Email).
--   * Never copy this setup to Production.
