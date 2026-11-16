# Remaining work before production

BiddWorld is a working development baseline with a growing admin and package-review workflow. It is **not a completed or production-ready financial marketplace**. CI and the GitHub Pages preview pass for the latest code, but that does not validate the live database or authorize financial operations.

## Implemented in the repository

- Responsive React + TypeScript + Vite marketplace interface and Supabase email/password authentication.
- Auction bidding calls a server-side RPC designed to lock the auction and wallets and debit Bid Wallet before Income Wallet.
- Package activation reference submission, client-side reference normalization, duplicate-reference handling in the database workflow, admin pending-review UI, and an admin review RPC call.
- Admin sponsor management, member directory/search, MLM overview and structure report.
- Admin audit-log RPC/UI with search, filtering and CSV export.
- Reusable CSV formula-injection protection and unit tests for CSV, audit filtering, payment-reference validation and formatting.
- GitHub Actions CI and GitHub Pages preview deployment.


## Verified production migration drift (2026-11-15)

A read-only inspection of the configured **BiddWorld-Production** project found a migration-history mismatch. Its Supabase migration history currently records only these five versions: `20261114161950`, `20261114181107`, `20261114181114`, `20261114183412`, and `20261114183454`. The repository contains no migration files for versions `20261114181107` and `20261114181114`. Repository migrations from `20261114200000` onward are not recorded in that production migration history, even though the live schema already contains a number of their newer columns and structures. Therefore, neither replaying the full repository migration directory nor simply marking files as applied is safe.

The live `get_my_mlm_dashboard()` and `admin_get_mlm_overview()` functions still compare `package_activations.payment_status` to `verified`, while the current repository's package-review workflow writes `approved`. The repository migration `20261115020000_admin_package_activation_review.sql` corrects those comparisons, but it is not recorded as applied in production. Its SQL was tested inside a transaction and rolled back; no persistent production change was made.

**Required next step:** reconstruct the missing historical migrations and compare every live object/function/policy with the repository before preparing a forward-only reconciliation migration. Do not apply baseline migrations, insert migration-history rows, or change production functions until that review is complete and explicitly approved.

## Required before production

- Apply and verify the reviewed package-activation/admin-review migration on the **production Supabase project**. It has only been rollback-tested; production schema has not been changed. Verify grants, RLS, authorization, idempotency and wallet ledger effects in a non-production environment first.
- Provision the first trusted administrator securely and configure the default sponsor/Main ID. There is no self-service admin role assignment UI.
- Complete package receipt upload/storage policies if image/PDF receipts are required; current member submission uses a payment reference/UTR.
- Define and implement the referral commission engine: versioned plan snapshots, exact eligibility semantics, trigger timing, approval and atomic posting. Do not post commissions until the owner-defined rules and schema semantics are confirmed.
- Define duplicate-ID generation, admin enable switch, tree traversal/slot rules, concurrency-safe placement and Main-ID wallet attribution. These remain disabled; do not infer placement rules.
- Define fixed-bid entry, tie, winner and settlement rules.
- Define auction close, winner/tie/extension/cancellation rules and settlement.
- Implement winning-item payment from Income Wallet, delivery tracking and notifications.
- Define withdrawals: enable switch, min/max, review, payout integration, rejection and refund workflow. No payout integration is present.
- Complete admin reporting/export coverage, notifications and support tools.
- Add rate limits, abuse prevention, monitoring, backups, privacy/terms/legal review and independent security review.
- Expand integration and browser E2E coverage; verify security/performance advisors and real transaction scenarios.

## Explicitly not implemented or not enabled

- No payment gateway or actual money transfer.
- No withdrawal payout.
- No automatic referral commission posting.
- No duplicate-ID generation or placement.
- No fixed-bid winner algorithm or settlement.
- No auction winner settlement.
- No admin role assignment UI.

Do not enable bidding or other financial features in production until the database migrations, policies, RPC authorization and transaction behavior have been independently reviewed and tested. Never expose Supabase service-role/secret keys in the browser.


### Signup migration regression caught before deployment

The pending `20261114200000_save_registration_phone.sql` originally replaced the Auth signup trigger without carrying forward the sponsor-referral validation/default-sponsor linking logic already present in Production (from the historical sponsor migrations `20261114181107` and `20261114181114`). Applying that version would have silently stopped validating/linking the submitted sponsor referral ID and default sponsor. The repository migration has now been corrected to preserve the live sponsor-validation behavior while saving the registration phone. The corrected SQL was executed inside a transaction and rolled back successfully; Production remains unchanged. This is a code correction, not a production deployment.


## Updated read-only Production snapshot (2026-11-15)

The earlier five-migration snapshot above is superseded by a newer read-only catalog inspection. Production currently reports 30 migration-history entries, including Admin draft/read-only modules and feature-gate migrations. Several of those applied migration names do not have matching source files in the current `completion-work` migration directory; reconstruct and compare them before any future migration-history reconciliation. Do not replay the repository directory or insert history rows.

The live schema confirms `products(name,image_path,category,status)`, not the legacy baseline `products(title,image_url,is_active)`. Public marketplace and Admin product source has been aligned to that live shape, and the pending product migrations were corrected in GitHub only. Production was not changed.

The live `admin_save_referral_plan_draft(uuid,jsonb)` function still requires exactly five level rules, while the Admin editor can add more. A source-only forward migration has been added to remove the five-level backend restriction; it is not applied. The live `admin_create_duplicate_member_id` currently accepts only `p_main_member_code`, while the branch's Under-ID UI calls the two-argument version defined by the pending placement-attribution migration. This mismatch also remains blocked on reviewed migration reconciliation.

Live feature settings read during this audit show bidding, Fixed Bid, duplicate IDs, referral commissions, withdrawals, winner payments and notifications disabled. Do not change these settings during development. The live `financial_model_approved` key was not present in the inspected settings snapshot; the source-only financial approval guard has not been applied. Treat this as a production-readiness blocker and do not enable financial features.


## Financial approval safeguard gap — live Production (2026-11-15)

A read-only check found `package_activations_enabled=true`, `bid_wallet_enabled=true`, and `income_wallet_enabled=true`, while the new `financial_model_approved` guard key was absent. The source-only approval guard migration has not been applied. The Admin frontend now disables package approval/credit and permits only rejection while the owner approval gate is unresolved. This is not a substitute for database enforcement: the Admin review RPC remains directly callable by a trusted Admin until the guard is reconciled and installed. No Production setting or data was changed.


## Member support workflow (2026-11-16)

- Added a member support ticket form and private request history, plus an Admin support queue with status updates and responses.
- Added additive migration `20261116040000_member_support_tickets.sql` with owner-only member reads, trusted `app_metadata.role=admin` access, constrained member inserts, Admin-only updates, timestamps and Admin update audit events.
- The UI is linked from the signed-in navigation. No email/SMS provider, push delivery, attachments, SLA automation or support notifications are included yet.
- Migration is source-only and has NOT been applied to Production. No Production data/schema/settings were changed. The new module has not yet been built or tested.


### Support module verification follow-up

- Support audit logging now targets the existing `audit_logs.metadata` column.
- Added `tests/support-migration.test.ts` to verify the migration security contract.
- CI now includes pushes to `completion-work`; GitHub currently reports no workflow run for the latest branch commit. Build, TypeScript, unit tests and live RLS behavior remain unverified.


### In-app Notifications remaining verification

- Member inbox and targeted Admin notification authoring are implemented in source.
- Database migration `20261116050000_member_notifications.sql` is source-only and not applied to Production.
- Email/SMS/push dispatch, delivery retries, scheduled notices and browser push permissions remain out of scope until a free approved provider and consent design are selected.
- Run CI/build/tests and validate RLS in a disposable Supabase project before production reconciliation.


## CI verification update — 2026-11-16

GitHub Actions run `43751441554` for `completion-work` commit `c9b77e971cffb7ab43f947f822b472e4a1a27c02` passed dependency installation, the configured unit-test suite, TypeScript type-check and Vite production build. This is source/CI verification only. Pending migrations, Production RPC/RLS compatibility, Storage policies, real database transactions, browser E2E, security review and financial workflows remain unverified. No Production migrations or data changes were made.


## Admin product/media security contract — 2026-11-16

- Added static migration-contract coverage for the `product-media` bucket MIME/size limits, public-read versus trusted-Admin write policies, privileged RPC claim checks, draft-only product creation/editing and anonymous EXECUTE revocation.
- This test coverage does not prove Storage behavior or live Production compatibility. The migration remains source-only; Storage bucket/policy state and the `audit_logs` column contract still require reconciliation before rollout.
- Admin product media now has a file picker and direct Storage upload for JPG/PNG/WebP up to 5 MB, with upload errors surfaced and the public URL attached to the product draft. Object cleanup for replaced/abandoned uploads and live Storage-policy validation remain outstanding.


## Support ticket notification integration — 2026-11-16

- Added a database trigger that creates an in-app notification for the ticket owner when a trusted Admin changes ticket status or response. The trigger uses a fixed search path, checks the trusted Admin JWT claim, bounds message length and revokes direct EXECUTE from client roles.
- Added static SQL contract tests for Admin authorization, owner-only recipient, change detection, message bound and function ACL.
- GitHub Actions run `43752553469` on commit `af4ae55f71e62905644fba19f70c5f4ee6a7c911` passed unit tests, TypeScript type-check and Vite build. This is repository CI only; no live database behavior was exercised.
- Support and notification migrations remain source-only and are not applied to Production. Email/SMS/push delivery, retries and delivery logs remain unimplemented.


## Delivery tracking source reconciliation — 2026-11-16

- The Admin and member interfaces call `admin_save_delivery_tracking` and `admin_list_delivery_tracking`, and delivery rows are displayed in the member account. However, the current `completion-work` migration directory contains no source migration defining these RPCs. Their live Production implementation and grants cannot be reconstructed safely from frontend call sites alone.
- Added `delivery_tracking_enabled` to the Admin feature switches that remain unavailable while their backend source contract is pending. This prevents the UI from presenting delivery tracking as fully enabled before the RPC definitions, table constraints, ownership rules and audit behavior are version-controlled and reviewed.
- No delivery data, Production settings, schema or financial state was changed. The feature can be unblocked only after the existing Production contract is inspected read-only and a forward-only source migration is reconciled.


## Delivery tracking backend source recovery — 2026-11-16

- Recovered the existing Production delivery schema, owner-scoped RLS policy and Admin list/save RPC contracts through read-only catalog inspection.
- Added a forward source migration with Admin authorization, paid-payment validation, concurrency protection and audit logging. Delivery writes remain behind the existing server-side feature switch, which was not enabled.
- Corrected support audit logging to use the live audit_logs.details column and removed a duplicate migration timestamp by renaming the support migration.
- No Production changes were made; CI static contract tests are not live database integration tests.

## Admin member directory server-side search and pagination — outstanding

- Read-only Production inspection confirms `admin_list_members_sponsors()` currently returns only the newest 500 Main IDs and has no search/offset parameters.
- The Admin UI filters and exports only this loaded result. A versioned, Admin-checked paginated/search RPC plus Load More/full-history export is required before the member directory/report can be called complete.
- No Production changes were made during this inspection.


## Admin member directory pagination batch — 2026-11-16

- Added source-only Admin-checked RPC `admin_list_members_sponsors_page(text,integer,integer)` with bounded 100-row pages, stable created_at/ID ordering and optional safe text filtering across Main ID, name, phone and sponsor ID.
- Admin directory now loads the first 100 Main IDs and exposes Load More. Current UI search remains scoped to records already loaded; server-side search wiring and full-history filtered CSV export remain outstanding.
- No Production migration or data change was made.

## Latest verification — 2026-11-16

- Source commit `4b8e89f7e80f824cc5892126562603029f5f1d2e` passed CI run `43756709964`: 20/20 Vitest files, TypeScript build and Vite production bundle.
- This verifies source only. The member directory pagination migration remains unapplied; Production's existing `admin_list_members_sponsors()` still has its 500-row limit.

## Latest Admin member directory update — 2026-11-16

- Server-side Main ID search, paginated continuation and complete matching-result CSV export are implemented in source.
- Commit `53bc09805e88e0ffc37108431593682a43b4326f` passed CI run `43757646055`: 20/20 Vitest files, TypeScript build and Vite production build.
- Production RPC migration is still unapplied; do not deploy this UI to Production until migration reconciliation is reviewed.


## Sponsor genealogy scalable search and pagination (2026-11-16)

- Added the authenticated `get_my_mlm_dashboard_page(integer,integer,text,integer)` RPC migration to return a bounded 50-row page, total match count, continuation flag and summary fields. Page size is capped at 100; offsets and depth values are validated; recursive traversal remains cycle-safe.
- Updated the member Referrals workspace to search the complete sponsor downline server-side, filter by depth and load subsequent pages without fetching the full genealogy payload at once.
- Added static regression coverage for the frontend RPC contract and SQL safeguards.
- The first CI run for this commit passed all 21 test files / 83 tests but failed TypeScript build because the nullable Supabase client was not narrowed inside an async callback. The source correction is included in the following fix commit; final CI result is pending.
- The new migration remains source-only and is NOT applied to Production. No Production data/schema/settings or financial records were changed.


## Sponsor genealogy pagination — verified 2026-11-16

- Final source commit `c3217f8180941cfc6c2d1c0d56841ec2edaee60b` passed GitHub Actions run `43759348588`: 21/21 Vitest files passed, TypeScript build and Vite production bundle passed; npm audit reported 0 vulnerabilities.
- Member Referrals now uses authenticated server-side search and level filtering with bounded 50-row pages and Load More. SQL migration remains unapplied in Production.
- Latest read-only Production check: 30 migrations, 21/21 public tables RLS enabled, 43 authenticated-callable SECURITY DEFINER warnings plus one anon-callable signup lookup, leaked-password protection disabled, one unindexed FK and 17 unused indexes. Full security review and live migration reconciliation remain blockers.
- No Production data/schema/settings/migrations or financial records changed.


## Member package activation safety lock — 2026-11-16

- Member package page no longer accepts payment references or calls `submit_package_activation`. Package rows are informational only and any Bid Wallet amount is labeled as proposed/not issued.
- Free registration remains available. Paid activation remains disabled until owner financial/legal approval and independent database verification.
- Regression coverage added for the UI fail-closed state. This is a client-side guard only; Production backend safeguards remain unverified because migrations have not been applied.


## Admin Duplicate ID directory pagination — 2026-11-16

- Admin Duplicate ID list now has source-side full-history search and 50-row Load More using a new Admin-checked RPC.
- Migration `20261116110000_admin_duplicate_id_pagination.sql` is source-only and not applied to Production. Duplicate ID activation remains locked; this batch improves administrative visibility only.


## Admin Duplicate ID pagination CI correction — 2026-11-16

- Corrected a false-negative static test assertion; first CI run failed only this assertion (22/23 files, 91/92 tests passed), and TypeScript/build steps were skipped as a result.
- Admin UI now displays the missing-RPC error instead of silently showing an empty Duplicate ID list. The migration remains source-only.


## Admin Duplicate ID pagination — verified 2026-11-16

- Source commit `9e42ee4af7b3b49958f18e55a7505c218ad3feb0` passed CI run `43785364112`: 23/23 test files, 92/92 tests, TypeScript build, Vite production build; npm audit 0 vulnerabilities.
- New duplicate directory RPC migration remains unapplied. The Admin UI will surface an explicit RPC load error until source migrations are reconciled and deployed to the intended database.
- Production Security Advisor still reports 43 authenticated-callable SECURITY DEFINER functions, one anon-callable sponsor lookup, one RLS-enabled table without direct policies, one unindexed FK and 17 unused indexes. These require function-by-function review; do not blanket-revoke or drop indexes.
- Major blockers remain: Production/source migration and RPC drift, duplicate-ID enablement and placement policy validation, commission engine and owner-approved financial rules, auction/Fixed Bid winner rules and settlement, withdrawal payout integration, live RLS/Storage/integration/browser E2E tests, and final deployment readiness.


## Bulk development batch — 2026-11-16

- Completed public Product catalogue 100-row pagination with deterministic ordering, Load More, loaded-count feedback and explicit retry messaging. Search currently covers records loaded in this browser session; server-side search across the entire catalogue remains pending.
- Hardened Member Profile self-service validation and error handling to match the existing server RPC constraints. Only the caller's display name and phone can be changed; identity, sponsor, status and wallet data remain server-controlled.
- Added static contract tests for both changes. Execution is pending; do not treat the tests as passed until CI confirms.
- No Production schema, data, Storage, feature settings or financial state was changed.


## Public Product catalogue full-history search batch — 2026-11-16

- Replaced browser-only filtering of the first 100 loaded Products with a server-side search RPC covering the complete published catalogue, while retaining deterministic pagination and Load More for the matching result set.
- The RPC is `SECURITY INVOKER`, so existing table RLS remains in force; it returns only published products, validates search/page bounds, and is executable by anonymous and authenticated visitors for public catalogue reading.
- Added static regression tests for RLS-preserving invocation, published-only filtering, search bounds and pagination contract. CI verification is pending.
- Migration `20261116120000_public_product_catalogue_search.sql` is source-only and has NOT been applied to Production. No Production data, schema, settings, Storage or financial state was changed.


## Installable PWA foundation batch (2026-11-16)

- Added a Web App Manifest with standalone display, app scope/start URL, theme/background colours and scalable 192/512 SVG app icons.
- Added production-only service-worker registration using Vite BASE_URL, so GitHub Pages /biddworld/ and future root-domain hosting use the correct scope without cross-origin API caching.
- Added a versioned same-origin app-shell cache, network-first navigation fallback and same-origin static-asset cache; Supabase/API requests are not intercepted or cached.
- Added automated source-contract tests for the manifest, registration, offline fallback and cache boundaries.
- This is the installability/offline foundation, not a claim that Android installation, browser compatibility or offline authenticated workflows have been device-tested. Those remain in final QA.
- No Supabase migrations or Production changes were made.


## Member inbox and Support workflow usability batch (2026-11-16)

- Member notification inbox now provides an unread-only view over loaded rows and a bulk mark-as-read action. Bulk updates are limited to unread records and rely on the existing owner-scoped RLS policy; Admin notification authoring does not expose this member action.
- Support workspace now filters loaded tickets by status and case-insensitive subject/message/response text for both member and Admin views. The UI explicitly labels filters as applying to loaded records; existing 100-row pagination and database RLS remain in place.
- Added source-contract regression tests for both changes. CI is required to verify tests, TypeScript and production build.
- No migrations, Production schema/data/settings, wallet balances or financial workflows were changed.


## Fixed Bid catalogue and CI regression correction (2026-11-16)

- Added client-side search and status filters (Scheduled, Live, Ended) over the Fixed Bid campaigns already loaded by the existing 50-row paginated query. Search covers campaign title/description and product name/category. The UI labels the scope as loaded campaigns and preserves pagination.
- Corrected the notification inbox heading wording to retain the existing pagination test's explicit 'unread shown' contract while still clarifying that the count is for the current page.
- CI run `43789281452` exposed one existing source-contract assertion expecting the phrase `unread shown`; 27 test files passed and 1 test file failed (108/109 tests passed). This batch corrects that compatibility issue and adds Fixed Bid filter regression coverage. New CI verification is pending.
- No financial actions, migrations, Production data/schema/settings or wallet state changed. Fixed Bid remains read-only; no entries, bids or payments are enabled.


## Member wallet statement date filters (2026-11-16)

- Added inclusive UTC start/end date filters to the member Wallet Transaction History, alongside existing wallet-type and credit/debit filters.
- The same combined filter is applied to the complete Main-ID-scoped CSV export, not just the currently loaded 100-row screen. Invalid reversed date ranges are blocked and clearly reported; date filters can be cleared without reloading wallet records.
- Added regression tests for date boundaries, complete export parity and retention of Main ID scope/pagination.
- No wallet balances, ledger rows, financial RPCs, Supabase migrations, Production data/schema/settings or financial enablement were changed.


## Admin complete wallet ledger export (2026-11-16)

- Added a dedicated complete Admin wallet-transaction CSV export using the existing authenticated `admin_list_wallet_transactions` RPC in 100-row pages until the final page.
- Export includes transaction/member IDs, wallet type, direction, amount, balance-after, reference metadata, description and timestamp. It is read-only and does not alter balances or ledger records.
- Clarified the Reports screen about which exports are complete paginated RPC exports and which remain limited to currently returned source-RPC records (package activations, referral plans, auctions and Fixed Bid campaigns).
- Added regression tests for the RPC pagination contract, ledger fields and report-scope wording.
- No migrations, Production schema/data/settings, wallet balances or financial workflows were changed.


## Admin wallet ledger Reports entry-point correction (2026-11-16)

- Connected the Reports screen to the existing complete paginated wallet-ledger export action rather than maintaining a duplicate implementation. This avoids duplicate code and keeps one source of truth for its loading/error state and CSV generation.
- No new database calls or financial behavior were introduced; export remains read-only.
