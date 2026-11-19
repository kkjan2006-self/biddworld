# Automatic Matrix Placement — 2026-11-19

## Implemented on completion-work

- Added migration `20261119300000_automatic_duplicate_matrix_placement.sql`.
- Added a distinct `placement_depth` setting to each Matrix plan. Matrix Width, Placement Depth and Commission Depth are now independent.
- Updated the Admin Matrix Plan editor to configure Placement Depth separately from Commission Depth.
- Replaced manual Under ID selection in Admin Duplicate ID creation with a one-argument RPC. The browser cannot submit a placement parent.
- Database creation now requires the owner's **second package activation** to be approved and active, and requires an active Matrix plan for that activation's package.
- Database performs breadth-first, next-empty-slot placement under the owner's Main ID placement tree using the plan's Matrix Width and Placement Depth.
- Placement creation is serialized with the existing member graph advisory lock, respects the Duplicate ID feature switch, creates the ID as Pending, and writes an audit record including the automatic parent, position, plan and second activation.
- Registered the migration in the clean-install forward migration manifest.
- Updated RPC/UI and Matrix plan contract tests.

## Safety / execution status

- Source changes only. No migration was applied to TEST or Production.
- No member, wallet, package activation, commission or other production data was changed.
- No tests, type-check, build, browser QA or E2E were executed in this batch.
- The new automatic placement flow requires isolated TEST migration rehearsal before use. The TEST ledger currently does not include the preceding Matrix-plan migration; the Production ledger is also behind the source chain.

## Still pending

- Matrix commission engine traversing the Under ID chain, independent from Sponsor Referral commissions.
- Atomic, idempotent Matrix commission posting to the credited Main ID Income Wallet, with source Duplicate ID attribution.
- Main-only, Duplicate-only and consolidated reports and dashboard integration.
- Remaining Admin/Member integration and final all-at-once QA.
