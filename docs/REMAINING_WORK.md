# BiddWorld — Current Source Development Status

This file keeps the historical audit notes below, but the opening status is the current source-of-truth summary. Continue only on `completion-work`. This is a source-development checkpoint, not a runtime verification or production-readiness claim.

## Implemented in the current source tree

- Responsive React + TypeScript + Vite marketplace, installable PWA foundation, authentication and member workspace.
- Member Main/Duplicate ID views, sponsor/team genealogy, package activation request workflow and receipt handling.
- Bid Wallet and Income Wallet UI, wallet funding history, withdrawal requests, transaction statements and Admin wallet/withdrawal review workflows.
- Configurable referral and Matrix plans, automated placement/commission source workflows, Admin configuration and member summaries.
- Auction lifecycle with Starting/Expected Price, optional end time, 48-hour target countdown, idempotent bid RPC, Admin auction management and winner-payment/delivery workflows.
- Fixed-Amount Bid campaigns, member entries, Admin draw/settlement and reporting source.
- Member OLX-style product and auction submissions, private image uploads, duplicate-pending product prevention, editable resubmission, Admin/Staff review, public gallery publication and keyset pagination.
- Admin member/sponsor/ID management, staff permission scopes, package/payment review, reports/CSV exports, audit logs, feature settings and delivery tracking.
- In-app notifications, member support tickets, workflow status updates and notification history/realtime validation.
- Source migrations for RLS, RPC authorization, idempotency, Storage access, audit logging, clean-install inventory and regression-contract coverage.

## Remaining source-development work

- Finish a complete frontend RPC-to-migration signature reconciliation, including every argument name/type, return shape, authorization claim and UI call site. Fix all mismatches as forward-only source migrations.
- Finish the cross-module schema and Storage dependency reconciliation for the clean-install forward chain; ensure every required table, column, index, trigger, RPC, bucket and policy is represented exactly once.
- Close any remaining Member/Admin workflow gaps discovered by source inspection, especially error/retry states, permissions, pagination boundaries, media cleanup and cross-module state refresh.
- Complete static regression-contract coverage for every newly corrected RPC/migration and every critical workflow.
- Reconcile all source documentation and completion records with the current branch head.

## Verification deliberately deferred until source development reaches 100%

- Do not run the final unit-test suite, TypeScript/build pipeline, database replay, integration tests, browser/mobile E2E or user acceptance testing as a substitute for unfinished development.
- Do not apply migrations to either Supabase project during this development-only phase. Production remains untouched; TEST is reserved for the later approved functional-testing phase.
- Do not claim a module is functionally verified solely because its UI or source migration exists.

## External integrations not represented as completed source functionality

- No external payment gateway or bank payout provider is connected.
- No paid email/SMS/push delivery provider is connected; the implemented in-app inbox is separate from those external delivery channels.

## Current checkpoint

- Branch: `completion-work`
- Current migration inventory at this checkpoint: 137 forward + 16 excluded = 153 timestamped SQL files.
- Latest auction source repairs: `20261119680000_admin_auction_submission_expected_price_review.sql` and `20261119690000_prevent_duplicate_pending_auction_submissions.sql`.
- Source development estimate: 95% provisional. This is not a verified completion percentage.

## Historical audit notes

The dated sections below preserve earlier investigations and decisions. Some implementation gaps recorded there were subsequently closed by later source commits; use the current sections above and the latest completion register before reopening an item.

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


## Admin wallet ledger search and date filters (2026-11-16)

- Added client-side search over the currently loaded Admin wallet ledger (Main ID, wallet, transaction type/direction, reference and description) and inclusive UTC From/To date filters.
- Added a clear-filters action, matching-row count, and reversed-range warning. The UI explicitly states filters cover loaded rows only.
- The complete CSV export continues fetching all secured RPC pages independently of these screen filters, so the filters cannot silently narrow the archival export.
- Added source-contract regression tests. No wallet records, balances, RPCs, schema or Production settings changed.


## Admin pending package activation review filters (2026-11-16)

- Added search on the currently loaded pending activation requests by request number, Main ID, member name, package and payment reference.
- Added inclusive UTC submission-date filters, clear action, matching count and reversed-range warning.
- Filtering is display-only: it does not change payment status, reject/approve behavior, financial locks or the existing CSV export scope (which remains all currently loaded pending requests).
- Added regression tests. No package activation, wallet credit, payment status, Supabase schema or Production data was changed.


## Admin Auction and Fixed Bid report filters (2026-11-16)

- Added loaded-record search and status filters to the Admin Auction and Fixed Bid CSV report sections.
- Auction search covers ID, product, title, category and status. Fixed Bid search covers campaign ID, product, title, description and status.
- CSV exports now use the matching filtered rows and show matching versus loaded counts. UI text explicitly states these source RPC results are not guaranteed complete-history exports.
- Referral plan export remains clearly labelled as plan drafts, not a commission payout history. No Supabase schema/RPC, Production data, bidding, settlement or wallet behavior changed.


## Admin Winning Payment and Delivery report filters (2026-11-16)

- Added search, status and inclusive date-range controls for Winning Payments and Delivery Tracking report exports.
- Filters run after the exporter retrieves every 100-row page from the existing secured Admin RPC, so they apply to the complete fetched dataset rather than only the first on-screen page.
- Winning-payment date range uses `created_at`; delivery date range uses `updated_at` with `shipped_at` fallback. Export filenames and controls identify filtered complete exports.
- No payment, delivery, wallet, auction, Fixed Bid, Supabase schema/RPC or Production data was changed. This is reporting only.


## Admin Package Activation report filters (2026-11-16)

- Connected the existing pending-activation search and inclusive submitted-date filters to the CSV export; added a matching/total count and disabled export for reversed date ranges.
- The existing `admin_list_pending_activations()` RPC returns the complete pending-review queue (no page limit in its migration). The report is explicitly scoped to pending requests and is not represented as an approved/rejected historical activation archive.
- No approval/rejection action, wallet credit, payment, Supabase schema/RPC or Production data changed.


## Admin Withdrawal report filters (2026-11-16)

- Added search, status and inclusive request-date filters to the withdrawal CSV export.
- Filters are applied after the existing export helper retrieves every 100-row page from `admin_list_withdrawal_requests`; date range uses `requested_at`. Reversed ranges disable export.
- Export remains read-only. No withdrawal approval, payout, wallet balance, financial setting, Supabase schema/RPC or Production data changed.


## Fresh Production drift and security verification — 2026-11-16 (read-only)

A further direct read-only inspection was completed against the connected `BiddWorld-Production` project. No SQL writes, migrations, settings changes, Storage operations, or row changes were performed.

### Confirmed migration drift

- Production migration ledger currently contains **30 applied migrations**; latest is `20261115163218_admin_audit_log_pagination`.
- The branch contains forward migrations dated `20261116` that are not present in the Production ledger. The financial approval guard and expanded financial activity lockdown remain source-only.
- Production still exposes the one-argument `admin_create_duplicate_member_id(p_main_member_code text)`; the branch workflow expects the two-argument placement-aware signature. Do not use the branch Duplicate ID placement workflow against Production until its migration is owner-approved and reconciled.
- Production `place_bid` and `submit_package_activation` are SECURITY DEFINER wrappers that delegate to private SECURITY DEFINER implementations. The private implementations inspected derive the member from `auth.uid()`; bidding is additionally disabled by the current feature setting. This does not remove the need to install and verify the expanded source-only financial interlock before any financial enablement.

### Security review findings

- Catalog inventory confirms public Admin SECURITY DEFINER RPCs are executable by `authenticated` but not `anon`; the inspected Admin RPC bodies contain authenticated-user and `app_metadata.role = admin` checks. This is an inventory-level check, not a line-by-line certification of every function.
- `lookup_sponsor(text)` remains intentionally callable by `anon` and `authenticated`, returns exact-match active Main ID code and display name, and has no rate limiting in its current definition. Signup requires this lookup, so do not revoke it without replacing the signup flow. Rate limiting, enumeration controls and privacy review remain launch blockers.
- Supabase Security Advisor currently reports leaked-password protection disabled. Enable it through the Auth security settings after owner review; it was not changed during this audit.
- Security Advisor reports multiple authenticated-callable SECURITY DEFINER functions. The execute grant alone is not proof of a vulnerability; every function body must be checked for authentication, ownership or trusted Admin authorization, fixed search_path and data minimization.

### Financial interlock — do not enable

- The Production settings snapshot still has `package_activations_enabled=true`, `bid_wallet_enabled=true`, and `income_wallet_enabled=true`; the `financial_model_approved` setting is absent.
- Production has not received `20261116000000_financial_approval_guard.sql` or `20261116080000_financial_activity_lockdown.sql`. The source guard is therefore not active in Production.
- Treat package approval, wallet ledger writes, commission credits, bid debits, Fixed Bid entries, withdrawals and winner settlement as prohibited until a complete forward-only migration is reconciled, independently tested and explicitly approved by the owner. Keep financial features disabled; do not infer safety from client-side locks.

### Required next actions

1. Reconcile every source migration against actual Production object definitions, not only migration version names; prepare a forward-only plan and dry-run in a safe non-production environment.
2. Review every exposed SECURITY DEFINER RPC body, especially the Admin RPCs, member withdrawal request, sponsor lookup and bid/package wrappers.
3. Add rate-limit/abuse protection for public sponsor lookup without breaking signup.
4. Owner to review and enable leaked-password protection in Auth settings.
5. Do not apply migrations or alter financial settings without explicit owner approval.


## Critical Admin RPC authorization drift correction (2026-11-16)

- A fresh read-only Production catalog inspection found the live definitions of `admin_get_member_structure()` and `admin_get_mlm_overview()` did not contain the Admin-role guard present in the current source migrations. Both RPCs were executable by authenticated callers, so this represented a member-to-admin report data exposure risk.
- Added forward-only migration `20261116130000_restore_admin_report_rpc_authorization.sql` to restore `auth.uid()` plus trusted `auth.jwt()->'app_metadata'->>'role' = 'admin'` checks, fixed empty search_path, and revoke PUBLIC/anon execution while granting authenticated invocation (the function body enforces Admin role).
- Added regression tests for both function bodies and ACL statements.
- Migration is committed to GitHub only and is **NOT applied to Production**. Owner approval and non-production verification are required before deployment. No Production data/settings/schema were changed during this batch.


## Withdrawal RPC identity hardening (2026-11-16)

- Read-only Production function review found `member_create_withdrawal_request` checked authentication, the withdrawal feature switch and Income Wallet balance, but did not independently verify that the profile's Main ID belongs to the caller and is currently active.
- Added a source-only forward migration that validates the profile Main ID against `member_ids.owner_user_id`, `id_type='main'` and `status='active'` before creating a withdrawal request. Existing Income Wallet-only deduction/request behavior, balance row lock, open-request check, disabled-by-default feature switch and authenticated-only grant are preserved.
- Added regression tests. This is defense in depth; it does not enable withdrawals and does not replace the financial approval interlock.
- NOT applied to Production. No live database data, schema, settings or financial records were changed.

### Admin RPC review clarification

The latest exact Production definitions of `admin_get_member_structure()` and `admin_get_mlm_overview()` both contain `auth.uid()` and trusted `app_metadata.role='admin'` checks. The prior batch's concern that these two live functions lacked those checks was incorrect. Keep their proposed redefinition migration unapplied pending full reconciliation; it is redundant against the current observed definitions.


## Signup inactive-until-verified Production drift (2026-11-16)

- Read-only inspection of the live `auth.users` trigger found `private.handle_new_auth_user()` currently creates both `profiles.status='active'` and `member_ids.status='active'`.
- The development branch's intended lifecycle is inactive until a verified/approved package activation. The corresponding source migration is not applied in Production, so this is a real source/Production drift and member eligibility risk.
- Added `20261116150000_enforce_inactive_signup_until_verified.sql`, preserving Production's current `registration_enabled` and `sponsor_referrals_enabled` feature-switch behavior, sponsor validation/default sponsor logic, profile and wallet provisioning, while setting both new profile and Main ID to inactive.
- Added regression tests for inactive creation and preserved gates. The migration is source-only; NOT applied to Production. No existing account statuses were mass-updated and no Production rows/settings/schema were changed.
- Deployment remains blocked on full migration reconciliation, non-production testing, and explicit owner approval of the financial/legal model. Do not activate package, referral, wallet, bid, or withdrawal operations.


## Public sponsor lookup privacy hardening (2026-11-16)

- Replaced the public lookup response containing member_code and display_name with a boolean exact-match result only. The signup trigger remains the authoritative independent sponsor validation/linking path.
- Signup UI no longer displays another member's name from a public anonymous lookup. It validates a minimally complete alphanumeric code before lookup and debounces requests by 450 ms to avoid a request on every keystroke.
- Added regression coverage for data minimization, grants, independent signup validation, debounce and incomplete-code suppression.
- This reduces PII disclosure and accidental request volume, but is NOT IP-based rate limiting and does NOT eliminate valid/invalid code enumeration. A trusted Edge Function/API gateway with server-observed IP throttling and abuse controls remains a launch blocker. No Edge Function is currently present in the repository.
- Source-only migration; Production still has its prior table-returning function. Do not apply before complete migration reconciliation and explicit owner approval. No Production changes made.


## Registration-to-package request lifecycle verification (2026-11-16)

- Confirmed the branch's `20261115220000_inactive_until_verified_package_activation.sql` migration already replaces the package-request RPC so an authenticated owner can submit a pending request with an inactive Main ID. It still requires a caller-owned Main ID, creates only pending activation rows, and does not credit wallets or activate the account.
- The prior concern is therefore a **Production migration-drift / rollout-order issue**, not a missing source implementation. Production currently has not applied the 20261115/16 source migrations and its live RPC still requires an active Main ID.
- Added a regression test asserting inactive Main IDs can submit pending package requests without wallet credit, and that the branch migration retains the pending-only lifecycle.
- Before deployment, reconcile and test the entire ordered migration chain together; do not apply the signup trigger migration in isolation. No Production changes made.


## Immediate Production launch blocker — Admin package approval (2026-11-16)

Production's `admin_review_package_activation(uuid,boolean)` RPC can credit the Bid Wallet and activate a package when an Admin approves a pending request. It checks trusted Admin role but does not itself check the owner financial-approval setting. The database-level interlock migrations `20261116000000_financial_approval_guard.sql` and `20261116080000_financial_activity_lockdown.sql` are not applied in Production. Do not use package approval or enable paid activation. Reconcile and test the complete forward-only migration chain in non-production, then obtain explicit owner approval before Production rollout. The Admin UI lock alone is not an adequate security boundary.


- [ ] Apply and validate source-only `20261116170000_minimize_member_withdrawal_payout_data.sql` only after non-production migration testing; it reduces member withdrawal history to payout method only while Admin review retains payout details.


- [ ] Reconcile and non-production test Duplicate ID two-argument placement RPC before Production rollout; Production currently has only the one-argument function.
- [ ] Define and test whether Duplicate ID activation/reactivation must be blocked when its linked Main ID or placement parent is suspended/closed; current source status RPC does not revalidate these linked states.

- [ ] For existing Production members, perform a separately reviewed read-only eligibility report and owner-approved migration plan if historical inactive/active status reconciliation is required. Do not bulk change statuses as part of signup lifecycle migration.

- [x] Batch 24: remove historical bulk member/profile status rewrites from the inactive-until-verified package lifecycle migration; retain only row-specific activation after approved package transition.
- [x] CI: latest commit `e6d308437d89d3158bbca30433525baa0ee0812b` passed (44 test files, 162 tests; build completed; npm audit reported 0 vulnerabilities in that run).
- [ ] Complete non-production Supabase integration tests for signup trigger, pending package request, Admin approval rejection under the financial guard, and row-specific account activation. Do not run these against Production.

- [x] Read-only Production check of `app_settings` table grants and RLS: authenticated SELECT only, no client writes; ordinary Admin feature-setting allowlist does not expose `financial_model_approved`.
- [ ] Apply no Production migration until the complete migration history/object diff is reconciled, the guard is tested in a non-Production Supabase project, and the owner explicitly approves the rollout.

- [x] CI: commit `e027992d8b928fc70db97fb0a8e51ef75ca18215` passed, 44 test files / 163 tests, build successful.
- [ ] Production financial interlock migration rollout remains blocked pending non-Production Supabase integration test and explicit owner approval.

- [x] Read-only Production grant check across eight financial tables: no direct authenticated INSERT/UPDATE/DELETE grants; anon has no grants.
- [ ] Prove rollback of wallet balance changes when the financial interlock rejects a later ledger insert, using an isolated non-Production Supabase database. Production is not a test environment.
- [ ] Audit trusted service_role consumers separately; never expose service_role credentials to browser code.

- [x] Source scan of 18 browser TS/JS files found no service-role or secret-key pattern; browser Supabase config uses publishable/anon key only.
- [ ] Complete deployed-bundle, Git-history and CI secret review; audit service_role consumers separately.


## Wallet ledger immutability hardening — 2026-11-16

- Extended the source-only financial interlock migration with an append-only wallet ledger rule: UPDATE and DELETE attempts on `wallet_transactions` are rejected; corrections must use compensating ledger entries.
- Added static migration-contract coverage for the immutable-ledger trigger and its client-role EXECUTE revocation.
- This is source/CI contract coverage only. It has not been exercised against PostgreSQL, and the migration remains unapplied in Production. Before rollout, validate compatibility with every legitimate ledger maintenance/reversal workflow in a disposable database.
- No Production schema, settings, rows, grants or financial records were changed.


## Repository credential-surface regression guard — 2026-11-16

- Expanded browser-credential security tests to scan tracked browser source, public assets, GitHub workflow YAML and any Supabase Edge Function source for service-role/secret environment-variable assignments and Supabase secret-key tokens.
- The current GitHub Pages deployment workflow injects only the Supabase publishable key, which is a browser-safe public credential; it does not inject a service-role key.
- This is a source-text regression guard, not a Git-history scan, deployed-bundle inspection, GitHub Actions secret inventory, Edge Function secret inventory, or proof that external integrations never expose privileged credentials.
- No credential values were retrieved or printed. No Production setting, schema, data or financial operation was changed.


## Bulk security and production-readiness batch — 2026-11-16

- Added a migration-wide static contract test for every public SECURITY DEFINER SQL function: each declaration must pin `search_path` and explicitly revoke default EXECUTE before granting intended roles.
- Confirmed the latest credential-scan CI and wallet-ledger append-only CI passed before this batch. Follow-up CI `43798298345` passed (45 test files / 167 tests, type-check/build successful, npm audit 0 vulnerabilities).
- Remaining blockers are not small UI tasks: complete Production migration/function reconciliation; non-Production PostgreSQL integration tests; public sponsor lookup rate limiting; Auth leaked-password protection; full RPC body review; secret inventory/history/deployed bundle review; financial/legal model approval; and real browser/mobile E2E.
- Financial package, commissions, bids, Fixed Bid, winner settlement and withdrawals remain prohibited until owner/legal/economic approval and database enforcement are independently verified.


- Follow-up corrected template-literal escaping in the migration-wide SECURITY DEFINER contract test after CI detected a parse error; CI run `43798298345` passed after the parser fix (45 files / 167 tests).


## Migration history reconciliation — refreshed 2026-11-16

- [x] Read-only count: 42 source SQL migration files on `completion-work`; 30 applied rows in Production.
- [x] Exact version-prefix comparison: 4 timestamp matches; 26 Production ledger rows have no same-version source filename. Semantic similarity is not proof of identical SQL.
- [ ] Recover/reconstruct authoritative SQL for Production versions missing from source; compare live objects and prepare a forward-only reconciliation plan. Never replay baseline migrations or fabricate history.
- [ ] Rehearse the complete ordered chain in a disposable non-Production database before explicit owner approval. Production remains untouched.

## Route-level code splitting batch — 2026-11-16

- Converted all nine tab-level workspaces (Packages, Referrals, WalletHistory, FixedBid, Admin, Support, Notifications, Account, DashboardPreview) from static imports to `React.lazy` with a shared `WorkspaceFallback` Suspense placeholder styled like the existing workspace panel, including the wallet tab's inline history module.
- Initial JavaScript bundle reduced from approximately 506 KB to approximately 314 KB (about 93 KB gzipped versus about 135 KB); the Admin console now loads as a separate ~102 KB chunk only when an authorized admin opens it, and the member dashboard as a separate ~44 KB chunk only when a member opens it.
- Verified locally: TypeScript project build passed, Vite 6 production bundle built successfully, and all 60 test files / 228 tests passed. No routes, permissions, authentication, financial locks or feature switches were changed; no dependencies were added; no database changes were made.
- Git sync note: this Bolt workspace is not a git checkout, so the changes could not be committed or pushed to `completion-work` from here; use Bolt's publish/version history to sync, then confirm CI on GitHub.
- Remaining work is unchanged: database financial interlock rollout, migration reconciliation, sponsor-lookup rate limiting, leaked-password protection, live integration/E2E testing and owner financial/legal approval.


## Member product listings — development source added (2026-11-19)

- [x] Member OLX-style product submission form, private image uploads, owner-scoped history, Admin approval/rejection queue, signed private image previews, and publication into the existing public catalogue are now implemented in source.
- [x] Source-only migration `20261119440000_member_product_submission_moderation.sql` is registered in the clean-install forward migration manifest.
- [ ] Apply and validate the migration only in the isolated TEST database during the final testing phase; do not use Production for this task.


## Member product editing — development source added (2026-11-19)

- [x] Members can edit and resubmit their own Pending or Rejected product submissions. Existing private images can be retained or replaced; corrected submissions return to Pending Admin review.
- [x] Added owner-scoped RPC migration `20261119450000_member_product_submission_editing.sql`, registered in the clean-install forward manifest, plus source-only regression coverage.
- [ ] Apply and validate the migration only in the isolated TEST database during the final testing phase; do not use Production for this task.


## 2026-11-20 — Current TEST backend reconciliation

- Read-only check confirms BiddWorld-TEST is ACTIVE_HEALTHY. Current source forward manifest: 135 migrations. TEST migration history: 89 rows; one duplicate historical entry for 20261118230000_recover_admin_read_rpc_sources; latest applied migration: 20261119170000_admin_open_ended_auction_status.
- 48 forward migrations remain unapplied in TEST, beginning with 20261119180000_fix_auction_image_path_regex. The product_submissions table and product-submission-media Storage bucket are not present yet; the current product submission UI therefore cannot be fully exercised against this schema.
- No migration, schema, Storage or data changes were made. Apply the missing migrations to TEST only after explicit owner approval. Never apply these to Production.
- The previous checklist item requesting the two-argument Duplicate ID creation RPC is superseded: 20261119300000_automatic_duplicate_matrix_placement.sql intentionally replaces it with a one-argument automatic-placement RPC that uses the active Matrix plan and second package activation. The Duplicate ID activation RPC already requires an active linked Main ID and active placement parent (20261118270000); Main-ID child reconciliation is implemented in 20261119370000 and 20261119380000.


## 2026-11-20 — Admin auction submission approval contract repaired (source-only)

- Resolved the missing Admin/Staff `admin_review_auction_submission` RPC left after the Expected Price migration dropped the legacy fixed-end-time signature. Added `20261119680000_admin_auction_submission_expected_price_review.sql` with the current Frontend signature and Expected Price validation.
- The new RPC validates 1–8 unique public image paths belonging to the submitting member, verifies the objects exist in `product-media`, publishes the complete gallery, creates the auction with `ends_at = NULL`, and writes approval/rejection audit events. Pending submissions require Expected Price >= Starting Price.
- Added source regression test `tests/admin-auction-submission-expected-price-rpc.test.ts`, aligned Admin title preflight, and registered the migration in the clean-install forward manifest.
- Current manifest: 136 forward + 16 excluded = 152 timestamped migrations. This is source-only; no SQL was applied and tests/build/browser QA remain deferred until development is complete.


## 2026-11-20 — Latest source-only auction integrity batch

- Fixed Member Auction Submission optional-detail editing so line breaks round-trip as actual newlines. Tightened history response validation so Expected Price is required and must be >= Starting Price.
- Added forward migration #137 `20261119690000_prevent_duplicate_pending_auction_submissions.sql`: transaction-advisory-lock serialization and a database BEFORE INSERT/UPDATE guard reject duplicate normalized pending auction titles for the same submitter. Added static regression-contract test.
- Current clean-install inventory: 137 forward + 16 excluded = 153 timestamped migrations.
- No tests/build/QA or SQL replay were run; TEST and Production remain unchanged. Continue source-only development until the 100% development gate.


## 2026-11-20 — Expected Price equality lifecycle correction

- The auction deadline trigger runs on current-price updates, not initial inserts. Corrected Admin approval so Expected Price = Starting Price initializes `target_reached_at` at the scheduled start (or immediately for a live auction) and sets the 48-hour deadline. Higher Expected Prices remain open-ended until reached.
- Added source regression assertions; tests remain unexecuted during the development-only phase. Commit `a3b4dcf47685e9bdd9b4f94209c62b0c2beb70b4`.

## 2026-11-20 — Fixed Bid card and details experience

- Reworked Fixed Bid cards to show a single-line campaign title and product subtitle, a Product Details link, entry amount, percentage progress bar and prominent BID NOW action. Full details open in a responsive dialog with the complete published product attributes and all approved gallery images.
- Extended the restricted public catalogue RPC projection to return the approved product image gallery and product details, plus a percentage-only campaign capacity indicator. The response does not expose raw entry or participant counts. Existing secure member entry RPC and feature controls remain unchanged.
- Added source migration `20261120100000_public_fixed_bid_card_details_and_progress.sql` to the clean-install forward manifest. Source-only: no migration was applied and no tests/build/browser QA were run.
- Updated clean-install inventory: **138 forward + 16 excluded = 154 timestamped SQL migrations**.

## 2026-11-20 — Auction card visual refresh

- Refined the homepage Auction cards to match the clean Fixed Bid card system: single-line auction title, compact category subtitle, Auction Details link, prominent current-bid amount, time label, target-progress bar when an Expected Price exists, and a large gradient PLACE A BID action.
- Preserved the existing auction details dialog, live/scheduled state handling, bid eligibility checks, and server-side bid workflow. No auction schema or database changes were required.
- Added static source-contract assertions for the card hierarchy, progress indicator and bid action. No tests/build/browser QA were run during the development-only phase.

## 2026-11-20 — Auction item awards and homepage Winners

- Corrected Auction finalization: the highest eligible bidder is recorded as the winner and awarded the listed item. Auction finalization no longer creates a separate `winning_item_payments` record or returns a winner-payment obligation. Fixed Bid campaign winner-payment flows remain unchanged.
- Added a restricted public read RPC for recent finalized Auction winners, exposing only auction title, listing image, display name, winning bid amount and finalization date. Homepage shows responsive Recent Winners cards only when real winner records exist; no sample winners are invented.
- Auction winner-payment notifications are excluded; Fixed Bid winner-payment notifications remain active. Historical Auction payment records, if any, are not deleted or modified by this source migration.
- Added static source-contract assertions and registered migration `20261120110000_auction_item_awards_and_homepage_winners.sql`.
- Commit: `20fc530cea4e171bc3502ad23d49b63c7e6d3bb4`. No SQL was applied and no tests/build/browser QA were run.
- Clean-install inventory: **139 forward + 16 excluded = 155 timestamped SQL migrations**.
