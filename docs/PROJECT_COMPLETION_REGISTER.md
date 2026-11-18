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


## 2026-11-17 — Production public-table metadata snapshot

- Rechecked latest commit CI run `44047828813`: all workflow steps passed, including tests, TypeScript check and production build.
- Captured a verbose read-only Supabase catalogue listing for the 21 Production `public` tables, including columns, types, defaults, primary keys, foreign keys and RLS-enabled flags. No table rows or personal/financial records were exported.
- Added `docs/PRODUCTION_PUBLIC_TABLE_SCHEMA_SNAPSHOT_2026-11-17.md` as a schema-only comparison reference for the canonical TEST bootstrap.
- This metadata snapshot is deliberately not labelled as a complete schema dump or replayable baseline; indexes, all constraints, policies, grants, triggers, types, functions and storage configuration still require separate reconciliation.
- Production remained read-only; TEST remains untouched and empty.


## 2026-11-18 — Product catalogue and media workflow contract audit

- Re-read the source migrations `20261116010000_public_active_product_catalogue.sql` and `20261116020000_admin_product_management_and_media.sql`, the existing `tests/product-media-migration.test.ts`, and the Admin product-management implementation.
- Confirmed the source design includes public reads for published products only; Admin-only product list/draft-save/publish RPCs; audit-log entries; and a public `product-media` Storage bucket restricted to JPG/PNG/WebP images up to 5 MB, with upload/update/delete limited by the trusted `app_metadata.role=admin` claim.
- Confirmed the Admin UI already implements draft creation/editing, staged image upload and cleanup, and explicit publish/unpublish actions. Existing static migration tests cover the key Storage and RPC authorization clauses.
- This is not an end-to-end verified module: the latest Production audit found zero Storage buckets, and the current Production migration ledger does not establish that the product-media migration was applied. TEST still has no clean-install schema, so the UI-to-RPC-to-Storage path cannot be safely exercised there yet.
- The migration's prerequisites include the existing `storage.buckets`/`storage.objects` infrastructure, `public.products`, `public.audit_logs`, and the trusted Admin JWT claim contract. The public catalogue policy also depends on the current `products.status='published'` schema.
- Decision: do not apply the migration or create a bucket in Production or empty TEST as a shortcut. Keep product/media marked source-implemented but deployment-unverified until the curated baseline is replayed and a synthetic Admin/anonymous Storage integration test can run.
- No application source, database, Storage bucket, member, wallet, auction, or product records were changed in this audit. No completion percentage increase is justified.


## 2026-11-18 — Configurable referral plan depth hardening

- The Admin editor already supports adding/removing levels dynamically, but the SQL RPC accepted arbitrarily high level numbers and did not enforce sequential levels. This allowed malformed direct RPC requests to create a plan shape the UI could not safely copy back.
- Hardened `admin_save_referral_plan_draft` to accept 1–20 levels only, reject levels outside 1–20, and require contiguous sequential levels beginning at 1.
- Added `tests/admin-referral-plan-depth-contract.test.ts` covering the depth bound, sequential numbering, Admin authorization, inactive version creation, and the absence of commission/wallet posting in this draft-only RPC.
- Scope is source-level validation hardening only. No TEST or Production migration was applied; no package, referral plan, commission, wallet, or member rows were written.
- This does not complete the referral engine: commission calculation, eligibility resolution, idempotent posting/reversal, and end-to-end TEST coverage remain outstanding. Do not mark referral module complete or raise the overall completion percentage based on this change alone.


## 2026-11-18 — Referral draft RPC input hardening

- Follow-up review found the JSON payload type check and `jsonb_array_length` call were combined in one boolean expression. PostgreSQL does not guarantee boolean operand evaluation order, so a non-array JSON object could still reach the array function and raise an unintended error.
- Split the checks so the RPC rejects non-array payloads before calling array functions. Added a regression assertion for this ordering.
- Current source contract: 1–20 levels, sequential level numbering from 1, Admin-only execution, inactive plan version creation, and no commission or wallet posting in this draft RPC.
- This is source-level hardening only. CI has not yet reported a result for the latest commits. No Supabase migrations were applied and no database records were changed.


## 2026-11-18 — Referral depth test-source repair and commission-engine boundary

- Re-opened the committed referral depth contract test and found escaped newline text and over-escaped regular-expression patterns in the test source. Replaced these with normal TypeScript lines and literal contract assertions.
- Rechecked the Admin editor's exact twenty-level guard and the draft RPC's sequential-level, Admin-only, inactive-version behavior against the current branch source.
- Inspected the available source migrations and the Production schema-only snapshot for referral and wallet tables. The snapshot identifies the commission row fields and wallet ledger idempotency key, but it does not provide a complete verified schema, all constraints/indexes/triggers/grants, or a replayable migration baseline.
- No automatic commission calculation, eligibility traversal, idempotent wallet posting, or reversal engine is present in the inspected source. The existing feature-gate trigger only gates credited commission inserts and requires an approved active package activation; it is not a commission engine.
- Decision: do not invent commission SQL against an incomplete/unreconciled schema. Next implementation work must be preceded by a trustworthy schema/constraint/trigger contract and clean-install TEST baseline. Production remains read-only; TEST remains untouched.
- No tests were executed in a runtime during this repair. The repaired test source is committed, but it is not reported as passing until CI or a local test run confirms it.


## 2026-11-18 — CI repair and migration reconciliation recheck

- Confirmed the latest CI run [44180988534](https://github.com/kkjan2006-self/biddworld/actions/runs/44180988534) completed successfully on commit `fde73848286e3bdd40e2c0829b5702adeab8a006`: 90 test files, 342 tests passed, TypeScript check passed, and Vite production build passed.
- Verification completed: 90 test files and 342 tests passed; TypeScript check and Vite production build passed.
- Repaired 11 stale source-contract test files to assert the current implementation: member/admin request lifecycle guards, retryable wallet pagination, notification ownership/read-state paths, package activation lock copy, and all three support-ticket status-filtered query paths (initial load, continuation, and complete CSV export).
- Fixed a real TypeScript build error by importing the existing `csvDocument` helper into `src/components/Support.tsx`; no support workflow was removed.
- CI dependency audit still reports 12 high-severity npm dependency findings. This is an outstanding dependency-security work item, not a test/build failure.
- Four Vercel status checks remain blocked by the account's build-rate limit. No deployment was treated as verified.
- Reconciled the current migration inventory against the live Production migration ledger: repository has 49 SQL files (3 legacy/unversioned and 46 timestamped); Production has 30 ledger entries; only 4 exact timestamp/name matches and 9 same-name/different-timestamp matches. The other 17 Production ledger entries have no matching source file, and GitHub path history confirms those exact files are not recoverable from repository history.
- Read-only Production catalogue check: 21 public tables, RLS enabled on all 21, 110 constraints, 60 indexes, 20 policies, 10 non-internal triggers, 43 public functions, and no Storage buckets. The selected live RPC check confirms nine frontend RPC names remain absent; `place_bid(uuid)` and `admin_create_duplicate_member_id(text)` still have incompatible one-argument contracts.
- TEST remains ACTIVE_HEALTHY with zero migrations and zero public tables. Production received SELECT-only catalogue queries; no DDL, DML, RPC execution, Storage changes, or data writes were performed.
- No clean-install baseline has been applied or declared verified. The 17 missing historical migration definitions must not be invented. Next safe database task is to assemble a reviewed final-state baseline from complete, verified schema/function/policy/trigger/grant evidence, then replay it only in TEST.
- No completion-percentage increase is justified by CI repair or audit work. Referral calculation, eligibility, posting, reversal, and end-to-end verification remain incomplete.


## 2026-11-18 — Bulk source development: Fixed Bid, referral engine, auctions, withdrawals and wallet administration

- Continued on `completion-work`; source changes are committed through the GitHub Contents API using current file SHAs. No changes were made to `main`.
- Added `20261118080000_fixed_bid_campaign_entry_draw_settlement.sql`: configurable campaign entry amount, winner payment amount, per-member/total entry limits, schedule, winner count, optional non-winner refunds, idempotent member entry, Bid-Wallet-first then Income-Wallet debit, recorded one-time draw, wallet-source refunds, and Income-Wallet-only winner payment.
- Updated Member Fixed Bid catalogue to display campaign rules and submit an idempotent entry. Updated Admin Fixed Bid editor and lifecycle controls for schedule/open/pause/end, one-time winner draw and configured refunds. Added Member winner-payment action for both auction and Fixed Bid awards.
- Added `20261118090000_package_publication_and_referral_commission_engine.sql`: Admin referral-plan version activation, package publish/unpublish, activation-triggered level-wise pending commission calculation through the sponsor chain, active Main ID eligibility, Duplicate ID beneficiary attribution to the linked Main ID Income Wallet, idempotent ledger posting, reversal with compensating debit, and paginated Admin commission report. Posting is automatic only when the referral feature is enabled; Admin can also post pending commissions explicitly.
- Updated Admin package and referral-plan controls to activate a plan version, publish/unpublish packages, view/filter/paginate commissions, post pending commissions and reverse with a required reason.
- Added `20261118100000_admin_withdrawal_review_workflow.sql`: Admin approve/reject/mark-paid workflow. Approval reserves the amount from the Income Wallet; rejecting an approved request releases it through a compensating credit; marking paid records the completed payout.
- Updated Admin withdrawal queue with payout details for authorized Admin review and status actions.
- Added `20261118110000_auction_lifecycle_winner_settlement.sql`: schedule/live/pause/end/cancel lifecycle, cancellation refunds to the original wallet sources, deterministic highest-accepted-bid winner finalization with earliest-bid tie-break, and winning-payment creation.
- Updated Admin auction lifecycle and winner finalization controls.
- Added `20261118120000_admin_wallet_adjustments.sql`: Admin-only, idempotent Bid/Income Wallet credit/debit through an immutable ledger row and audit event; debit cannot overdraw the wallet.
- Updated Admin Wallet Management with an audited adjustment form.
- Added `20261118130000_withdrawal_minimum_and_server_validation.sql`: configurable minimum withdrawal amount, Admin setting controls and server-side enforcement in the member withdrawal RPC. Member portal displays the current minimum and validates it before submission.
- All new database migrations remain **source-only** pending the canonical clean-install baseline. Neither Production nor TEST received schema/data writes. No real members, wallet balances, bids, commissions, payments or payouts were created or changed.
- Per the requested development-first sequence, no manual tests, build, migration replay, E2E or mobile checks were run in this batch. Automated checks may be triggered by GitHub on pushed commits; their results have not been reviewed here.
- Known outstanding development remains: receipt-upload workflow, complete historical reports/CSV coverage, admin role/permission lifecycle, member lifecycle controls, complete notification provider delivery, full frontend/backend RPC reconciliation, and canonical clean-install baseline. All new SQL must be included in that baseline after dependency review.
- No overall percentage is claimed as 100%; the source implementation has advanced materially, but integration and final verification remain outstanding.


## 2026-11-18 — Bulk source development continuation

- Added `20261118140000_admin_main_member_lifecycle.sql`: Admin Main ID active/suspended/closed workflow, profile status synchronization, and controlled propagation/restoration for linked Duplicate IDs using an explicit management marker. Admin UI now exposes audited Main ID lifecycle controls.
- Added `20261118150000_package_receipt_uploads.sql`: private `package-receipts` Storage bucket, member-owned upload paths, Admin-only review access, 5 MB JPG/PNG/PDF constraints, receipt path on package activation, and signed Admin receipt links. Member activation form source now supports optional receipt upload while the existing activation lock remains unchanged.
- Added `20261118160000_primary_admin_role_management.sql`: only the designated Primary Admin account can grant/revoke trusted Admin app_metadata roles for existing accounts; prevents Primary Admin demotion and last-Admin removal, with audit records. Admin Access UI now exposes the controlled workflow.
- Added `20261118170000_support_ticket_idempotency_admin_audit.sql`: idempotent member support submission and Admin-only audited response/status RPC. Support UI now uses those server-side RPCs instead of direct ticket inserts/updates.
- Added `20261118180000_notification_delivery_idempotency.sql`: idempotent Admin in-app notification send RPC with recipient/category validation and audit record. Notifications UI now uses this RPC.
- Expanded Admin reports with complete paginated Duplicate ID and referral commission CSV exports, plus package configuration export.
- Current repository migration inventory verified from the branch tree: **60 SQL files (3 legacy/unversioned + 57 timestamped)**. All 11 new `20261118` migrations remain source-only.
- No Production or TEST database writes, schema changes, migration replay, real-member tests or wallet transactions were performed. No manual tests/build/mobile/E2E checks were run in this development-first batch.
- Remaining source work includes a trustworthy clean-install baseline, full package activation and receipt integration after owner-controlled enablement, complete archival reports for all activation statuses, notification read/write audit coverage, remaining frontend/backend RPC contract fixes, and final PWA/security integration. Final full testing remains deliberately deferred until development is complete.


## 2026-11-18 — Bulk reports and configurable referral rewards

- Updated the Admin referral editor to support both fixed INR rewards and percentage rewards per level, preserving the 20-level limit and sequential-level validation.
- Package activation requests now read the server-side `package_activations_enabled` setting instead of a hardcoded client lock. The existing disabled-by-default feature setting and database financial guard remain authoritative.
- Added `20261118190000_package_activation_history_reporting.sql`: complete paginated Admin activation history across pending, approved, rejected and refunded statuses, including receipt path and verification metadata.
- Added complete CSV exports for Duplicate IDs, referral commissions and package activation history; added package configuration export.
- Current branch tree inventory: **61 SQL files (3 legacy/unversioned + 58 timestamped)**. All 12 new `20261118` migrations remain source-only.
- No manual testing/build/E2E/mobile validation or migration replay was run, as requested. No Production or TEST database writes were performed.


## 2026-11-18 — PWA and SEO source polish

- Removed the unrelated Bolt.new social preview image from `index.html` and added BiddWorld-specific title, description, Open Graph and Twitter metadata.
- Bumped the service-worker shell cache from v1 to v2 so the next deployment invalidates the prior cached shell.
- Confirmed the current branch contains the PWA manifest, service worker and BiddWorld SVG icon. No PWA install/offline browser testing was run in this development-first phase.
- No migrations or database writes were performed for this UI/PWA change.


## 2026-11-18 — Bulk source hardening: lifecycle propagation and idempotent request integrity

- Re-reviewed the 12 newest source-only migrations against the available Production schema snapshot and the existing package-review contract. No migration was replayed and no tests/build were run, consistent with the development-first sequence.
- Fixed Main ID closure propagation: when an Admin closes a Main ID that was previously suspended, Duplicate IDs already suspended by that Main ID lifecycle are now also closed; manually suspended Duplicate IDs remain untouched.
- Hardened support-ticket idempotency: reusing a request key with a different subject or message now fails instead of silently returning the earlier ticket.
- Hardened notification idempotency: reusing a recipient-scoped request key with different title, message or category now fails instead of silently treating it as the same delivery.
- Hardened wallet-adjustment idempotency: replay keys must also match the original reason, in addition to member, wallet, direction and amount.
- Latest branch head: `e7050df1c973c6c73ce4ca6e94a84439a530c0f4` on `completion-work`. Changes remain source-only. Production remains read-only; TEST remains empty and untouched.
- Remaining blockers are unchanged: historical migration reconstruction/canonical baseline, SQL dependency and schema compatibility review, missing frontend/backend RPC reconciliation, and final end-to-end testing after development is complete.


## 2026-11-18 — SQL source review: Fixed Bid migration corrections

- Static review of the 12 latest source-only migrations identified an invalid PL/pgSQL UPDATE/RETURNING statement in `admin_save_fixed_bid_campaign`. Moved `RETURNING id INTO` into the UPDATE statement so the function body is syntactically structured correctly.
- Added cancellation settlement to `admin_set_fixed_bid_campaign_status`: when an unfinalized campaign is cancelled, every accepted/submitted entry is voided and its original Bid Wallet / Income Wallet debit splits are refunded through compensating ledger credits. A campaign with an already-paid winning item cannot be cancelled.
- Refund idempotency now guards both the wallet balance update and ledger insert, preventing a duplicate credit if a refund key already exists.
- Existing auction cancellation refund keys were checked against the bid RPC ledger key convention (`:bid` / `:income`) and match the source implementation.
- These are source-code corrections only. No migrations were applied, no TEST or Production data was changed, and no test/build was run. SQL execution and full schema compatibility remain pending until the clean TEST baseline is prepared.


### 2026-11-18 — Fixed Bid refund-ledger reconciliation hardening
- Rechecked the source schema snapshot: `fixed_bids.status` explicitly permits `voided`, and `winning_item_payments.fixed_bid_campaign_id` exists with its foreign key to `fixed_bid_campaigns`.
- Hardened Fixed Bid campaign cancellation and optional non-winner refunds: each entry's original debit ledger rows must now sum exactly to the recorded entry amount before the entry can be voided. Missing or partial debit history raises an exception and rolls back the complete operation, preventing silent under-refunds.
- No tests/build run (per development-first workflow). No Supabase migrations applied; Production and TEST databases remain untouched.


### 2026-11-18 — Member identity list RPC contract completion
- Added source migration `20261118200000_member_identity_ids_rpc.sql` for the Account portal's existing `member_list_my_ids()` call.
- The RPC returns only the authenticated user's own Main and Duplicate IDs, with the placement parent code needed by the Member UI; it accepts no caller-supplied user/member identifier.
- Execution is revoked from PUBLIC/anon and granted to authenticated users only. The function uses a fixed empty search_path and runs as a constrained SECURITY DEFINER read.
- This closes one confirmed frontend-to-migration source gap. Other legacy RPCs still need complete schema/production-history reconciliation before clean-install replay can be claimed.
- Source-only change. No tests/build run and no Supabase migrations applied; Production and TEST databases remain untouched.

### 2026-11-18 — Frontend/RPC contract review checkpoint
- Compared the current frontend RPC calls with the source migration signatures for product catalogue pagination, member identity/profile, member genealogy, Admin member and Duplicate ID pagination, auction draft management, bidding idempotency, sponsor validation, delivery tracking, and the recent Fixed Bid / package / withdrawal / notification workflows.
- Confirmed the two-argument Duplicate ID placement RPC is supplied by the later serialized-placement migration and the two-argument idempotent `place_bid` wrapper matches the current frontend call.
- Added the missing Member ID list RPC in the preceding migration batch. Remaining legacy Admin template/report RPCs and the overall historical migration baseline still require further reconciliation; this review does not establish clean-install readiness.
- No tests/build run and no database migrations applied. Production and TEST remain untouched.


### 2026-11-18 — Admin template, account directory and health RPC completion
- Added source migration `20261118210000_admin_templates_accounts_health.sql`.
- Implemented Admin-only notification template list/save RPCs and a dedicated `notification_templates` table with RLS enabled and direct table privileges revoked. Template saves remain inactive drafts; no email/SMS/in-app dispatch is performed by this feature.
- Implemented the Admin account directory from trusted `auth.users.raw_app_meta_data` role claims; the RPC returns only Admin accounts and does not expose password/authentication secrets.
- Implemented the read-only platform health RPC with public-table/RLS counts, settings count when the settings table exists, and latest audit timestamp.
- Frontend RPC signatures and expected result fields were checked against `src/components/Admin.tsx`.
- This is a source-only migration. No tests/build or migration replay were run. Production and TEST databases remain untouched.
- Current source migration inventory: **63 SQL files (3 legacy/unversioned + 60 timestamped)**, subject to final tree-wide inventory confirmation.


### 2026-11-18 — Member portal and remaining RPC contract audit
- Re-audited Account, Referrals, PlacementTree, Support, Notifications, Packages and Fixed Bid frontend RPC calls against the recently authored source migrations.
- Confirmed source definitions exist for `member_pay_winning_item_payment(uuid,text)` (Income Wallet-only, idempotent; defined in the Fixed Bid settlement migration), `member_create_withdrawal_request(numeric,jsonb)`, `member_list_my_ids()`, `member_submit_support_ticket(text,text,text)`, `admin_update_support_ticket(uuid,text,text)`, `admin_send_member_notification(uuid,text,text,text,text)`, `submit_package_activation_with_receipt(uuid,text,text)`, and `member_join_fixed_bid_campaign`.
- Identified additional Member portal calls requiring source-history/schema reconciliation: `member_get_my_identity()`, `member_update_my_profile(text,text)`, and `member_list_my_withdrawals()`. Their full source definitions were not present in the specific migration files reviewed in this batch; no replacement function was authored without complete schema/contract evidence.
- Referrals and PlacementTree call `get_my_mlm_dashboard_page` and `get_my_placement_tree`; their complete frontend/result contracts remain to be checked against the full migration history.
- Direct Account queries for wallet balances, bids, fixed-bid entries, commissions, winning payments and delivery tracking rely on member-row RLS and will require dedicated TEST-project verification during the final test phase.
- This batch is a source/documentation audit only. No application code, database schema, Production data or TEST data was changed. No tests/build or migration replay were run.


### 2026-11-18 — Member RPC reconciliation correction and placement-tree implementation
- Rechecked the original migration sources and corrected the previous checkpoint: `member_get_my_identity()`, `member_update_my_profile(text,text)`, `member_list_my_withdrawals()`, and `get_my_mlm_dashboard_page(integer,integer,text,integer)` are already defined in the historical/source migrations; they were not missing RPCs.
- Confirmed the Member PlacementTree component calls `get_my_placement_tree()`, but no definition was found in the inspected SQL migration history. Added source migration `20261118220000_member_placement_tree_rpc.sql`.
- The new SECURITY DEFINER RPC derives the caller's Main ID from their authenticated profile, returns the root plus descendants using `placement_parent_id`, prevents cycles, traverses duplicate IDs only as structural links, and displays Main IDs only. It returns the exact fields consumed by `PlacementTree.tsx`.
- The RPC grants execution only to authenticated users and revokes PUBLIC/anon execution. No caller-supplied member ID is accepted.
- Updated source SQL inventory: **65 files (3 legacy/unversioned + 62 timestamped)**, confirmed by a fresh recursive Git tree inventory. The migration is source-only; no SQL replay, tests, build, Production changes, or TEST changes were performed.
- Remaining work includes complete Admin RPC inventory reconciliation, full migration dependency/baseline reconstruction, and then isolated TEST replay plus final testing.


### 2026-11-18 — Admin RPC source reconciliation checkpoint
- Re-audited the Admin component's RPC inventory against the migration files reviewed in this batch.
- Confirmed source definitions for Admin member/sponsor and duplicate-ID reports, feature settings, package activation review/history, audit logs, product/auction management, delivery tracking, referral plan draft/commission workflows, Fixed Bid campaigns, withdrawal review, wallet adjustments, Main ID lifecycle, Primary Admin role management, notification templates, Admin accounts and platform health.
- Recorded seven Admin calls whose complete definitions were not located in the reviewed migration sources: `admin_list_packages()`, `admin_list_referral_plans()`, `admin_list_withdrawal_requests(integer,integer)`, `admin_list_wallet_accounts(integer,integer)`, `admin_list_wallet_transactions(integer,integer)`, `admin_list_winning_item_payments(integer,integer)`, and `admin_set_default_sponsor(text)`.
- Added `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md` with the confirmed source map and recovery requirements. These calls may exist in unrecovered Production migration history; they are not asserted to be absent from Production. No replacement SQL was invented because exact live signatures and result contracts must be recovered first.
- Reconfirmed that `0001_biddworld.sql` is a simplified fresh-project baseline and is not proof of the current Production schema. The existing read-only recovery script remains the correct path for catalog evidence.
- No tests/build, migration replay, or Supabase database writes were performed. Production and TEST remain untouched.


### 2026-11-18 — Read-only Production RPC recovery and source alignment
- Queried Production's PostgreSQL function catalogue read-only for the Admin RPCs previously not found in the reviewed migration files and for `get_my_placement_tree()`. Captured exact signatures, return types, function bodies, SECURITY DEFINER status, fixed search_path and ACL metadata.
- Recovered the existing Production Admin functions into source migration `20261118230000_recover_admin_read_rpc_sources.sql`: package list, referral-plan list, paginated withdrawal report, both wallet-account overloads, both wallet-transaction overloads, winning-payment report, and default-sponsor setting. The migration preserves the recovered result contracts and explicitly revokes PUBLIC/anon execution while granting authenticated/service_role.
- Corrected `20261118220000_member_placement_tree_rpc.sql` to match the actual Production `get_my_placement_tree()` body and response: Main-ID descendants only, maximum depth 20, cycle protection, and the original JSONB keys/order. This replaces the earlier unverified proposal; no Production function was changed.
- Updated `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md` with the recovery evidence and a TEST requirement to verify PostgREST overload resolution for the wallet transaction functions.
- Latest verified inventory: **65 files under `supabase/migrations` (3 legacy/unversioned + 62 timestamped)**, plus 1 separate SQL audit script under `supabase/audit` (66 `.sql` files repository-wide). All changes remain source-only. Production was queried read-only; no writes, migration replay, tests or builds were run. TEST remains untouched.


### 2026-11-18 — Production RPC catalogue recovery and contract alignment
- Used a read-only Production PostgreSQL catalogue query to retrieve `pg_get_functiondef`, signatures and return types for the previously unreconciled Admin RPCs. No Production DDL/DML was executed.
- Added source migration `20261118230000_recover_admin_read_rpc_sources.sql` for the recovered package, referral-plan, withdrawal, wallet-account, wallet-transaction, winning-payment and default-sponsor RPCs. Preserved both wallet-account overloads and both wallet-transaction overloads. Corrected the paginated wallet-account `currency` return type to `text`, matching the live catalogue.
- Confirmed the Admin frontend calls these RPCs using the named pagination arguments and updated the Admin RPC reconciliation document with the recovered source map.
- Recovered the live `get_my_placement_tree()` definition and aligned `20261118220000_member_placement_tree_rpc.sql` to its existing JSONB response and Main-ID traversal contract.
- Recorded a remaining TEST contract check: PostgREST overload resolution for the two `admin_list_wallet_transactions` signatures with default arguments must be verified before relying on the frontend named-argument call.
- No tests/build, migration replay, or Supabase writes were performed. Production and TEST databases remain untouched.


### 2026-11-18 — Full Admin frontend RPC presence audit against Production
- Extracted the complete set of 51 unique RPC names used by `src/components/Admin.tsx` and compared them with `public.pg_proc` on Production using a read-only catalogue query.
- Found 30 RPC names installed in Production and 21 not currently installed. The missing names are primarily newer Admin workflows already represented in source-only migrations; this confirms the frontend branch includes functionality that has not been deployed to Production.
- Recorded the exact distinction in `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md`. Do not infer that a source-defined RPC is live, and do not deploy anything to Production during this development phase.
- Admin component direct table access is limited to Supabase Storage buckets `product-media` and `package-receipts`; reviewed the corresponding Storage policies and upload/signed-URL usage. Product media is public-read with Admin-only mutations; package receipts are private and readable by the owner or Admin.
- No tests/build, migration replay, or Supabase writes were performed. Production and TEST remain untouched.


### 2026-11-18 — Member Portal RPC and direct-table Production RLS audit
- Audited direct Supabase RPC/table access across Account, Packages, Support, Notifications, Fixed Bid, Referrals, Placement Tree, Wallet History and App components.
- Compared 16 selected Member/Public RPC names with Production `pg_proc` using a read-only query. Confirmed Production currently exposes `get_my_placement_tree()`, `lookup_sponsor(text)`, `member_create_withdrawal_request(numeric,jsonb)`, `member_list_my_withdrawals()` and legacy `place_bid(uuid)`; several newer Member RPCs used by the branch are not yet installed in Production.
- Recorded the compatibility gap: frontend uses the idempotency-aware `place_bid` call, while Production currently has only the legacy one-argument signature. A source migration provides the newer contract; no Production change was made.
- Queried RLS status and policy names for the Member-facing direct-query tables. Thirteen existing tables in scope have RLS enabled and one named policy each. `support_tickets` and `member_notifications` were not found in the current Production table inventory, matching their newer source-only implementation status.
- Added `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md` with the exact RPC/table findings and follow-up steps. Policy predicates and column-level contracts remain to be inspected; catalogue presence alone is not runtime authorization proof.
- No tests/build, migration replay, or database writes were performed. Production and TEST remain untouched.


### 2026-11-18 — Member-facing RLS predicate review and app_settings read fix
- Inspected exact Production RLS predicates for Member-facing profile, settings, package, wallet, bid, referral, winning-payment, delivery and auction/campaign tables; traced corresponding frontend query scopes.
- Confirmed member-owned financial/activity records are scoped through `member_ids.owner_user_id = auth.uid()`; profiles are scoped to the signed-in user; catalogue policies restrict package/auction/campaign visibility.
- Found an actual frontend/RLS mismatch: Account and Packages read `minimum_withdrawal_amount` and `package_activations_enabled`, but Production's `app_settings_read_scoped` did not include those keys in its authenticated-member allow-list.
- Added source-only migration `20261118240000_member_public_feature_settings_read.sql`, preserving existing Admin/Support/Finance visibility and allowing authenticated members to read only those two additional settings.
- Reviewed source-only Support/Notification policies: support owner/admin read, owner insert, Admin update; notification owner/admin read, Admin insert, owner-only read-state update. Neither table exists in the current Production catalogue yet.
- Added detailed findings to `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md`.
- No migration applied, no database writes, no build/tests. Production and TEST remain unchanged.


### 2026-11-18 — Production schema catalogue snapshot and clean-install blockers
- Read-only Production catalogue snapshot verified: 21 public tables, 175 columns, 243 constraints, 60 indexes, 17 triggers, 43 public functions, 20 RLS policies, 21/21 tables with RLS enabled, and 30 Supabase migration ledger rows.
- Captured all 21 table names, column names/types, primary keys and foreign-key relationships in `docs/PRODUCTION_SCHEMA_CATALOGUE_SNAPSHOT_2026-11-18.md`.
- Confirmed the repository's `001_initial_schema.sql` is empty (newline only); `0001_biddworld.sql` is a simplified early schema with incompatible column names and object contracts (e.g. user_id vs owner_user_id/member_id; amount vs bid_amount).
- Therefore neither file is a valid canonical clean-install baseline. Do not replay them against Production or use them as the final TEST baseline.
- Recorded all 30 live migration ledger versions and the need to recover private-schema dependencies, extensions/types, exact constraints/indexes/triggers/functions/policies/grants before constructing a clean-install chain.
- No data rows exported; no DB writes, migrations, builds or tests performed. Production and TEST remain unchanged.


### 2026-11-18 — Production private-schema and trigger reconciliation
- Reconfirmed the latest branch HEAD as `e7050df1c973c6c73ce4ca6e94a84439a530c0f4`.
- Recounted the repository SQL inventory from the GitHub tree: 66 files under `supabase/migrations` (63 timestamped + 3 legacy/unversioned) and 1 separate audit SQL script; 67 SQL files repository-wide.
- Read-only Production catalogue inspection identified the app-owned `private` schema (owner postgres) and four private functions: `enforce_feature_gate()`, `handle_new_auth_user()`, `place_bid(uuid)`, and `submit_package_activation(uuid,text)`.
- Recovered the exact auth.users trigger contract: `on_biddworld_auth_user_created` AFTER INSERT calls `private.handle_new_auth_user()`. The function provisions the profile, Main ID and wallets, and obeys registration/sponsor settings.
- Identified 10 non-internal public-table feature-gate triggers across bids, delivery_tracking, fixed_bid_campaigns, member_ids, package_activations, referral_commissions, referrals, wallet_transactions, winning_item_payments and withdrawal_requests. All invoke `private.enforce_feature_gate()`.
- Compared the live feature-gate body with source history. The final Production body aligns with `20261115154510_extend_wallet_and_sponsor_feature_gates.sql`; earlier versions are intermediate and must remain ordered before the final replacement in any replay.
- Recorded installed Production extensions (pgcrypto, pg_stat_statements, plpgsql, supabase_vault, uuid-ossp) and the rule that Supabase-managed schemas/extensions must not be recreated as application objects.
- Added `docs/PRODUCTION_PRIVATE_SCHEMA_TRIGGER_RECONCILIATION_2026-11-18.md` with function signatures, trigger inventory, ACL/search_path observations, and clean-install implications.
- No Production or TEST writes, no migration replay, no build or tests. Canonical baseline reconstruction remains pending.

### 2026-11-18 — Production Storage bucket and policy reconciliation
- Read-only Production catalogue queries confirmed `storage.buckets` and `storage.objects` exist, but the live project currently has 0 buckets and 0 Storage RLS policies; `storage.objects` itself has RLS enabled.
- Compared with branch source: `product-media` is declared by `20261116020000_admin_product_management_and_media.sql`; `package-receipts` is declared by `20261118150000_package_receipt_uploads.sql`. Both are source-only and not installed in Production.
- Recorded the exact intended access controls and file restrictions in the Production private-schema/trigger reconciliation document. Treat Storage as a confirmed Production deployment gap; do not create buckets or policies in Production during this development phase.
- No Production/TEST writes, migration replay, build or tests.


### 2026-11-18 — Exact Production migration SQL history recovered
- Queried the Production `supabase_migrations.schema_migrations` ledger read-only and recovered the exact stored SQL statements for all 30 applied migration versions.
- Compared the ledger against the current repository migration directory: 4 same-version files had divergent contents, 9 same-name files had matching SQL but different timestamp prefixes, and 17 ledger migration names had no same-name source file.
- Archived all 30 exact historical SQL statements under `supabase/audit/production-ledger/` (30 SQL snapshots + README). This is an evidence archive outside `supabase/migrations/`; it is not automatically executable by Supabase CLI and does not overwrite current source.
- Verified archive commit: `d872d6cb25d1931e5152e7f16e121a3f877fcfe5`.
- This recovers the historical SQL evidence, but the canonical clean-install migration chain still needs dependency ordering, source-divergence reconciliation, complete schema-object comparison, and later source-only migration integration.
- No Production/TEST writes, no migration replay, no build or tests.

### 2026-11-18 — Historical migration semantic divergence check
- Normalized the four same-version-prefix source files against the exact Production ledger SQL by removing comments and whitespace.
- Three files (`20261114183412`, `20261114183454`, `20261115154433`) are semantically identical; their raw differences are comments/formatting.
- One file (`20261114161950_secure_bid_rpc_and_signup_provisioning.sql`) differs materially: Production history moves an existing `public.place_bid(uuid)` into `private`, while the current source file creates/recreates the private implementation. The historical migration depends on a correct pre-ledger public function.
- Confirmed `0002_place_bid_rpc.sql` is not a valid substitute prerequisite because it uses legacy `user_id`/old bid columns and incompatible status contracts.
- Updated the migration recovery archive README and reconciliation document. Preserve the historical SQL archive; do not overwrite source files or replay the legacy baseline as a shortcut.
- No database writes, migration replay, build or tests.


### 2026-11-18 — Full Production public-schema structural snapshot
- Ran read-only catalogue queries against Production and captured the complete column/default definitions for all 21 public base tables (175 columns).
- Captured all 110 table constraints (21 primary keys, 34 foreign keys, 11 unique constraints, 44 checks), all 60 indexes (34 unique), and all 20 RLS policies across 20 tables.
- Captured direct table grants for API roles: authenticated has SELECT on 17 tables and no direct write grants; anon has no public-table grants. Application writes are intended to use audited/authorized RPC paths.
- Recorded the only public sequence usage grants: `audit_logs_id_seq` currently grants USAGE to anon, authenticated, postgres and service_role. This is an observed state for later baseline review; no privileges were changed.
- Confirmed no public views in `information_schema.views`.
- Added `docs/PRODUCTION_PUBLIC_SCHEMA_STRUCTURAL_SNAPSHOT_2026-11-18.md` with full structural definitions and RLS/grant predicates. It is a documentation snapshot, not executable DDL.
- No Production/TEST writes, no migrations, no tests or builds.


### 2026-11-18 — Production public RPC security-boundary inventory
- Read-only inspection enumerated all 43 public functions: all 43 are SECURITY DEFINER and all 43 have an explicit function-level search_path.
- All 43 are executable by authenticated; only one is executable by anon: `lookup_sponsor(text)`.
- All 36 `admin_%` functions statically reference `auth.uid()` and the JWT `app_metadata`/role claim. This is an inventory result, not a substitute for full semantic code review.
- Inspected the three public wrappers/exception cases: `lookup_sponsor(text)` returns only the matched active Main ID's member code and display label; `place_bid(uuid)` delegates to `private.place_bid(uuid)`; `submit_package_activation(uuid,text)` delegates to `private.submit_package_activation(uuid,text)`.
- Recorded the complete security-boundary findings and remaining per-function review tasks in `docs/PRODUCTION_PUBLIC_RPC_SECURITY_INVENTORY_2026-11-18.md`.
- No Production/TEST writes, no migrations, no build or tests.


### 2026-11-18 — Referral reward percentage validation hardening
- Compared Admin UI validation with the configurable-depth database migration.
- Found that the UI limits percentage rewards to 100%, but the database RPC previously accepted percentage values up to 100000 (the fixed-INR ceiling).
- Updated `20261116030000_admin_configurable_referral_plan_depth.sql` so fixed rewards remain capped at 100000 and percentage rewards are independently capped at 100. Both limits are enforced in the database, not just in the browser.
- The RPC still accepts sequential plans from 1 to 20 levels and creates inactive plan versions only.
- Source migration only; not applied to Production or TEST. No build or tests run.


### 2026-11-18 — Member MLM dashboard pagination contract
- Cross-checked `src/components/Referrals.tsx` against the checked-in migration set and Production RPC inventory.
- Confirmed the component calls `get_my_mlm_dashboard_page(integer,integer,text,integer)`, while the checked-in migration set had only the legacy unpaginated `get_my_mlm_dashboard()`; the paginated RPC was not present in the Production RPC inventory either.
- Added a source-only migration implementing the exact frontend parameter and JSON response contract: summary cards, filtered/paginated Main-ID sponsor genealogy, total count and has-more flag.
- The recursive genealogy follows Sponsor Referral links between Main IDs only, has a 20-level traversal ceiling and cycle protection. Search and depth filters apply to the displayed genealogy; summary totals remain whole-team totals.
- The RPC is authenticated, read-only, SECURITY DEFINER with an explicit empty search_path; public/anon execution is revoked and authenticated execution granted.
- Not applied to Production or TEST. No build/tests run; no data writes.


### 2026-11-18 — Member withdrawal privacy and settings RLS audit
- Read-only comparison found that live Production `member_list_my_withdrawals()` still returns the complete payout_details JSON, while the checked-in `20261116170000_minimize_member_withdrawal_payout_data.sql` returns only the payout method needed by the member UI.
- Read-only comparison found that live Production `app_settings_read_scoped` does not yet allow members to read `package_activations_enabled` and `minimum_withdrawal_amount`; checked-in `20261118240000_member_public_feature_settings_read.sql` adds both keys while preserving privileged role visibility.
- Both fixes are already in source migrations. Recorded the live Production/source divergence and the required TEST validation in `docs/MEMBER_WITHDRAWAL_PRIVACY_AND_SETTINGS_RLS_AUDIT_2026-11-18.md`.
- No Production or TEST changes, no migration execution, no build or tests.


### 2026-11-18 — Admin wallet transaction RPC overload ambiguity fixed in source
- Compared Admin.tsx's `admin_list_wallet_transactions({p_limit,p_offset})` call with live Production signatures and recovered source migration.
- Confirmed the wallet-wide overload accepts `p_limit,p_offset`, while the wallet-specific overload also had a defaulted `p_wallet_account_id = NULL`. Both therefore match the same named PostgREST argument set and can produce an ambiguous RPC resolution.
- Updated `20261118230000_recover_admin_read_rpc_sources.sql` so the wallet-specific overload requires `p_wallet_account_id`; its remaining pagination parameters keep defaults. Existing wallet-wide Admin call now has one unambiguous match, while wallet-specific callers can still supply the account ID.
- Source-only correction. Production and TEST databases were not changed; no build or tests were run. Validate overload resolution on the isolated TEST project after clean-install baseline is prepared.


### 2026-11-18 — Storage and media integration audit
- Read-only Production Storage catalogue check found 0 buckets, 0 Storage object policies, 0 objects; `storage.objects` RLS is enabled.
- Confirmed source definitions for public Admin-managed `product-media` and private member-owned `package-receipts` buckets, including upload limits, MIME allowlists and role/owner policies.
- Confirmed Admin product image upload/public URL flow, member receipt upload/server association flow, and Admin 300-second signed receipt preview flow are present in frontend source.
- Recorded that runtime behavior remains unverified and both buckets must be included in the isolated TEST clean-install baseline before validation.
- No Production/TEST changes, no build or tests.


### 2026-11-18 — Clean-install baseline incompatibility confirmed
- Compared `0001_biddworld.sql` with the first timestamped migration and subsequent signup/sponsor/package schema contracts.
- Confirmed the legacy baseline uses `member_ids.user_id`, `wallet_accounts.user_id`, and legacy package activation/referral columns, while the timestamped chain expects `owner_user_id`, `member_id`, `main_member_id`, `source_member_id`, and newer activation columns. No conversion migration appears before the first timestamped migration.
- Confirmed `001_initial_schema.sql` is empty and `0002_place_bid_rpc.sql` is a legacy implementation using the old wallet schema.
- Read-only isolated TEST catalogue check: no public tables, public functions, migration-history table or Storage buckets; no migrations applied.
- Documented that the current folder is not yet a validated clean-install sequence and recorded remediation paths. No schema was changed; no Production/TEST writes, no builds or tests.


## 2026-11-18 — CI assertion alignment with current feature contracts

- Inspected the latest `completion-work` head and GitHub Actions run #893 logs. The two current failures were stale source assertions: the package test expected a removed hard-coded lock constant, and the withdrawal test expected a read-only queue that had since been replaced by a server-authorized Admin review workflow.
- Updated the package regression test to verify fail-closed database feature-setting behavior, conditional activation form rendering, receipt upload/RPC wiring, proposed-only wallet credit display, and continued free registration.
- Updated withdrawal regression coverage to verify the database feature interlock, trusted-Admin RPC usage, row locking, Income Wallet reservation, idempotent release, audit logging, and member payout-data minimization.
- Changes are committed to `completion-work`; GitHub Actions verification for the new head is pending. No TEST or Production database writes were made. No completion percentage increase is claimed from test-only changes.


## 2026-11-18 — CI regression contract reconciliation verified

- Latest branch CI run [#898](https://github.com/kkjan2006-self/biddworld/actions/runs/44234569835) passed on commit `936d05864e93b1d452a89bac9c224852510e4eb6`.
- GitHub Actions reported **90/90 test files and 343/343 tests passed**. TypeScript project build/type-check and Vite 6.4.6 production build also completed successfully.
- Corrected stale assertions to match current member selection, pending activation export, 20-level editor guard, referral draft validation, Fixed Bid server-side participation/idempotency, account refresh lifecycle and database-driven package activation gate.
- Rebuilt the frontend RPC call-site inventory from the ten React surfaces: 67 unique literal RPC-and-surface entries. This is a source inventory only, not proof that all RPCs are deployed in Production.
- No Supabase writes or migrations were run. Production remains read-only and TEST remains empty. This CI pass verifies repository source only; clean-install replay and live integration remain unverified.


## 2026-11-18 — Production RPC/schema contract diff captured

- Added `docs/PRODUCTION_FRONTEND_RPC_LIVE_DIFF_2026-11-18.md` from fresh read-only Production catalogue queries and the refreshed 67-name frontend RPC inventory.
- Current comparison: 35 frontend RPC names exist in Production; 32 are absent. Confirmed live drift includes one-argument bidding and Duplicate ID functions, five-level live referral draft validation versus the source 1–20-level editor, a stale feature-setting implementation, and no configured Storage buckets.
- Revalidated 21/21 public tables have RLS, 110 constraints, 60 indexes, 20 SELECT-only policies, 10 non-internal application triggers, and 43 SECURITY DEFINER public functions with explicit settings. TEST remains empty.
- This is an evidence/reconciliation checkpoint, not a completed clean-install baseline. Production and TEST remain unmodified; no completion percentage increase is claimed.


### 2026-11-18 — Notification template creator attribution fix
- Source review found the Admin template table requires `created_by`, but the template-create RPC omitted that column, causing new template inserts to fail on a clean database.
- Updated `admin_save_notification_template` to record the authenticated Admin as `created_by` on insert; updates continue to preserve the original creator.
- This is a source migration correction only. Per the agreed development-first workflow, tests/builds are deferred to the final consolidated testing phase. No Supabase database was modified.
- No overall completion percentage increase is claimed for this isolated correction.


### 2026-11-18 — Production schema baseline candidate assembled
- Captured the current Production schema through read-only catalogue queries and added a separate candidate baseline under `supabase/clean-install/`; it is not in the Supabase CLI migration directory.
- Candidate inventory: 21 public tables, 110 constraints, 28 non-constraint indexes, 20 RLS policies, 47 public/private function definitions, 11 application triggers, and captured table/sequence/function grants.
- Added an ordered manifest of 48 source-only forward migration candidates after the Production snapshot. Historical migrations already represented by the snapshot are excluded; the duplicate audit-log pagination source is also excluded.
- Added explicit function/sequence ACL revocation before replaying observed grants, preventing PostgreSQL's default PUBLIC function EXECUTE privilege from weakening the captured access model.
- This is a schema-only candidate, not a verified canonical migration chain. No migration was executed and no Production or TEST writes occurred. Final replay, comparison and all tests remain deferred until the consolidated testing phase.
- Overall completion percentage remains unchanged; baseline replay and end-to-end integration are not yet verified.


### 2026-11-18 — Referral commission ledger idempotency integrity
- Hardened commission posting so a pre-existing credit idempotency key is accepted only when the ledger row matches the exact Income Wallet, credited Main ID, transaction type, direction, amount and commission reference.
- Hardened reversal so the original credit ledger row must reconcile before reversal, and an existing reversal key must match the exact debit transaction before it is treated as a replay.
- This prevents an unrelated wallet transaction with a colliding idempotency key from being mistaken for a posted commission or completed reversal.
- Source migration only. No database migration, financial transaction, build or test was run; final consolidated testing remains deferred as requested.
- Overall completion percentage is not increased for this isolated integrity hardening.


### 2026-11-18 — Withdrawal reservation/release ledger reconciliation
- Hardened Admin rejection of an approved withdrawal: the original Income Wallet reservation debit must exist and match the exact wallet, Main ID, amount and withdrawal reference before funds can be released.
- Existing release idempotency keys are now validated against the exact expected credit transaction instead of being treated as success based on key presence alone.
- Admin payout confirmation now also requires a matching reservation ledger entry, preventing an approved status without a corresponding reserved amount from being marked paid.
- Source migration only. No database migration, payout, build or test was run; all tests remain deferred to the final consolidated phase.
- Overall completion percentage is not increased for this isolated integrity hardening.
