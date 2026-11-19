# BiddWorld migration baseline audit

Date: 2026-11-19
Branch: `completion-work`
Scope: source-only inspection; no database connection or migration execution.

## Finding: checked-in bootstrap schema does not match the schema assumed by later migrations

The checked-in `supabase/migrations/0001_biddworld.sql` defines legacy columns including:

- `member_ids.user_id` and `member_ids.parent_member_id`
- `package_activations.user_id`, `activation_no`, `amount`, and `status`
- `wallet_accounts.user_id`
- `wallet_transactions.user_id` and no `direction` column
- `audit_logs.metadata`

The next checked-in `0002_place_bid_rpc.sql` also queries wallets by `user_id` and writes legacy wallet transaction columns.

By contrast, later migrations and current application source assume:

- `member_ids.owner_user_id`, `main_member_id`, `placement_parent_id`, and `placement_position`
- `package_activations.member_id`, `activation_number`, `payment_status`, `activation_status`, `amount_paid`, and `submitted_at`
- `wallet_accounts.member_id`
- `wallet_transactions.member_id` and `direction`
- `audit_logs.details`

For example, `20261114161950_secure_bid_rpc_and_signup_provisioning.sql` already assumes the newer member and wallet columns. `20261115010000_submit_package_activation_request.sql` assumes the newer activation fields. The checked-in `001_initial_schema.sql` is an empty one-byte file.

## What this means

A clean database replay beginning with the checked-in `0001_biddworld.sql` cannot be assumed to reach the schema required by the later migrations. The source tree does not currently provide a clearly identified, complete legacy-to-current schema reconciliation migration.

This is a repository migration-chain finding, not proof that either hosted TEST or Production currently has the legacy schema. Those live schemas were not inspected.

## Safe next action

1. Preserve all existing migrations and production data.
2. Obtain an authoritative schema-only snapshot or migration history from the intended TEST project, plus confirmation of which migration files were applied there.
3. Compare that snapshot with the current application and Matrix migration column contracts.
4. Only then author a forward-only, idempotent reconciliation migration if required, and rehearse it on TEST after explicit authorization.

Do not edit `0001_biddworld.sql`, do not backfill or rename live columns based on inference, and do not apply any migration to TEST or Production as part of this audit.

## Verification boundary

- Inspected source files: `0001_biddworld.sql`, `0002_place_bid_rpc.sql`, `001_initial_schema.sql`, `20261114161950_secure_bid_rpc_and_signup_provisioning.sql`, `20261114200000_save_registration_phone.sql`, `20261114230000_mlm_dashboard_genealogy.sql`, `20261115010000_submit_package_activation_request.sql`, `20261115020000_admin_package_activation_review.sql`, `20261115190000_member_profile_self_service.sql`, `20261115203000_member_identity_summary.sql`, `20261115230000_duplicate_under_id_placement_attribution.sql`, `20261119300000_automatic_duplicate_matrix_placement.sql`, and `20261119310000_matrix_commission_engine.sql`.
- No tests, build, type-check, browser/mobile QA run.
- No TEST or Production database was queried or modified.
