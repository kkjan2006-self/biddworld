# Financial workflow integration audit — 2026-11-17

## Scope and method

Bulk source review of wallet balance/ledger handling, auction bidding, package activation, referral-plan configuration, withdrawal requests, financial feature gates, and current frontend-to-Production RPC compatibility. This is static source inspection only. No Supabase database was queried or modified in this batch.

## Implemented in branch source

### Wallet and auction bidding
- `private.place_bid(uuid,text)` requires an authenticated caller with an active Main ID.
- A transaction-scoped advisory lock serializes reuse of the same idempotency key; replays for the same member/auction return the original bid, while reuse for a different request is rejected.
- Auction row and both wallet rows are locked before balances change.
- Debit order is Bid Wallet first, then Income Wallet for the remainder.
- Insufficient combined funds raise an exception before a bid is inserted.
- Balance updates, wallet ledger entries, bid insertion, and auction current-price update are within the same PostgreSQL RPC transaction.
- The public two-argument RPC is authenticated-only; the private implementation revokes client execution.
- The later financial lockdown migration adds a wallet-ledger insert guard and rejects wallet ledger UPDATE/DELETE.

### Package activation
- Request submission is pending-only and does not write wallet balances or ledger rows.
- The final submission function checks both the package activation feature flag and trusted owner-approval setting, defaulting missing settings to false.
- Admin review locks the activation, Main ID, and Bid Wallet; writes the balance and a stable activation-specific ledger idempotency key; then approves the activation and writes an audit record in the same transaction.
- Database triggers independently guard activation approval and wallet ledger insertion.
- The final lockdown migration sets the financial feature switches to false on rollout and blocks ordinary Admin re-enablement unless the trusted approval setting is true.

### Referral and withdrawals
- Admin can save versioned referral-plan drafts with configurable levels and fixed/percentage reward rules. Drafts are restricted to inactive packages and remain inactive.
- Withdrawal request RPC requires the caller's active Main ID, uses the Income Wallet only, locks the wallet row, checks available balance and open requests, and creates a pending request.
- Financial interlock source covers credited referral commissions, withdrawal requests/status progression and winner-payment settlement.

## Material gaps and risks found

1. **No commission calculation/posting engine found.** The branch contains referral plan draft configuration and referral dashboard/reporting, but no complete automatic calculation, eligibility snapshot, posting, reversal/refund, or plan-version selection engine. The completion register also lists these as pending.
2. **Main ID lifecycle status is not constrained consistently by package activation.** The final submission RPC looks up the caller's Main ID without restricting its status. The Admin approval RPC verifies only that the target is a Main ID, not that its status is `inactive` or `active`. A suspended or closed Main ID can therefore reach the pending/approval path if the feature interlocks are deliberately opened.
3. **Activation trigger can produce mismatched status pairs.** It promotes a Main ID only from `inactive`, and independently promotes the owning Profile only from `inactive`. It does not assert that both records were in an allowed matching state before approval or that both end in the same state.
4. **Fixed Bid and winner settlement are not end-to-end complete.** The financial interlock protects Fixed Bid inserts and winner-payment settlement, but the inspected Admin auction migration is draft management. This audit did not find a complete verified fixed-bid debit/winner selection/settlement lifecycle.
5. **Frontend Production contract mismatch remains.** The current Production RPC inventory documents the deployed one-argument `place_bid(uuid)` while the branch frontend expects `place_bid(uuid,text)`. The frontend correctly refuses an unsafe fallback that would discard idempotency. The branch migration remains unapplied to Production.
6. **No live transactional verification is available.** There is no separate disposable Supabase test project configured in the known project state. Static tests cannot prove actual PostgreSQL locking, trigger ordering, RLS, or rollback behavior.

## Recommended implementation sequence

- Define the permitted Main ID/Profile status pairs for package requests and approvals (new inactive account versus active top-up; suspended/closed must not be silently reactivated).
- Implement a consistency-checked activation transition and regression tests once that status policy is explicit.
- Build the referral commission engine as an independently versioned, idempotent, ledger-backed server-side workflow, including eligibility snapshots and reversals.
- Complete Fixed Bid entry, winner selection, and settlement as a single tested lifecycle.
- Reconcile the deployed Production RPC signatures against the branch migrations only after disposable-project integration tests.
- Run database integration tests for concurrent bid replay, insufficient-funds rollback, concurrent package approval, duplicate payment references, withdrawal race conditions, and financial-trigger rollback.

## Data and deployment boundary

All findings refer to branch source and existing project documentation. No migration was applied. No Production setting, schema, account, package activation, wallet balance, ledger row, commission, bid, withdrawal, or winner-payment row was changed. Do not describe the source interlocks as active in Production; they are committed source code only.
