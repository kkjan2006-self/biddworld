# BiddWorld — AI Continuation & Repository Operating Guide

> Purpose: make every new ChatGPT conversation resume the existing project from repository evidence with minimal prompt text. This guide is the operating contract for AI-assisted work; it does not replace source code, SQL, product requirements, or the official status checkpoint.

## 1. Repository identity and protected boundaries

- Repository: https://github.com/kkjan2006-self/biddworld
- Working branch: `completion-work`
- Protected branch: `main` — never commit directly to or rewrite it.
- Brand: **BiddWorld**.
- Website UI language: English. User instructions and progress reports: Telugu.
- Intended domain: `biddworld.com`; do not purchase domain/hosting or deploy without the owner's explicit instruction.
- Work in bulk where practical. A user message of **“Next”** means continue the next evidenced pending task without asking for a confirmation step.

## 2. Source-of-truth hierarchy

When sources disagree, use this order and document the discrepancy:

1. **Current repository source at the latest verified `completion-work` HEAD** — actual implementation, SQL, tests, configuration and migrations.
2. **`PROJECT_STATUS.md`** — authoritative current recovery checkpoint: verified progress, blockers, test state and next action.
3. **This guide (`docs/AI_CONTINUATION_GUIDE.md`)** — rules for how to resume and work safely.
4. **`docs/PROJECT_COMPLETION_REGISTER.md`** — chronological evidence and historical decisions.
5. **Focused audit/reconciliation documents** linked from `PROJECT_STATUS.md` and relevant source folders.
6. **Conversation history or model memory** — convenience only; never override repository evidence.

Do not assume that an old commit SHA, percentage, migration count, CI result, branch state, or pending-task list is still current. Re-fetch the current branch HEAD and relevant files every new chat. If a referenced document is missing or stale, inspect the source and record a correction rather than guessing.

## 3. Mandatory new-chat startup

Before changing code:

1. Confirm repository access and inspect the current `completion-work` branch HEAD (not just a remembered SHA).
2. Read the complete current `PROJECT_STATUS.md`.
3. Read this guide and the relevant sections of `docs/PROJECT_COMPLETION_REGISTER.md`.
4. Follow the “Next development batch” in the status file. Open the focused audit documents and exact source files named there.
5. Inspect recent commits/diffs where needed to distinguish already completed work from pending work.
6. Check whether the task is safe to do in the current phase. If the repository evidence is contradictory or incomplete, investigate first; do not invent schema, API contracts, or business rules.
7. State a concise Telugu checkpoint only after the evidence has been checked; then proceed with the largest safe coherent batch.

Never restart the project from scratch, recreate completed modules, or rely on the last chat's summary without verifying the repository.

## 4. Development and testing phase gate — owner instruction

The owner's explicit workflow is:

### Phase A — Development to 100%

- Finish all required application source, database source, frontend/backend integrations, documentation, configuration and release-preparation development.
- Perform code/source reading, static reasoning, schema and RPC contract reconciliation, dependency analysis, migration ordering analysis, security source review, and documentation review as development activities.
- **Do not intentionally run or initiate tests before Development is confirmed 100%.** This includes unit, automated, integration, browser, E2E, regression, manual and full test suites; build/typecheck commands when they are part of a test/verification run; database migration replay; and manually triggering CI/test workflows.
- Do not edit tests merely to make a failing test green during this phase. Record known CI failures and defer their repair to the consolidated final testing/repair phase, unless the owner explicitly changes this rule.
- If GitHub Actions or another CI system runs automatically after a commit, do not initiate additional runs. Report the automatic result accurately and do not describe it as completion of final testing.
- Keep an evidence-based list of remaining requirements. Do not declare 100% because the UI or SQL files merely exist.

### Development-complete gate

Only declare Development 100% when every requirement in the project scope has been traced to implementation and source evidence, all required integrations have corresponding source contracts, all migration/baseline dependencies have been reconciled, and no known development item remains. A source-only review is not proof of runtime correctness. Record the gate decision and its evidence in `PROJECT_STATUS.md`.

### Phase B — One consolidated final testing and repair phase

Only after Phase A reaches 100%:

- Perform the complete planned testing campaign together, not as scattered partial test sessions.
- Use the isolated TEST Supabase project only, with synthetic data and explicit owner authorization for database replay or destructive test setup.
- Test database bootstrap and ordered migrations, Auth, RLS, grants, RPC authorization/contracts, wallets and ledger idempotency, referral/duplicate-ID, package activation, auctions, Fixed Bid, winner payment, withdrawals, reports/exports, notifications, Storage, PWA/offline, Android/mobile responsiveness, build and regression.
- Fix defects found and rerun the relevant tests/regression until the release gate is met.
- Never use real Production members or real financial activity as test fixtures.

### Phase C — Finalization and delivery

- Complete release checklist, final source archive/ZIP, setup/deployment instructions and verified delivery links.
- Do not buy domain/hosting, deploy, switch Production settings, or activate live financial features unless the owner explicitly instructs it.

## 5. Supabase and data-safety contract

- Production project: `hbqatszyzqobgtauyuzy` — **READ-ONLY** throughout development and testing. Never run DDL, DML, migrations, RPCs that mutate data, seed data, wallet operations, package activations, commissions, payouts, or destructive actions against Production.
- Isolated TEST project: `yoaauthwejdgaevfvwpo` — keep unchanged during Phase A. Use only for Phase B after the development gate and explicit authorization.
- Never use the retired/old `BidWorld-Database` project.
- Do not copy Production personal, member, wallet, or financial data into TEST. Use synthetic test records only.
- Never expose service-role keys, secrets, passwords, or private credentials in frontend code, commits, logs, prompts, or documentation.
- Do not claim a source migration is applied or deployed unless the exact database ledger/state has been verified.
- Do not label a schema candidate as an approved executable baseline until it has passed the required review and TEST replay.

## 6. Project scope and product rules

Use the existing detailed project requirements, SQL contracts and focused decisions in the repository. The core scope includes:

- Responsive mobile-first BiddWorld marketplace website and installable Android PWA.
- English member and Admin portals; authentication, profiles, Main IDs and linked Duplicate IDs, sponsor/referral genealogy, dashboards and history.
- Admin-managed packages, activation requests, UTR/receipt workflow and verification.
- Separate Bid Wallet and Income Wallet, transaction ledger, idempotency, atomic server-side debit/credit and wallet history.
- Auction and separate Fixed Amount Bid systems, campaign lifecycle, entries/bids, winner selection, settlement/payment and history.
- Admin-configurable referral plan, eligibility and commission lifecycle; Duplicate ID placement/attribution and Main ID ownership.
- Income-Wallet-only withdrawal and winner-payment flows, with Admin review/settings.
- Admin member, package, product, payment, wallet, referral, auction, Fixed Bid, winner, withdrawal, notification, support, reports, audit and access-control modules.
- Reports, search/filter/pagination/CSV exports, notifications, private receipt storage, product media and operational controls.
- Supabase Auth, RLS, RBAC, secure RPCs, server-side validation, audit trails and abuse controls.

Specific retained inactive package draft (do not activate by assumption):
- `BiddWorld 1:5 Growth Package`; ₹3,000 price; ₹3,500 Bid Wallet credit; referral 1:5 across up to five levels at ₹200 per eligible level.
- Only eligible active Main IDs receive commissions; Duplicate ID commissions credit to the linked Main ID's Income Wallet and are separately reportable.
- Keep package/commission activation inactive unless the owner explicitly authorizes a change.

Wallet/business rules:
- Bid Wallet is for bidding only and cannot be withdrawn.
- Income Wallet receives eligible income and is the only wallet for withdrawals and winner payments.
- For a bid charge, debit Bid Wallet first, then Income Wallet; reject atomically if the combined balance is insufficient.
- Preserve transaction ledger, idempotency, authorization and concurrency protections.
- Do not create real credits, commissions, payouts or activations for testing.

## 7. User constraints and working style

- The owner works from an Android Vivo phone (Android 10), has no computer/laptop and does not code.
- Keep the workflow free-tier/₹0 where possible; do not recommend paid upgrades or purchase hosting/domain during development.
- Prefer making repository changes directly through connected GitHub tools rather than asking the owner to manually edit source.
- Avoid many small approval questions, repeated “Next” prompts, or long explanations. Ask only when a genuinely essential decision cannot be resolved from repository evidence.
- Do not raise financial/legal review considerations in BiddWorld discussions unless the owner explicitly asks.

## 8. Development batch and commit discipline

- Prefer one large, coherent, reviewable batch over many tiny edits.
- Inspect exact existing source and call sites before editing. Preserve established contracts and avoid speculative rewrites.
- Fix only evidenced defects; do not silently change product rules.
- Add/update focused documentation when an audit or important decision is completed. Keep docs concise, dated and explicit about evidence versus assumptions.
- Update `PROJECT_STATUS.md` at the end of every batch with: verified branch HEAD, actual commits, work completed, work remaining, blockers, percentage estimate and basis, testing/CI status, database safety state, and the exact next batch.
- Add material historical decisions/evidence to `docs/PROJECT_COMPLETION_REGISTER.md` where appropriate.
- Commit only to `completion-work`. Verify the resulting commit and branch ref after writing. Never claim a commit or successful operation that the GitHub response did not confirm.
- If a write fails or the branch moved, re-fetch the current HEAD and reconcile before retrying; never force-push or overwrite unknown changes.

## 9. Progress and reporting rules

- Completion percentage is a planning estimate, not a test pass rate or deployment claim. Change it only when verified scope evidence justifies the change.
- Distinguish clearly between: source implemented, statically reviewed, CI checked, tested against TEST, deployed to Production.
- Report automatic CI failures/passes honestly, but preserve the owner's Phase A testing gate.
- End each batch with a concise Telugu summary: what changed, verified commit link, what remains, test/DB state, and the current estimate.
- At the end of each chat, provide the compact Universal Master Prompt below, updated only if repository workflow or essential instructions changed. Do not paste this entire guide into chat again.

## 10. Compact Universal Master Prompt

Paste only the following in a new chat:

> Continue my existing BiddWorld project; do not start over. Repository: https://github.com/kkjan2006-self/biddworld. Work only on `completion-work`; never modify protected `main`. First verify the latest branch HEAD and read `PROJECT_STATUS.md`, `docs/AI_CONTINUATION_GUIDE.md`, the relevant `docs/PROJECT_COMPLETION_REGISTER.md` entries and linked audit documents. Treat current repository source and these documents as the source of truth, not old chat memory. Resume from the exact next pending task; do not repeat completed work or guess missing contracts. Complete **100% Development before intentionally running any tests, builds/typechecks as verification, CI/test workflows, database replay or manual checks**. After the development-complete gate, perform the consolidated full test/repair phase once, using isolated TEST only and synthetic data. Production Supabase `hbqatszyzqobgtauyuzy` is always read-only; TEST `yoaauthwejdgaevfvwpo` stays untouched until final testing; never use old `BidWorld-Database`. Work in bulk; “Next” means continue immediately without asking. Commit only to `completion-work`, verify every commit, and update `PROJECT_STATUS.md` after each batch. No paid upgrades, domain/hosting purchase or deployment without explicit approval. Give instructions and progress in Telugu; keep website UI in English.

## 11. Related repository references

- Current checkpoint: `PROJECT_STATUS.md`
- Historical evidence: `docs/PROJECT_COMPLETION_REGISTER.md`
- Clean-install candidate and manifests: `supabase/clean-install/README.md`, `production_schema_baseline_candidate.sql`, `forward-migrations.txt`, `excluded-historical-migrations.txt`
- Production checklist: `docs/PRODUCTION_CHECKLIST.md`
- Focused audit/reconciliation docs: follow the exact links and filenames listed in the current `PROJECT_STATUS.md`; do not rely on stale counts in older documents.
