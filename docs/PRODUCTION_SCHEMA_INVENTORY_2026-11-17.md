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
- The public function catalogue contains 43 functions/overloads; all 43 are SECURITY DEFINER. A fresh catalogue check shows 42 use an empty `search_path`; `public.place_bid(uuid)` explicitly sets `pg_catalog, public, private`. The private helper `private.place_bid(uuid)` explicitly sets `pg_catalog, public`. These restricted paths are not empty paths and require function-body/ACL review.
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

- Current 2026-11-18 repository tree: 49 SQL files (3 legacy/unversioned files plus 46 timestamped files).
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


## 2026-11-18 recheck — object-level and frontend contract findings

- The Production public-table list is exactly the 21 tables shown above. It does **not** include `support_tickets` or `member_notifications`; the current source branch has separate migrations to create those tables. `delivery_tracking` is present. The `notification_templates` table is present, but its historical creation migration is one of the unrecovered Production ledger entries.
- A fresh `storage.buckets` SELECT returned zero rows. The source migration `20261116020000_admin_product_management_and_media.sql` creates the `product-media` bucket and its policies; those changes are not present in Production.
- All 20 Production RLS policies are SELECT policies for `authenticated`; there are no table write policies in this catalogue result. Authenticated table grants are SELECT-only; privileged writes are exposed through SECURITY DEFINER RPCs. This is a metadata observation, not a complete security approval.
- Ten public-table triggers all call `private.enforce_feature_gate()`. The private schema contains four helper functions: `enforce_feature_gate()`, `handle_new_auth_user()`, `place_bid(uuid)`, and `submit_package_activation(uuid,text)`.
- Exact migration comparison: 4/30 exact timestamp-and-name matches; 9/30 same-name/different-timestamp matches; 17/30 Production ledger entries have no corresponding source file. Exact-path GitHub history checks for those 17 files returned no commits. Sixteen of the 46 timestamped source files do not map by name to a Production ledger entry and require object-level classification before replay.
- The nine missing frontend RPCs listed in the current RPC matrix do have definitions in current source migrations, but are absent from Production. Their source files are: `20261115203000_member_identity_summary.sql`, `20261115230000_duplicate_under_id_placement_attribution.sql`, `20261115190000_member_profile_self_service.sql`, `20261116090000_admin_members_sponsors_pagination.sql`, `20261116110000_admin_duplicate_id_pagination.sql`, `20261116100000_member_genealogy_pagination.sql`, `20261116120000_public_product_catalogue_search.sql`, `20261116020000_admin_product_management_and_media.sql`, and `20261117120000_admin_update_member_profile.sql`.
- Two live RPC contracts are confirmed mismatched: Production exposes `place_bid(uuid)`, while current source migration `20261116190000_bid_request_idempotency.sql` defines `place_bid(uuid,text)`; Production exposes `admin_create_duplicate_member_id(text)`, while current source migration `20261117110000_serialize_admin_duplicate_id_placement.sql` defines `admin_create_duplicate_member_id(text,text)`.
- Two additional disclosure contracts differ: Production `lookup_sponsor(text)` returns a table with `member_code` and `display_name`, while source migration `20261116160000_minimize_public_sponsor_lookup.sql` returns only a boolean. Production `member_list_my_withdrawals()` exposes `payout_details`, while source migration `20261116170000_minimize_member_withdrawal_payout_data.sql` reduces the returned payout JSON to the method label.
- The three legacy files are not a valid current baseline: `0001_biddworld.sql` uses legacy columns and enums (for example `member_ids.user_id` rather than `owner_user_id`, and legacy `profiles.role/email` fields); `0002_place_bid_rpc.sql` is the one-argument bid RPC; `001_initial_schema.sql` is empty. None should be replayed as the current schema baseline.

**Baseline gate:** build a separate reviewed clean-install chain from the complete current schema evidence and the source-only deltas. Do not treat a migration name as proof that its object is present, and do not apply any migration to Production.
