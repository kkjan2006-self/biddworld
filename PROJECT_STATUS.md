# BiddWorld — Official Project Status

> This file is the authoritative recovery checkpoint for all future BiddWorld development chats. The detailed historical evidence remains in `docs/PROJECT_COMPLETION_REGISTER.md` and the linked audit documents. Do not restart completed work or infer deployment from source presence.

## A. Project Information

- Project: BiddWorld
- Repository: https://github.com/kkjan2006-self/biddworld
- Current development branch: `completion-work` (verified present)
- Protected branch: `main` (do not modify)
- Latest verified repository commit at this checkpoint: `415364b71534c7fc31d6c0928dd8395e10cbd94f`
- Latest commit message: `Document clean-install baseline incompatibility`
- Last updated: 2026-11-18
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
- Historical CI evidence: run #898 on commit `936d05864e93b1d452a89bac9c224852510e4eb6` passed 90/90 test files, 343/343 tests, TypeScript check and Vite production build. A later run #915 exposed 7 failing files / 362 tests; source/test repairs were committed around `c87a2baa3eddf159fd8f1c8c882fb0be31db1542`. The current latest documentation commit does not itself establish a new passing CI result.

## C. IN PROGRESS

- Establish a trustworthy canonical clean-install database baseline and migration replay path.
- Reconcile every frontend RPC call and SQL signature/result contract.
- Review SQL dependency ordering, object prerequisites, grants, RLS, policies, triggers, Storage and function security.
- Resolve latest CI regression repair and verify the current branch head with a fresh successful CI run.
- Continue source-only development only where contracts are sufficiently evidenced; do not invent missing schema or business rules.

## D. PENDING — Major Development Work

1. **Canonical database baseline:** validate `supabase/clean-install/` candidate against the complete read-only Production evidence; verify ordering and prerequisites for all source-only forward migrations; replay only in isolated TEST after review; compare resulting catalogue with expected snapshot.
2. **RPC reconciliation:** reconcile all frontend RPC call sites, overload resolution, argument names, return fields, authorization and source migrations. Key audit: `docs/PRODUCTION_FRONTEND_RPC_LIVE_DIFF_2026-11-18.md`, `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md`, and `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md`.
3. **Migration compatibility:** inspect latest migration chain for duplicate/replacement signatures, ordering, idempotency and dependency issues. Do not treat the 30 historical Production ledger SQL snapshots as a ready-made clean-install sequence.
4. **Dependency security/reproducibility:** inspect package-lock status and current npm advisories; pin reproducible dependencies and remediate without blind forced major upgrades.
5. **Remaining source features/integration:** receipt upload and product-media Storage integration; complete historical report/filter/export coverage; Admin role and member lifecycle edges; notification read-state and delivery/provider boundary; verify PWA/offline behavior; complete remaining UI/RPC contract gaps.
6. **Security and operational readiness:** per-function SECURITY DEFINER semantic review, grants/RLS/Storage verification, rate limiting/abuse controls, Auth configuration review, backup/monitoring/support readiness.
7. **Documentation/release:** update production checklist, deployment/environment instructions and source ZIP only after development and consolidated testing are complete.

## E. BLOCKED / SAFETY BOUNDARIES

- The current `supabase/migrations` directory is not a validated clean-install sequence. `0001_biddworld.sql` is a legacy schema incompatible with later contracts; `001_initial_schema.sql` is empty; `0002_place_bid_rpc.sql` is legacy. Do not replay these as a shortcut.
- Production evidence: 21 public tables, all 21 with RLS; 110 constraints, 60 indexes, 20 policies, 10 application triggers, 43 public functions, and 30 historical migration ledger rows. These snapshots are evidence, not an executable baseline.
- Production RPC/frontend drift has been documented: the latest audit found 35 frontend RPC names present and 32 absent in Production; some live signatures differ from current source. Never infer that source-defined functionality is deployed.
- Production Storage currently has no configured buckets/policies according to the latest read-only audit, while source migrations define `product-media` and `package-receipts`.
- Isolated TEST project was last verified empty (zero migrations/public tables/buckets). Keep it untouched until the canonical baseline has been reviewed.
- No Production writes, migrations, data changes, wallet credits/debits, commissions, payouts or package activations are permitted in development.
- CI: run #915 had 7 failing test files / 362 tests before repair; repair was committed and needs fresh verification. Do not claim latest CI is green based on the earlier #898 pass.
- No overall completion percentage is asserted. Development and testing completion must be tracked separately.

## F. DEVELOPMENT ROADMAP (Bulk Batches)

- Batch 1 — Recover and validate clean-install baseline candidate; reconcile full Production schema evidence and historical ledger archive.
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
- CI evidence is historical and branch-specific; the current head requires a fresh successful run.
- Do not claim modules fully complete merely because UI, SQL source or static tests exist.

## H. NEXT DEVELOPMENT BATCH

Start with the existing clean-install candidate and evidence, not a new audit from zero:
1. Read `supabase/clean-install/` manifest and all candidate baseline files.
2. Compare the candidate against `docs/PRODUCTION_SCHEMA_CATALOGUE_SNAPSHOT_2026-11-18.md`, `docs/PRODUCTION_PUBLIC_SCHEMA_STRUCTURAL_SNAPSHOT_2026-11-18.md`, `docs/PRODUCTION_PRIVATE_SCHEMA_TRIGGER_RECONCILIATION_2026-11-18.md`, `docs/PRODUCTION_PUBLIC_RPC_SECURITY_INVENTORY_2026-11-18.md`, Storage reconciliation and the 30-file historical ledger archive.
3. Check every one of the 48 forward migration candidates for prerequisites, order, duplicate function signatures, DROP/CREATE compatibility, and required extension/schema assumptions.
4. Do not apply to TEST until static reconciliation is complete; never apply to Production.
5. After the baseline is trustworthy, proceed with TEST-only replay and RPC contract validation.

## I. CHANGE HISTORY

- 2026-11-18 — Created this official recovery status file on `completion-work` after verifying the branch and reading the completion register. No application source or database was changed.
- Detailed development history, evidence and prior checkpoints: `docs/PROJECT_COMPLETION_REGISTER.md`.

## Status update rule

At every development batch/chat end, update this file with the actual verified branch head, commit, completed/in-progress/pending items, testing status and next batch. Never downgrade completed source work without a documented regression/reopen reason. Never claim a GitHub commit, CI pass, migration replay or deployment without verifying it.
