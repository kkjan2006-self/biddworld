# Withdrawal Lifecycle — Source Review (2026-11-16)

## Implemented safeguards confirmed in source

- The member request RPC requires an authenticated caller and a caller-owned active Main ID.
- It checks the withdrawals_enabled feature switch and checks the Income Wallet balance under a row lock.
- It prevents a second open request while an earlier request is pending, approved, or processing.
- Member history returns only the payout method label, not UPI ID or bank account number.
- The financial approval trigger blocks withdrawal request inserts and status transitions to approved, processing, or paid until financial_model_approved is true.
- The Admin withdrawal queue is deliberately read-only and does not show payout credentials.

## Remaining work before this module can be called complete

1. Define whether a request reserves funds immediately or whether funds are reserved only on approval. Implement an atomic reservation ledger and release path for rejection/cancellation; do not infer this business rule.
2. Define owner-approved minimum and maximum withdrawal amounts, daily limits, fees, and payout verification requirements.
3. Implement an authenticated Admin review workflow with separate approve/reject permissions, idempotent transitions, audit logging, and race-safe row locking.
4. Implement settlement only after approved payment-provider/bank reconciliation; never mark paid based only on an Admin button click.
5. Add disposable-database integration tests for concurrent requests, insufficient available balance, duplicate submissions, rejection release, approval, settlement, and replay.
6. Reconcile the source schema and migrations against Production before any deployment. Do not replay the source migration directory wholesale.

## Safety decision

No new withdrawal approval, payout, wallet debit, or reservation behavior is enabled by this review. The existing financial interlock remains in place. Production Supabase was not modified.
