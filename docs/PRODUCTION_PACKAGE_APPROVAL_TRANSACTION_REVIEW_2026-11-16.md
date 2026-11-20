# Package approval transaction and live guard reconciliation — 2026-11-16

## Production read-only findings
Project: BiddWorld-Production (`hbqatszyzqobgtauyuzy`). Queries were SELECT/catalogue reads only.

### Live Admin approval function
The live `public.admin_review_package_activation(uuid,boolean)`:
1. checks authenticated Admin app_metadata;
2. locks the pending package activation row;
3. locks its Main ID row and verifies it is a Main ID;
4. on approval, locks the Bid Wallet row;
5. updates the Bid Wallet balance;
6. inserts a `package_activation_credit` wallet ledger row with a deterministic activation-scoped idempotency key;
7. updates the activation to `approved/active` and writes an audit log.

The function body executes as one PostgreSQL function call/transaction. A raised exception from a BEFORE trigger or later statement aborts the call and rolls back earlier balance/ledger/activation changes. The source-only financial interlock is designed to exploit this transaction boundary: it rejects the wallet ledger insert and/or activation status update before commit. This has not been integration-tested in a disposable TEST project.

### Actual live triggers on financial tables
The Production trigger inventory currently shows `private.enforce_feature_gate()` on:
- `package_activations` (insert and activation_status update);
- `wallet_transactions` (insert);
- `bids`;
- `referral_commissions`;
- `withdrawal_requests`;
- `winning_item_payments`.

The Production inventory does **not** show `private.require_financial_model_approval()` guards on package activation or wallet ledger writes, nor the append-only wallet-ledger mutation trigger from the source financial lockdown migration.

The live `private.enforce_feature_gate()` checks the relevant feature switch, but it does not check `financial_model_approved`. Therefore the existing trigger does not provide the owner-approval control required for financial launch.

### Live feature-setting snapshot
The latest read-only snapshot returned:
- `package_activations_enabled=true`
- `bid_wallet_enabled=true`
- `income_wallet_enabled=true`
- `bidding_enabled=false`
- `fixed_bid_enabled=false`
- `referral_commissions_enabled=false`
- `withdrawals_enabled=false`
- `winning_payment_enabled=false`
- no `financial_model_approved` row was returned.

This is a serious discrepancy from the source branch's intended financial lockdown. The branch UI lock does not change these Production values and cannot stop direct authenticated RPC calls.

## Branch migration chain assessment
- `20261116000000_financial_approval_guard.sql` installs a first package approval guard.
- `20261116080000_financial_activity_lockdown.sql` replaces it with broader table guards, forces multiple financial feature switches false, restricts Admin feature enabling until owner approval, and makes wallet ledger rows append-only.
- `20261116200000_lock_package_activation_submission.sql` adds the same owner-approval + feature-switch gate at package request submission, so direct authenticated submission cannot bypass the UI lock.
- `20261116150000_enforce_inactive_signup_until_verified.sql` changes new signup profile/Main ID creation to inactive.
- None of these source migrations has been applied to Production in this audit.

## Safe next step
Do not manually toggle settings as a substitute for the database guard. Do not approve pending package requests. Before any Production rollout:
1. reconcile the complete migration chain and all trigger names/order with the live schema;
2. run the exact migration sequence in a disposable TEST Supabase project;
3. test Admin approve and reject, feature flags false/missing/true, zero and non-zero Bid Wallet credit, direct RPC bypass, transaction rollback after each guard failure, replay/concurrent Admin approval, and ledger immutability;
4. confirm all tests pass and get explicit owner approval before any Production DDL/DML.

No Production writes, financial actions, Auth user creation or member status changes were performed.
