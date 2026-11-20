-- Expose only non-sensitive feature switches and the public withdrawal minimum
-- to authenticated members. All other app_settings keys remain role-scoped.
-- This keeps the existing Admin/Support/Finance visibility unchanged.

drop policy if exists app_settings_read_scoped on public.app_settings;

create policy app_settings_read_scoped
on public.app_settings
for select
to authenticated
using (
  setting_key = any(array[
    'bidding_enabled',
    'fixed_bid_enabled',
    'withdrawals_enabled',
    'duplicate_ids_enabled',
    'winner_selection_configured',
    'package_activations_enabled',
    'minimum_withdrawal_amount'
  ]::text[])
  or coalesce((select auth.jwt()->'app_metadata'->>'role'),'')
     = any(array['admin','support','finance']::text[])
);
