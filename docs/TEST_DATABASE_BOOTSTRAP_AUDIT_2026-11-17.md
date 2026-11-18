# BiddWorld TEST database bootstrap audit — 2026-11-17

## Scope and safety

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Audited HEAD before this documentation checkpoint: `2e46aed6c1dea685eecd939afd1e3c0f917573a2`
- TEST project: `BiddWorld-TEST` (`yoaauthwejdgaevfvwpo`), region `ap-south-1`
- Production project was inspected read-only for schema comparison. No Production SQL writes, migrations, settings changes, or data changes were performed.
- TEST project was inspected read-only. No migrations, tables, seed records, or Auth users have been created there.

## Live TEST state

- Project status: `ACTIVE_HEALTHY`
- PostgreSQL: 17.12
- Applied migration ledger: empty
- `public` tables: empty

## Repository migration inventory

The 2026-11-18 `completion-work` tree contains 49 SQL migration files:
- 3 legacy/unversioned files: `0001_biddworld.sql`, `0002_place_bid_rpc.sql`, and `001_initial_schema.sql`
- 44 timestamped migrations

The existing `docs/MIGRATION_RECONCILIATION_MATRIX_2026-11-16.md` describes an older 43-file inventory and an earlier HEAD. It must not be treated as a current migration plan.

## Blocking schema incompatibility

The legacy `0001_biddworld.sql` is explicitly a fresh-project baseline, but it does not represent the current Production schema expected by the timestamped migration series:

- Legacy baseline defines `member_ids.user_id`; current schema and timestamped migrations use `member_ids.owner_user_id`.
- Legacy baseline defines wallet accounts by `user_id`; current schema and migrations use `wallet_accounts.member_id`.
- Legacy baseline uses a materially different package activation, wallet transaction, referral, and bid data model.
- `0002_place_bid_rpc.sql` defines the old one-argument `place_bid(uuid)` implementation; later source migration `20261116190000_bid_request_idempotency.sql` replaces it with a two-argument idempotent contract.
- `001_initial_schema.sql` is empty.

Therefore, replaying `0001` followed by the timestamped migrations is not a valid bootstrap strategy. Applying the legacy baseline would create incompatible objects and cause later migrations to fail or silently preserve wrong assumptions.

## Decision

**Do not apply any repository migration to TEST yet.** First establish a canonical, data-free TEST bootstrap that matches the current application schema and required dependencies. The baseline must be reconstructed/reconciled from the current authoritative schema and source migrations, including tables, constraints, indexes, RLS policies, grants, triggers, private functions, and public RPCs. Then apply the ordered migrations to TEST and verify the resulting schema and behavior.

This is a deliberate safety stop, not a completed database setup.

## Next actions

1. Complete a read-only schema/function/policy/trigger/grant inventory from Production as the current schema reference; do not copy Production rows.
2. Compare the full inventory with every source migration and frontend RPC inventory.
3. Recover missing migration SQL from repository history where possible; do not invent historical migration contents.
4. Create a reviewed clean-install baseline or corrected ordered migration sequence on `completion-work`.
5. Apply only to `BiddWorld-TEST`; keep all business/financial features disabled and seed only synthetic test fixtures.
6. Run schema checks, RLS/RPC tests, integration tests, `npm test`, `npm run typecheck`, and `npm run build`; record actual outcomes.

## Supabase migration practice

Supabase's current Database Migrations guide recommends keeping schema changes in migration files, testing them locally, and deploying them through the migration workflow rather than making ad hoc remote schema edits. The repository's bootstrap must follow this discipline.

Reference: https://supabase.com/docs/guides/deployment/database-migrations


## 2026-11-18 — Current branch and Production ledger reconciliation

The current branch inventory supersedes the older count above: **49 SQL files total, 3 legacy/unversioned and 46 timestamped**. The Production migration ledger still contains 30 applied entries.

Exact comparison of the 30 Production ledger entries against the 46 timestamped repository files found:

- 4 exact version-and-name matches.
- 9 matching migration names with different timestamps.
- 17 Production ledger entries with no matching source migration file.

For all 17 missing filenames, the GitHub commit-history query for the exact `supabase/migrations/<filename>` path returned no history. Those migration definitions are not recoverable from this repository's visible commit history. Do not recreate them from names or mark them as applied.

A fresh read-only Production catalogue query returned 21 public base tables, 110 constraints, 60 indexes, 20 policies, 10 non-internal triggers, 43 public functions, no public views, no public enum types, and RLS enabled on all 21 public tables. A separate Storage catalogue query returned zero buckets. These are metadata counts only; no table rows were read.

The selected frontend/backend contract recheck confirms these nine frontend RPC names remain absent from Production:

- `public_list_active_products_page`
- `member_get_my_identity`
- `member_list_my_ids`
- `member_update_my_profile`
- `admin_list_members_sponsors_page`
- `admin_list_duplicate_ids_page`
- `get_my_mlm_dashboard_page`
- `admin_set_product_active`
- `admin_update_member_profile`

Production still exposes `place_bid(p_auction_id uuid)` rather than the source-required two-argument idempotent contract, and `admin_create_duplicate_member_id(p_main_member_code text)` rather than the source-required Main ID + placement contract. The referral-plan draft RPC exists with `(p_package_id uuid, p_rules jsonb)`; that does not implement commission calculation or posting.

TEST remains `ACTIVE_HEALTHY`, PostgreSQL 17.12, with zero applied migrations and zero public tables. Production was queried with SELECT-only catalogue statements. No migrations, DDL, DML, RPC calls, Storage changes, or data writes were performed in either project.

**Decision remains unchanged:** do not replay the 49-file directory, do not fabricate the 17 missing historical migrations, and do not apply a partial baseline. A separately reviewed final-state clean-install baseline must be built from complete schema evidence and tested only in TEST.


## 2026-11-18 — Source-only feature migrations added after baseline audit

The current repository now contains **55 SQL files: 3 legacy/unversioned and 52 timestamped**. Six additional timestamped migrations were added after the earlier 49-file inventory:

- `20261118080000_fixed_bid_campaign_entry_draw_settlement.sql`
- `20261118090000_package_publication_and_referral_commission_engine.sql`
- `20261118100000_admin_withdrawal_review_workflow.sql`
- `20261118110000_auction_lifecycle_winner_settlement.sql`
- `20261118120000_admin_wallet_adjustments.sql`
- `20261118130000_withdrawal_minimum_and_server_validation.sql`

These migrations are source-only. They have not been applied to TEST or Production. Their prerequisites include the verified current schema objects described in the earlier inventory; they must be incorporated into the separately reviewed clean-install baseline and replayed only after that baseline is prepared. Production remains read-only; TEST remains empty.


## 2026-11-18 — Final source migration count after bulk development

Current branch tree inventory: **60 SQL files total: 3 legacy/unversioned and 57 timestamped**. Eleven new timestamped migrations dated 2026-11-18 are present, covering Fixed Bid, referral commissions, withdrawals, auctions, wallet adjustments, Main ID lifecycle, receipt uploads, Primary Admin roles, support tickets and notification idempotency. All remain source-only. TEST is still empty; Production remains read-only.
