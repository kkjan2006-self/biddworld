-- Ensure the signup feature switches exist on environments where the
-- feature-settings seed was absent or the settings table was provisioned empty.
-- Preserve any explicit administrator choice already stored.
insert into public.app_settings(setting_key,setting_value,updated_at)
values
 ('registration_enabled','true'::jsonb,now()),
 ('sponsor_referrals_enabled','false'::jsonb,now())
on conflict(setting_key) do nothing;

-- Keep the Auth trigger's fail-closed behavior for registration if an operator
-- later explicitly disables the setting. The seed above only supplies defaults.
