# Production readiness checklist

This ZIP is a runnable frontend + fresh-database baseline. It is **not yet a complete production financial platform**. The original business requirements contain decisions that must not be guessed. Financial operations remain disabled by default.

## Included
- Responsive React + TypeScript + Vite marketplace interface.
- Supabase email/password sign-up and sign-in.
- Auction and wallet read UI.
- Server RPC call for auction bidding; database-side row lock and Bid Wallet-first debit order.
- Fresh-project SQL schema baseline, signup profile/wallet trigger, RLS read policies, client write revocation.
- `.env.example`, setup guide and build scripts.

## Still required before launch
1. Admin provisioning with a trusted, non-self-service role assignment process; admin console and RBAC.
2. Package activation payment workflow: receipt upload, UTR/reference validation, admin verification, idempotent activation and Bid Wallet credit.
3. Referral engine: versioned plan snapshots, eligibility, unlimited configured levels, commission approval and posting.
4. Duplicate IDs: admin enable switch, concurrency-safe team placement, agreed tree traversal and Main-ID wallet attribution.
5. Fixed-bid module: owner-defined entry, tie, winner and settlement rules.
6. Auction close and winner selection: owner-defined tie/extension/cancellation rules and settlement process.
7. Winning item payment from Income Wallet, delivery status and notifications.
8. Withdrawals: owner-defined min/max, enable switch, payout integration, review, rejection and refund workflow.
9. Admin reports, CSV/PDF export, audit-log interface, notifications and support tools.
10. Storage buckets and policies, rate limits, abuse prevention, monitoring, backups, privacy/terms/legal review.
11. Unit/integration/E2E tests, security advisor review and independent penetration test.

## Explicitly not implemented
- No payment gateway or actual money transfer.
- No withdrawal payout.
- No referral commission posting.
- No duplicate-ID generation/tree-placement.
- No fixed-bid winner algorithm.
- No auction winner settlement.
- No admin role assignment UI.

Do not enable `app_settings.bidding_enabled` until the backend has been reviewed and tested with real transaction scenarios. Do not expose Supabase service-role/secret keys in the browser.
