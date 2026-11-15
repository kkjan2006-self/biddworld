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
