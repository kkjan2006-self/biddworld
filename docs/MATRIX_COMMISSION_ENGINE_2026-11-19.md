# Matrix Commission Engine — 2026-11-19

## Implemented on `completion-work`

- Added `20261119310000_matrix_commission_engine.sql`, independent of the Sponsor Referral commission engine.
- Matrix uplines are resolved exclusively through `member_ids.placement_parent_id` (Under ID). The referral graph is not queried.
- Each enabled Matrix level rule supports Fixed or Percentage calculation and the existing eligibility JSON contract.
- Commission rows preserve the placement-chain source ID and the credited Main ID separately. When an ancestor is a Duplicate ID, its owner Main ID is the wallet beneficiary; the Duplicate ID remains visible as the commission source.
- Posting locks the activation, commission rows and Income Wallet, updates the balance and inserts the wallet ledger row in one transaction. A deterministic idempotency key is checked against the complete ledger identity before replay is accepted.
- Admin reversal is ledger-backed and audited. Admin reporting is paginated and includes activated Main ID, source ID/type, credited Main ID, level, amount and status.
- Direct access to the commission table is revoked and RLS is enabled.
- `matrix_commissions_enabled` is seeded OFF. The Admin control is visible but remains locked until the full Matrix workflow is completed; the setting RPC refuses to enable it at this stage.
- Fixed a malformed regular-expression literal in `20261119300000_automatic_duplicate_matrix_placement.sql` that would have prevented SQL parsing.

## Not performed

- No migration was applied to TEST or Production.
- No wallet balance, commission row, member record or other database data was written.
- No tests, typecheck, build, browser or mobile QA were executed. The new tests are source-contract tests only until the final QA phase.

## Remaining work

- Connect the Matrix commission report to the Admin UI and add source-aware filters/exports.
- Add Matrix commission totals to member and Admin dashboards without merging them into Sponsor Referral totals.
- Complete the feature-setting readiness transition only after the end-to-end workflow is fully implemented.
- Reconcile the migration against the isolated TEST baseline and run the full test/build/functional QA batch at the user's requested final testing stage.
