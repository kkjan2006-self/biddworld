# BiddWorld — Official Project Status

> This file is the authoritative recovery checkpoint for all future BiddWorld development chats. The detailed historical evidence remains in `docs/PROJECT_COMPLETION_REGISTER.md` and the linked audit documents. Do not restart completed work or infer deployment from source presence.

## A. Project Information

- Project: BiddWorld
- Repository: https://github.com/kkjan2006-self/biddworld
- Current development branch: `completion-work` (verified present)
- Latest verified source batch: Auction bid eligibility now serializes with Admin Main-ID lifecycle changes and rechecks active Main ID/Profile status after acquiring a shared per-member advisory lock. Added migration `20261118430000_serialize_auction_bid_member_eligibility.sql`; not applied to any database.
- Protected branch: `main` (do not modify)
- Latest verified application/source work commit: `5f15127ec192bd04c0fcd0908e0bb441674daaa8` (serialize Auction Bid eligibility with Main-ID lifecycle).
- Source commit message: `fix: serialize auction bid eligibility with member lifecycle`.
- Latest verified source/documentation batch commits: `025ec6050f5846347d682025e2cd443feaabf5f7` (clean-install inventory correction), `74337c27b1646887f13340d4495147189f223e4e` (auction refund/delivery tracking review), `1d0103c623d207cfa1c2a24a19e7b78d0928b68e` (completion register).
- Previous verified `completion-work` checkpoint: `4d1b05c8e42071dc805cf39663a5bfb9033c0721`. The baseline function ACL and SECURITY DEFINER/trigger dependency source reviews are committed through `7a85cdd714146e3fc8474def3c642e0d724d6254`; verify branch HEAD on resume. Protected `main` remains exactly `415364b71534c7fc31d6c0928dd8395e10cbd94f` and was not modified.
- Latest application-source correction: `dd34feece77d383979a2a60b2210def738e48064`
- Last updated: 2026-11-18
- Overall project completion estimate: **55%** (source modules and documentation are substantially present; canonical database bootstrap, remaining integrations, consolidated testing and release work are still pending). This is a planning estimate, not a verified deployment or test percentage.
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
- Continue source-only development only where contracts are sufficiently evidenced; do not invent missing schema or business rules.

## D. PENDING — Major Development Work

1. **Canonical database baseline:** static object inventory and migration partition are reconciled. The 36 Admin function auth predicates, all 43 public SECURITY DEFINER/search_path declarations, four private function boundaries and 11 trigger dependency ordering have now been source-reviewed; see `docs/CLEAN_INSTALL_BASELINE_SECURITY_DEFINER_TRIGGER_REVIEW_2026-11-18.md`. Remaining: compare every complete baseline function body with the recovered migration archive; resolve exact service_role and identity-sequence ACL parity; continue all 65 forward migration dependency checks; replay only in isolated TEST during final testing.
2. **RPC reconciliation:** selected Admin signatures plus Member/Package/Fixed Bid argument and consumed result contracts are source-reconciled; remaining work is all other Admin/member RPC call sites, direct table-select/RLS contracts, authorization, overloads and migration coverage. See both focused reconciliation docs and the existing Production/RPC audits. Key audit: `docs/PRODUCTION_FRONTEND_RPC_LIVE_DIFF_2026-11-18.md`, `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md`, and `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md`.
3. **Migration compatibility:** the current source directory has 84 SQL files (81 timestamped + 3 legacy); the 65 forward and 16 excluded manifests account for all 81 timestamped files exactly once. Continue semantic review of function replacements, object prerequisites, ACLs and platform dependencies. The legacy `0001_biddworld.sql` mismatch is not a blocker for the candidate-baseline path: static comparison shows the separate candidate has the canonical columns used by the first forward migrations. See `docs/CANONICAL_CLEAN_INSTALL_PATH_RECONCILIATION_2026-11-18.md`. Do not treat the 30 historical Production ledger SQL snapshots as a ready-made clean-install sequence.
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
2. Baseline function ACL source reconciliation: 43/43 public functions have authenticated EXECUTE and anon EXECUTE is limited to public.lookup_sponsor(text), matching the Production inventory. Candidate also grants service_role on all 43 public functions plus private.place_bid(uuid); live service_role parity is not captured. audit_logs_id_seq USAGE for anon/authenticated is unexplained. Do not change either grant without evidence. See docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md.
3. Continue the 65-forward-migration semantic dependency review, including final function bodies, trigger references, function search_path, trigger order, extensions and sequence ownership.
4. Continue remaining frontend RPC/direct-table RLS coverage and member/Admin lifecycle edge cases. Fix only evidenced defects in source migrations; do not run tests/builds or database replay before the 100% development gate.
5. Reconcile dependency lockfile/security advisories and remaining notification provider boundary, PWA/offline source integration and operational readiness.
6. Keep Production hbqatszyzqobgtauyuzy read-only and TEST yoaauthwejdgaevfvwpo unchanged. Consolidated tests/replay remain deferred.

## I. CHANGE HISTORY

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
