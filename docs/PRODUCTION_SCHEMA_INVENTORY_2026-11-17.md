# BiddWorld live schema inventory and TEST bootstrap decision — 2026-11-17

## Scope and safeguards

- Source: `completion-work` branch; this audit is documentation-only.
- Production reference: `BiddWorld-Production` / `hbqatszyzqobgtauyuzy`.
- TEST target: `BiddWorld-TEST` / `yoaauthwejdgaevfvwpo`.
- Production catalogue queries were read-only. No Production DDL/DML, function invocation, migration, Auth, Storage, wallet, member, auction or payment action was performed.
- TEST remains empty. No migration has been applied to TEST.
- The catalogue snapshot records structure and metadata only; no Production business rows or secrets were copied.

## Live Production catalogue snapshot

The current Production public schema contains 21 ordinary tables:

`app_settings`, `auctions`, `audit_logs`, `bids`, `delivery_tracking`, `fixed_bid_campaigns`, `fixed_bids`, `member_ids`, `notification_templates`, `package_activations`, `packages`, `products`, `profiles`, `referral_commissions`, `referral_level_rules`, `referral_plan_versions`, `referrals`, `wallet_accounts`, `wallet_transactions`, `winning_item_payments`, `withdrawal_requests`.

- RLS is enabled on all 21 tables.
- FORCE ROW LEVEL SECURITY is not enabled on these tables.
- The catalogue reports 20 table policies; all are SELECT policies assigned to the `authenticated` role. This is not, by itself, a complete authorization review.
- Ten feature-gate triggers are present on bids, delivery tracking, fixed-bid campaigns, member IDs, package activations, referral commissions, referrals, wallet transactions, winning payments and withdrawals.
- The public function catalogue contains 43 functions/overloads. The separate RPC security review records 43/43 SECURITY DEFINER functions with an explicit empty search_path configuration; Admin authorization and grants still require function-by-function review.
- Authenticated table grants are read-oriented; privileged mutations are predominantly exposed through RPCs. Do not infer safety from grants alone.

## Important current column contracts observed

- `member_ids`: `owner_user_id`, `main_member_id`, `member_code`, `id_type`, `status`, `placement_parent_id`, `placement_position`.
- `profiles`: `id`, `main_member_id`, `display_name`, `phone`, `status`.
- `wallet_accounts`: `member_id`, `wallet_type`, `balance`, `currency`.
- `wallet_transactions`: `wallet_account_id`, `member_id`, `transaction_type`, `direction`, `amount`, `balance_after`, optional `idempotency_key`.
- `package_activations`: `member_id`, `package_id`, `activation_number`, `payment_status`, `activation_status`, `payment_reference`, `bid_wallet_credit`.
- `bids`: `auction_id`, `member_id`, `bid_amount`, wallet debit split, required `idempotency_key`.
- `fixed_bids`: `campaign_id`, `member_id`, `bid_amount`, `status`, required `idempotency_key`.

This abbreviated list is not a substitute for full DDL, constraints, index definitions, function bodies, ACLs, grants, policies and trigger definitions.

## Migration ledger reconciliation

- Current repository tree: 47 SQL files (3 legacy/unversioned files plus 44 timestamped files).
- Production migration ledger: 30 applied entries; latest recorded version is `20261115163218_admin_audit_log_pagination`.
- TEST migration ledger: empty.
- The Production ledger is not a one-to-one match for the current branch file names/timestamps. Existing `docs/SUPABASE_MIGRATION_HISTORY_RECONCILIATION_2026-11-17.md` details the mismatch.
- The old baseline `0001_biddworld.sql` uses incompatible legacy identifiers/data shapes; `0002_place_bid_rpc.sql` contains the legacy one-argument bid RPC; `001_initial_schema.sql` is empty.
- Current source-only migrations include later changes after the Production ledger's latest version, including sponsor/duplicate-placement serialization, Admin profile update, duplicate-status no-op guard and package activation member-status guard.

## Current mismatch and test blockers

1. Current UI requires `place_bid(uuid,text)` with stable idempotency; Production still exposes `place_bid(uuid)`. No unsafe fallback is permitted.
2. Production `admin_create_duplicate_member_id(text)` is one-argument; current UI/source expects Main ID plus placement-under ID.
3. Production sponsor lookup returns a table including display name; current source migration narrows the result to a boolean contract.
4. Several UI RPCs are absent from Production; see `docs/FRONTEND_PRODUCTION_RPC_MATRIX_2026-11-17.md`.
5. Production has zero Storage buckets; product-media upload has not been verified.
6. The branch's CI workflow runs JS tests/typecheck/build but does not replay Supabase migrations against an empty database or run PostgreSQL/RLS integration tests.
7. No checked-in `supabase/config.toml` exists to define a reproducible local Supabase stack.

## Decision

**Do not apply the 47 files as-is to TEST. Do not modify Production.** The schema snapshot is a comparison reference, not a deployable migration. A canonical clean-install baseline cannot safely be inferred from catalogue names alone; it must preserve complete definitions and dependencies and must not copy Production data.

Next engineering batch:
1. Recover exact SQL lineage where possible from Git history and Supabase migration history.
2. Build a data-free clean-install baseline from verified source definitions; explicitly reconcile every object against the 21-table snapshot and the 43-function catalogue.
3. Add a reproducible local Supabase configuration and migration replay job.
4. Replay the full chain locally/against disposable TEST, recording every migration result.
5. Verify RLS, grants, function signatures/ACLs, trigger order, constraints/indexes and Auth/signup behavior.
6. Only after clean replay passes, run synthetic end-to-end tests against TEST and update the completion register with actual evidence.

## References

- `docs/TEST_DATABASE_BOOTSTRAP_AUDIT_2026-11-17.md`
- `docs/SUPABASE_MIGRATION_HISTORY_RECONCILIATION_2026-11-17.md`
- `docs/FRONTEND_PRODUCTION_RPC_MATRIX_2026-11-17.md`
- `docs/PRODUCTION_RPC_SECURITY_CONTRACT_MATRIX_2026-11-17.md`
- Supabase migration workflow: https://supabase.com/docs/guides/deployment/database-migrations
