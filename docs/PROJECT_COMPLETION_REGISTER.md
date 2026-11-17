# Project Completion Register

## 2026-11-17 — Bulk continuation CI verification

- Confirmed GitHub Actions run [44045424821](https://github.com/kkjan2006-self/biddworld/actions/runs/44045424821) completed successfully on commit `95713e6798258ce7aaef49aa42e5f946110727c5`.
- The verification job completed dependency installation, dependency security reporting, test suite, TypeScript type-check and production build.
- This confirms the current source branch passes its configured CI checks; it does not validate Supabase RPC deployment, clean-database migration replay, live authorization, or browser E2E.
- The Production schema remains read-only and the isolated TEST project remains empty. No migrations or financial/member data changes were made.
- Next safe gate remains canonical migration reconstruction and clean-install replay in TEST. Continue source-only changes only where they do not assume missing Production RPCs or unverified business rules.

# Project Completion Register

## 2026-11-17 — Fixed Bid catalogue server-side filtering

- Replaced client-only filtering of the first 50 loaded campaigns with server-side campaign-title search and status filtering before pagination.
- Search/status changes now restart at offset zero; debounced title search avoids issuing a request for every keystroke.
- Stable ordering and bounded 50-row pagination are retained. Load-more requests append only to the current filter result set.
- Stale requests are invalidated when filters change or the component unmounts; the catalogue remains read-only.
- This is a functional catalogue improvement, not completion of Fixed Bid entry, draw, refunds or settlement.
- Verification: 80 test files / 307 tests passed in CI; TypeScript initially caught a select-value typing issue, corrected in the follow-up commit; final CI result pending.
- Production Supabase was not modified and no migration was applied.
\n\n## 2026-11-17 — Referral plan draft version editor\n\n- Added a safe way to load an existing inactive package's fixed-reward referral plan into the editor as a starting point for a new version. Existing versions are never overwritten.\n- Active-package plans, unsupported reward types and non-sequential level definitions are refused rather than silently altered.\n- The editor now validates fixed rewards against the database RPC range (greater than zero and at most ₹100,000) before submission.\n- Saving still creates an inactive version only; commission calculation, posting and activation are unchanged.\n- Regression tests added. CI first caught a literal newline escape in the inserted helper; corrected in follow-up commit and rechecked. Production Supabase untouched; no migration applied.\n

## 2026-11-17 — Support queue status filtering

- Support ticket status selection is now applied in the Supabase query before 100-row pagination for both member and Admin views.
- Changing status reloads the matching result set from offset zero, so older open/in-progress/resolved/closed tickets are not hidden behind the first 100 mixed-status records.
- Text search remains explicitly limited to loaded records; member ownership continues to be enforced by the user filter and database RLS.
- Regression test verifies both paginated queries apply the selected status. Production Supabase was not modified.


## 2026-11-17 — Notifications inbox server-side filters

- Unread-only (member) and category filters are now applied in the Supabase query before pagination, for both the first page and Load more.
- Filter changes restart loading from the first page through the existing request invalidation flow; member ownership remains scoped to the signed-in user and RLS.
- Category choices come from the database-supported category set, so categories are available even when none occur in the first 100 records.
- Text search remains limited to loaded records and is labelled accordingly. Regression tests cover both paginated query paths.
- Production Supabase was not modified; no migration was applied.


## 2026-11-17 — TEST database bootstrap audit

- Created and verified the isolated `BiddWorld-TEST` project (`yoaauthwejdgaevfvwpo`, `ap-south-1`, PostgreSQL 17.12, `ACTIVE_HEALTHY`).
- TEST database is still empty: no migrations or public tables applied.
- Audited the current branch migration inventory and found 47 SQL files (3 legacy/unversioned and 44 timestamped); the prior migration matrix's 43-file inventory is stale.
- Found that `0001_biddworld.sql` does not match the current Production schema expected by later migrations (`user_id` versus `owner_user_id` and `user_id` versus `member_id`); `0002_place_bid_rpc.sql` is the old one-argument bid RPC, and `001_initial_schema.sql` is empty.
- Decision: do not replay the legacy baseline or apply timestamped migrations to TEST until a canonical clean-install bootstrap is reconciled. Production remains read-only and unchanged.
- Detailed findings and next steps: `docs/TEST_DATABASE_BOOTSTRAP_AUDIT_2026-11-17.md`.


## 2026-11-17 — Live schema inventory and TEST bootstrap decision

- Read-only Production catalogue snapshot confirms 21 public tables, RLS enabled on all 21, 20 SELECT policies and 10 feature-gate triggers; the public function catalogue contains 43 functions/overloads.
- Production migration ledger contains 30 entries through `20261115163218_admin_audit_log_pagination`; TEST migration ledger remains empty.
- Confirmed the migration chain still cannot be replayed as-is: legacy baseline incompatibility, non-one-to-one migration ledger history, missing local Supabase config, and no DB replay in current CI.
- Added `docs/PRODUCTION_SCHEMA_INVENTORY_2026-11-17.md` with table names, key contracts, catalogue counts, RPC mismatch references and a safe bootstrap plan.
- No Production changes or data copies. No TEST migration applied.


## 2026-11-17 — Bulk continuation checkpoint: CI and database boundary revalidated

- Latest repository verification run `44044489172` completed successfully: dependency installation, tests, TypeScript check and production build all passed.
- Re-read the exact Supabase migration ledgers: Production has 30 recorded migrations through `20261115163218_admin_audit_log_pagination`; isolated TEST project `yoaauthwejdgaevfvwpo` still has zero applied migrations.
- Reconfirmed the branch migration history is not a safe clean-install replay: legacy baselines are incompatible with the current schema contract; Production history has only four exact timestamp/name matches and nine recognizable-name migrations with differing timestamps. Remaining entries cannot be reconciled by filename metadata alone.
- Reconfirmed the frontend-to-Production RPC gap: nine source RPC names are absent, and the known `place_bid` and duplicate-ID creation signatures are incompatible. No legacy fallback that weakens bid idempotency was introduced.
- Decision for this batch: keep Production read-only and keep TEST empty. Do not create a guessed baseline, mark migrations as applied, or run unreviewed SQL merely to advance the migration count.
- No application code, database schema, member, wallet, package, bid, payment or withdrawal data was changed in this checkpoint. This checkpoint records verification and the exact blocker; it is not a claim that the database modules are complete.
- Next engineering gate: reconstruct the 30 applied SQL definitions from repository history/Supabase function and schema evidence, then build and replay a canonical baseline in TEST. Parallel feature work must remain source-only until that clean-room test environment is reproducible.


## 2026-11-17 — Sponsor graph serialization and production contract recheck

- Confirmed GitHub Actions run [44046687675](https://github.com/kkjan2006-self/biddworld/actions/runs/44046687675) completed successfully; the verification job passed dependency installation, tests, TypeScript check and production build.
- Re-read source migrations and regression tests for sponsor graph and Admin Duplicate ID placement serialization. Both source migrations take transaction-scoped advisory locks before reading graph/settings/placement state; static contract tests are included and passed in CI.
- Rechecked the live Production definitions read-only: admin_set_member_sponsor(text,text) still has no graph-wide advisory lock; admin_create_duplicate_member_id(text) remains the old one-argument RPC. The two-argument Duplicate ID placement and sponsor serialization migrations are source-only and are not in the Production migration ledger.
- Isolated TEST still has zero applied migrations. Therefore no live PostgreSQL concurrency test has been run and neither source migration is safe to apply yet; the canonical clean-install migration chain remains the deployment blocker.
- No Production writes, schema changes, account changes, or financial/member transactions were performed. Do not interpret static tests as proof of deployed behavior.


## 2026-11-17 — Production sponsor and Duplicate ID live-contract audit

- Executed six SELECT-only catalogue queries against Production: exact RPC definitions/ACLs, relevant columns, constraints, RLS policies, grants, triggers and indexes. No member/customer records were queried.
- Confirmed Production `admin_set_member_sponsor(text,text)` still lacks the graph-wide transaction advisory lock present in source migration `20261117100000_serialize_admin_sponsor_graph_changes.sql`.
- Confirmed Production `admin_create_duplicate_member_id(text)` remains one-argument and does not accept/store an Under ID. Source migration `20261115230000_duplicate_under_id_placement_attribution.sql` replaces it with a two-argument Main ID + Under ID contract, and `20261117110000_serialize_admin_duplicate_id_placement.sql` adds the transaction lock. Neither is live in Production.
- Confirmed Production `admin_list_members_sponsors()` is an unpaginated, 500-row function; it is not the paginated contract expected by the current frontend path. `lookup_sponsor(text)` returns member_code/display_name and has anon EXECUTE; it uses an empty search_path.
- Confirmed `member_ids` has placement columns, owner-only authenticated SELECT policy, Main/Duplicate and status checks, restrictive self-FKs, and a feature-gate trigger blocking Duplicate ID activation when the setting is off.
- Added `docs/PRODUCTION_SPONSOR_DUPLICATE_LIVE_CONTRACT_AUDIT_2026-11-17.md` with exact findings and deployment boundaries.
- Production was queried read-only only. No DDL/DML/RPC invocation, member data export, TEST migration, or Production change was performed. Actual concurrency behavior still requires a clean TEST database and transaction-level tests.
