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
