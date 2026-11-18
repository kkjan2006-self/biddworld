# Auction cancellation, Fixed Bid refund and delivery tracking source review — 2026-11-18

## Scope and evidence
Reviewed the auction lifecycle, secure Fixed Bid draw, winner-payment guard, delivery tracking migration, and Member/Admin call sites. Source-only review; no tests, builds, migration replay or database writes.

## Auction cancellation and refund
- Admin-only status RPC locks the auction row and validates supported states.
- Cancellation is blocked after any linked winning-item payment is paid.
- Accepted bids are locked. Each source debit is checked against the bid owner, wallet account/member, wallet type, transaction type, direction, auction reference and expected `:bid` / `:income` idempotency suffix.
- The source debit sum must equal the recorded bid amount. Any mismatch raises and rolls back cancellation and all refunds in the transaction.
- Deterministic refund keys are scoped to bid and wallet account. Existing rows are accepted only if wallet, member, transaction type, direction, amount and reference match.
- Refunds, auction status update and audit record share one transaction.

## Fixed Bid draw and refund
- Winner ranking uses a random UUID seed with SHA-256 digest scoring and stable tie-breaking; at most one best entry per eligible active Main ID is considered.
- Non-winner refund selection excludes only the exact winning entry UUIDs, so additional losing entries belonging to a winning member are still eligible for refund.
- Every source debit is checked against entry owner, wallet type, transaction metadata, reference, idempotency suffix and amount. The debit sum must equal the recorded entry amount.
- Refund keys are deterministic per entry and wallet account; conflicting existing ledger rows fail closed.
- Campaign locking, recorded draw, winner-payment rows, refunds and audit data are handled transactionally; repeat draw returns the existing recorded result.

## Delivery tracking contracts
- A unique index permits one tracking row per winning-item payment. RLS is enabled.
- Members have authenticated SELECT-only column grants and an owner-scoped SELECT policy through the winning payment's Main ID. No direct member write grants are provided.
- Admin list/save RPCs enforce the Admin app-metadata role and have explicit authenticated EXECUTE grants.
- New tracking requires a winning-item payment already marked paid and takes a payment-scoped advisory transaction lock before uniqueness checking.
- Existing tracking updates lock the tracking row and recheck that its payment remains paid.
- Member Account loads tracking only for its Main ID's winning-payment IDs; additional winner-history pages fetch their related tracking rows. Admin loads the paginated tracking report and exports through the same bounded RPC.
- UI and RPC support the same statuses: pending, packed, shipped, in_transit, delivered and returned. Shipped/delivered timestamps are populated when those states are entered.

## Unresolved delivery lifecycle policy
The SQL validates the status vocabulary but does not constrain transitions. Admin can change delivered back to pending, returned to shipped, or create a record directly in a later state. When status changes away from delivered, `delivered_at` is cleared; `shipped_at` remains once set.

This is a concrete missing state-machine rule, but the repository requirements do not define the allowed transition graph, whether returned items may be re-shipped, or whether Admin corrections may reopen terminal states. No speculative transition guard was added. The approved transition semantics must be defined before enforcing a database state machine.

## Clean-install documentation correction
- Current inventory: 83 SQL files (80 timestamped + 3 legacy/unversioned).
- The manifests contain 64 forward candidates and 16 excluded timestamped files, accounting for all 80 timestamped migrations exactly once.
- Corrected the clean-install README's stale 78-timestamped / 81-total inventory references.

## Phase status
Source review only. No tests/builds or migration replay. Production `hbqatszyzqobgtauyuzy` and TEST `yoaauthwejdgaevfvwpo` remain untouched.
