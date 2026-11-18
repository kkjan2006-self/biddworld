# Auction Bid / Main-ID lifecycle concurrency review — 2026-11-18

## Finding

The final source definition of `private.place_bid(uuid,text)` selected an active Main ID and Profile, then continued through idempotency handling, auction locking and wallet debit without synchronizing with Admin Main-ID suspension/closure. The Admin lifecycle RPC independently changed Main ID/Profile status. A bid could therefore pass the active check concurrently with an Admin status change.

## Source correction

Migration: `supabase/migrations/20261118430000_serialize_auction_bid_member_eligibility.sql`

- Carries forward the current Admin `admin_set_main_member_status(text,text,text)` function body and acquires a per-Main-ID advisory transaction lock after the Main ID row lock, before status mutation.
- Carries forward the current private bid implementation and acquires the same advisory lock after identifying the candidate Main ID.
- Rechecks the same owner's Main ID identity/type/status and Profile status after acquiring the lock. An inactive member fails before idempotency processing, auction locking or wallet debit.
- Preserves the public `place_bid(uuid,text)` signature, authenticated EXECUTE grant, wallet debit ordering, ledger metadata and idempotency contract.

## Migration inventory

The new file is forward candidate 65. Current source inventory: 81 timestamped SQL files (65 forward + 16 excluded) plus 3 legacy/unversioned SQL files = 84 total.

## Verification boundary

Source inspection only. No tests/builds, CI, database replay or database writes. Production `hbqatszyzqobgtauyuzy` and TEST `yoaauthwejdgaevfvwpo` remain untouched. The full consolidated testing phase remains deferred until development reaches 100%.
