# BiddWorld — Official Project Status

> This file is the authoritative recovery checkpoint for all future BiddWorld development chats. The detailed historical evidence remains in `docs/PROJECT_COMPLETION_REGISTER.md` and the linked audit documents. Do not restart completed work or infer deployment from source presence.

## A. Project Information

- Project: BiddWorld
- Repository: https://github.com/kkjan2006-self/biddworld
- Current development branch: `completion-work` — ongoing bulk source development; latest batch adds individual Admin-controlled permissions for restricted payment-review Staff (2026-11-19).
- Latest verified source batch: Fixed Bid public catalogue projection includes `max_entries_total` and `refund_non_winners` (forward #70); Placement Tree verifies Main-ID root ownership (forward #71); Admin notification history displays recipient Main ID/name through a bounded Admin-only RPC (forward #72); Admin pending activation receipt links now track their five-minute expiry and can be refreshed without reloading the queue; Support-ticket Admin updates now write one audit record through the row trigger rather than duplicating it in the RPC; Member Support retries retain a key only for unchanged payloads; Admin notification fingerprints use an unambiguous JSON tuple; Support queue and CSV export use stable keyset pagination; Member wallet history and complete wallet CSV export now use stable `(created_at, id)` keyset pagination. Latest source commits: receipt viewer `d938fc397a19cac7737079236ed3f69d41d33380`; support audit dedup migration `2648cc6e6260d83494e6299290f0c211f757137a`.
- Protected branch: `main` (do not modify)
- Latest verified application/source work commit: `2648cc6e6260d83494e6299290f0c211f757137a` (single Audit Log writer for Admin support-ticket updates, preserving the existing `support.ticket_updated` action and `response_updated` detail contract).
- This bulk batch's committed updates: forward manifest `9e4ee080befb1bdafe83148487ba5a81acb31ba5`, clean-install README `22cb014748abb373880ad3b084a4e5c7191870b7`, Fixed Bid projection contract test source `3331875af097b925e0336cc9bfd88d059ae7b521`, static reconciliation `7e79fa0a36509ae6a28fe9101ab36d9e5f81005a`, completion register `071e16e058f0c54aa71884b99cd2171fa1a68ed7`; this status checkpoint was refreshed again at verified branch HEAD `7207c75c51f0340373cd12a33204a8e0cc905d0e`.
- Latest source commit message: `fix: align placement tree UI with duplicate ID hierarchy`.
- Latest verified source/documentation batch commits: `1bee5aa29697701bc714163bc84256b46dc4b70d` (source fix), `e0692f028bda716bf3b3b909a9bf1e1e44ffe244` (forward manifest), `ab9d485766c86d8b5e9a03a4bd9e40ee4a7e2d1d` (clean-install README), `864c2ae315e512e8b3921279375cdd6dfd290de0` (status), `98abc466b7a7e812ed965b7bff54c019d352474b` (completion register), `285fa062988ee44c39706d6cd174c3bfbbf55148` (concurrency audit).
- Previous verified `completion-work` checkpoint: `4d1b05c8e42071dc805cf39663a5bfb9033c0721`. The baseline function ACL and SECURITY DEFINER/trigger dependency source reviews are committed through `7a85cdd714146e3fc8474def3c642e0d724d6254`; verify branch HEAD on resume. Protected `main` remains exactly `415364b71534c7fc31d6c0928dd8395e10cbd94f` and was not modified.
- Latest application-source correction: `dd34feece77d383979a2a60b2210def738e48064`
- Last updated: 2026-11-18 — Member wallet statement and Support queue/export keyset pagination
- Previous historical checkpoints below are retained as evidence; they are superseded by the latest verified HEAD above.
- Protected `main` HEAD verified unchanged: `415364b71534c7fc31d6c0928dd8395e10cbd94f`.
- Overall project completion estimate: **59%** (source modules and documentation are substantially present; canonical database bootstrap, remaining integrations, consolidated testing and release work are still pending). This is a planning estimate, not a verified deployment or test percentage.
- Production Supabase: `hbqatszyzqobgtauyuzy` — READ-ONLY during development
- Isolated TEST Supabase: `yoaauthwejdgaevfvwpo` — currently empty; do not replay until baseline review is complete
- Budget/hosting: free-tier only; no domain or hosting purchase during development

## B. COMPLETED — Verified Source Work (not equivalent to deployed/live completion)

The following source/UI/documentation work is present in the current branch and must not be recreated from scratch:

- React + TypeScript + Vite responsive application, member and Admin portal foundations, Supabase Auth integration, environment-mode separation, PWA manifest/service worker/icon, and BiddWorld SEO/social metadata.
- Member profile/identity, Main ID and Duplicate ID views, member dashboard summaries, wallet balances/history, referral genealogy, placement tree, package catalogue/activation request, auction/Fixed Bid catalogues, withdrawal requests, support, notifications, account security, winner/delivery history and member exports.
- Admin member/sponsor/duplicate-ID management, package/referral-plan drafts, product/media management UI, auction and Fixed Bid management, wallet ledger/adjustments, withdrawal review, winner/payment and delivery views, support queue, notification templates/send flow, Admin access/role management, platform health, audit logs, filters, pagination and CSV exports.
- Source SQL includes wallet-first debit/idempotency patterns, referral draft versioning and commission calculation/post/reversal workflows, Duplicate ID placement and graph serialization, auction and Fixed Bid lifecycle/draw/refund/settlement workflows, withdrawal reservation/release/review, winner payment, support/notification idempotency, Admin wallet adjustment, receipt/media Storage policies, Admin role management and report RPCs.
- Numerous static source-contract tests and migration/security audit documents exist. These are source artifacts; they do not prove that migrations are deployable or live.
- Historical CI evidence: run #948 passed 102/102 test files and 431/431 tests, TypeScript check, Vite production build and GitHub Pages subpath build. Subsequent runs #996–#1003 did not establish a green CI state; the known recurring failure is a stale source-string assertion in `tests/admin-package-activation-report-filters.test.ts`. Runs #1004 and #1005 both completed with test-step failures; #1005 is the latest completed run at this checkpoint. Type-check/build results for failed runs must not be assumed. See `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`.

## C. IN PROGRESS

- Establish a trustworthy canonical clean-install database baseline and migration replay path.
- Reconcile every frontend RPC call and SQL signature/result contract; selected Admin signatures, Member/Package/Fixed Bid contracts, and auction/fixed-bid report contracts have been source-checked (see the focused reconciliation documents). A source-level Admin dashboard count defect was corrected: counts now derive from Admin-authorized RPC responses rather than direct table HEAD counts subject to member RLS. Auction bid, Fixed Bid entry, catalogue export and notification delivery paths were also source-reconciled with their SQL signatures, result fields, grants and RLS policies; see `docs/ADMIN_REPORT_NOTIFICATION_CONTRACT_RECONCILIATION_2026-11-18.md`.
- Review SQL dependency ordering, object prerequisites, grants, RLS, policies, triggers, Storage and function security.
- Resolve the known stale Admin package-activation report test assertion during the consolidated final test/repair phase; the latest CI run is not green.
- Continue source-only development only where contracts are sufficiently evidenced; do not invent missing schema or business rules. Recent Support/notification retry-key edge cases have been corrected with source-contract tests (not run). PWA service-worker cache is v4; documentation is aligned, while the PWA source test still has a stale v3 literal assertion deferred to final test/repair.

## D. PENDING — Major Development Work

1. **Canonical database baseline:** static object inventory and migration partition are reconciled. The 36 Admin function auth predicates, all 43 public SECURITY DEFINER/search_path declarations, four private function boundaries and 11 trigger dependency ordering have now been source-reviewed; see `docs/CLEAN_INSTALL_BASELINE_SECURITY_DEFINER_TRIGGER_REVIEW_2026-11-18.md`. Remaining: compare every complete baseline function body with the recovered migration archive; continue all 73 current forward migration dependency checks and per-object semantic review; replay only in isolated TEST during final testing. Read-only Production evidence now confirms service_role EXECUTE on all 43 public functions. The candidate intentionally narrows audit_logs_id_seq to service_role USAGE only; anon/authenticated sequence access is removed in the candidate because those roles have no audit_logs table privileges.
2. **RPC reconciliation:** selected Admin signatures plus Member/Package/Fixed Bid argument and consumed result contracts are source-reconciled; remaining work is all other Admin/member RPC call sites, direct table-select/RLS contracts, authorization, overloads and migration coverage. See both focused reconciliation docs and the existing Production/RPC audits. Key audit: `docs/PRODUCTION_FRONTEND_RPC_LIVE_DIFF_2026-11-18.md`, `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md`, and `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md`.
3. **Migration compatibility:** the current source directory has 92 SQL files (89 timestamped + 3 legacy); the 75 forward and 16 excluded manifests account for all 91 timestamped files exactly once. Continue semantic review of function replacements, object prerequisites, ACLs and platform dependencies. The legacy `0001_biddworld.sql` mismatch is not a blocker for the candidate-baseline path: static comparison shows the separate candidate has the canonical columns used by the first forward migrations. See `docs/CANONICAL_CLEAN_INSTALL_PATH_RECONCILIATION_2026-11-18.md`. Do not treat the 30 historical Production ledger SQL snapshots as a ready-made clean-install sequence.
4. **Dependency security/reproducibility:** package-lock v3 is committed (228 packages). Locked Vite 6.4.6 and @vitest/mocker 4.1.12 are at the published patched versions for the currently reviewed advisories. CI now uses npm ci and no longer runs on completion-work pushes, preserving the development-first testing gate. Full npm audit/signature review remains deferred to final testing. See `docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md`.
5. **Remaining source features/integration:** receipt upload and product-media Storage integration; complete historical report/filter/export coverage; Admin role and member lifecycle edges; notification read-state and delivery/provider boundary; verify PWA/offline behavior; complete remaining UI/RPC contract gaps. PWA source registration, scope, manifest and service-worker cache boundaries are present; actual Android/offline behavior remains unverified.
6. **Security and operational readiness:** per-function SECURITY DEFINER semantic review, grants/RLS/Storage verification, rate limiting/abuse controls, Auth configuration review, backup/monitoring/support readiness.
7. **Documentation/release:** update production checklist, deployment/environment instructions and source ZIP only after development and consolidated testing are complete.

## E. BLOCKED / SAFETY BOUNDARIES

- The current `supabase/migrations` directory is not a validated clean-install sequence. `0001_biddworld.sql` is a legacy schema incompatible with later contracts; `001_initial_schema.sql` is empty; `0002_place_bid_rpc.sql` is legacy. Do not replay these as a shortcut.
- Production evidence: 21 public tables, all 21 with RLS; 110 constraints, 60 indexes, 20 policies, 10 application triggers, 43 public functions, and 30 historical migration ledger rows. These snapshots are evidence, not an executable baseline.
- Production RPC/frontend drift has been documented: the latest audit found 35 frontend RPC names present and 39 absent in Production (74 unique frontend RPC names). Some live signatures differ from current source. Never infer that source-defined functionality is deployed.
- Production Storage currently has no configured buckets/policies according to the latest read-only audit, while source migrations define `product-media` and `package-receipts`.
- Isolated TEST project was last verified empty (zero migrations/public tables/buckets). Keep it untouched until the canonical baseline has been reviewed.
- No Production writes, migrations, data changes, wallet credits/debits, commissions, payouts or package activations are permitted in development.
- CI: latest completed run #1005 failed during the test step; type-check/build and Pages build were skipped. The known recurring stale assertion is deferred to the consolidated final test/repair phase. Run #948 was a prior successful CI run, not the current state.
- Overall planning estimate: 55% source/development completion; consolidated testing and release are not included as completed work. Treat this as an estimate, not verified deployment readiness.

## F. DEVELOPMENT ROADMAP (Bulk Batches)

- Batch 1 — Source-level clean-install baseline inventory and exact migration partition completed; semantic dependency/ACL review and TEST replay remain pending.
- Batch 2 — Resolve migration dependency/order/replay blockers and validate baseline in TEST only.
- Batch 3 — Complete frontend/RPC/SQL contract reconciliation and source corrections.
- Batch 4 — Finish remaining member/Admin/report/notification/Storage/PWA source integration and dependency/security remediation.
- Batch 5 — Development-complete gate: confirm every unique requirement is implemented and source migrations are replayable in TEST.
- Batch 6 — One consolidated final testing phase: database replay/integration, auth, RLS/RPC authorization, wallet/referral/duplicate-ID, package, auction, Fixed Bid, winner payment, withdrawal, reports, notifications, Storage, PWA, Android responsiveness, build and regression.
- Batch 7 — Final readiness review, release ZIP and deployment instructions. Do not buy domain/hosting or deploy without the owner's explicit decision.

## G. TESTING STATUS

- Manual testing: NOT STARTED (deliberately deferred).
- Full isolated TEST migration replay: NOT STARTED; TEST remains empty.
- End-to-end/browser/Android checks: NOT STARTED.
- Automatic CI: latest completed run #1005 failed during the test step; type-check/build and Pages build were skipped. Manual/full final testing remains NOT STARTED.
- Do not claim modules fully complete merely because UI, SQL source or static tests exist.

- 2026-11-18 — Clarified the clean-install starting point: do not use legacy `0001_biddworld.sql`; the separate schema-only Production baseline candidate contains the key canonical fields required by the first forward migrations. Updated the clean-install README and static reconciliation. No replay or database changes; full 64-migration dependency review remains open.

- Canonical clean-install path reconciliation: documented the distinction between the legacy `0001_biddworld.sql` schema and the separate schema-only candidate baseline. Static checks confirmed the candidate includes key canonical columns consumed by the first forward migrations. Updated `supabase/clean-install/README.md`, `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`, and added `docs/CANONICAL_CLEAN_INSTALL_PATH_RECONCILIATION_2026-11-18.md`. No database replay, tests or DB writes. Latest documentation commit: `7e91a2e7ec97b75513db599913b6a827f6550483`.

- 2026-11-18 — Reviewed the package receipt Storage chain from initial upload through private bucket/Admin-only read tightening and the Admin pending-activation receipt-path RPC. Confirmed intended final source policy: member-folder INSERT only, Admin SELECT only; product-media remains a separate public-read/Admin-write bucket. Added `docs/STORAGE_POLICY_FINAL_STATE_RECONCILIATION_2026-11-18.md`. Effective policies still need TEST replay verification; no tests/build or database changes. Commit: `5b308934613b33df9f581c8c9c451b56f9774498`.

- Status checkpoint: package-receipt Storage policy sequence and product-media policy separation are documented; current inventory corrected to 82 SQL files (79 timestamped + 3 legacy), 63 forward + 16 excluded timestamped migrations. Full replay and policy verification remain pending.

- 2026-11-18 — Fixed Bid secure random-draw migration review found two source defects in `20261118340000_secure_fixed_bid_random_draw.sql`: refund variables were referenced without declarations (PL/pgSQL compilation failure), and refund selection excluded every entry from a winning member rather than excluding only the actual winning entry IDs. Declared the refund idempotency key and existing-ledger row variables; changed the losing-entry predicate to exclude only `v_winner_entries`, so additional entries from a winner are handled as non-winning entries when configured refunds are enabled. Source commit: `81c245c1688fcff306ca7b556f1f0e268eca68e3`. Not executed or tested; no DB changes.

## H. NEXT DEVELOPMENT BATCH

1. Auction cancellation and Fixed Bid refund source paths have been reconciled against original debit ledger metadata and idempotency keys. Delivery Tracking table/RLS and Member/Admin RPC callers are reconciled. The missing Delivery Tracking transition graph is documented; do not invent terminal-state or return/re-shipment rules absent an approved product contract.
2. Baseline function ACL reconciliation: read-only Production catalogue queries confirm authenticated EXECUTE on 43/43 public functions, anon EXECUTE only on public.lookup_sponsor(text), and service_role EXECUTE on 43/43 public functions. The candidate explicitly grants service_role on those 43 public functions plus private.place_bid(uuid). Production audit_logs_id_seq has broad SELECT/UPDATE/USAGE grants to anon/authenticated/service_role, but the candidate intentionally narrows this to service_role USAGE only because anon/authenticated have no audit_logs table privileges. This least-privilege deviation is documented; Production is unchanged. See docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md.
3. Continue the 72-forward-migration semantic dependency review, including final function bodies, trigger references, function search_path, trigger order, extensions and sequence ownership.
4. Continue remaining frontend RPC/direct-table RLS coverage and member/Admin lifecycle edge cases. Fixed Bid entry, withdrawal request and both winner-payment RPCs now share the Admin Main-ID lifecycle advisory lock and recheck activity after acquiring it. Fix only evidenced defects in source migrations; do not run tests/builds or database replay before the 100% development gate.
5. Reconcile dependency lockfile/security advisories and remaining notification provider boundary, PWA/offline source integration and operational readiness.
6. Keep Production hbqatszyzqobgtauyuzy read-only and TEST yoaauthwejdgaevfvwpo unchanged. Consolidated tests/replay remain deferred.

## I. CHANGE HISTORY

- 2026-11-18 — Verified current refs (`completion-work` starting HEAD `bd857fefef45943f14446b5c828f9d46e6c14bdb`; protected `main` `415364b71534c7fc31d6c0928dd8395e10cbd94f`). Read-only Production catalogue queries confirmed service_role EXECUTE on all 43 public functions. Narrowed the clean-install candidate's audit_logs_id_seq grants to service_role USAGE only; removed anon/authenticated sequence access because those roles have no audit_logs table privileges. Updated ACL/security audit and completion register. No tests/build/CI/replay or database writes; Production and TEST unchanged. Overall estimate remains 55%.


- 2026-11-18 — Auction winner/payment source reconciliation: Admin status/finalize calls match SQL signatures and consumed result fields; Member Account uses the shared winner-payment RPC with a stable retry key. Found that auction finalization did not recheck current Main ID/Profile activity, potentially selecting a suspended winner whom payment would reject. Added `20261118420000_active_winner_eligibility_and_payment_replay_guard.sql`: active Main ID/Profile winner filtering, shared lifecycle advisory lock before auction locking, and fail-closed replay validation for shared and legacy Fixed Bid winner-payment RPCs (payment must already be paid with paid_at). Preserved highest-bid tie-break, Income-Wallet-only debit, RPC signatures and grants. Forward manifest now 64; SQL inventory 83 (80 timestamped + 3 legacy; 65 forward + 16 excluded). No tests/build, replay or DB writes. Production and TEST untouched.


- 2026-11-18 — Auction bid creation source reconciliation: verified `src/App.tsx` calls `place_bid` with the exact two named arguments exposed by the final idempotent RPC; verified wallet debit suffixes, transaction type and reference metadata match the auction cancellation refund consumer. Found and fixed the missing active-profile eligibility check with migration `20261118410000_require_active_profile_for_auction_bids.sql`. Updated the forward manifest to 63 and clean-install README. No tests/build, TEST replay or DB writes. Production and TEST remain untouched.


- 2026-11-18 — Created this official recovery status file on `completion-work` after verifying the branch and reading the completion register. No application source or database was changed.
- 2026-11-18 — Clean-install static reconciliation: verified 81 SQL files (78 timestamped + 3 legacy), exact 62-forward / 16-excluded partition, candidate baseline object counts, function ACL/search_path counts, ordered replacement dependencies and final package-receipt Storage policy dependency. Added `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`; corrected historical inventory figures. Latest completed CI #997 failed the same stale assertion; no manual testing or database replay.
- 2026-11-18 — Compared selected Admin/Member/package/Fixed Bid frontend RPC calls with baseline and forward migration signatures. No named-argument mismatch was found in the inspected subset; confirmed wallet transaction overload first argument is required, avoiding the suspected PostgREST ambiguity. Added `docs/ADMIN_FRONTEND_RPC_SOURCE_SIGNATURE_RECONCILIATION_2026-11-18.md`. Source inspection only; no tests/build or database writes.
- 2026-11-18 — Reconciled Member Account, Package activation and Fixed Bid catalogue/entry RPC arguments and consumed result fields against their final source definitions, including final strict withdrawal payout validation. No mismatch was found in this subset; no speculative source edit was made. Added `docs/MEMBER_PACKAGE_FIXED_BID_RPC_CONTRACT_RECONCILIATION_2026-11-18.md`. Source inspection only; no tests/build or database writes.
- 2026-11-18 — Admin workspace count review found that six dashboard totals were sourced from direct table HEAD-count queries and therefore could be filtered by member-facing RLS policies. Replaced those queries with existing Admin-authorized overview/list RPC results; renamed the tile from “Registered Profiles” to “Main Member IDs”. Commit: `dd34feece77d383979a2a60b2210def738e48064`. CI #1004 failed during tests; no manual tests or database writes.
- 2026-11-18 — Reconciled Auction Bid and Fixed Bid Entry report RPC arguments/result fields, paginated catalogue exports, and member/Admin notification table access, RLS and idempotent Admin-send RPC. No mismatch found in inspected paths; recorded remaining Admin recipient UUID usability improvement. Added `docs/ADMIN_REPORT_NOTIFICATION_CONTRACT_RECONCILIATION_2026-11-18.md`. Source review only; no tests/build, migration replay or database writes. CI #1005 failed during tests; type-check/build skipped. Commit: `cfca840519a09b585e96e398036d45f210a705d6`.
- Detailed development history, evidence and prior checkpoints: `docs/PROJECT_COMPLETION_REGISTER.md`.

## Status update rule

At every development batch/chat end, update this file with the actual verified branch head, commit, completed/in-progress/pending items, testing status and next batch. Never downgrade completed source work without a documented regression/reopen reason. Never claim a GitHub commit, CI pass, migration replay or deployment without verifying it.

## J. AI continuation documentation

- Added `docs/AI_CONTINUATION_GUIDE.md` as the repository operating contract for future AI-assisted chats. It defines the source-of-truth hierarchy, mandatory new-chat startup, development-before-testing gate, Production/TEST boundaries, product scope, commit discipline and the compact Universal Master Prompt.
- New chats should paste only the compact prompt in Section 10 of that guide; then read this status file, the guide, the relevant completion-register entries and focused audit documents before continuing.
- Guide commit: `65194b9452a10de7f6d7a0527ef8c2b5ebd70dc3`.
- This documentation-only batch did not change application source, SQL, Supabase, member or financial data. No tests, builds, CI workflows or database replay were initiated.
- Existing planning estimate remains 55%; this documentation addition does not change development completion.

## K. Per-step overall completion reporting

- Owner instruction: at the end of every development step/batch, show one clear Telugu line with the **overall BiddWorld project completion percentage** (not merely the current task's progress).
- Keep the percentage evidence-based and consistent with this status file; do not increase it for documentation-only changes.
- Added this mandatory reporting rule to Section 9 and the compact prompt in `docs/AI_CONTINUATION_GUIDE.md`.
- Guide update commit: `da8d4040ab40c47bdd8dfb428d37c55263f67d32`.
- Documentation-only update; no application/SQL/Supabase changes and no tests, builds, CI workflows or database replay initiated. Overall estimate remains 55%.


- 2026-11-18 — Auction cancellation and Fixed Bid refund ledger reconciliation completed at source level. Delivery Tracking table/RLS and Member/Admin RPC calls were traced; paid-payment-only creation, payment advisory lock, owner-only member reads and Admin-only writes are confirmed in source. The status vocabulary exists but no allowed-transition graph is defined; documented this as an unresolved product contract rather than inventing state transitions. Corrected clean-install README inventory to 83 SQL files (80 timestamped = 64 forward + 16 excluded, plus 3 legacy). Added `docs/AUCTION_REFUND_DELIVERY_TRACKING_SOURCE_REVIEW_2026-11-18.md` and updated completion register. No tests/build, migration replay or database writes. Production and TEST untouched. Documentation commits: `025ec6050f5846347d682025e2cd443feaabf5f7`, `74337c27b1646887f13340d4495147189f223e4e`, `1d0103c623d207cfa1c2a24a19e7b78d0928b68e`. Overall estimate remains 55%.


- 2026-11-18 — Auction bid/Main-ID lifecycle concurrency review found a race between active-member lookup in `private.place_bid` and Admin suspension/closure. Added `20261118430000_serialize_auction_bid_member_eligibility.sql`: both RPC paths share a per-Main-ID advisory transaction lock and the bid path rechecks Main ID/Profile activity after locking, before idempotency, auction locking or wallet debit. Public RPC signature/grant and wallet debit/idempotency logic are retained. Added as forward candidate 65; inventory is now 81 timestamped (65 forward + 16 excluded) + 3 legacy = 84 SQL files. Source-only; no tests/build, CI, TEST replay or Production/TEST writes. Overall estimate remains 55%. Commit: `5f15127ec192bd04c0fcd0908e0bb441674daaa8`.


- 2026-11-18 — Reconciled candidate clean-install baseline function ACL structure against the Production public RPC security inventory. Candidate contains 43 public functions and 4 private functions; all 43 public signatures have authenticated EXECUTE, anon EXECUTE is limited to public.lookup_sponsor(text), and the two wallet-report overload pairs are granted explicitly. service_role is explicitly granted on all 43 public functions plus private.place_bid(uuid), but the Production inventory does not capture service_role parity. Also flagged unexplained anon/authenticated USAGE on the audit_logs identity sequence. No speculative ACL change made; exact live privilege and identity-sequence behavior remain to be verified. Added focused audit and updated clean-install README/status. No tests/build, migration replay or database writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Source-reviewed the clean-install baseline's 43 public SECURITY DEFINER declarations and explicit search_path settings; confirmed all 36 Admin functions include authenticated-user and exact app_metadata admin-role checks, member-scoped RPCs use auth.uid(), and public wrappers delegate to private implementations. Reconciled four private function roles and the 11-trigger creation order (one auth.users signup trigger plus ten public feature-gate triggers). No authorization or trigger-order source defect found; service_role and audit_logs identity-sequence ACL parity remain unresolved from missing live evidence. Added focused audit and linked it from clean-install README/status/register. No tests/build/CI, migration replay or database writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Reviewed the 65-file forward migration chain in focused high-impact groups (Auth/signup, member graph, package/referral, financial guards, Fixed Bid/auction settlement, withdrawal, wallet, Storage receipts, notification, reports and public catalogues). No evidenced ordering defect was found in inspected dependencies; full PostgreSQL replay remains deferred. Reviewed lockfile v3 (228 packages): Vite 6.4.6 and @vitest/mocker 4.1.12 match published patched floors for current advisories; full npm audit remains pending. Corrected CI sequencing so pushes to completion-work do not automatically run tests/builds before development completion, and changed install to npm ci. Reviewed PWA registration, manifest and service-worker scope/cache boundaries; Android/offline verification remains pending. Added focused audit. No tests/build/CI run, npm install/audit or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Member Main-ID lifecycle concurrency review found four source paths that checked active Main-ID/Profile status without sharing the per-Main-ID advisory lock already used by Admin suspension/closure and auction bids: Fixed Bid entry, withdrawal request, auction winner payment and Fixed Bid winner payment. Added `20261118440000_serialize_member_financial_eligibility.sql` as forward candidate #66. Each path now acquires the same transaction lock and rechecks ownership/type/active status before campaign/payment processing, request insertion or wallet debit. Existing RPC signatures, idempotency, wallet rules, payout validation and grants are retained. Updated forward manifest to 66; inventory is now 82 timestamped (66 forward + 16 excluded) + 3 legacy = 85 SQL files. Added `docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md`. No tests/build/CI, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Frontend support/notification direct-write RLS review: `Support.tsx` reads support tickets directly under owner-or-Admin RLS, but submits and updates only through audited idempotent RPCs; the table still granted direct INSERT/UPDATE, allowing unused direct writes to bypass those RPC contracts. `Notifications.tsx` reads directly and updates only `read_at` under owner-only RLS, while Admin sends only through the audited idempotent RPC; direct authenticated INSERT was unnecessary. Added `20261118450000_restrict_direct_support_notification_writes.sql` as forward candidate #67, revoking support-ticket INSERT/UPDATE and notification INSERT from authenticated while retaining SELECT and owner-scoped notification read-state UPDATE. Added `docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md`. Updated manifest to 67 forward; inventory 83 timestamped + 3 legacy = 86 SQL files. Source-only; no tests/build/CI, SQL replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.

- Latest branch verification: `completion-work` HEAD `03a6b5b2747014c9a7b50f813438bd17c2cb9b7e`; protected `main` remains `415364b71534c7fc31d6c0928dd8395e10cbd94f` (identical to its prior checkpoint). Support/notification direct-write restriction is committed and present in the 68-entry forward manifest. No Production or TEST access/writes.

- Latest verified checkpoint before this documentation batch: `b3dd20395c115055b69c55af4e0eaef8b438e7d6`. Member/Admin direct-read and RLS review covers Account, WalletHistory, Packages, App catalogue/wallet summary, Referrals, PlacementTree, FixedBid, Notifications, Support, Admin dashboard and selected reports. No additional evidenced access defect found in this slice; full grant parity and effective policy verification remain pending for final TEST replay.

- 2026-11-18 — Focused frontend direct-read/RLS reconciliation: checked profile self-read, wallet account/transaction owner policies, allowlisted member app_settings read, Packages feature switch, public catalogue and member-scoped RPC callers, notification owner read-state updates, Support owner/Admin reads, and Admin dashboard/report RPC-only data and mutation paths. No additional evidenced authorization defect found in this slice. Documented wallet CSV export's all-visible-rows client filtering as an efficiency enhancement, not an access-control defect. Added `docs/FRONTEND_MEMBER_ADMIN_DIRECT_READ_RLS_REVIEW_2026-11-18.md`. Static source review only; no tests/build/CI, SQL replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.

- Latest documentation checkpoint verified: `a6574cfdb85f416aa0b0cde1c8304a487af6e240`; protected `main` remains exactly `415364b71534c7fc31d6c0928dd8395e10cbd94f`. No Production or TEST access/writes.


- 2026-11-18 — Follow-up static privilege review found that migration #67 revoked table-level INSERT/UPDATE on support_tickets but did not revoke the separate column-level INSERT(user_id, subject, message) and UPDATE(status, admin_response) grants introduced by migration 20261116041000_member_support_tickets.sql. Added forward candidate #68, 20261118460000_revoke_support_ticket_column_writes.sql, explicitly revoking both table-level and column-level INSERT/UPDATE from authenticated. SELECT and the audited idempotent support RPC paths remain. Added docs/SUPPORT_TICKET_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md; updated forward manifest and clean-install inventory to 69 forward + 16 excluded timestamped migrations, plus 3 legacy SQL files (88 total). Source-only; no tests/build/CI, SQL execution, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Notification residual column privilege correction: the original `member_notifications` migration granted authenticated column-level INSERT(user_id, title, message, category), while candidate #67 revoked only table-level INSERT. Because column ACLs are independent, an Admin could retain a direct INSERT path under the Admin-only RLS policy and bypass audited/idempotent `admin_send_member_notification(...)`. Added candidate #69, `20261118470000_revoke_member_notification_column_insert.sql`, revoking both table-level and exact column-level INSERT. Preserved owner-scoped UPDATE(read_at) for member read-state. Added `docs/MEMBER_NOTIFICATION_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`; manifest now has 69 forward + 16 excluded timestamped + 3 legacy SQL files (88 total). Source-only; no tests/build/CI, SQL execution, migration replay or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


- 2026-11-18 — Completed explicit GRANT/REVOKE statement scan across all 69 ordered forward migrations. The only independently granted column-scoped write privileges identified were support-ticket INSERT/UPDATE (corrected in #68) and member-notification INSERT (corrected in #69); notification UPDATE(read_at) is intentionally retained for owner-scoped read-state changes. No other explicit column-scoped INSERT/UPDATE grants were found in the forward candidates. Broader baseline/effective ACL parity, policies, default privileges and runtime verification remain pending. Updated `docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md`. Source-only; no tests/build/CI or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


- 2026-11-18 — Member Auction Bid UX source correction: the existing idempotent `place_bid` caller now maps insufficient funds to the requested “Insufficient Funds – Please Add Funds” message, explains closed/ended/non-live auctions, and avoids presenting uncertain network outcomes as confirmed failures. The same retry key is retained for ambiguous outcomes. Commit: `e055aeb5a645f64ebb54de36af803c0a341f3bd2`. No tests/build/CI or database operations.

- 2026-11-18 — Member Account report export hardening: paginated CSV export now detects repeated full pages and applies a safe upper bound, stopping with a clear error instead of hanging or silently duplicating records. Commit: `88c7c5e55510161cac4e3e7c1b4c87ae8aa6988a`.

- 2026-11-18 — Member Wallet History account-scope correction: when the authenticated user changes, wallet history rows, page/retry state, has-more state and prior errors are reset before loading the new member's records. A ref tracks the active auth scope so state-reset side effects are not placed inside a state updater. Commits: `d8d283593796ffa762c4d18eacf985e36713eda8`, `5cbe4d7d9e376fc574c817baa999712704a7d138`. No tests/build/CI, database replay or DB access/writes. Production remains read-only; TEST untouched. Overall estimate remains 55%.

- 2026-11-18 — Recovery checkpoint refreshed after verifying `completion-work` HEAD `5cbe4d7d9e376fc574c817baa999712704a7d138`. Updated latest source commits and the exact completed Account/Wallet changes above. No application or database changes in this checkpoint update; no tests/build/CI or database replay initiated.


- 2026-11-18 — Notifications pagination hardening: Load More now deduplicates by notification ID and stops pagination with a clear refresh message if a full page contains no new records, preventing an endlessly repeatable page from accumulating duplicate notifications. Commit: `947d52d14d1a8d020b73c7ce768e6ecd13490d0e`.

- 2026-11-18 — Support queue and CSV export hardening: Load More deduplicates ticket IDs and stops on a repeated full page; full CSV export now fingerprints page IDs, detects repeated pages, and has a safe upper bound with a clear error. Commit: `e8aeb776c5ab6a848e017d9e7ea57f9b13cf33ba`. Source-only changes; no tests/build/CI, migration replay or database operations. Production remains read-only; TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Admin Portal pagination hardening: member directory Load More now deduplicates by Main ID; audit log, wallet ledger and withdrawal queue stop when a full returned page contains no new unique records and show a refresh instruction. This prevents duplicate rows and repeated-page pagination loops across Admin data lists. Commit: `dea33ef8fac35d52b26e935334f353bad596258c`. Source-only update; no tests/build/CI or database operations. Production remains read-only; TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Member Portal feature integration correction: the existing account view had the Placement Tree and Commission History rendered under the same `member-network` active-section condition as My Network, while the navigation exposed only My Network. Added dedicated navigation entries and independent active-section visibility for Placement Tree and Commission History. This makes both already-implemented member features directly reachable without showing all three views together. Commit: `f5f2ccf0888118e64fcf32a885566ba608502a80`. Source-only; no tests/build/CI or database operations. Production remains read-only; TEST untouched. Overall estimate remains 55% pending broader feature inventory and final test phase.


- 2026-11-18 — Fixed Bid catalogue projection reconciliation: added forward candidate #70 (`20261119000000_fixed_bid_public_rules_projection.sql`) to expose the missing `max_entries_total` and `refund_non_winners` rules already consumed by the Member UI. Updated the forward manifest (70 + 16 excluded timestamped + 3 legacy = 89 SQL files), clean-install README and static reconciliation. Added a source-contract test but did not execute it. Branch HEAD at start of batch was `ec70002007d2b52719af7709f68dcff700f9eabc`; latest source feature there also exposes Main/Duplicate ID ownership in Placement Tree. No tests/build/CI, SQL replay or database writes. Overall estimate remains 55%.


- 2026-11-18 — Placement Tree SECURITY DEFINER root-ownership guard added as forward candidate #71 (`20261119010000_enforce_member_placement_tree_root_ownership.sql`). The authenticated profile's Main-ID pointer must now resolve to a Main ID with matching `owner_user_id`; Main/Duplicate recursive traversal and existing grants are preserved. Updated source-contract test (not run), forward manifest, clean-install README, static reconciliation and completion register. Inventory: 87 timestamped (72 forward + 16 excluded) + 3 legacy = 90 SQL files. Start-of-batch branch HEAD: `aeb0672aa48486f477d5e0ca21e78a79fc4e0f7d`; migration commit: `094185fa968b4327612e20752ef631e53914af08`. No tests/build/CI, SQL replay or database writes. Overall estimate remains 55%.


- 2026-11-18 — Admin notification history recipient projection added as forward candidate #72 (`20261119020000_admin_notification_history_recipient_labels.sql`). Admin notification history now uses an Admin-claim-protected, bounded, category-filtered RPC returning recipient Main ID/name; Member inbox and owner-only read-state behavior are unchanged. Updated Notifications UI, source-contract test coverage (not executed), forward manifest, clean-install README, notification reconciliation and completion register. Inventory: 88 timestamped (72 forward + 16 excluded) + 3 legacy = 91 SQL files. Source commit `f6846e12919ec0d940840a34af3505ed1e937563`; tests/build/CI/replay/database writes not performed. Overall estimate remains 55%.


- 2026-11-18 — Admin package-receipt viewer refresh correction: the Admin pending-activation queue previously replaced the View button with a signed URL link after generating a five-minute Storage URL. Once that URL expired, the UI retained only the dead link and offered no way to refresh it without reloading the queue. Updated `src/components/Admin.tsx` to retain the URL expiry timestamp, hide expired links, and always offer a View/Refresh action that requests a new five-minute signed URL. Extended `tests/admin-pending-activation-receipt-path.test.ts` with source assertions; test not run. Commits: `d938fc397a19cac7737079236ed3f69d41d33380` (UI), `ea38258d36a239249a81afb533ddc14ab0e9722c` (test). Forward migration inventory unchanged at 72 forward + 16 excluded + 3 legacy = 91 SQL files. No tests/build/CI, SQL replay or database writes; Production remains read-only and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Support-ticket audit event deduplication (#73): the original `support_tickets` AFTER UPDATE trigger and the later Admin update RPC both inserted an audit row for one Admin action. Added `20261119030000_deduplicate_support_ticket_audit_events.sql` to keep the row trigger as the single writer, retain actor/ticket/member/old-status/new-status/response-change context, and remove the second RPC insert while preserving Admin authorization, validation, row locking, return shape and explicit grants. Added `tests/support-ticket-audit-deduplication.test.ts` (not run). Forward inventory: 73 forward + 16 excluded + 3 legacy = 92 SQL files. No tests/build/QA/CI, SQL replay or database writes; Production remains read-only and TEST untouched. Completion estimate remains 55% (Provisional).


## Latest development checkpoint — 2026-11-18

- Admin Auction Bid report page loading and complete CSV export now use a dedicated cursor RPC with stable descending `(created_at,id)` pagination.
- Admin Fixed Bid Entry report page loading and complete CSV export now use the equivalent cursor RPC.
- Existing offset RPCs were preserved for compatibility; new cursor RPCs are Admin-role checked, bounded to 101 rows, use an empty search_path and omit internal idempotency keys.
- Added source-contract tests: `tests/admin-auction-bid-report-keyset-pagination.test.ts` and `tests/admin-fixed-bid-entry-report-keyset-pagination.test.ts`. Not executed.
- Added forward migration candidates #74 and #75: `20261119040000_admin_auction_bid_report_keyset_pagination.sql` and `20261119050000_admin_fixed_bid_entry_report_keyset_pagination.sql`. Manifest now contains 75 forward + 16 excluded timestamped + 3 legacy SQL files = 94 SQL files (91 timestamped).
- No tests, builds, CI, QA, database replay, Production/TEST writes or deployment were performed. Production remains read-only; TEST remains untouched.
- Overall planning estimate remains 55% (Provisional); this source-only batch does not justify changing the overall estimate.


## Latest development checkpoint — 2026-11-19 Main Wallet funding

- Added member-facing Add Money to Wallet Balances with KRFSI UPI QR (krindia@bpunity), amount entry, UTR, payment screenshot/receipt upload and pending/approved/rejected request history.
- Added Admin pending funding review queue with private signed receipt links, review note, approve/reject actions. Approval credits the Main Wallet through a locked server-side transaction and immutable wallet ledger entry; duplicate UTRs and repeat reviews are rejected.
- Renamed member-facing Income Wallet labels to Main Wallet while preserving internal wallet_type='income' and existing settlement contracts. Bid Wallet unchanged.
- Added 20261119060000_member_wallet_funding_requests.sql as forward migration #76 and added private Storage policies, member submit/history RPCs, Admin list/review RPCs, audit events and idempotent ledger credit.
- The existing authorization model currently defines Admin, not a distinct Admin Staff role; no new staff role was fabricated. Admin-only approval remains enforced.
- QR payload was regenerated from the supplied UPI payment data: upi://pay?pa=krindia@bpunity&pn=KRFSI&cu=INR. No payment was made or verified.
- No tests/build/CI/QA, SQL replay, database writes, Production access or deployment. Production remains read-only; TEST untouched. Overall estimate remains 55% (Provisional).


- Inventory update after Main Wallet funding migration #76: 76 forward + 16 excluded timestamped + 3 legacy SQL files = 95 SQL files (92 timestamped). This is source inventory only; no replay was performed.


## Latest development checkpoint — shared UTR protection (#77)

- Added a database trigger-level cross-workflow payment reference guard for package activation and Main Wallet top-ups. Both insert paths use one normalized-reference advisory transaction lock and reject cross-use, preventing concurrent submissions from reusing the same UTR between these two workflows.
- Added source-contract test file `tests/cross-workflow-payment-reference-uniqueness.test.ts` (not run).
- Forward migration candidate #77 added. Inventory: 77 forward + 16 excluded timestamped + 3 legacy SQL files = 96 SQL files (93 timestamped).
- Source-only development; no tests/build/CI/QA, SQL replay, database writes, Production access or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 55% (Provisional).


## Latest development checkpoint — Registration Email Verification (#78)

- Added Admin Email Verification ON/OFF under Member Registration. Default is ON. The switch is stored in app_settings, returned through Admin settings RPC and audit logged.
- Registration reads the policy through a narrow public boolean RPC. ON keeps the confirmation redirect and confirmation messaging. OFF omits the redirect and expects Supabase Auth Confirm Email to be disabled; if provider-level confirmation remains ON, the UI clearly reports the mismatch. Browser code cannot change Supabase project-wide Auth configuration.
- Added migration 20261119080000_registration_email_verification_setting.sql as forward candidate #78 and test source tests/registration-email-verification-setting.test.ts (not executed). Inventory: 78 forward + 16 excluded timestamped + 3 legacy SQL files = 97 SQL files (94 timestamped).
- Removed the hardcoded client-side Admin approval lock so UI actions now defer to database safeguards. Server-side financial interlocks remain unchanged; Production remains protected. Isolated Test unlock/configuration remains part of final Test setup after canonical baseline review.
- No tests/build/CI/QA, database replay/writes, Production access or deployment. Overall planning estimate remains 55% Provisional.


- Follow-up in the same consolidated member-payment batch: Package Activation now displays the KRFSI UPI payee/UPI ID and payment QR beside the package selection and UTR/receipt submission form. The member can pay the selected package amount and submit the existing receipt-backed request for Admin verification. Source-only; no tests or deployment.


## Latest development checkpoint — Restricted Payment Review Staff (#79)

- Added a dedicated `admin_staff` role for an existing registered account. Only the designated Primary Admin (`Kkjan2006@gmail.com`) can grant/revoke it; grants contain exactly `package_activation_review` and `wallet_funding_review` permissions, with audit logging.
- Added isolated Staff portal with only two queues: Package Activation payment review and Main Wallet Add Money review. Staff cannot access the full Admin dashboard, member management, wallet adjustments, reports, settings, or role management.
- Updated package and Main Wallet queue/review RPCs and private receipt Storage read policies to require the corresponding explicit staff permission. Approvals remain server-side, atomic, and ledger/audit recorded; the reviewer is recorded.
- Added migration #79 `20261119100000_restricted_payment_review_staff.sql` and source-contract test `tests/restricted-payment-review-staff.test.ts` (not executed). Inventory: 79 forward + 16 excluded + 3 legacy SQL files = 98 total (95 timestamped).
- No tests/build/CI/QA, SQL replay, DB writes, Production access or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 55% Provisional.


## Latest development checkpoint — Notification inbox pagination (#80)

- Updated both Member and Admin notification inboxes to bounded keyset pagination using descending `(created_at,id)` cursors; 100 visible rows plus one look-ahead row. Member queries remain user-scoped and retain unread/category filters. Admin history uses a new Admin-only cursor RPC.
- Existing Admin offset RPC is preserved for compatibility. Added migration #80 and source-contract test (not executed). Inventory: 80 forward + 16 excluded + 3 legacy SQL files = 99 total (96 timestamped).
- No tests/build/CI/QA, migration replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 55% Provisional.


## Latest development checkpoint — Member auction submissions (#81–#82)

- Added Place an Auction member form and submission history; active Main ID and active profile are enforced server-side. Submission supports 1–8 images, title, description, optional category, starting price, bid increment, start/end times and optional additional details.
- Submissions remain private and pending until Admin or restricted Staff with `auction_submission_review` edits and approves/rejects. Approval creates the published product and scheduled/live auction transactionally; member and reviewer actions are audited.
- Added migrations #81–#82, member form, editable review queue, and source-contract test (not run). Inventory: 82 forward + 16 excluded + 3 legacy SQL files = 101 total (98 timestamped).
- Private image storage is in place, but public delivery of approved images needs a dedicated publishing/media delivery step before live rollout. No tests/build/QA, SQL replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 56% Provisional.


## Latest development checkpoint — Approved auction image delivery (#83)

- Pending member-auction images remain private. During approval, Admin/authorized Staff copy images into public `product-media`; the approval RPC publishes the product/auction with those paths. Catalogue cards and auction detail views resolve media paths to public URLs.
- Added migration #83 and source-contract test (not run). Inventory: 83 forward + 16 excluded + 3 legacy SQL files = 102 total (99 timestamped).
- Image copy and database approval are separate operations; an unsuccessful approval after a successful upload may leave an unreferenced public object for cleanup. No tests/build/QA, SQL replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 57% Provisional.


## Latest development checkpoint — Expected-price auction lifecycle (#84)

- Member auction submission now collects Starting Price and Expected Price (Expected Price must be >= Starting Price); End Time is no longer compulsory or shown. Bidding stays open until current bid reaches/exceeds Expected Price; then DB sets a 48-hour deadline.
- Bid RPC accepts null `ends_at` while target is pending and rejects bids after deadline. `pg_cron` job starts scheduled auctions and marks expired auctions ended. Public catalogue exposes expected price, target-reached timestamp, start time, and nullable end time; UI displays live countdown or Waiting for expected price.
- Admin/authorized Staff review can edit Expected Price. Added migration #84 and source-contract test (not run). Inventory: 84 forward + 16 excluded + 3 legacy SQL files = 103 total (100 timestamped).
- No tests/build/QA, migration replay, DB writes or deployment. Cron is source-defined only and not verified/applied. Overall estimate: 58% Provisional.


## Latest development checkpoint — Individual restricted Staff permissions (#85)

- Primary Admin can independently grant/revoke each existing restricted Staff member's Package Activation Payment Review, Main Wallet Add Money Review, and Member Auction Listing Review permission. At least one permission is required; use Revoke Staff Access to remove the restricted Staff role entirely.
- Added Primary-Admin-only RPC `admin_update_payment_review_staff_permissions`, allowlisted permission validation, audit logging, per-user checkbox UI and source-contract test (not run). Existing role-grant response now accurately lists all three permissions.
- Migration #85: `20261119160000_individual_payment_staff_permissions.sql`. Registered in forward manifest. All work is on `completion-work`; no test/build/QA, SQL replay, database writes or deployment. Production remains read-only; Test Supabase untouched.
- Overall development estimate: **59% Provisional**; this is a planning estimate, not verified live completion.


## 2026-11-19 — Verified branch-head reconciliation

- Latest `completion-work` HEAD inspected: `42e8855a8af1e36d7d247a4e26a85970b41f4b43` (supersedes the earlier `1577a433` recovery reference and the older #85 documentation checkpoint). Protected `main` was not changed in this batch.
- Source review confirms Main Wallet Add Money QR/UTR/private receipt workflow, Admin/Staff approval with Main Wallet ledger credit, cross-workflow UTR uniqueness, Registration Email Verification setting, restricted Staff review, individual Staff permissions, notification keyset pagination, member auction moderation, approved auction image delivery, and Expected Price/48-hour auction lifecycle are already represented in source.
- Rechecked the clean-install forward manifest: the ten relevant wallet-funding, email-verification, Staff and auction lifecycle migrations were already listed. Inventory remains 85 forward + 16 excluded timestamped + 3 legacy SQL files = 104 total (101 timestamped). This is a file inventory, not proof of replayability.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes, or deployment. Production remains read-only; TEST Supabase remains untouched.
- Remaining major work: complete baseline/function and all-forward-migration semantic dependency review; reconcile remaining frontend/RPC/RLS/Storage contracts; finish remaining Fixed Bid, referral, withdrawal, reporting and notification integrations; complete security/operational review. Consolidated testing is still deferred until the owner authorizes it.
- Overall development estimate remains **59% Provisional**. This is a planning estimate, not a verified live/deployment completion percentage.


## Latest source-development batch — Member auction upload lifecycle

- Fixed a partial-upload leak in the member auction submission UI. If image upload/validation fails before the submission RPC, already uploaded private objects are removed. If the RPC returns a definite Postgres error code, uploaded objects are also removed.
- Ambiguous RPC/network failures deliberately retain uploaded objects: the database may have committed even if the client did not receive the response, so deleting those paths could break a successfully created submission.
- File selection now preserves the actual selected count so the existing 1–8 image limit is enforced and visible instead of silently truncating selections above eight.
- Added source-contract coverage in `tests/member-auction-upload-cleanup.test.ts`. Test source written only; not executed. No build, QA, browser/device checks, SQL replay, Supabase writes or deployment.
- Source commits: `4640e3ce46d471cd8f2a677c5400ae75f1a35700` (implementation), `7014af25690d906d4e3717f3bc0c4762861dbb2d` (test source).
- Development estimate remains **59% Provisional** pending broader RPC/RLS, baseline and integration work.


## Latest source-development batch — Wallet funding receipt cleanup

- Added safe cleanup for Main Wallet Add Money receipts when the submission RPC returns a definite database error. This prevents rejected requests from leaving unnecessary private receipt objects in Storage.
- Ambiguous RPC/network failures retain the uploaded receipt because the request may have committed despite a lost response; the UI does not risk deleting a receipt referenced by a successfully created request.
- Added `tests/member-wallet-funding-upload-cleanup.test.ts` source-contract coverage (not executed).
- Source commits: `c010a7b1e72f06670191c0b74c789c7f015909a8` (implementation), `1e64fa623a40842ffb796df8dba0c52877030dd1` (test source).
- No tests/build/QA, browser/device checks, SQL replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## Latest source-development batch — Wallet funding integration in member portal

- The Add Money workflow component was present but was not mounted in the authenticated member Wallet tab. Added a lazy-loaded `WalletFunding` route section above wallet history, making the QR/UTR/receipt submission and request history reachable from the actual member navigation.
- Added `tests/member-wallet-funding-navigation.test.ts` source-contract coverage (not executed).
- Source commits: `bf4242f2a8b2435e8ad1d532bbf65b75eb786357` (Wallet navigation integration), `158faafdbe48b4585e2f49e90a44cc036edca052` (test source).
- Together with the prior auction and wallet-funding receipt cleanup commits, this batch improves orphaned private upload handling without risking cleanup after ambiguous RPC outcomes.
- No tests/build/QA, browser/device checks, SQL replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## Latest source-development batch — Wallet funding session isolation

- Main Wallet Add Money request history now follows the active Supabase auth session. It clears the previous member's request rows on sign-out/account switch, invalidates stale in-flight responses, reloads for the new session and displays loading/retrieval errors instead of silently presenting an empty history.
- Added `tests/member-wallet-funding-session-scope.test.ts` source-contract coverage (not executed).
- Implementation commit: `b9c294035bd71bb9e192240bc370fe9d530980da`; test-source commit: `491e0960fbc3472264d875b212ecef77e64988e9`.
- No tests/build/QA, browser/device checks, SQL replay, Supabase writes or deployment. Development planning estimate: **60% Provisional**; remaining cross-module contracts, clean-install semantic review and other source integrations are substantial.


## Latest source-development batch — OLX-style Auction Classified Upload

- Expanded the member Auction submission form with structured classified fields: category, brand, model/variant, condition, age/year, warranty, ownership, area/locality, city, state and six-digit PIN code, alongside title, description, 1–8 images, Starting Price, Expected Price, bid increment and start date/time.
- Classified attributes are passed through the existing optional_details payload; Admin/authorized Staff review now displays and can edit those attributes before approval. Existing pending-review and publish controls remain in force.
- The Admin workspace already contains direct Auction product/auction draft creation and a separate Fixed Bid draft/campaign workflow; the member-facing Auction submission remains distinct. Fixed Bid creation remains in the Admin workspace only.
- Added tests/olx-style-auction-classified-fields.test.ts as source-contract coverage; not executed. No tests/build/QA/browser checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST untouched.
- Implementation commits: 0006ea751a11d343aad2e65df2e1e2e71cb6abdb (member classified form), cc2c3c3361468a45fb85ced579d6eb1473ce3f61 (Admin review fields); test source commit: 1ae04c0d3a665e9b24b6623823baec908175f07f.
- Overall development estimate remains **60% Provisional**; this feature batch does not imply the broader project is complete.


## Latest source-development batch — Auction classified form validation hardening

- Member auction submission now validates positive Starting Price, Expected Price greater than or equal to Starting Price, positive bid increment and a valid start date before uploading images, reducing avoidable orphan uploads.
- Successful submission clears every classified field (brand, model, condition, age, warranty, ownership, locality, city, state, PIN), pricing/schedule fields and extra specifications so the next listing starts cleanly.
- Corrected the classified form's category-to-fields markup separator. Added source-contract assertions for price validation and complete form reset; test file not executed.
- Commits: `2b703301857bcf9d5fc561b67dde883ccb574a7c` (implementation), `71c980e26f54e51d2a5a1ed324c4302e783f25cc` (test source). No tests/build/QA/browser checks, SQL replay, Supabase writes or deployment.
- Admin direct Auction draft parity is now implemented in source; remaining project development is tracked in the completion register. Development estimate remains **60% Provisional**.


- 2026-11-19 — Admin direct Auction draft workflow aligned with Expected Price lifecycle: Expected Price is mandatory and cannot be below Starting Price; fixed Planned End input removed; `ends_at` remains null until target price is reached and the existing 48-hour trigger derives the deadline. Added forward-only RPC migration and source-contract test. Not applied; no tests/build/QA run; production and TEST Supabase untouched.


## 2026-11-19 — Admin Auction Expected Price lifecycle parity (bulk batch)

- Completed the Admin direct Auction draft workflow parity: Expected Price is mandatory, must be at least Starting Price, is sent to the secured RPC, and appears in the Admin auction list. The fixed Planned End field and obsolete client state were removed; the database derives `ends_at` only after the Expected Price is reached, then starts the 48-hour countdown.
- Added a forward-only migration replacing the Admin save/list RPC contracts and extending the lifecycle trigger to start the 48-hour timer when an immediate or scheduled Admin auction becomes live already at its target price.
- Updated shared Admin draft validation and its existing validation tests; corrected and extended the Admin lifecycle source-contract test. Test sources only; none executed.
- Commits: `ff8bcc7b45fdb60890ccb116b85e681e0984d0ee` (Admin UI), `6744e49d7c55d3899fbd82738c8297bb580c3071` (migration), `a1ac4d638e91e2d54794ae57c860296b22993c42` (shared validation), `d42e34cffc1d5a0788c32e3796078c1bf4cb6a5c` (validation tests), `cc0d99460340eb561259c41234535468c1166912` (lifecycle test), `26aaa50be1600878345c05dcb2bb54906c0c21b2` (immediate-start lifecycle fix). Documentation updates follow.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Development estimate remains **60% Provisional**.


## 2026-11-19 — Admin open-ended Auction publishing compatibility

- Found and corrected a backend contract gap exposed by the new Expected Price schedule: the existing Admin status RPC still required a fixed `ends_at`, which prevented Admin-created open-ended auctions from being scheduled or opened. Added a forward-only replacement retaining the original Admin authorization, bidding feature gate, cancellation refund ledger reconciliation/idempotency, closed-auction restrictions and audit logging.
- The status RPC now accepts `ends_at = NULL` for Expected Price auctions; scheduled auctions still require a future start time, while immediate auctions may omit Planned Start and open now. Existing time-window checks remain for supplied start/end values.
- Added source-contract coverage. Tests not executed; migration not applied. No build/QA/browser/device checks, Supabase writes or deployment. Production remains read-only and TEST remains untouched.
- Commits: `4c4ee4421509927bac9fbf903ca089deaefde742` (forward migration), `bae13b91738234446744759a0b0b3576210ffea3` (test source), `575959255a2d01d9f41f133e3239edff6476ee03` and `3b51f703fdd08dcfb9f16fdf032edad32d403e96` (migration refinements), `410b52965b8ce295d116de7b19cc03c7ff590fd6` (test refinement).
- Overall development estimate remains **60% Provisional**; broader modules and source/database contract reconciliation remain.


## 2026-11-19 — Fixed Bid product image delivery

- Corrected the member Fixed Bid campaign cards to resolve product-media Storage object paths through Supabase's public URL helper instead of assigning raw storage paths to `<img src>`. Existing absolute HTTP(S) URLs remain supported; missing image paths use the visual fallback. Images are lazy-loaded.
- Added a source-contract test; not executed. No build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched.
- Commits: `758aef3c942ffe45091ab010c0ddaa1523a2f441` (media URL resolution), `2c3c44be230d63e1c8fb904c69cab70ad76644e5` (JSX fallback correction), test commit recorded separately.


## Latest Frontend Batch — Homepage discovery and accessibility

- Added visible Category and Sort controls to the homepage Auctions row, activating the existing category/sort state (All categories, ending soon, newest, low-to-high and high-to-low). The matching-auction count updates with the filters; the existing horizontal card row and separate Fixed Bids row are preserved.
- Added explicit accessible labels for marketplace search and expanded/collapsed state plus control association for the mobile navigation menu.
- Added keyboard-visible focus styling and reduced-motion support without changing marketplace or account workflows.
- Added `tests/homepage-auction-discovery-controls.test.ts` as source-contract coverage. It was not executed.
- Source commits: `6e3ee90f2289bdf523b9fef4b3f1e27d544cb45b` (auction filters), `03af6f2bf428a900734d5bf14fa3c4a11f3d86ae` (CSS accessibility), `0e4d5cbccde0d0fc68c29f89031567ffda924d5e` (test source), `198c9af0e8a398277b30ee08adb658077635b6ce` (search/navigation accessibility), `2d89fe5aa7771e0bfef783c0e7de6309bff47cce` (test update).
- No tests, type-check, build, browser/device QA, database replay, Supabase writes or deployment were performed. Production remains read-only and TEST remains untouched.
- Overall development estimate remains **60% Provisional**; this UI batch does not establish full frontend, database integration or release completion.


## Latest Frontend Batch — Marketplace sample preview cards

- Added three clearly labelled, display-only Fixed Bid sample cards (smartphone, home appliances, smartwatch) with example entry amount, winner payment, winner count, entry limits and schedule fields.
- Homepage Auctions now reliably shows the existing sample auction cards whenever the live auction list is empty or only local demo fixtures are present. Sample cards are visibly marked and cannot trigger real bidding or Fixed Bid entry actions.
- Real published listings take precedence and replace the sample cards automatically. Sample data exists only in frontend source; no database records, wallet credits, payments or user accounts were created.
- Added `tests/marketplace-sample-preview-cards.test.ts` as source-contract coverage; not executed.
- Commits: `5acf28e728e948721794ce5839a3dd4759f19f76` (Fixed Bid fixtures), `e466b3fbf4834466b3f240797bbf10e182797cc9` (Auction fixtures), `ca6e5cc9a2a6b0f773a11054239bc840a652d991` (sample card styling), `0289b0797fc445eda3301eb5025522daadb2086a` (demo-fixture labelling), `e231a8ec21dca8660b25f7c096290144db426e20` (test source).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Frontend Batch — Product catalogue sample preview

- Added three display-only product catalogue examples (Bluetooth headphones, fitness watch, home/kitchen essentials) so the Products page has visible cards before real catalogue records are published.
- Product cards use the existing responsive marketplace card design and carry a clear SAMPLE PREVIEW label. Published product rows replace local samples automatically.
- Search filters local sample cards while the preview fallback is shown. No product records, purchases or transactions are written to Supabase.
- Added `tests/product-catalogue-sample-preview.test.ts` as source-contract coverage; not executed.
- Commits: `011516e55ea49d33760fd0699c0c53f68100b6a5` (product preview data and rendering), `1e9a868d4bead476608667287f5adac14e757da3` (product card styling), `2becdfedfc712d9f40f53100761bb4aa79bbcf84` (test source).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Admin Frontend Batch — Product draft editing controls

- Admin product form now clearly switches between new-product and edit-product modes, with matching Save/Update button text.
- Added Cancel Edit to clear the unsaved form state and return to new-product mode; if an unattached temporary image exists, its existing cleanup flow is invoked.
- Product draft save is disabled while an image upload is in progress, preventing a premature save before the selected image upload finishes.
- Added `tests/admin-product-draft-edit-controls.test.ts` source-contract coverage; not executed.
- Commits: `c08491dff55286de474175b3830b08c71b5aa5bb` (Admin form controls), `450e46c6308c9ed1debdc4aa8bbd047ae3783b3a` (test source).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Admin Product UX batch — image preview

- Added a live preview beneath the Admin product draft image field. It reflects the manually entered URL or newly uploaded image, uses descriptive alt text and lazy loading, and hides a broken image link while leaving the URL available for correction.
- Added `tests/admin-product-draft-image-preview.test.ts` as source-contract coverage; not executed.
- Implementation commit: 14f51ad3c72eb3d2663601039efe07b71adff285; test-source commit: 68242c7ec242ed5cf4effb6ea8a473875a7150cd.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Admin product catalogue batch — saved-product thumbnails

- Admin Saved Products now shows a compact thumbnail for each product when an image is available. Absolute HTTP(S) image URLs remain unchanged; Storage object paths resolve through the existing `product-media` bucket. Thumbnails are lazy-loaded, have product-specific alternative text, and hide broken images without affecting product data.
- Added `tests/admin-saved-product-thumbnails.test.ts` source-contract coverage; not executed.
- Source commit: 8828d1b616c249b0eb06d90945031bba63b3db70; test-source commit: 0572ed0d6bd6bba74fe8133d362bbce4d158d7ac. Overall completion remains **60% Provisional**.
- No test/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched.
