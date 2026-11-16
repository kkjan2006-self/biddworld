# Bid idempotency migration compatibility review — 2026-11-16

## Scope
Compared the source-only `20261116190000_bid_request_idempotency.sql` and its browser call site against read-only Production table/function/index/constraint definitions. No Production data or schema was changed; no bid was placed.

## Verified Production compatibility
The live Production catalogue confirms the columns referenced by the new migration exist:
- `auctions`: id, status, starts_at, ends_at, current_price, minimum_increment, updated_at.
- `member_ids`: owner_user_id, id_type, status, created_at.
- `wallet_accounts`: member_id, wallet_type, balance, updated_at.
- `wallet_transactions`: wallet_account_id, member_id, transaction_type, direction, amount, balance_after, reference_type, reference_id, idempotency_key, description.
- `bids`: auction_id, member_id, bid_amount, bid_wallet_debit, income_wallet_debit, status, idempotency_key.

Production already has unique indexes/constraints on `bids.idempotency_key` and `wallet_transactions.idempotency_key`. The source migration's stable key and `:bid` / `:income` suffixes align with the wallet ledger unique key. The live auction status check includes `live`; bid status check includes `accepted`.

The existing Production private/public `place_bid(uuid)` functions still generate a fresh random key inside the server for every call, confirming the retry gap remains live. The source migration drops those one-argument signatures and creates the keyed `(uuid,text)` signature. Production has not received that migration.

## Browser retry behavior
The branch UI creates one cryptographically random key per auction and retains it in a component ref until a successful RPC response. Network exceptions preserve the key and show a safe-retry message. On success, the key is cleared. RPC-returned errors also retain the key, which is safe because failed PostgreSQL transactions do not persist a bid or wallet debit.

## Important limits / rollout blockers
1. Existing Vitest coverage is source-text contract testing. It does not execute the PL/pgSQL migration against PostgreSQL, simulate concurrent calls, or verify actual transaction rollback.
2. No disposable Supabase TEST project was available/used in this audit. Do not claim end-to-end idempotency is tested.
3. Before rollout, test in TEST: first call debit exactly once; same-key replay returns same bid and does not debit; same key with another member/auction rejects; two concurrent same-key calls produce one bid and one debit; distinct keys serialize correctly on auction price; insufficient funds leaves both balances/ledger/bids unchanged; disabled bidding rejects new keys; replay of an already accepted key remains read-only even after the auction closes or feature is disabled.
4. Confirm any downstream caller uses the two-argument RPC and no external clients depend on the old signature.
5. Reconcile the existing unique constraints and migration dependencies again immediately before rollout.

## Security and financial safety
The live `bidding_enabled` setting was previously observed false. Keep it false. The source migration is not a permission to enable bidding and must not be applied to Production without explicit owner approval and complete TEST validation.
