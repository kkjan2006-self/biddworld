# Supabase migration-chain readiness audit — 2026-11-16

## Scope and evidence
Read-only source review of the 44 files under `supabase/migrations/`, CI workflow, and the package/auth/financial migrations on `completion-work`. Production was not modified. No disposable TEST Supabase project credentials or database connection are configured in this repository, so no migration was executed.

## Findings

### 1. CI does not validate the database migration chain
`.github/workflows/ci.yml` runs Node dependency installation, `npm test`, TypeScript/Vite build and dependency audit. It does not install/use Supabase CLI, start a local Postgres/Supabase stack, replay migrations, or run SQL integration tests. A green CI run therefore proves the frontend/source-contract suite and build, not that the 44 SQL migrations apply cleanly to an empty database or safely upgrade the existing Production schema.

### 2. No Supabase project config is checked in
The recursive branch tree contains `supabase/migrations/` but no `supabase/config.toml`. The repo does not currently define a reproducible local Supabase stack configuration. Do not invent a project ID, secrets, Auth confirmation setting, Storage buckets, or TEST database endpoint.

### 3. Baseline migration lineage needs a clean-room replay
- `0001_biddworld.sql` is labelled as a fresh-project baseline and creates a legacy schema shape (for example `member_ids.user_id`, `package_activations.activation_no/status`, `wallet_accounts.user_id`, `wallet_transactions.user_id`).
- Subsequent timestamped migrations use the newer shape (for example `member_ids.owner_user_id/id_type/status`, `package_activations.activation_number/payment_status/activation_status`, `wallet_accounts.member_id`, `wallet_transactions.member_id/direction`). The intervening migration chain must be proven to transform the baseline completely before any reset or rollout.
- `0002_place_bid_rpc.sql` is an early legacy bid implementation and is superseded by later private/public wrapper migrations and the stable-idempotency migration.
- `001_initial_schema.sql` is present but empty. Its role in the migration history must be confirmed rather than treated as a second baseline.
- There are 44 migration files total. A file count or successful application of the latest migration alone is not evidence that the full ordered chain is sound.

### 4. Package lifecycle source ordering
The current source sequence includes:
1. `20261115010000_submit_package_activation_request.sql` and `20261115020000_admin_package_activation_review.sql`: pending payment request and Admin review RPC.
2. `20261115220000_inactive_until_verified_package_activation.sql`: new profile/Main ID inactive; verified package approval's AFTER trigger activates the profile/Main ID.
3. `20261116000000_financial_approval_guard.sql` and `20261116080000_financial_activity_lockdown.sql`: owner approval interlocks and fail-closed feature settings.
4. `20261116150000_enforce_inactive_signup_until_verified.sql`: signup trigger replacement retaining registration/sponsor checks while keeping new IDs inactive.
5. `20261116200000_lock_package_activation_submission.sql`: direct package submission RPC also checks the package feature switch and owner approval.

This is a coherent intended source sequence, but it is not yet a verified executable migration chain. Trigger order, exact table/column names, function ownership/ACLs and existing Production drift must be checked by replaying the exact ordered files against a disposable database.

## Required clean-room validation before Production
1. Provision a disposable TEST Supabase project (not the Production project and not the old BidWorld-Database project) with explicit owner authorization and no real member/payment data.
2. Establish and commit a reviewed `supabase/config.toml` and documented TEST-only environment variables; keep secrets out of Git.
3. Replay all 44 migrations from an empty database in their actual CLI order; record each migration's result and schema diff.
4. Compare the resulting schema, triggers, function signatures/owners/ACLs and RLS policies against the live Production read-only inventory.
5. Test Auth signup, confirmation/resend and inactive account behavior; pending package request rejection while flags are false; Admin approve/reject; rollback on financial guard failure; duplicate payment references under concurrency; and no wallet/member activation on failed approval.
6. Run the same test suite against the upgraded TEST snapshot and retain logs/artifacts.
7. Only after owner review and explicit approval may a separately planned Production rollout be considered. Never reset Production or replay the baseline against it.

## Safety status
- No Production SQL writes, DDL, DML, feature changes, Auth users, package requests or wallet activity.
- No TEST project was assumed to exist or silently selected.
- Package activation and all financial features remain unavailable until economic, funding and legal/compliance approval.
