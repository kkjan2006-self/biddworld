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


### 2026-11-18 — Winner-payment replay ledger verification
- Tightened both Fixed Bid-specific and shared Auction/Fixed Bid winner-payment retry paths.
- A repeated payment key now counts as a successful replay only when the existing ledger row matches the winner's Income Wallet, Main ID, debit direction, exact amount, transaction type and winning-payment reference.
- A colliding key from an unrelated wallet transaction now fails closed instead of returning a false paid/replayed response.
- Source migration only. No payment, database migration, build or test was executed; consolidated testing remains deferred.
- Overall completion percentage is not increased for this isolated integrity hardening.

### 2026-11-18 — Withdrawal payout details server-side validation
- Added a forward-only migration that validates payout details independently of the member UI: exact supported methods (UPI / Bank Transfer), matching credential field, account-holder length, UPI syntax, bank account length and rejection of unexpected JSON keys.
- The database stores a normalized method-specific payout object and audit logs record only the payout method and amount, never the UPI ID, account number or account-holder name.
- Preserved the existing active Main ID ownership check, Income Wallet balance lock, minimum-withdrawal setting, withdrawals feature gate and authenticated-only RPC grant.
- Added a focused static contract test. As requested, tests and builds remain deferred until the consolidated final testing phase.
- Source-only change. No Supabase migration or payout was executed; Production and TEST remain unchanged. No overall completion percentage increase is claimed for this isolated security hardening.

### 2026-11-18 — Auction and Fixed Bid cancellation refund ledger integrity
- Hardened Fixed Bid cancellation to verify every original debit belongs to the entry's Main ID and one of that member's wallets, uses the expected transaction/reference contract, and reconciles to the recorded entry amount.
- Existing Fixed Bid refund idempotency keys are now accepted only when the ledger row matches the exact wallet, Main ID, transaction type, direction, amount and entry reference.
- Hardened Auction cancellation with equivalent source-debit ownership/type/reference checks, bid-amount reconciliation, and exact validation of any existing refund key before treating it as a replay.
- Added a focused source-contract test for both cancellation workflows. Tests/builds remain deferred to the final consolidated phase as requested.
- Source-only changes to the not-yet-replayed migration chain. No database migrations or wallet transactions were executed; Production and TEST remain unchanged. No overall completion percentage increase is claimed for this isolated integrity work.

### 2026-11-18 — Member identity RPC migration compatibility
- Corrected the member identity migration chain: the earlier `member_list_my_ids()` definition returned eight columns, while the newer definition returns seven. PostgreSQL does not permit this table-return row type change through `CREATE OR REPLACE FUNCTION`.
- The forward migration now drops only the exact zero-argument RPC signature before recreating the seven-column contract consumed by the Account portal, then reapplies authenticated-only execution grants.
- This prevents a deterministic clean-install / forward-replay migration failure. Source-only correction; no Production or TEST database was changed. Tests/builds remain deferred to the final consolidated testing phase.
- No overall completion percentage increase is claimed for this migration compatibility correction.

### 2026-11-18 — Registration and Account status messaging alignment
- Aligned signup confirmation text with the existing auth-user trigger, which creates the member profile, Main ID and initial wallet rows at registration. The UI no longer incorrectly claims every new account remains inactive pending Admin verification.
- Email-confirmation-required users are instructed to confirm their email before signing in; users receiving an immediate session are told their free member account and Main ID have been created.
- Replaced the Account portal's unrelated review wording with a direct support/admin instruction for genuinely inactive accounts.
- Added a focused static contract test. Source-only change; no registrations, database writes, builds or tests were run. Production and TEST remain unchanged.
- No overall completion percentage increase is claimed for this UI consistency correction.

### 2026-11-18 — Duplicate ID placement approval hardening
- Removed the obsolete one-argument `admin_create_duplicate_member_id(text)` overload, which could create a pending Duplicate ID without an Under ID. The current two-argument placement RPC remains the sole creation contract.
- Duplicate ID activation now requires an active owner Main ID, a non-null active placement parent, and a different parent owner. The existing closed-ID no-reactivation rule remains, and status changes are audited.
- Unified the transaction-scoped advisory lock for Duplicate ID creation, Duplicate ID status changes, and Main ID lifecycle changes to serialize overlapping graph mutations.
- Main ID reactivation now only auto-reactivates linked Duplicate IDs whose placement parent is still active and belongs to another member.
- Added a focused source-contract test. Development-only migration; no database changes or tests/builds were executed. Production and TEST remain unchanged.
- No overall completion percentage increase is claimed for this security hardening batch.
## 2026-11-18 — Admin form validation lock recovery

- Fixed three Admin save handlers that acquired their in-flight mutation lock before validating input: notification template save, member profile save, and sponsor reassignment.
- Invalid or incomplete input now returns before the lock is acquired, so the Admin can correct the fields and submit again without refreshing the page.
- Valid submissions retain the existing in-flight guard, server RPC, success/error feedback and finally-based lock release.
- Added a source-contract regression test for validation-before-lock ordering and the existing finally cleanup.
- Source-only change. No tests/build were run in this development phase; all testing remains deferred to the final testing stage. Production and TEST Supabase projects were not accessed or modified. No completion-percentage increase is claimed.

## 2026-11-18 — Latest branch CI regression repair

- Re-fetched `completion-work` and confirmed the exact head before changes: `c87a2baa3eddf159fd8f1c8c882fb0be31db1542`.
- Inspected GitHub Actions run #915: 89/96 test files passed (355/362 tests); seven failures were traced to stale source assertions after legitimate workflow/lock/message changes, plus malformed duplicated fragments in the payout-validation migration.
- Updated the Duplicate ID serialization contract to assert the shared `biddworld.member_id_graph_mutation` transaction lock used by Duplicate ID approval and Main ID lifecycle operations.
- Updated registration/account tests to match the actual free-registration confirmation and current account-activation lock notice without asserting an inactive status that the Auth provisioning flow does not promise.
- Updated withdrawal safety assertions to verify the current select-and-validate idempotent release path rather than the removed `IF NOT EXISTS` insert pattern.
- Rebuilt the payout-detail validation migration as one complete function definition, correcting the UPI and bank-account regular expressions and removing orphaned duplicated PL/pgSQL fragments. This is source-only; no migration was applied to TEST or Production.
- GitHub Actions verification for this repair is pending. No completion percentage increase is claimed until the integrated application/database workflows are implemented and validated.

### 2026-11-18 — CI assertion follow-up
- The first repair run (#916) confirmed the seven original failures were reduced to two stale test files; the remaining assertions were overly whitespace-sensitive and one phone-pattern assertion retained an obsolete escaping form.
- Updated those checks to validate the actual phone-length contract and payout validation semantics independent of SQL formatting.
- The repaired payout migration remains source-only. Awaiting the next integrated CI run; no database changes and no completion percentage increase.

### 2026-11-18 — CI payout validation assertion follow-up
- CI run #918 passed 95/96 test files (the only remaining failure was an over-specific assertion that omitted the deliberate JSON null-type guard's `coalesce(..., 'null')` wrapper).
- Updated the assertion to verify the complete fail-closed type check. The payout validation migration itself now has one complete function definition and both format patterns include their end anchors.
- Awaiting CI run #919 for the final test/type-check/build result. No database migration was executed.

## 2026-11-18 — CI verification restored and withdrawal profile guard strengthened

- GitHub Actions run [#919](https://github.com/kkjan2006-self/biddworld/actions/runs/44241327288) passed on commit `ea2082e4fecd747621d2726f37cfb9f0d1285d05`: 96/96 test files and 362/362 tests passed; TypeScript project build/type-check and Vite production build passed.
- Follow-up source review found that the member withdrawal RPC and Admin approval workflow checked the active Main ID but did not independently require the linked member profile to be active, although the Member UI already checks both.
- Updated the member request RPC to require an active profile and Main ID, and Admin approval to lock/check the linked profile and Main ID together before reserving Income Wallet funds.
- Added regression assertions for both server-side checks. Source-only; no TEST or Production database writes or migration replay.
- The next CI run is pending. No completion percentage increase is claimed.

### 2026-11-18 — Withdrawal profile authorization CI follow-up
- CI run #920 stopped during test-file parsing because the payout validation contract test file contained SQL source instead of TypeScript test content.
- Restored the test file and retained the SQL migration in its intended path. The profile-status authorization checks in the member request and Admin approval RPCs remain in the source migration files.
- A fresh CI run is required before considering this follow-up verified. No database changes or migrations were applied.

## 2026-11-18 — Fixed Bid and Referral engine hardening

- Added source-level integrity checks to Fixed Bid entry replay: the existing entry must still be open and its Bid/Income Wallet debit ledger must reconcile to the recorded entry amount and owner.
- Fixed Bid participation and winner-payment RPCs now require the caller's active member profile and owned active Main ID. Draw eligibility now excludes inactive profiles/IDs.
- Fixed Bid draws now return the recorded draw result on retry, validate source debit ownership/type/wallet/reference before refunds, and verify existing refund ledger rows before treating them as completed.
- Unified the Fixed Bid-specific winner-payment ledger transaction type with the shared winning-payment contract.
- Referral commission reversal replay now verifies the original credit and reversal ledger rows; pending-only reversals remain replayable without a wallet debit.
- Added focused static contract tests for the Fixed Bid and referral calculation/posting/reversal source paths. Runtime database verification remains deferred until the TEST clean-install baseline is reviewed and development is complete.
- No TEST or Production writes or migration replay. CI for this batch is pending.

## 2026-11-18 — Clean-install migration partition audit

- CI run #922 passed after Fixed Bid and Referral source hardening: 98/98 test files and 372/372 tests passed; TypeScript check and Vite production build passed.
- Reconciled the current migration directory against the clean-install forward manifest: 66 timestamped migration files are partitioned into 50 ordered forward candidates and 16 historical/source files already represented by the Production baseline.
- Added an explicit excluded-historical manifest and a regression test requiring every timestamped migration to appear exactly once in either the forward or excluded list. The two missing Production ledger source files remain preserved only in the exact historical archive under `supabase/audit/production-ledger/`.
- The 1,929-line Production schema baseline remains a candidate only. No TEST migration replay or Production write was performed; canonical clean-install status is not claimed.

### 2026-11-18 — Clean-install partition CI verification and catalogue scope correction
- GitHub Actions run #923 passed: 99/99 test files and 375/375 tests; TypeScript and Vite production build passed.
- Added a machine-checked partition of the 66 timestamped source migrations: 50 forward candidates plus 16 explicitly excluded historical files, with every file accounted for exactly once.
- Updated the Production catalogue documentation to distinguish 243 constraints across all inspected catalogue schemas from the 110 constraints on the 21 public application tables; clarified the 17 all-schema triggers versus 11 application-owned triggers.
- Updated migration recovery documentation to reflect the exact 30 historical Production migration SQL bodies now archived under `supabase/audit/production-ledger/`. The two unrecoverable executable paths remain archival-only and are not copied into the executable migration directory.
- Clean-install baseline remains a candidate only. No TEST migration replay or Production write was performed.

### 2026-11-18 — Public auction RPC CI follow-up
- CI run #925 validated the new public-auction RPC source coverage, but two test assertions failed: the explicit frontend RPC inventory did not yet include the newly added RPC, and the SECURITY DEFINER test regex was over-escaped.
- Added `public_list_active_auctions_page` to the frontend RPC inventory and refreshed its source snapshot commit. Updated the branch RPC contract test to reference the final Member ID list RPC and new public auction RPC.
- Corrected the regex assertion. The source migration and App integration are unchanged. Awaiting a fresh CI run.

## 2026-11-18 — Public Auction RPC and source inventory verification

- GitHub Actions run #926 passed on source commit `6c272b5b9a462e7943dc97be6e0f34a030bbed77`: 100/100 test files and 413/413 tests passed; TypeScript and Vite production build passed.
- Added the public paginated auction catalogue RPC and replaced the anonymous direct-table query in the website. The function exposes only public listing fields for published products with live/scheduled time windows and grants RPC execution to anon/authenticated, without table SELECT grants.
- Refreshed the frontend RPC inventory to 68 unique literal RPC names. The Production diff now records 35 live names and 33 source-only names, with source migration coverage checks for all 33.
- Updated the clean-install forward chain to 51 timestamped migrations; the explicit excluded historical list remains 16, partitioning all 67 timestamped migration files exactly once.
- No Production or TEST SQL writes or migrations were performed. The public auction RPC is source-only pending clean-install replay and final deployment.

### 2026-11-18 — Public Fixed Bid catalogue CI follow-up
- CI run #929 confirmed the new public Fixed Bid RPC source tests and the 69-name frontend RPC inventory coverage, but the pre-existing Fixed Bid pagination test still asserted the removed direct-table query.
- Rewrote those assertions to verify the RPC-based search/status/page contract while retaining the request lifecycle and idempotent entry checks.
- The source RPC and migration manifest changes are unchanged. A fresh CI run is pending.

### 2026-11-18 — Fixed Bid pagination test syntax correction
- CI run #931 stopped before TypeScript/build because the updated Fixed Bid pagination test had an incorrectly escaped single-quoted assertion.
- Corrected the assertion to use a double-quoted TypeScript string. The source UI and migration are unchanged.
- The public package catalogue RPC batch has also been committed; its CI result is pending.

### 2026-11-18 — Fixed Bid pagination regex correction
- CI run #932 confirmed 418/418 individual tests passed, but the Fixed Bid pagination suite failed while constructing an over-escaped regular expression.
- Replaced the regex with direct source-string assertions for client-side insert/update/upsert calls. The Fixed Bid UI and database migration remain unchanged.
- A fresh CI run is pending.

### 2026-11-18 — Fixed Bid public catalogue time-filter hardening
- CI run #933 passed: 102/102 test files and 423/423 tests; TypeScript check and Vite production build passed.
- Hardened the Fixed Bid public catalogue time-window predicate with an explicit SQL CASE so ended campaigns do not evaluate timestamp casts for their configuration. Scheduled/live campaign timestamp validation remains strict.
- Added a contract assertion for the branch-specific time-window behavior. A fresh CI run is pending.

## 2026-11-18 — Production dependency audit gate

- CI run #934 passed: 102/102 test files and 423/423 tests; TypeScript check and Vite production build passed.
- The full dependency audit reported 12 high-severity and 0 critical findings, concentrated in the development/build toolchain dependency graph (including picomatch, chokidar, Tailwind, Vite and Vitest). Major-version changes are not being forced blindly.
- Added a separate `npm audit --omit=dev --audit-level=high` CI gate and a retained production-only audit report. This distinguishes deployable runtime dependencies from dev tooling and blocks high/critical production dependency findings.
- The all-dependency high findings remain an open security-remediation item before launch; no production package upgrades have been applied yet.

## 2026-11-18 — Public catalogue coverage and dependency security gate

- GitHub Actions run #934 passed: 102/102 test files and 423/423 tests; TypeScript and Vite production build passed.
- Added secure public catalogue RPCs for Fixed Bid campaigns and active packages. The public Fixed Bid UI no longer directly selects campaign rows; it receives only published-product data and member-facing campaign configuration. The Packages UI now lists active packages through a limited public RPC and reads the activation feature flag only for authenticated sessions.
- Frontend inventory is now 70 unique literal RPC names: 35 present in Production and 35 source-only. Source coverage tests verify every source-only RPC has a corresponding forward migration and UI call.
- Clean-install partition now contains 53 ordered forward candidates and 16 excluded historical source files, accounting for all 69 timestamped migration files exactly once (72 SQL files in `supabase/migrations`, including three legacy files).
- GitHub Actions run #935 passed the production dependency audit gate: `npm audit --omit=dev` reported 0 vulnerabilities (0 high/critical). The full dependency audit still reports 12 high, 0 critical findings in development/build tooling; this remains an open remediation item before launch. No major dependency upgrades were forced.
- No TEST migration replay or Production writes were performed. All three new public catalogue RPCs remain source-only.

## 2026-11-18 — PWA install icon assets

- GitHub Actions run #938 passed: 102/102 test files and 423/423 tests; TypeScript check and Vite production build passed.
- Added real 192×192 and 512×512 PNG install icons derived from the existing BiddWorld SVG brand mark. The 512 icon is declared `any maskable`; the Apple touch icon now points to the 192 PNG.
- Added both PNGs to the service-worker shell cache and strengthened PWA tests to verify actual PNG signatures and dimensions.
- Bumped the service-worker cache to v3 in a follow-up commit so previous shell assets are retired on activation. CI for that cache-version change is pending.
- Android installation and offline behavior still require real-device verification during final QA; source tests/build do not prove device installation.

### 2026-11-18 — PWA cache lifecycle and Pages build verification
- CI run #939 passed: 102/102 test files and 423/423 tests; TypeScript and Vite production build passed.
- Bumped the service-worker shell cache to v3 so the prior v2 cache is removed on activation after the PNG icon update.
- Added an explicit PWA test for the GitHub Pages `/biddworld/` base-path contract and a second CI build using `GITHUB_PAGES=true`. This validates the Pages subpath build without deploying or configuring hosting.
- CI for the Pages subpath build is pending; real Android installation/offline verification remains part of final QA.

### 2026-11-18 — Auction Bid report inventory follow-up
- CI run #942 validated the new Admin auction bid report source coverage, but the explicit frontend RPC inventory surface allow-list did not yet include the new `AdminAuctionBidReport.tsx` component.
- Added the component to the known UI surface list and refreshed the inventory snapshot commit. The SQL RPC, Admin integration and pagination/CSV implementation are unchanged.
- A fresh CI run is pending.

### 2026-11-18 — Fixed Bid entry reporting source integration
- Added an Admin-only, paginated Fixed Bid entry report with campaign/member search, status/date filters, continuation and complete CSV export.
- Added the `admin_list_fixed_bid_entries_page` SECURITY DEFINER RPC with trusted Admin-role authorization and a restricted result projection that omits idempotency keys.
- Added the new migration to the forward manifest and source RPC coverage. The inventory allow-list is being updated for the new UI surface; CI is pending.
- No TEST or Production database writes were performed.

### 2026-11-18 — Complete auction/Fixed Bid export assertion update
- CI run #946 confirmed the new paginated Admin auction and Fixed Bid export source contracts, but the existing filter test still expected the previous “current loaded rows” export button labels.
- Updated the assertions to the new complete-history CSV labels. The filters, RPCs and migration are unchanged.
- CI for the refreshed assertions is pending.

### 2026-11-18 — Referral commission report level filtering
- Added a 1–20 level filter to the Admin commission register, alongside the existing status filter.
- Complete CSV export now passes the selected status and level filters to the paginated Admin RPC, while the on-screen list retains its load-more behavior.
- Added source-contract coverage for the level/status filter and complete export. CI is pending.

## 2026-11-18 — Complete Admin bid and catalogue report coverage

- Added Admin-only paginated Auction Bid History and Fixed Bid Entries reports, each with server-side search, status/date filters, load-more pagination and complete CSV export. Internal idempotency keys are excluded from both RPC projections.
- Replaced the current-loaded-row-only Auction and Fixed Bid campaign CSV exports with complete server-paginated exports using new Admin-only RPCs. Existing management-list RPCs remain unchanged.
- Added level 1–20 filtering to the referral commission register; complete CSV export now applies the selected status and level filters.
- Frontend RPC inventory: 74 unique calls; 35 names exist in the read-only Production catalogue and 39 remain source-only. The source coverage test maps all 39 source-only contracts to forward migrations and UI call sites.
- Migration partition: 75 SQL files total (72 timestamped + 3 legacy); 56 ordered forward candidates and 16 excluded historical files account for all 72 timestamped files exactly once.
- GitHub Actions run #948 passed: 102/102 test files, 431/431 tests, TypeScript, normal production build and GitHub Pages subpath build. Production dependency audit: 0 vulnerabilities; full development/build dependency audit still reports 12 high, 0 critical.
- No Production or TEST writes were performed. The new reporting RPCs remain source-only pending the clean-install replay and integration phase.

### 2026-11-18 — Android PWA install control
- Added a conditional `Install App` button to the public header. It uses the browser's `beforeinstallprompt` event, appears only when the browser considers the app installable, and clears on prompt completion or `appinstalled`.
- Added source-contract coverage for install prompt and installed-event handling. No install prompt is fabricated when the browser does not offer one.
- Real-device installation and offline navigation remain pending final Android QA.

### 2026-11-18 — PWA install header wiring correction
- CI run #950 caught that the install-button component and test were added, but the final App source commit did not include the header render.
- Wired the component import and render into the public header. The browser event handler component and PWA manifest/service worker are unchanged.
- CI rerun is pending.

### 2026-11-18 — PWA import correction
- CI run #951 passed all tests but TypeScript failed on a duplicate `PWAInstallButton` import in `src/App.tsx`.
- Removed the duplicate import; the header render and install prompt component remain intact. CI rerun is pending.


## 2026-11-18 — Latest branch CI and read-only database revalidation

- Confirmed the exact `completion-work` branch HEAD: `398398927d97154cf94417234449c7c60a73b069` (`fix: remove duplicate PWA install component import`). This is the branch HEAD; repository-wide commit search results are not used as a substitute for branch metadata.
- Inspected GitHub Actions run [#951](https://github.com/kkjan2006-self/biddworld/actions/runs/44248768197): all 102 test files / 432 tests passed; TypeScript then failed because `src/App.tsx` imported `PWAInstallButton` twice. Removed the duplicate import in the next commit.
- Verified GitHub Actions run [#952](https://github.com/kkjan2006-self/biddworld/actions/runs/44248923875) on the current HEAD: 102/102 test files and 432/432 tests passed; TypeScript project build, Vite production build and GitHub Pages subpath build all passed.
- Rechecked the package activation and support-filter contracts on the current branch. The package activation UI fails closed unless the database setting is explicitly true; the support queue applies status filters in initial load, load-more and full CSV export paths. The current support test expects all three paths. The older reported two-assertion CI failure is not present on this HEAD.
- Read-only Production catalogue revalidation: 21 public tables / 175 columns; RLS enabled on all 21; 110 constraints; 60 indexes; 20 public policies; 47 public/private application functions; 10 public-table triggers plus the Auth-user trigger (11 application triggers total). Storage currently has 0 buckets.
- Read-only TEST revalidation: project is `ACTIVE_HEALTHY`, PostgreSQL 17.12; 0 public tables, 0 migrations, 0 application functions, 0 public policies, 0 public indexes, 0 public-table triggers and 0 Storage buckets. No migrations or data were written.
- The clean-install baseline remains a candidate only: 56 ordered forward migrations and 16 explicitly excluded historical timestamped migrations are listed; three legacy/unversioned SQL files still require explicit treatment. The candidate must be reviewed and replayed only on TEST after development completion. It is not approved for Production.
- Production Storage is not configured yet, although source migrations define the intended media/receipt buckets. This remains a TEST replay and final integration-verification item.
- This entry records verification and blockers only. No feature completion percentage increase is claimed; no Production or TEST writes were performed.


### 2026-11-18 — Clean-install candidate structural and migration-partition cross-check
- Compared the schema-only baseline candidate's static object inventory with fresh read-only Production catalogue results: 21 tables, 21 RLS enablements, 20 policies, 47 functions, 11 application triggers and 28 explicit non-constraint indexes are represented; live Production reports 21 tables / 175 columns, 110 constraints, 60 total indexes, 20 policies, 47 public/private functions and 10 public-table triggers plus the Auth trigger. No object-count discrepancy was found in this structural pass.
- Recomputed the source migration partition against the current branch directory: 75 SQL files total (72 timestamped and 3 legacy/unversioned); 56 ordered forward candidates plus 16 explicitly excluded historical migrations account for all 72 timestamped files exactly once. No missing entries, duplicates or overlaps were found.
- Confirmed `pgcrypto` version 1.3 is already installed in the `extensions` schema in both Production and TEST, matching the baseline's extension prerequisite. No extension changes were made.
- Reviewed the two source Storage migrations: `product-media` is public-read with Admin-only mutation; `package-receipts` is private with member-owned upload/read and Admin review. Neither Production nor TEST currently has a Storage bucket, so these policies and upload paths remain unverified until TEST replay.
- Remaining baseline review gates: exact function-definition/ACL parity, trigger function/order and identity-sequence ownership, and dependency/semantic review of all 56 forward migrations. Candidate remains non-executable pending TEST replay; Production stays read-only.
- No database writes, migrations, test data, member actions or wallet activity. No completion-percentage increase is claimed.


### 2026-11-18 — Notification template persistence contract repair
- Current branch review found that `admin_save_notification_template` inserted `created_by`, but the new `notification_templates` table definition omitted that column. This would fail on first template creation after clean-install replay.
- Added nullable `created_by uuid references auth.users(id) on delete set null` to the table definition. The save RPC continues to force all saved templates to inactive drafts; no email/SMS dispatch is introduced.
- Source change committed as `960681dcafc84e5c86db1b6f7b02a4c8ee304f97`. No database was modified and no tests were run manually, per the requested final testing phase.
- Remaining work continues with full module integration and schema/function/ACL reconciliation. This isolated repair does not justify a completion percentage increase.


### 2026-11-18 — Fixed Bid winner draw security hardening
- Reviewed the existing Fixed Bid entry/draw/settlement SQL and found winner ranking used PostgreSQL `hashtextextended` with a random UUID seed. This is a non-cryptographic hash, so replaced the future-draw ranking with a seeded SHA-256 digest using the already-installed `pgcrypto` extension in the `extensions` schema.
- Added forward migration `20261118340000_secure_fixed_bid_random_draw.sql`; existing recorded draw rows remain immutable. New migration is appended to the ordered clean-install forward manifest (57 candidates now) and the README count was updated.
- Added a source-contract assertion to the existing Fixed Bid integrity test for the SHA-256 ranking and absence of the old hash scoring. Tests intentionally not run, per the request to execute the full test suite only after development completion.
- No Production or TEST database changes; no real member, wallet or campaign activity. The source migration remains pending final TEST replay and integration verification.


### 2026-11-18 — Member profile and withdrawal input validation repair
- Source inspection of the member Account portal found several regular-expression literals with doubled backslashes. As written, the mobile-number pattern expected a backslash rather than an optional plus sign, and the withdrawal amount / bank-account patterns did not match ordinary digits. Corrected the literals to use the intended digit and plus-sign classes.
- Added a regression contract to `tests/member-withdrawal-payout-privacy.test.ts` covering the mobile, amount and bank-account patterns. Tests were not run; all testing remains deferred to the final phase as requested.
- No database changes or financial actions were performed. The fix affects client-side input validation only; server-side payout validation remains authoritative.


### 2026-11-18 — Private package receipt Storage integration
- Found an end-to-end gap: Member and Admin portals both use the `package-receipts` bucket, while the reviewed Production and TEST catalogues had no Storage buckets and no forward migration created this bucket.
- Added `20261118350000_private_package_receipt_storage.sql`: private 5 MB bucket, JPEG/PNG/PDF allowlist, authenticated member upload restricted to their own `auth.uid()` folder, and SELECT access restricted to the Admin `app_metadata.role` claim. No public access, member read, update or delete policy is added.
- Added a source-contract test and included the migration in the clean-install forward manifest (58 candidates). Updated clean-install documentation.
- Tests not run per the requested final-only testing phase. No Production or TEST database writes; the migration still requires isolated TEST replay and Storage API verification at final testing.


### 2026-11-18 — Admin pending activation receipt-path integration
- Source review found that the Admin pending-activation RPC omitted `receipt_path`, even though the Admin UI's receipt viewer requires it to create a private signed URL. The receipt preview was therefore unreachable from the pending queue for uploaded receipts.
- Added `20261118360000_admin_pending_activation_receipt_path.sql` to return the receipt object path while retaining Admin-only authorization and authenticated-only EXECUTE grants. Results now use stable newest-first ordering.
- Added a regression source-contract test and included the migration in the clean-install forward manifest (59 candidates). Updated clean-install documentation.
- Tests not run, as requested; no Production or TEST database writes. The migration and private Storage access still require final isolated TEST replay and integration verification.


### 2026-11-18 — Package receipt read-policy tightening
- Review of the original receipt migration found a legacy `package_receipts_select_own_or_admin` Storage policy that still allowed a member to read their own receipt, even after the later migration introduced an Admin-only SELECT policy. The older policy was not removed by the later migration, so both policies would be OR-combined by PostgreSQL RLS.
- Added `20261118370000_restrict_package_receipt_reads_to_admin.sql` to drop the permissive legacy SELECT policy and duplicate legacy INSERT policy, then retain one owner-folder-only member upload rule and one Admin-role-only read rule.
- Added a regression source-contract test and included the migration in the clean-install forward manifest (60 candidates). Updated clean-install documentation.
- Tests not run per the requested final-only testing phase. No Production or TEST database writes; policy behavior still requires isolated TEST replay and Storage API verification at final testing.


### 2026-11-18 — Member placement tree includes Duplicate IDs
- Source review found `get_my_placement_tree()` traversed only child rows with `id_type='main'`, omitting Duplicate IDs even though Duplicate IDs participate in placement and can be selected as Under IDs for subsequent placements.
- Added `20261118380000_include_duplicate_ids_in_member_placement_tree.sql`: cycle-safe, depth-bounded traversal now includes Main and Duplicate nodes, and each returned node identifies its ID type and owning Main ID. The authenticated member's own Main ID remains the only root.
- Added regression source-contract test; included migration in clean-install forward manifest (61 candidates) and updated README.
- Tests not run per requested final-only testing phase. No Production or TEST database writes; runtime RPC validation remains part of final isolated TEST replay.


### 2026-11-18 — Filterable complete package activation history export
- Extended the Admin Reports package activation section beyond the pending-only queue export. Administrators can now export the complete activation history with payment-status (pending / approved / rejected / refunded), text search and inclusive submission-date filters.
- The status filter is passed to the Admin-only paginated RPC; search/date filters are applied across all fetched pages before CSV generation. The existing pending-only report remains separate and clearly labelled.
- Added regression assertions for the complete-history filter contract. Tests intentionally not run until the final testing phase. No Production or TEST database changes.
- Source commits: `ea86ea7f0f2b591d7a908e9c820fcf86cec2bbbc` (Admin UI) and `8f958924453442a194350d5974cf28afba494c65` (regression coverage).


### 2026-11-18 — Clean-install manifest and dependency reconciliation (current branch checkpoint)
- Reconciled the GitHub `supabase/migrations` directory against both clean-install manifests. The current directory has 80 SQL files: 77 timestamped plus 3 legacy/unversioned files. All 77 timestamped files are partitioned exactly once into 61 ordered forward candidates and 16 excluded historical files. No missing, stale, duplicate or overlapping manifest entries were found.
- Confirmed the existing `tests/clean-install-migration-manifest-integrity.test.ts` enforces exact partition, existence, order and candidate-only guard assertions. The test was inspected, not run.
- Reconciled the baseline candidate's static object counts: 21 public tables, 175 columns per the catalogue snapshot, 110 public constraints, 28 explicit non-constraint indexes (60 total including constraint-backed indexes), 21 RLS enablements, 20 policies, 47 functions (43 public + 4 private), and 11 app-owned triggers.
- Inspected all 61 forward migration files at source level for DDL and object references. Recorded important replacements and prerequisites, including support-ticket notification ordering, repeated financial-guard function replacements, signup-function replacement, MLM dashboard replacement, identity RPC return-type drop/recreate, placement-tree replacement, and Storage bucket/policy sequence.
- Identified an important final-state dependency: the package receipt owner-read policy introduced in `20261118150000` is not fully removed by `20261118350000`; the final `20261118370000` migration drops the permissive owner-read policy and leaves Admin-only receipt SELECT plus owner-folder upload. The complete ordered sequence through `20261118370000` is required.
- Added `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md` and corrected the current inventory in the clean-install README and Production audit documents. Earlier 48/56 forward and 72 timestamped counts are superseded by the current 61/16/77 inventory.
- Latest GitHub Actions run #989 on commit `dd72209c1da51d7953da14245d6520431f03469c` failed at the test step: 105/106 files and 443/444 tests passed. The only failure is a stale source-string assertion in `tests/admin-package-activation-report-filters.test.ts`; type-check/build and Pages build were skipped. This automatic CI result is recorded for the consolidated final testing/repair phase; no manual tests were run.
- No Production or TEST database writes, migrations, Storage changes, member actions, wallet transactions or payouts occurred. No overall completion percentage is claimed.


### 2026-11-18 — Baseline function ACL/search-path static pass and repeated CI result
- Scanned the baseline candidate's function and grant statements: 47 SECURITY DEFINER function definitions, 47 function-level search_path settings, 88 explicit EXECUTE grants across 42 function names, and schema-wide function revocations before grants. Three private helper functions have no direct client EXECUTE grant; `private.place_bid(uuid)` is service_role-only. All 11 app-owned triggers are defined after the functions they invoke.
- Confirmed 38 table grant statements align with authenticated SELECT on 17 public tables and service_role access to all 21 public tables. These are source-level ACL observations, not runtime verification.
- Latest completed CI at this checkpoint is run #996 on `f7274c13053ad593c3fa303560d0e4f06f51c42a`; it repeats the single stale assertion failure in `tests/admin-package-activation-report-filters.test.ts` (105/106 files, 443/444 tests). Build/type-check and Pages build were skipped. The failure remains deferred to the consolidated final test/repair phase.
- No Production or TEST writes, no migration replay, no manual test execution, and no wallet or member activity.


### 2026-11-18 — Auction bid active-profile eligibility alignment
- Reconciled the public auction bid call in `src/App.tsx` with the final `public.place_bid(uuid,text)` wrapper and cancellation refund ledger contract. Named RPC arguments, request-key reuse, `:bid`/`:income` suffixes, `auction_bid` transaction type and `auction` reference metadata align.
- Found that auction bid eligibility required an active Main ID but did not also require its owning `profiles` row to be active, unlike the Fixed Bid entry workflow. Added `20261118410000_require_active_profile_for_auction_bids.sql` to require active profile status and the canonical `profiles.main_member_id` ownership link while preserving the existing debit/idempotency implementation and RPC grants.
- Added the migration to the ordered forward manifest and updated the clean-install README count to 63. Current SQL inventory: 82 files (79 timestamped + 3 legacy), partitioned as 63 forward + 16 excluded timestamped.
- Source inspection only. Tests/build, TEST replay and browser checks remain deferred; Production `hbqatszyzqobgtauyuzy` and TEST `yoaauthwejdgaevfvwpo` were not modified.


### 2026-11-18 — Active winner eligibility and payment replay integrity
- Reconciled Admin auction status/finalize calls with SQL signatures, Admin authorization and consumed JSON result fields; reconciled Member Account winner-payment call with the shared RPC named arguments and stable retry-key behavior.
- Found that auction finalization selected the highest accepted bid without checking current Main ID/Profile activity. A suspended member could be selected but then be blocked by the payment RPC. Added `20261118420000_active_winner_eligibility_and_payment_replay_guard.sql`: only active Main IDs with their canonical active owning profiles are eligible at finalization. It acquires the same member-graph advisory lock as the Admin Main-ID lifecycle function before locking the auction, preserving the winner eligibility snapshot against concurrent lifecycle changes. Highest-bid / earliest-created / UUID tie-break ordering remains unchanged.
- Hardened both shared and legacy Fixed Bid winner-payment idempotent replay branches: an existing matching ledger row now returns replay success only if the winning payment row is already marked paid and has `paid_at`; inconsistent ledger/payment state fails closed. Income-Wallet-only debit, ledger metadata, public signatures and authenticated grants remain intact.
- Added migration to clean-install forward manifest (64 candidates) and updated README. Inventory: 83 SQL files (80 timestamped + 3 legacy), 64 forward + 16 excluded timestamped migrations.
- Source review only; tests/build and TEST replay remain deferred. Production `hbqatszyzqobgtauyuzy` and TEST `yoaauthwejdgaevfvwpo` were not modified.


### 2026-11-18 — Auction refund and delivery tracking source reconciliation
- Rechecked Auction cancellation against source bid debits and refund idempotency keys: accepted bid rows and wallet accounts are locked; member, wallet type, transaction metadata, auction reference and debit suffixes are validated; summed source debits must equal the recorded bid amount; mismatches roll back the transaction.
- Rechecked Fixed Bid draw refunds: SHA-256 seeded ranking remains deterministic for the recorded draw; only exact winning entry IDs are excluded from refunds; each losing entry's wallet debit is reconciled and conflicting refund ledger rows fail closed.
- Reconciled Delivery Tracking table/RLS and Member/Admin callers: members receive owner-scoped read-only access; Admin RPCs enforce role; new tracking requires a paid winning-item payment and uses a payment advisory lock; updates lock the tracking row and recheck paid status; Member Account loads tracking alongside paginated winning-payment history.
- Found that Delivery Tracking validates the status vocabulary but does not define allowed transitions. Admin can reopen a delivered record or move returned records to shipped; changing away from delivered clears delivered_at. The repository does not specify an authoritative transition graph or correction/return rules, so no speculative guard was added. This remains a documented policy requirement before lifecycle hardening.
- Corrected clean-install README inventory text: 80 timestamped SQL files (64 forward + 16 excluded) plus 3 legacy files = 83 total. README had stale 78 / 81 counts.
- Added `docs/AUCTION_REFUND_DELIVERY_TRACKING_SOURCE_REVIEW_2026-11-18.md`. Source review only; no tests/builds, TEST replay or database writes. Production and TEST remain untouched.
- Documentation commits: `025ec6050f5846347d682025e2cd443feaabf5f7` (clean-install README) and `74337c27b1646887f13340d4495147189f223e4e` (source review).


### 2026-11-18 — Serialize Auction Bid eligibility with Main-ID lifecycle

- Found a source-level race between `private.place_bid` and Admin Main-ID suspend/close: the bid RPC read active Main ID/Profile state without synchronizing with the Admin status mutation.
- Added `20261118430000_serialize_auction_bid_member_eligibility.sql`. Both paths now acquire the same per-Main-ID advisory transaction lock; the bid path rechecks Main ID and Profile active state after acquiring it, before idempotency, auction or wallet processing.
- Retained the existing public RPC signature/grant and bid wallet debit/idempotency behavior. The Admin lifecycle function body is carried forward with the added lock; no product status rules were changed.
- Added the migration as forward candidate 65. Current SQL inventory: 81 timestamped (65 forward + 16 excluded) + 3 legacy = 84 total.
- Source-only change. No tests/builds, CI, TEST replay, Production access or database writes. Consolidated testing remains deferred. Overall estimate remains 55%.
- Source commit: `5f15127ec192bd04c0fcd0908e0bb441674daaa8`.


### 2026-11-18 — Clean-install baseline function ACL reconciliation

- Compared the candidate baseline's 47 function definitions (43 public, 4 private) and explicit EXECUTE grants with the Production public RPC security inventory.
- Candidate grants authenticated EXECUTE on all 43 public signatures and anon EXECUTE only on public.lookup_sponsor(text), matching the recorded Production counts. Both wallet-account and wallet-transaction overloads are granted by exact signature.
- Candidate explicitly grants service_role EXECUTE on all 43 public functions and private.place_bid(uuid). The referenced Production inventory does not record service_role privilege state; exact parity remains unverified.
- Candidate grants anon/authenticated USAGE on audit_logs_id_seq although the identity-sequence privilege rationale is not recorded. This is flagged for exact ACL/identity behavior verification; no speculative grant change made.
- Added docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md and linked it from the clean-install README.
- Source-only review. No tests/build, database replay, Production or TEST access/writes. Overall estimate remains 55%.


### 2026-11-18 — Clean-install baseline SECURITY DEFINER and trigger dependency review

- Inspected all 43 public function declarations: all are SECURITY DEFINER and carry explicit function-level search_path settings.
- All 36 Admin functions contain auth.uid() and exact JWT app_metadata.role = admin authorization checks with a rejection path. The SQL `admin_list_members_sponsors()` applies the predicate in its WHERE clause and returns no rows to unauthorized callers.
- Member-scoped RPCs use auth.uid(); public bid and package-activation wrappers delegate to the private implementations. The four private functions and their client-execution boundary were recorded.
- Confirmed the candidate creates one auth.users signup trigger and ten public feature-gate triggers after the corresponding private function and application table definitions. Supabase-managed schemas/tables remain platform prerequisites, not app-created schema objects.
- No evidenced authorization or trigger-order source defect found; no speculative SQL patch made. service_role and audit_logs identity-sequence ACL parity remain unresolved pending exact evidence.
- Added docs/CLEAN_INSTALL_BASELINE_SECURITY_DEFINER_TRIGGER_REVIEW_2026-11-18.md and linked it from the clean-install README.
- Source-only review. No tests/build/CI, database replay, Production or TEST changes. Overall estimate remains 55%.


### 2026-11-18 — Forward migration dependency, CI sequencing and dependency security review

- Source-reviewed high-impact portions of the ordered 65-forward-migration chain: Auth/signup, member graph, package/referral, financial guards, Fixed Bid/auction settlement, withdrawals, wallet, receipt Storage, notification and report/catalogue dependencies. No evidenced ordering defect found in inspected groups; full SQL compile/replay remains pending.
- Confirmed package-lock v3 contains 228 package entries and exact key versions Vite 6.4.6, Vitest 4.1.12, @vitest/mocker 4.1.12 and @supabase/supabase-js 2.57.4. Current Vite and Vitest mocker advisories list the locked versions as patched floors; no speculative upgrade made.
- Updated CI workflow: push-triggered verification no longer runs on completion-work, while main pushes and PRs to main retain verification. Changed install step to npm ci for lockfile-based reproducibility. Workflow was not executed.
- Reviewed PWA production-only service worker registration, BASE_URL scope, relative manifest URLs/icons, and service-worker cache rules that exclude cross-origin Supabase/API traffic. Actual Android install/offline verification remains pending.
- Added docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md. No tests/build/CI, npm install/audit, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Member Main-ID lifecycle concurrency: Fixed Bid, withdrawals and winner payments

- Found four member RPCs that checked active Main-ID/Profile status without sharing the per-Main-ID advisory lock introduced for Admin lifecycle changes and auction bids: `member_join_fixed_bid_campaign`, `member_create_withdrawal_request`, `member_pay_winning_item_payment`, and `member_pay_fixed_bid_winning_payment`.
- Added `supabase/migrations/20261118440000_serialize_member_financial_eligibility.sql` (forward candidate #66). Each function acquires the shared lifecycle transaction lock and rechecks the same user's Main ID ownership/type and active Profile/Main-ID status before processing.
- Preserved function signatures, idempotency keys, campaign/payment behavior, wallet debit rules, strict payout validation and authenticated EXECUTE grants.
- Package activation already locks the Main-ID row `FOR UPDATE`; auction winner selection already takes the member-graph mutation lock. Those paths were not changed.
- Updated clean-install forward manifest and README to 66 forward + 16 excluded timestamped migrations, plus 3 legacy SQL files (85 total). Added `docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md`.
- Source-only. No tests/build/CI, SQL execution, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Frontend support and notification direct-write/RLS reconciliation

- Confirmed Support UI reads tickets directly under owner-or-Admin RLS, but member submission and Admin status/response changes use audited idempotent RPCs. Unused direct table INSERT/UPDATE grants could bypass RPC idempotency and audit behavior.
- Confirmed Notifications UI reads directly, marks read via owner-scoped UPDATE(read_at), and Admin sends only through the audited idempotent RPC. Direct authenticated INSERT was unnecessary.
- Added `supabase/migrations/20261118450000_restrict_direct_support_notification_writes.sql` (forward candidate #67): revoke authenticated direct INSERT/UPDATE on support_tickets and direct INSERT on member_notifications; preserve SELECT and owner-only read-state UPDATE.
- Added `docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md`; updated manifest/clean-install README to 67 forward + 16 excluded timestamped + 3 legacy SQL files (86 total).
- Source-only. No tests/build/CI, SQL execution, migration replay or database writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Frontend member/Admin direct-read and RLS review

- Reviewed App catalogue/wallet summary, Account, Packages, WalletHistory, Referrals, PlacementTree, FixedBid, Notifications, Support, Admin dashboard and selected report components against the clean-install baseline RLS and relevant forward policies.
- Confirmed own-profile SELECT, member-owned wallet account/transaction SELECT through member_ids.owner_user_id, allowlisted app_settings read for the package activation switch, and owner/Admin notification/support read boundaries.
- Confirmed inspected Admin data and mutation call sites use Admin RPCs; member identity/graph/withdrawal and Fixed Bid actions use member-scoped RPCs. No additional evidenced direct-read ownership or Admin direct-table-write defect found in this focused slice.
- Noted WalletHistory CSV export retrieves all RLS-visible transactions in 500-row batches and filters client-side; this is an efficiency enhancement, not an authorization defect.
- Added `docs/FRONTEND_MEMBER_ADMIN_DIRECT_READ_RLS_REVIEW_2026-11-18.md`. Source-only; no tests/build/CI, SQL execution, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Baseline ACL evidence and least-privilege correction

- Verified current GitHub refs: `completion-work` was `bd857fefef45943f14446b5c828f9d46e6c14bdb`; protected `main` was `415364b71534c7fc31d6c0928dd8395e10cbd94f`. The branch comparison shows `main` has one documentation-only commit not present on `completion-work`; `main` was not modified.
- Ran read-only Production catalogue queries only. Confirmed `service_role` has EXECUTE on all 43/43 public functions, matching the clean-install candidate's explicit public function grants; `private.place_bid(uuid)` remains an explicit service_role-only private grant.
- Confirmed Production `audit_logs_id_seq` grants SELECT, UPDATE and USAGE to anon, authenticated and service_role, while `audit_logs` table access is limited to service_role and postgres. Tightened the schema-only candidate to grant only USAGE on this sequence to service_role and no sequence privileges to anon/authenticated. This is an intentional least-privilege improvement, not exact live ACL parity. Production and TEST were not changed.
- Updated the ACL and SECURITY DEFINER/trigger audit documents to record the evidence and remaining limits. No tests, builds, CI, SQL replay or database writes were run. Overall estimate remains 55%.


### 2026-11-18 — Support-ticket residual column privilege correction

- Inspected the original support-ticket grants and discovered that migration #67 revoked only table-level INSERT/UPDATE, while the original migration had separately granted INSERT(user_id, subject, message) and UPDATE(status, admin_response). PostgreSQL column ACLs are independent; those column-level privileges can survive table-level REVOKE.
- Added `20261118460000_revoke_support_ticket_column_writes.sql` as forward candidate #68. It revokes both table-level and exact column-level INSERT/UPDATE from authenticated while preserving SELECT and the intended audited/idempotent RPC write paths.
- Added `docs/SUPPORT_TICKET_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`; updated manifest to 68 forward + 16 excluded timestamped + 3 legacy SQL files (87 total), clean-install README, status and static inventory checkpoint.
- Source-only. No tests/build/CI, SQL execution, migration replay or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.
