# Matrix Commission Engine — 2026-11-19

## Implemented on `completion-work`

- Added `20261119310000_matrix_commission_engine.sql`, independent of the Sponsor Referral commission engine.
- Matrix uplines are resolved exclusively through `member_ids.placement_parent_id` (Under ID); Sponsor Referral relationships are never used for Matrix commission calculation.
- Enabled level rules support Fixed or Percentage rewards and the plan's eligibility JSON contract.
- Commission rows preserve the source ID and credited Main ID separately. A Duplicate ID remains visible as the commission source while its linked Main ID receives the Income Wallet credit.
- Posting locks the activation, commission rows and Income Wallet; updates balance and inserts the wallet ledger row atomically. Deterministic idempotency keys are checked against the full ledger identity before replay is accepted.
- Admin reversal is ledger-backed and audited. The Admin report is paginated and includes activated Main ID, source ID/type, credited Main ID, level, amount and status.
- Direct table access is revoked and RLS is enabled. The Matrix feature setting is seeded OFF and has a dedicated Admin control; enablement is gated by the server-side condition.
- Admin Matrix Plan editor, Admin Matrix Commission Register, member Matrix commission summary and member dashboard integration are now connected to the relevant RPCs.
- Follow-up migrations handle automatic placement depth, owner exclusion, source labels and report/dashboard summary integration.

## Not performed

- No migration was applied to TEST or Production.
- No wallet balance, commission row, member record or other database data was written.
- Tests, type-check, build, browser/mobile QA and E2E remain deferred to the final QA phase.

## Remaining work

- Complete static frontend/RPC/RLS/Storage contract reconciliation and canonical migration dependency review.
- Replay the clean-install chain only in the isolated TEST project after explicit authorization, then perform the full test/build/functional QA batch.
