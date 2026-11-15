# Production readiness checklist

BiddWorld is a runnable frontend and development database baseline. It is **not yet a complete production financial platform**. GitHub Actions CI and the GitHub Pages preview currently pass for the latest commit; this validates the repository build/tests and deployment workflow, not production database readiness.

## Included in the repository

- Responsive React + TypeScript + Vite marketplace interface.
- Supabase email/password sign-up and sign-in.
- Auction and wallet read UI; bidding calls a server-side RPC with auction/wallet locking and Bid Wallet-first debit logic.
- Admin dashboard with member search, sponsor management, MLM overview and member structure reporting.
- Package payment reference/UTR submission UI with normalization and pending status; admin pending-activation review UI.
- Admin audit-log RPC/UI with search, filtering and CSV export.
- CSV formula-injection protection and unit tests for core helpers.
- SQL baseline, RLS policies and client-side use of the Supabase publishable/anon key.

## Database deployment status

- The package activation/admin review migration has been rollback-tested as SQL but **has not been applied to the production Supabase project**.
- Do not treat package activation, wallet credit, or audit RPCs as live until the migration is safely applied and verified against the intended production project.
- The first trusted administrator and default sponsor/Main ID still require secure provisioning.
- Keep service-role/secret keys out of frontend code and environment variables exposed to Vite.

## Still required before launch

1. Apply and verify pending migrations in staging, then production; review SECURITY DEFINER authorization, grants, RLS, idempotency and ledger writes.
2. Provision the first administrator through a trusted out-of-band process; no admin role assignment UI exists.
3. Complete receipt upload/storage policies if receipts are required beyond a payment reference/UTR.
4. Define and implement referral plan eligibility, trigger timing, version snapshots, approval and atomic commission posting.
5. Define duplicate-ID generation, admin toggle, placement traversal/slots and concurrency-safe Main-ID attribution.
6. Obtain owner-defined fixed-bid entry, tie, winner and settlement rules before implementation.
7. Obtain owner-defined auction close, tie, extension, cancellation and settlement rules before implementation.
8. Implement Income Wallet winning-item payment, delivery updates and notifications.
9. Define withdrawals (enable switch, min/max, approval/rejection/refund) and integrate a real payout provider; none is currently implemented.
10. Add rate limits, abuse prevention, monitoring, backups, privacy/terms/legal review and support workflows.
11. Expand unit/integration/browser E2E tests and complete independent security review.

## Explicitly not implemented

- No payment gateway or actual money transfer.
- No withdrawal payout.
- No automatic referral commission posting.
- No duplicate-ID generation or team placement.
- No fixed-bid winner algorithm or settlement.
- No auction winner settlement.
- No admin role assignment UI.

Do not enable bidding in production until backend authorization and real transaction scenarios have been reviewed and tested. Unknown business rules must remain disabled rather than being guessed.
