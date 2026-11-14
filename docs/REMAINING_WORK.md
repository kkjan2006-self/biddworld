# Remaining work before production

The repository is a working development baseline, not a completed financial marketplace. These items are intentionally not enabled:

- Trusted administrator provisioning and complete RBAC. Sponsor lookup, default-sponsor configuration, member sponsor correction and audit logging are implemented as secured RPCs; the first administrator/Main ID still needs to be provisioned and selected as the default sponsor.
- Package payment reference/receipt submission, duplicate-reference prevention, verification, activation and Bid Wallet credit.
- Referral commission engine with versioned plan snapshots, eligibility and configurable levels.
- Duplicate member IDs, admin enable switch, concurrency-safe team placement and Main-ID wallet attribution.
- Fixed-bid entry, tie, winner and settlement rules (must be supplied by the owner).
- Auction close, winner/tie/extension/cancellation rules and settlement.
- Winning item payment from Income Wallet and delivery updates.
- Withdrawals: enable switch, min/max, approval, payout integration, rejection and refund.
- Notifications, searchable admin reports, CSV/PDF export and audit-log UI.
- Storage bucket policies, rate limits, abuse prevention, monitoring, backups and privacy/terms/legal review.
- Full unit, integration and browser E2E coverage, security advisor review and independent security review.

Do not invent unresolved business rules or enable financial features before server-side implementation and testing.
