-- BiddWorld registration does not require email verification by default.
-- Keep the Admin override available, but make clean installs and upgrades consistent
-- with the requested immediate-login registration flow. Supabase Auth's provider
-- Confirm Email option remains an environment-level setting and must be OFF as well.
insert into public.app_settings(setting_key,setting_value,updated_at)
values('email_verification_required','false'::jsonb,now())
on conflict(setting_key) do update
 set setting_value=excluded.setting_value,updated_at=now();

create or replace function public.public_get_registration_email_verification()
returns boolean
language sql
stable
security definer
set search_path=''
as $function$
 select coalesce((
  select (setting_value#>>'{}')::boolean
  from public.app_settings
  where setting_key='email_verification_required'
 ),false);
$function$;

revoke all on function public.public_get_registration_email_verification() from public;
grant execute on function public.public_get_registration_email_verification() to anon,authenticated;
