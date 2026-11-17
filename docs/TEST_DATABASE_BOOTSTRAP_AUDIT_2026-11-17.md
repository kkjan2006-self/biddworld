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

The current `completion-work` tree contains 47 SQL migration files:
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
