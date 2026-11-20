# BiddWorld Production RPC lifecycle and retry findings — 2026-11-16

## Audit provenance

This supplements `PRODUCTION_RPC_RLS_TRIGGER_AUDIT_2026-11-16.md`. It is based on read-only inspection of live Production function bodies, catalog constraints/indexes, RLS flags and source migration SQL. No Production state was changed.

## Additional confirmed findings

### A. Inactive signup versus package request is not aligned in Production

The source migration `20261115220000_inactive_until_verified_package_activation.sql` creates new Main IDs as inactive and intentionally allows those inactive IDs to submit a package activation request, so a payment can be reviewed before activation.

The live Production `private.submit_package_activation(uuid,text)` instead selects the caller's Main ID with `status='active'`. This means an inactive newly registered member cannot use the live package request path as designed by the branch. This is a concrete onboarding contract mismatch, not merely a UI issue.

### B. Bid retry is not idempotent across repeated client requests

The live `private.place_bid(uuid)` generates `gen_random_uuid()` inside each call and uses that new value for the bid and ledger keys. Unique indexes exist on `bids.idempotency_key` and `wallet_transactions.idempotency_key`, but a repeated client request generates a different key each time. The unique constraints prevent duplicate key values, not duplicate logical requests. A future compatible RPC must accept/derive a stable per-request idempotency identity and replay the original result safely.

### C. Package payment reference duplicate protection exists

Production has unique indexes on `lower(payment_reference)` and `lower(btrim(payment_reference))` for non-empty values. These constraints provide database-level duplicate protection beyond the function's pre-check. There are two overlapping indexes with slightly different normalization expressions. Do not drop or consolidate them until usage, existing data and source migration history are reviewed.

### D. Withdrawal checks in the live RPC are incomplete against the branch's intended controls

The live `member_create_withdrawal_request(numeric,jsonb)`:
- requires an authenticated user;
- requires a positive amount rounded to two decimals;
- bounds the payout JSON object length;
- checks the withdrawals feature setting;
- resolves the profile's Main ID;
- locks and checks the Income Wallet balance;
- prevents another open request for the same member.

The live definition does not verify that the Main ID is active and does not enforce configured minimum/maximum withdrawal amounts. The source migration `20261116140000_require_active_main_id_for_withdrawals.sql` adds the active Main ID ownership check but is not applied. Withdrawals are disabled in current Production settings; keep them disabled.

The live request function does not reserve/debit the wallet at request time. That may be an intentional approval model, but it creates a balance race if multiple requests or other spending paths are later enabled. A future approved design must explicitly define reservation, available balance, rejection/release, payout and reconciliation semantics.

### E. RLS is enabled but not forced

All 21 public tables have `relrowsecurity=true`; all report `relforcerowsecurity=false`. This is not automatically a defect because table owners and SECURITY DEFINER owners may bypass RLS by design, but it must be explicitly accounted for in the threat model and tested. Do not globally enable FORCE RLS without disposable integration tests and review of trusted owner/service-role behavior.

### F. Public policies and write-path architecture

The 20 enumerated public policies are SELECT-only. Authenticated direct table grants observed are SELECT-only on exposed business tables; service_role has broad privileges. This supports an RPC-mediated write design, but every SECURITY DEFINER routine still requires body-level authorization and state-transition review.

## Next required disposable tests

1. Sign up a fresh user; confirm new Main ID is inactive; verify they can submit a package request without being active; verify no activation or credit occurs before Admin review.
2. Repeat the same bid request using one stable request key; confirm exactly one bid and one debit are recorded and the same response is replayed.
3. Submit the same normalized payment reference concurrently from two accounts; confirm exactly one request can be recorded.
4. Attempt withdrawal as an inactive Main ID, with insufficient funds, below/above configured limits, and with concurrent requests; verify no balance race or payout data disclosure.
5. Test cross-member reads and unauthorized RPC execution for member, support, finance and admin JWT roles.
6. Test each owner financial interlock trigger with `financial_model_approved=false`, including direct table writes through privileged test roles, in a disposable database.

## Status

These are source/Production reconciliation findings and test specifications. No Production migrations or settings were changed. No financial feature is approved for activation.
