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

  insert into public.app_settings(setting_key, setting_value, updated_at)
  values
    ('registration_enabled', 'true'::jsonb, now()),
    ('email_verification_required', 'false'::jsonb, now())
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
