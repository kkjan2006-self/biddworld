- **Clean-install migration manifest regression source syntax repaired:** replaced literal backslash-n characters embedded between TypeScript statements in the version-prefix uniqueness test with real source line breaks. Assertions and manifest inventory unchanged; source-only test not executed. No SQL migration or database change required.
- **Member Income Wallet Add Money history pagination hardened:** request IDs/payment fields, review status and timestamps are validated; every page enforces consistent `has_more`, full 50-row continuation pages, strict descending `(created_at,id)` order and no overlap with loaded rows. Source-only regression assertion added; not executed. No SQL change required.
- **Member Withdrawal History pagination integrity completed:** initial and continuation pages now share strict row, lifecycle status, timestamp, safe payout projection, page-size, consistent `has_more`, descending `(requested_at,id)` order and cross-page duplicate/cursor validation. Invalid or overlapping pages fail closed instead of being appended. Source-only regression assertions added; not executed. No SQL change required.
- **Staff Package Activation queue now preserves legacy requests with no receipt:** SQL projects nullable `receipt_path`, and the Staff screen already has a no-receipt state that allows rejection but blocks approval. The parser previously rejected the entire page for any null receipt. It now accepts null while retaining strict path validation for non-null receipts; approval still requires a successfully signed receipt URL. Source-only regression assertion added; not executed.
- **Income Wallet Add Money Admin queue pagination reconciled:** the SQL returns an ordered 50-row page plus a continuation flag. The client now rejects short continuation pages and verifies strict ascending `(created_at,id)` order inside every page, while comparing cursor timestamps as parsed dates rather than relying on string ordering. Replaced stale source-contract assertions with assertions matching the current SQL/UI contract. Source-only tests added/updated; not executed.
- **Admin Auction Submission Review source syntax defect fixed:** a literal `\n` sequence had been written between two helper declarations instead of a real line break. Replaced it with a source newline and added a source-only regression assertion. No SQL migration required; test not executed.
- **Staff Package Activation numeric RPC contract fixed:** the SQL queue returns `activation_number` as a JSON number (the source column and submit RPC use PostgreSQL `integer`), but the Staff parser required a string and rejected every otherwise-valid row. The Staff UI now validates a positive safe integer; source-only regression coverage confirms the SQL-to-UI type contract. No migration required; test not executed.
- **Admin Income Wallet funding queue response integrity completed:** request UUIDs, INR amount/reference bounds and authenticated-user receipt object paths are validated before signed URLs; every page enforces full-page continuation, strict ascending `(created_at,id)` order, cursor-to-final-row equality and cross-page non-overlap. Source-only assertions added; not executed. No migration required.
- **Restricted Staff package activation queue integrity completed:** strict activation/payment/receipt path validation and exact keyset cursor/order checks now run before signed receipt URL creation; source-only assertions added, not executed. No migration required.
- **Admin Matrix report response integrity completed:** UUID identities, 1–50 level bounds, safe summary counts and cross-status count/amount reconciliation are enforced before report display/export. Source-only assertions added; not executed. No migration required.
- **Support history owner/row validation completed:** initial, keyset and CSV export reads now enforce authenticated owner identity and existing SQL column bounds, UUID shape, status and timestamp integrity; Admin queue remains separate. Source-only assertions added; not executed. No migration required.
- **Notification Realtime payload validation completed:** INSERT/UPDATE events now reuse full notification-row and authenticated-recipient validation; UPDATE events reconcile active category/unread filters, and DELETE events reject explicit cross-recipient metadata. Source-only assertions added; not executed. No migration required.
- **Notification inbox now verifies recipient ownership at the client boundary:** member initial pages and keyset pages validate every row against the authenticated user ID, and member realtime INSERT/UPDATE events reject mismatched owners even if a subscription filter or upstream policy is misconfigured. Admin history remains on its Admin-only recipient projection. Source-only assertions added; not executed.
- **Admin withdrawal review now shares the Main-ID lifecycle lock:** approve, reject/release and mark-paid acquire the same per-Main-ID advisory lock used by member financial actions and Admin Main-ID lifecycle changes before eligibility checks or wallet ledger mutations. Existing reserve/release ledger validation and audit behavior remain intact. Migration `20261120210000_serialize_admin_withdrawal_review_lifecycle.sql`; source-only regression test added, not executed.
- **Admin Main-ID lifecycle is now serialized with member financial actions:** the Admin suspend/close/reactivate RPC acquires the same per-Main-ID advisory lock used by Fixed Bid, withdrawal and winner-payment RPCs before changing Main/Profile/Duplicate statuses. This closes the race where a financial eligibility check and an Admin status change could overlap. Migration `20261120200000_serialize_admin_main_member_lifecycle.sql`; source-only regression test `tests/admin-main-member-financial-lifecycle-serialization.test.ts` added, not executed.
- **Member withdrawal pagination payout privacy fixed:** the newer keyset-paginated RPC previously returned the full stored payout JSON, bypassing the earlier privacy migration for the legacy endpoint. It now returns only the payout method label (or an empty object), keeping UPI IDs and bank account numbers out of member history responses. Added migration `20261120190000_minimize_paginated_withdrawal_payout_data.sql` and source-only test `tests/member-withdrawal-paginated-payout-privacy.test.ts`; not executed.
- **Income Wallet Add Money active-profile eligibility fixed:** submission now requires both the authenticated profile and its owned Main ID to be active, with both rows locked during validation. This aligns the workflow with other member financial actions and prevents suspended profiles from submitting funding requests. Added migration `20261120180000_require_active_profile_for_wallet_funding.sql` and source-only test `tests/member-wallet-funding-active-profile.test.ts`; not executed.
- **Global payment-reference collision race fixed:** Package Activation and Income Wallet Add Money now share a transaction-scoped advisory lock keyed by normalized UTR. Each workflow's database trigger checks the opposite workflow after acquiring the lock, so simultaneous cross-workflow submissions cannot both claim the same reference. Existing per-table uniqueness remains. Added migration `20261120170000_global_payment_reference_uniqueness.sql` and source-only regression test `tests/global-payment-reference-uniqueness.test.ts`; not executed.


- **Matrix auto-post no longer blocks restricted Staff package approval:** the activation trigger now calls a private internal posting routine instead of the Admin-only public posting RPC. Staff retain only their existing package-activation review permission; the manual Matrix posting RPC remains Admin-only. The internal path preserves the activation advisory lock, Income Wallet ledger idempotency and audit attribution to the approving actor. Added migration `20261120160000_matrix_staff_activation_auto_post.sql` and source-only test `tests/matrix-staff-activation-auto-post.test.ts`; not executed.
- Member Product/Auction histories now validate UUID submission IDs and SQL-compatible owner-folder image paths before signed URL generation. Persisted orphan queues require the authenticated account folder and safe generated filename contract; cleanup retry is single-flight and blocks concurrent submission. Source-only assertions added; not executed.
- Storage upload workflows now record generated paths before upload for Package/Income Wallet receipts and Member/Admin Product/Auction images; failed pre-RPC uploads are included in cleanup/retry handling, while ambiguous committed RPC outcomes remain protected. Added source-only path-order assertions; not executed.
- Admin Product moderation now persists definite-rejection/pre-RPC temporary public-image cleanup failures in a bounded Admin-account-scoped queue, with generated-path validation and a manual retry action; ambiguous outcomes retain images. Source-only assertion added; not executed.
- Wallet History now validates transaction/to-one wallet embeds and Matrix source rows, chunking CSV attribution lookups to the SQL 200-ID limit. Admin notification template save validates ID/inactive state/edit identity. Member Product/Auction submission create/edit validates returned UUID and edit identity before form reset; ambiguous outcomes preserve media. Source-only tests added/extended; not executed.
- Admin Product/Auction moderation now validates exact action status and publication identity before success; Product checks returned UUID/image count, Auction checks Auction/Product UUIDs, Expected Price and 48-hour deadline. Corrected stale auction title-bound regression assertion. Source-only assertions added; not executed.
- Matrix commission reporting now validates bounded 100-row pages, numeric summary/amount fields and consistent required `has_more` metadata; invalid short-page continuation flags are rejected. Source-only assertions added; not executed.
- Support CSV export now validates every 500-row page against the complete ticket response contract before export; malformed pages fail closed. Source-only regression assertion added; not executed.
- Income Wallet Add Money receipt cleanup now survives page reloads in a bounded user-scoped retry queue, with account-folder path validation, automatic revisit retry and manual retry. Submission validates the returned request UUID/status before clearing the form. Source-only assertions added; not executed.
- Member package activation now validates the exact RPC activation UUID/number, pending statuses and receipt path before clearing the form; malformed/ambiguous outcomes retain the receipt and require history refresh before retry. Added source-only response contract test; not executed.
- Member package catalogue RPC data is validated before rendering; orphaned private package receipts from definite activation rejections are persisted in a user-scoped bounded cleanup queue with automatic revisit retry and a manual Retry action. Source-only regression assertions added; not executed.
- Matrix plan management now validates exact draft-save and activation response identity/configuration, rejects duplicate versions/multiple active plans and enforces the SQL fixed-reward ceiling; the package selector is locked during mutations. Added source-only regression assertions; not executed. No database or runtime verification performed.
- Added a source-only clean-install documentation count guard to `tests/clean-install-migration-manifest-integrity.test.ts`; it checks the README's forward, excluded and timestamped migration totals against the manifests. Not executed. Updated the current inventory statements to 143 forward + 16 excluded + 3 legacy SQL files (162 total, 159 timestamped).
- Fixed a concrete Staff grant contract mismatch: persisted permissions and audit log listed three capabilities, while the RPC result returned only two, causing false UI failure. Added a forward migration to align the RPC result and a source-only regression assertion; registered in clean-install manifest (143 forward entries). Not executed. Commits: `12681db2`, `b1f72cca`, `249b70ca`, `518e5156`.
- Corrected and aligned restricted Staff grant/revoke result checks with SQL's three default permissions; individual permission edits now verify returned account identity and exact selection. Updated stale Main Wallet Staff copy to Income Wallet. Hardened notification recipient and delivery response checks; expanded support ticket contract assertions. Source-only tests were added/updated but not executed. Commits: `79b0c624`, `48631bc2`, `a9a528eb`, `2611c414`, `b8a222ad`, `da6e31a5`, `8ca17618`.
- Hardened restricted Staff grant/revoke, individual permission edits, Staff package activation review, notification recipient lookup and notification delivery response validation. Notification idempotency key is cleared only after a valid UUID/replay result. Added source-only regression assertions; not executed. Commits: `67759a01`, `616a72bc`, `6fd53920`, `444f4f91`, `d746bbf7`.
- Hardened Product and Auction Admin draft/publication mutations: UUID identity and published/draft status are validated before form clearing or success messaging. Added source-only regression assertions; not executed. Commits: `bce4924e`, `5620eb00`.
- Hardened additional Admin mutation responses for package activation, minimum withdrawal setting, inactive referral-plan draft and delivery tracking. Each now validates returned values/identity before confirming success or clearing form state. Added static source-only assertions; not executed. Commits: `520d35f9`, `97495b39`.
- Refined wallet workflow error handling so malformed withdrawal results retain actionable messages and Admin Add Money errors consistently display Income Wallet terminology. Commits: `45f91041`, `0e2b8e37`.
- Hardened remaining Admin Auction/Fixed Bid mutation responses: Fixed Bid draft UUID, Fixed Bid status/refund count and Auction status/refund count are validated against the submitted records before UI success/clearing. Added source-only assertions; not executed. Commits: `35d93630`, `7430ee2e`.
- Enforced Auction item-only awards: new payment requests for non-Fixed-Bid winner records are rejected server-side; Member UI only offers payment for Fixed Bid winners. Historical paid records remain untouched. Added `20261120140000_restrict_winner_payment_to_fixed_bid.sql` to forward manifest and source-only regression assertions; not executed. Commits: `2d262859`, `129c1a29`, `ab881865`, `699b60dd`.
- Hardened Member/Staff mutation response contracts across Fixed Bid entry, winning-item payment, withdrawal creation, profile editing, support ticket submit/update, Add Money submission and Admin Add Money review. Request keys/forms are cleared only after validated responses where idempotency is available. Corrected legacy Main Wallet labels to Income Wallet across related UI. Added `tests/member-workflow-mutation-response-integrity.test.ts`; not executed. Commits include `4c2017d7`, `f2cc4a58`, `7a10458c`, `030415b2`, `19893ba8`, `6bc5aeeb`, `8ba1f547`, `699c732b`, `3cdac6f9`, `9960ffee`, `349dcd58`.
- Hardened five additional Admin mutation response contracts (withdrawal review, Primary Admin role, member profile, package publication, referral-plan activation); local success/state updates now require matching returned identities and result values. Corrected withdrawal wallet terminology to Income Wallet. Static regression file added, not executed. Commits: `85bae1ab125e7beb912b1e77086ea8d540253cef`, `450afd35be20f35946adae8b81ca3a0e1bbf8eb1`.
## Latest source development batch — Admin wallet adjustment retry integrity

- Fixed incomplete idempotent replay response for `admin_adjust_member_wallet`: replay now returns the original complete result and immutable ledger balance-after snapshot.
- Admin client validates the full response against the submitted request and clears the idempotency key only after validation; ambiguous outcomes retain the same key.
- Added `tests/admin-wallet-adjustment-response-contract.test.ts`; not executed. Added migration `20261120130000_wallet_adjustment_idempotent_response_integrity.sql` to the clean-install forward manifest.
- Commits: `1319b0f9f9c4a5ba516d293ff3f1ef390fcfb5ee`, `1b4d6e7b33a36b0c8a42593f57dd1f30af1c1065`, `c66aa3e84c8b41fcd141e29bca8933b3b5125ec0`, `73225a2fac62fa34d619abccf8f12e2b000378f9`, `5e48e5cffc1d744f1fcddec3e991b091bd289923`.
- Current forward manifest count: 141; excluded timestamped entries: 16; three legacy/unversioned SQL files remain intentionally excluded. No database or runtime verification performed.

- Duplicate ID lifecycle response integrity is now checked end-to-end at the client boundary (identity, returned status, old status, and idempotent `changed` semantics); static source assertions added, not executed. Commits: `205898b1899c1a4337673472c953b6d0cb691698`, `5a718f1a649644c075c8e30a1613ec7ee3803609`.
- Main ID lifecycle response validation now checks success, exact member identity, requested status and linked Duplicate ID count before reporting success; static regression assertions added, not executed. Commits: `808bf9a9bcf6109837a320c5cb172f1ec0e77645`, `446f6afaf467e8ad6063abec809a383fb63fbb92`.
- Also corrected stale Admin Member Details copy that incorrectly labelled the implemented Main ID status / linked Duplicate ID lifecycle workflow as pending; added source-only copy assertions (not executed). Commits: `d6981da16c05ad09db2401023ae430c2c32705a1`, `0aa6c0dc3389342fbe4be5cd7aa0573ca4341f97`.
## Latest source development batch — Admin Main ID lifecycle contract

- Fixed a real UI/RPC mismatch: the Admin Main ID status form exposed Suspended but the client validation rejected it, while accepting unsupported `inactive`. Client validation now matches SQL's `active | suspended | closed` enum.
- Added static regression assertions to `tests/admin-main-member-status-mutation-safety.test.ts`; not executed.
- Commits: `432de61aa9103d0db85ef8a0552fbec5d6d5734f`, `3abb51231f118c1e38c29eb09d714f0f62861f53`.
- Continue with complete RPC/schema/authorization reconciliation and remaining source integration gaps. No runtime verification has been run.

## Latest source-only development batch — 2026-11-20 (Admin media recovery)

- Admin Product temporary image cleanup now survives page reloads through account-scoped browser storage, generated-path validation, a 100-entry cap and successful-retry removal.
- Admin Auction Submission Review now retains and retries failed private-source and temporary-public image cleanup by bucket/path. The queue is account-scoped, validated and persistent; ambiguous RPC outcomes still preserve potentially committed public media.
- Added source-only regression coverage: `tests/admin-product-media-cleanup-recovery.test.ts` and `tests/admin-auction-submission-media-cleanup-recovery.test.ts`. Neither was executed.
- Commits: `1a0d63be3f8edd4e561c6021cf5784949d9868b3`, `93451d08943fd914582a79253885f45eb6a93bf9`, `3e89f0ded12dfa34380d2ac4d6831a91f462e87f`, `03ce3269951399a89d8046ded353b108c7a34181`, `9cf833a6927d4124d285f88f54afedd90988221e`.
- No SQL, database, test, build, type-check or deployment operation was performed. No schema changes were required.

# BiddWorld — Current Source Development Status

This file keeps the historical audit notes below, but the opening status is the current source-of-truth summary. Continue only on `completion-work`. This is a source-development checkpoint, not a runtime verification or production-readiness claim.

## Implemented in the current source tree

- Responsive React + TypeScript + Vite marketplace, installable PWA foundation, authentication and member workspace.
- Member Main/Duplicate ID views, sponsor/team genealogy, package activation request workflow and receipt handling.
- Bid Wallet and Income Wallet UI, wallet funding history, withdrawal requests, transaction statements and Admin wallet/withdrawal review workflows.
- Configurable referral and Matrix plans, automated placement/commission source workflows, Admin configuration and member summaries.
- Auction lifecycle with Starting/Expected Price, optional end time, 48-hour target countdown, idempotent bid RPC, Admin auction management, item-award-only auction finalization and separate Fixed Bid winner-payment/delivery workflows.
- Refreshed Auction and Fixed Bid cards with one-line titles/subtitles, details dialogs, percentage progress and prominent bid actions; homepage Recent Winners cards and My Team terminology.
- Fixed-Amount Bid campaigns, member entries, Admin draw/settlement and reporting source; strict public catalogue parsing for campaign rules, progress and product gallery/details.
- Member OLX-style product and auction submissions, private image uploads, duplicate-pending product prevention, editable resubmission, Admin/Staff review, public gallery publication and keyset pagination; structured product fields are protected from free-form extras overrides.
- Admin member/sponsor/ID management, staff permission scopes, package/payment review, reports/CSV exports, audit logs, feature settings and delivery tracking.
- In-app notifications, member support tickets, workflow status updates and notification history/realtime validation.
- Source migrations for RLS, RPC authorization, idempotency, Storage access, audit logging, clean-install inventory and regression-contract coverage.

## Remaining source-development work

- Finish a complete frontend RPC-to-migration signature reconciliation, including every argument name/type, return shape, authorization claim and UI call site. Fix all mismatches as forward-only source migrations.
- Finish the cross-module schema and Storage dependency reconciliation for the clean-install forward chain; ensure every required table, column, index, trigger, RPC, bucket and policy is represented exactly once.
- Close any remaining Member/Admin workflow gaps discovered by source inspection, especially error/retry states, permissions, pagination boundaries, media cleanup and cross-module state refresh.
- Complete static regression-contract coverage for every newly corrected RPC/migration and every critical workflow.
- Reconcile all source documentation and completion records with the current branch head.

## Latest source-only development batch — 2026-11-20

- **Member Product/Auction media cleanup now survives page reloads:** failed image-object removals and definite-rejection upload cleanup paths are persisted in account-scoped browser storage, restored only for the signed-in account, constrained to that account's storage prefix, capped at 100 paths, and removed from the queue after successful retry. In-memory retry remains available if browser storage is unavailable. Added/extended `tests/member-submission-media-cleanup-recovery.test.ts`; source-only, not executed. Commits: Product retry `667205ff0512076556394ac6e455d9da8478f3a0`, Auction retry `36b5253e30615411d35750cca51c902ce269470e`, persistence Product `49ef130bbb0b76aac4f6f2308c791de3ccf6ba80`, Auction `fdbd78a5292fcf3297222140144a5e3cee523a75`, test `3ea16cb108394d964053faf209b2c0deba82771c`.


- **Member Product/Auction submission media recovery:** failed removal of replaced draft images and definitely rejected upload batches is now retained in an in-session cleanup queue in both member submission screens, with a visible Retry image cleanup action. This prevents a transient Storage deletion failure from silently losing the paths needed to retry. Ambiguous network/RPC outcomes are deliberately not deleted because the submission may already have committed. Added `tests/member-submission-media-cleanup-recovery.test.ts`; source-only, not executed.



- Fixed a real client/server idempotency mismatch: Referral and Matrix commission reversal replay responses (which omit commission_id only when `replayed=true`) are now accepted and accurately described; first-time responses still require the exact commission ID. Regression source test extended; not executed.


- Referral and Matrix commission Admin actions now validate complete server mutation results (requested activation/commission identity, success status, posted count or reversal status) before reporting success. Added source-only regression coverage; not executed.


- Admin Product image replacement/discard cleanup now retains failed temporary-object removals in a visible retry queue and clears stale image references after successful removal. Added source-only regression coverage; not executed. Persistent orphan inventory across page reloads remains a possible follow-up.

## Latest source-only reconciliation — 2026-11-20

- Member/Admin Product and Auction submission create/edit/review/history RPCs and all four bounded moderation queue pagination contracts were compared between frontend call sites and SQL migrations. No mismatch was found in this scoped set; regression source coverage was added in `tests/member-admin-submission-rpc-contracts.test.ts` and was not executed.
- This does not close the project-wide RPC/schema/RLS/Storage reconciliation. Overall source development remains 95% provisional.

## Verification deliberately deferred until source development reaches 100%

- Do not run the final unit-test suite, TypeScript/build pipeline, database replay, integration tests, browser/mobile E2E or user acceptance testing as a substitute for unfinished development.
- Do not apply migrations to either Supabase project during this development-only phase. Production remains untouched; TEST is reserved for the later approved functional-testing phase.
- Do not claim a module is functionally verified solely because its UI or source migration exists.

## External integrations not represented as completed source functionality

- No external payment gateway or bank payout provider is connected.
- No paid email/SMS/push delivery provider is connected; the implemented in-app inbox is separate from those external delivery channels.

## Current checkpoint

- Branch: `completion-work`
- Current migration inventory: static source-tree accounting confirms 162 SQL files = 143 forward manifest entries + 16 excluded timestamped entries + 3 legacy/unversioned SQL files; no timestamped file is missing, stale or duplicated in the manifests. Migration dependency/order and SQL compatibility review remain pending.
- Latest auction source repairs: `20261119680000_admin_auction_submission_expected_price_review.sql`, `20261119690000_prevent_duplicate_pending_auction_submissions.sql`, and `20261120120000_fix_recent_auction_winner_profile_join.sql` (canonical `owner_user_id` join for Recent Winners), plus strict client-side Recent Winners response validation.
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

## 2026-11-20 — Member team terminology

- Updated the member navigation label from **My Network** to **My Team**, changed the section heading to **My Team**, and renamed **My MLM Dashboard** to **My Team Dashboard**. Updated administrator-facing overview diagnostics to use Team terminology.
- Internal RPC names and database identifiers were intentionally preserved for compatibility; the change is to user-facing wording only.
- Commit: `f405d2ae85038b204cc769cb86f75d94560cfdb1`.


## 2026-11-20 — Admin Auction submission media path and retry hardening

- Tightened Admin Auction queue validation so every private image path must match the submitting member UUID folder and the exact UUID-based JPG/PNG/WebP object naming used by the member uploader. Malformed or cross-member paths are rejected before signed-URL generation.
- Tightened persisted cleanup recovery by validating private and public paths against their respective bucket contracts, including the SQL-approved public auction image filename format. Invalid persisted entries are discarded rather than passed to Storage deletion.
- Added a ref-backed single-flight lock for cleanup retries so rapid duplicate taps cannot issue overlapping delete requests or race the review action.
- Extended `tests/admin-auction-submission-media-cleanup-recovery.test.ts` with source-only assertions. No tests/build/type-check were executed.
- No SQL migration was needed; no database was accessed, no Preview deployment was created, and `main` was not modified. Development remains 95% provisional.


## 2026-11-20 — Admin withdrawal queue response validation

- Admin withdrawal first-page and Load More responses now share one strict parser. It validates UUID request/reviewer identities, bounded member/name/reason fields, positive bounded numeric amounts, ISO currency, allowed lifecycle statuses, timestamps, and the exact supported UPI / Bank Transfer payout-detail shape before records reach the review UI.
- Subsequent pages now reject any overlap with already-loaded request IDs instead of silently filtering duplicate rows and advancing the offset. Existing refresh-generation and single-flight guards remain.
- Added source-only assertions in `tests/admin-withdrawal-pagination-hardening.test.ts`; not executed. No SQL migration required because this closes a client response-integrity gap against the existing withdrawal RPC contract.
