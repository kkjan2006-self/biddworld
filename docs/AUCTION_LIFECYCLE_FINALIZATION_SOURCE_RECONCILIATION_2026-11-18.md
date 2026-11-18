# Auction lifecycle and winner finalization source reconciliation — 2026-11-18

## Scope

Reviewed `20261118110000_auction_lifecycle_winner_settlement.sql` and the final Fixed Bid draw definition in `20261118340000_secure_fixed_bid_random_draw.sql` after the refund-path correction.

## Auction lifecycle findings

- `admin_set_auction_status(uuid,text)` is Admin-role gated, locks the auction row, validates the requested state against the supported values, and requires a published linked product plus valid schedule before scheduling/opening.
- Live transition is constrained to the configured time window and checks the platform `bidding_enabled` setting.
- End transition is rejected before the configured end timestamp.
- Cancellation is blocked after a paid winner-item payment exists. It locks accepted bids and their wallet accounts, validates the original debit ledger against member, wallet type, transaction type, reference and amount, and posts idempotent refunds before voiding the bid.
- The cancellation loop and status update execute within one function transaction; a ledger mismatch raises and rolls back the operation.

## Auction finalization findings

- `admin_finalize_auction(uuid)` requires Admin role, locks the auction row, and requires ended status plus elapsed end timestamp.
- Winner selection is deterministic: highest accepted bid, then earliest creation time, then bid UUID as tie-breaker.
- A unique result row per auction and the replay branch prevent a second winner result from being created on repeated calls.
- A pending winner-item payment is created only when an accepted winning bid exists; no-bid auctions receive a result row with null winner fields.
- Finalization and pending-payment creation occur in the same transaction.

## Fixed Bid draw findings

- Winner ranking uses SHA-256 scores from a per-draw UUID seed and entry UUID, with stable tie-breaking by member UUID.
- At most one winning entry per eligible active Main member is selected; eligibility joins the active Main ID to its active owner profile.
- The corrected non-winner refund predicate excludes only winning entry IDs, so additional losing entries from a winning member are not accidentally skipped.
- Refund source debits are checked against the original entry owner, wallet type, transaction metadata, idempotency key and recorded entry amount before idempotent credits are posted.

## Remaining verification

- Frontend Admin status/finalize actions and member winner-payment presentation still require full repository-wide call-site reconciliation.
- Confirm the auction bid creation RPC uses the same accepted status, idempotency-key suffixes, wallet debit types and reference contract consumed by cancellation.
- Confirm the final migration order and runtime row-lock behavior in isolated TEST during the consolidated final testing phase.
- No tests, build, migration replay, Production writes or TEST writes were performed in this source review.


## Follow-up: auction bid creation eligibility alignment — 2026-11-18

Source review of `20261116190000_bid_request_idempotency.sql` and the public `src/App.tsx` bid call confirmed that the client sends both named arguments (`p_auction_id`, `p_idempotency_key`) and the authenticated wrapper exposes the matching `public.place_bid(uuid,text)` signature. The bid debit ledger uses the exact `:bid` / `:income` idempotency suffixes and `auction_bid` transaction type / `auction` reference consumed by auction cancellation refunds.

A concrete eligibility inconsistency was found: Fixed Bid entry requires both an active Main ID and its owning active profile, while auction bid creation checked only the Main ID. This could allow an inactive profile whose Main ID remained active to place an auction bid despite the member-facing account lock. Added source-only migration `20261118410000_require_active_profile_for_auction_bids.sql` to join the Main ID to its owning profile and require `profiles.main_member_id` ownership plus `profiles.status='active'`. Existing idempotency, wallet-first debit, ledger metadata, public RPC signature and grants are preserved.

Added the migration as forward candidate 63. The manifest now contains 63 ordered forward files; with 16 excluded timestamped files and 3 legacy/unversioned files, the migration directory inventory is 82 SQL files (79 timestamped + 3 legacy). No tests/build were run, no migration was replayed, and neither Production nor TEST was modified. Runtime validation remains deferred to the consolidated final testing phase.


## Follow-up: active winner eligibility and payment replay integrity — 2026-11-18

Reconciled the Admin auction UI calls with `admin_set_auction_status(uuid,text)` and `admin_finalize_auction(uuid)`: the named arguments match, Admin-only authorization is enforced in SQL, and the UI consumes only the finalization fields actually returned (`winner_member_id`, `winning_amount`). The member Account calls the shared `member_pay_winning_item_payment(uuid,text)` with the exact named arguments and retains the same request key after an uncertain response. The server debits only the Income Wallet, locks the payment and wallet rows, writes a matching ledger entry, and marks the payment paid atomically.

Found a substantive edge case: auction finalization previously chose the highest accepted bid without rechecking the winner's current Main ID and owning Profile status. A member suspended after bidding could therefore become the winner, while the member payment RPC correctly refuses inactive profiles. Added `20261118420000_active_winner_eligibility_and_payment_replay_guard.sql`: finalization now selects only an active Main ID with its canonical active owning Profile; it takes the same `biddworld.member_id_graph_mutation` advisory lock as the Admin Main-ID lifecycle RPC before locking the auction, serializing the eligibility snapshot against concurrent suspension/closure. Highest bid / earliest creation / UUID tie-break ordering is preserved.

The same migration hardens both shared and legacy Fixed Bid winner-payment RPC replay paths: a matching idempotency ledger row is accepted as a replay only when the payment record is already `paid` with a non-null `paid_at`; a ledger/payment-state mismatch now fails closed instead of reporting success. Existing Income-Wallet-only debit, request-key format, ledger fields, public signatures and authenticated EXECUTE grants are preserved.

Added the migration as forward candidate 64 and updated the clean-install README. Current SQL inventory: 83 files (80 timestamped + 3 legacy), partitioned as 64 forward + 16 excluded timestamped. Source-only review; no tests/builds, no TEST replay, and no Production or TEST database writes. Runtime lock-order, RPC and ledger behavior remain for the consolidated final testing phase.
