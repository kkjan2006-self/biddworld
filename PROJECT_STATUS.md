# BiddWorld — Official Project Status

> This file is the authoritative recovery checkpoint for all future BiddWorld development chats. The detailed historical evidence remains in `docs/PROJECT_COMPLETION_REGISTER.md` and the linked audit documents. Do not restart completed work or infer deployment from source presence.

## A. Project Information

- Project: BiddWorld
- Repository: https://github.com/kkjan2006-self/biddworld
- Current development branch: `completion-work` (verified present)
- Latest verified source batch: Admin Notifications now supports searching Main ID/name/mobile and selecting a member instead of requiring the operator to know an Auth UUID. Added an Admin-only, bounded, SECURITY DEFINER lookup RPC with explicit EXECUTE grants; migration has not been applied.
- Protected branch: `main` (do not modify)
- Latest verified application/source work commit: `5908a39bd9412d8fa3a974cc9df1df39c19ca03c` (Admin notification recipient lookup UI + Admin-only lookup RPC migration); forward manifest inclusion: `2417bf925a08178f846ab62f70f864a9c52041b1`
- Source commit message: `feat: add secure Admin notification recipient lookup`
- Latest verified source/documentation work commit: `6f5de9f6a53580bcb006fcc4bf8303b133a2d424` (`docs: reconcile auction lifecycle and winner finalization`)
- This status file is the current branch recovery checkpoint; verify `completion-work` HEAD when resuming.
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

1. **Canonical database baseline:** static object inventory and migration partition are reconciled. Remaining: semantic review of all baseline functions/ACLs/triggers/sequences and all 62 forward migration dependencies; replay only in isolated TEST during final testing.
2. **RPC reconciliation:** selected Admin signatures plus Member/Package/Fixed Bid argument and consumed result contracts are source-reconciled; remaining work is all other Admin/member RPC call sites, direct table-select/RLS contracts, authorization, overloads and migration coverage. See both focused reconciliation docs and the existing Production/RPC audits. Key audit: `docs/PRODUCTION_FRONTEND_RPC_LIVE_DIFF_2026-11-18.md`, `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md`, and `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md`.
3. **Migration compatibility:** the current source directory has 81 SQL files (78 timestamped + 3 legacy); the 62 forward and 16 excluded manifests account for all 78 timestamped files exactly once. Continue semantic review of function replacements, object prerequisites, ACLs and platform dependencies. The legacy `0001_biddworld.sql` mismatch is not a blocker for the candidate-baseline path: static comparison shows the separate candidate has the canonical columns used by the first forward migrations. See `docs/CANONICAL_CLEAN_INSTALL_PATH_RECONCILIATION_2026-11-18.md`. Do not treat the 30 historical Production ledger SQL snapshots as a ready-made clean-install sequence.
4. **Dependency security/reproducibility:** inspect package-lock status and current npm advisories; pin reproducible dependencies and remediate without blind forced major upgrades.
5. **Remaining source features/integration:** receipt upload and product-media Storage integration; complete historical report/filter/export coverage; Admin role and member lifecycle edges; notification read-state and delivery/provider boundary; verify PWA/offline behavior; complete remaining UI/RPC contract gaps.
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

- 2026-11-18 — Clarified the clean-install starting point: do not use legacy `0001_biddworld.sql`; the separate schema-only Production baseline candidate contains the key canonical fields required by the first forward migrations. Updated the clean-install README and static reconciliation. No replay or database changes; full 62-migration dependency review remains open.

- Canonical clean-install path reconciliation: documented the distinction between the legacy `0001_biddworld.sql` schema and the separate schema-only candidate baseline. Static checks confirmed the candidate includes key canonical columns consumed by the first forward migrations. Updated `supabase/clean-install/README.md`, `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`, and added `docs/CANONICAL_CLEAN_INSTALL_PATH_RECONCILIATION_2026-11-18.md`. No database replay, tests or DB writes. Latest documentation commit: `7e91a2e7ec97b75513db599913b6a827f6550483`.

- 2026-11-18 — Reviewed the package receipt Storage chain from initial upload through private bucket/Admin-only read tightening and the Admin pending-activation receipt-path RPC. Confirmed intended final source policy: member-folder INSERT only, Admin SELECT only; product-media remains a separate public-read/Admin-write bucket. Added `docs/STORAGE_POLICY_FINAL_STATE_RECONCILIATION_2026-11-18.md`. Effective policies still need TEST replay verification; no tests/build or database changes. Commit: `5b308934613b33df9f581c8c9c451b56f9774498`.

- Status checkpoint: package-receipt Storage policy sequence and product-media policy separation are documented; current inventory corrected to 81 SQL files (78 timestamped + 3 legacy), 62 forward + 16 excluded timestamped migrations. Full replay and policy verification remain pending.

- 2026-11-18 — Fixed Bid secure random-draw migration review found two source defects in `20261118340000_secure_fixed_bid_random_draw.sql`: refund variables were referenced without declarations (PL/pgSQL compilation failure), and refund selection excluded every entry from a winning member rather than excluding only the actual winning entry IDs. Declared the refund idempotency key and existing-ledger row variables; changed the losing-entry predicate to exclude only `v_winner_entries`, so additional entries from a winner are handled as non-winning entries when configured refunds are enabled. Source commit: `81c245c1688fcff306ca7b556f1f0e268eca68e3`. Not executed or tested; no DB changes.

## H. NEXT DEVELOPMENT BATCH

Start with the existing clean-install candidate and evidence, not a new audit from zero:
1. Continue from the Fixed Bid draw correction; inspect remaining final RPC definitions and frontend call/result mappings, especially settlement/refund and winner-payment paths.
2. Continue the 62-forward-migration semantic review, especially final function bodies, trigger references, grants and Storage policy state.
3. Fix only evidenced source defects in bulk; do not infer missing business rules or change Production/TEST.
4. Keep full tests and database replay deferred to the consolidated final testing phase.

- Admin notification recipient usability: replaced manual Auth UUID entry with an Admin-only search by Main ID, member name or mobile, returning up to 25 Main ID matches and requiring an explicit selection. Added migration `20261118400000_admin_notification_recipient_lookup.sql`; no database was modified and no tests/build were run. Source commit: `5908a39bd9412d8fa3a974cc9df1df39c19ca03c`.

- 2026-11-18 — Added Admin notification recipient lookup migration to the ordered forward manifest; current inventory is 78 timestamped migrations (62 forward, 16 excluded) plus 3 legacy files. Manifest test remains deferred to consolidated final testing. Commit: `2417bf925a08178f846ab62f70f864a9c52041b1`.

- 2026-11-18 — Source-reconciled the Auction lifecycle/finalization RPC and corrected Fixed Bid draw flow. Confirmed Admin-only lifecycle gates, schedule/platform enable checks, ledger-validated atomic cancellation refunds, deterministic highest-bid winner selection, idempotent finalization, pending winner-payment creation, SHA-256 Fixed Bid ranking and one-winner-per-eligible-Main rule. Also confirmed the prior Fixed Bid refund fix now targets losing entry IDs rather than excluding all entries of a winning member. Added `docs/AUCTION_LIFECYCLE_FINALIZATION_SOURCE_RECONCILIATION_2026-11-18.md`. Frontend call-site and bid-creation RPC contract remain open. Source review only; tests/build and DB replay not run. Commit: `6f5de9f6a53580bcb006fcc4bf8303b133a2d424`.

## I. CHANGE HISTORY

- 2026-11-18 — Created this official recovery status file on `completion-work` after verifying the branch and reading the completion register. No application source or database was changed.
- 2026-11-18 — Clean-install static reconciliation: verified 81 SQL files (78 timestamped + 3 legacy), exact 62-forward / 16-excluded partition, candidate baseline object counts, function ACL/search_path counts, ordered replacement dependencies and final package-receipt Storage policy dependency. Added `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`; corrected historical inventory figures. Latest completed CI #997 failed the same stale assertion; no manual testing or database replay.
- 2026-11-18 — Compared selected Admin/Member/package/Fixed Bid frontend RPC calls with baseline and forward migration signatures. No named-argument mismatch was found in the inspected subset; confirmed wallet transaction overload first argument is required, avoiding the suspected PostgREST ambiguity. Added `docs/ADMIN_FRONTEND_RPC_SOURCE_SIGNATURE_RECONCILIATION_2026-11-18.md`. Source inspection only; no tests/build or database writes.
- 2026-11-18 — Reconciled Member Account, Package activation and Fixed Bid catalogue/entry RPC arguments and consumed result fields against their final source definitions, including final strict withdrawal payout validation. No mismatch was found in this subset; no speculative source edit was made. Added `docs/MEMBER_PACKAGE_FIXED_BID_RPC_CONTRACT_RECONCILIATION_2026-11-18.md`. Source inspection only; no tests/build or database writes.
- 2026-11-18 — Admin workspace count review found that six dashboard totals were sourced from direct table HEAD-count queries and therefore could be filtered by member-facing RLS policies. Replaced those queries with existing Admin-authorized overview/list RPC results; renamed the tile from “Registered Profiles” to “Main Member IDs”. Commit: `dd34feece77d383979a2a60b2210def738e48064`. CI #1004 failed during tests; no manual tests or database writes.
- 2026-11-18 — Reconciled Auction Bid and Fixed Bid Entry report RPC arguments/result fields, paginated catalogue exports, and member/Admin notification table access, RLS and idempotent Admin-send RPC. No mismatch found in inspected paths; recorded remaining Admin recipient UUID usability improvement. Added `docs/ADMIN_REPORT_NOTIFICATION_CONTRACT_RECONCILIATION_2026-11-18.md`. Source review only; no tests/build, migration replay or database writes. CI #1005 failed during tests; type-check/build skipped. Commit: `cfca840519a09b585e96e398036d45f210a705d6`.
- Detailed development history, evidence and prior checkpoints: `docs/PROJECT_COMPLETION_REGISTER.md`.

## Status update rule

At every development batch/chat end, update this file with the actual verified branch head, commit, completed/in-progress/pending items, testing status and next batch. Never downgrade completed source work without a documented regression/reopen reason. Never claim a GitHub commit, CI pass, migration replay or deployment without verifying it.
