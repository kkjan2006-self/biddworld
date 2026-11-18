# Member Withdrawal Privacy and Settings RLS Audit — 2026-11-18

## Scope and safety
- Read-only inspection of the live Production Supabase project and checked-in source migrations / member UI.
- Production project was queried only; no DDL, DML, migration, storage or auth changes were made.
- TEST project was not modified. No build or test commands were run.

## Finding 1 — Member withdrawal history returns payout identifiers in live Production

The live Production definition of `public.member_list_my_withdrawals()` returns `w.payout_details` unchanged. That JSON can contain a member's UPI ID or bank account number. The endpoint is scoped to the authenticated user's Main ID, so this is not a cross-member disclosure, but it returns more sensitive payout data than the member history UI needs. The UI only renders `payout_details.method`.

The checked-in migration `20261116170000_minimize_member_withdrawal_payout_data.sql` already fixes this by returning only:
- `{"method":"UPI"}` or the configured method label when present; or
- an empty JSON object when no method is recorded.

It retains the RPC response shape, requires authentication, and revokes execution from `public` and `anon`, granting it only to `authenticated`.

**Status:** source migration exists; live Production definition is still the older version. This audit did not apply the migration.

## Finding 2 — Live Production app_settings policy is behind the checked-in member settings policy

The live Production `app_settings_read_scoped` SELECT policy permits members to read:
- `bidding_enabled`
- `fixed_bid_enabled`
- `withdrawals_enabled`
- `duplicate_ids_enabled`
- `winner_selection_configured`

The Member UI also reads `package_activations_enabled` and `minimum_withdrawal_amount`. These two keys are not in the live Production policy's member-visible allowlist, so those direct reads can be denied by RLS.

The checked-in migration `20261118240000_member_public_feature_settings_read.sql` replaces the policy and adds both keys while preserving Admin/Support/Finance role visibility.

**Status:** source migration exists; live Production policy remains older. This audit did not apply the migration.

## Member UI contract
- `src/components/Account.tsx` displays only the payout method from the withdrawal history response.
- `src/components/Account.tsx` reads the public withdrawal minimum and withdrawal feature switch.
- `src/components/Packages.tsx` reads the package activation feature switch.
- The checked-in source therefore contains the intended privacy and RLS fixes, but the live Production database has not yet received those source migrations.

## Required future baseline work
1. Preserve `20261116170000_minimize_member_withdrawal_payout_data.sql` in the canonical clean-install migration chain.
2. Preserve `20261118240000_member_public_feature_settings_read.sql` in the canonical clean-install migration chain.
3. Validate both behaviors only against the isolated TEST database after clean-install bootstrap is prepared.
4. Keep Production untouched until the user explicitly authorizes a deployment/migration phase.

## Conclusion
Two concrete live-database/source divergences were confirmed. Both have source migrations already checked in; this batch records the evidence and deployment dependency without making any database changes.
