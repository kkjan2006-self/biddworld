# Member Main-ID lifecycle concurrency review — financial actions — 2026-11-18

## Scope and checkpoint

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Starting HEAD: `52110d08561c1975470d056172368f4216135aab`
- Protected `main`: `415364b71534c7fc31d6c0928dd8395e10cbd94f` (unchanged)
- Production `hbqatszyzqobgtauyuzy`: read-only
- TEST `yoaauthwejdgaevfvwpo`: untouched

## Shared lifecycle contract

The final Admin Main-ID lifecycle RPC in `20261118430000_serialize_auction_bid_member_eligibility.sql` obtains a per-Main-ID transaction advisory lock:

`hashtextextended('biddworld.main_member_lifecycle:' || main_member_id::text, 0)`

It acquires that lock before changing Main ID and Profile statuses. Auction bid placement obtains the same lock and rechecks the authenticated user's Main ID/Profile status after waiting.

## Evidence-based findings

Four member RPCs performed an active Main-ID/Profile check but did not acquire the shared lock or recheck after waiting:

| RPC | Existing active check | Consequence without shared serialization |
|---|---|---|
| `member_join_fixed_bid_campaign(uuid,text)` | Active Main ID + Profile before campaign lock | Fixed Bid entry and wallet debits could race with Admin suspension/closure |
| `member_create_withdrawal_request(numeric,jsonb)` | Active Profile/Main ID before Income Wallet lock | A withdrawal request could be created after a concurrent status change |
| `member_pay_winning_item_payment(uuid,text)` | Active Profile/Main ID before payment lock | Income Wallet debit/payment settlement could race with suspension/closure |
| `member_pay_fixed_bid_winning_payment(uuid,text)` | Active Profile/Main ID before payment lock | Fixed Bid winner debit/payment settlement could race with suspension/closure |

This is the same read-then-change concurrency class already fixed for auction bidding. No new eligibility rule was introduced: these RPCs already required an active Main ID/Profile; the correction makes that existing rule serializable with Admin lifecycle changes.

## Source correction

Added `20261118440000_serialize_member_financial_eligibility.sql` as forward migration #66.

Each affected RPC now:
1. Performs its existing initial lookup and validation.
2. Acquires the shared per-Main-ID transaction advisory lock.
3. Rechecks that the authenticated user still owns the same Main ID, the ID type is `main`, and both Main ID and Profile remain `active`.
4. Proceeds only after the post-lock check succeeds.

The recheck occurs before campaign/payment row processing, wallet debits or withdrawal request insertion. Existing signatures, return contracts, idempotency behavior, wallet debit priority, Income-Wallet-only winner/withdrawal behavior, strict payout detail validation and authenticated EXECUTE grants are preserved.

## Adjacent paths checked

- Package activation request already locks the selected Main-ID row `FOR UPDATE` before creating the activation. Admin lifecycle changes lock that same row before changing status, so this path already serializes against lifecycle mutation.
- Auction winner selection already takes the global member-graph mutation advisory lock before selecting an eligible winner.
- Auction bid placement already shares the per-Main-ID lock and rechecks active status after locking.

## Lock-order review

The Admin lifecycle RPC obtains the graph mutation lock, then the Main-ID row lock, then the per-Main-ID lifecycle lock. The four corrected member RPCs acquire their request-key lock first (where applicable), then the per-Main-ID lifecycle lock; after acquiring it, they perform ordinary reads and do not request the graph mutation lock or Main-ID row lock. This introduces no reverse dependency on the Admin lock sequence.

The lock is transaction-scoped. If a member action obtains it first, the Admin status change waits until that action completes; if Admin obtains it first and commits a suspension/closure, the waiting member action fails its post-lock active-state recheck.

## Verification boundary

Static source review and source patch only. No tests, builds, CI workflow, npm audit, SQL execution, migration replay or database access/writes were performed. Consolidated concurrency testing remains deferred until development reaches 100%.
