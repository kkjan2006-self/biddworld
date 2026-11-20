# Production bidding, activation and referral RPC review — 2026-11-16

## Scope and safety
- Production: `BiddWorld-Production`, project ref `hbqatszyzqobgtauyuzy`, PostgreSQL 17.11.
- Read-only inspection of live function bodies, indexes and triggers.
- No Production writes, migrations, settings, wallet transactions, bids, referrals or member records were changed.

## Auction bidding — live `private.place_bid(uuid)`
Positive controls observed:
- Requires authenticated user and `bidding_enabled=true`.
- Requires an active Main ID owned by the authenticated user.
- Locks the auction row and checks live status and time window.
- Computes next bid as current price plus minimum increment.
- Locks Bid Wallet then Income Wallet, deducts Bid Wallet first and Income Wallet for the remainder.
- Rejects insufficient combined balance.
- Updates both balances, inserts corresponding wallet ledger debits and accepted bid, then updates auction price in the same database transaction.
- Live trigger `enforce_bid_wallet_and_bidding_features` also gates bid inserts; Production currently has `bidding_enabled=false`.

Important retry/idempotency gap:
- The RPC generates `gen_random_uuid()` internally for every invocation; callers cannot supply a stable request/idempotency key.
- A network timeout followed by client retry is treated as a new bid, not a replay of the original request. The unique `bids.idempotency_key` and `wallet_transactions.idempotency_key` indexes do not solve this because each retry gets a fresh random key.
- Auction row locking serializes competing bids but does not prevent a repeated user request from charging twice.
- Required fix: accept a validated client-generated idempotency key, persist and scope it to the authenticated member/action, return the original result on retry, and ensure all ledger writes use deterministic keys derived from that request. Keep the lock and atomic transaction.

## Package activation submission
Live `private.submit_package_activation(uuid,text)`:
- Requires authenticated user and an active Main ID.
- Validates payment reference syntax and length.
- Locks the Main ID and selected active package.
- Checks for a duplicate payment reference before inserting a pending activation.
- Live database has unique case-insensitive trimmed payment-reference indexes, which provide a final concurrency guard.
- Live unique `(member_id, activation_number)` also protects activation numbering.
- Submission itself does not credit a wallet; it creates a pending request and audit event.
- Approval remains unsafe for Production use until the owner-approved financial interlock is installed and verified. The earlier report documents the approval RPC's direct Bid Wallet credit.

## Referral commission execution
- The live catalogue contains Admin referral-plan listing and draft creation, and the `referral_commissions` table has a unique key on `(package_activation_id, level_number, beneficiary_member_id)`.
- No public/private commission calculation-and-credit RPC was found in the inspected live function catalogue. This is not proof no alternate privileged execution path exists; table grants, triggers and all private routines require a complete separate audit.
- Live trigger `enforce_referral_commission_feature` gates referral commission inserts/status updates. Production setting `referral_commissions_enabled=false` at the previously captured settings snapshot.
- The unique index is useful duplicate protection but does not itself prove eligibility, correct level traversal, Main-ID credit routing, or wallet ledger atomicity.
- Do not enable commissions or issue credits.

## Relevant live triggers
- `bids`: `enforce_bid_wallet_and_bidding_features` before insert.
- `package_activations`: `enforce_package_activation_feature` before insert or activation_status update.
- `referral_commissions`: `enforce_referral_commission_feature` before insert or status update.
- `wallet_transactions`: `enforce_package_wallet_credit_feature` before insert.
- Earlier review found these feature gates do not provide the missing trusted owner-approval interlock for package approval / financial activation.

## Required next implementation work
1. Add stable request idempotency to auction bid RPC and test timeout/retry behavior.
2. Add an isolated test project and concurrency tests for simultaneous bids, insufficient balances and duplicate requests.
3. Trace all private routines, table grants, triggers and any background workers for referral commission posting; implement only after full audit.
4. Ensure commission creation and Income Wallet ledger credit are atomic, idempotent, eligibility-checked, and routed from duplicate IDs to Main ID where required.
5. Reconcile and deploy the financial approval guard only through an approved, schema-aware Production rollout.
6. Keep bidding, referral commissions, package activation and other financial features disabled until audited and tested.

## Completion boundary
This is a limited read-only RPC/index/trigger review, not a complete security audit or launch certification. No Production state was changed.
