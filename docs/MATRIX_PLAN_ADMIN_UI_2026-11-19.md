# Matrix Plan Admin UI — 2026-11-19

## Implemented on completion-work

- Added a dedicated **Matrix Plans** entry under Admin → Money & Packages, separate from Sponsor Referral Commissions.
- Added package selection and package-specific Matrix plan history.
- Added Matrix Width selection (predefined 1:3–1:7 plus custom widths) independently from Matrix Depth (1–50).
- Added per-level enable/disable, Fixed Amount / Percentage reward values, and JSON eligibility-rule input.
- Saving creates a new inactive version through `admin_save_matrix_plan_draft`; activation requires an explicit confirmation and calls `admin_activate_matrix_plan`.
- Published packages are read-only in this editor, matching the current database contract.
- Enabled RLS and revoked direct anon/authenticated table privileges on `matrix_plan_versions` and `matrix_level_rules`. Admin access is through the existing role-checked RPCs only.
- Added source-contract coverage in `tests/admin-matrix-plans-ui.test.ts`. The test has not been run.

## Still pending

- Automatic width × depth next-empty placement; duplicate placement must be automatic under the owner's Main ID team and must never use a manually selected Under ID.
- Enforce the second-approved-package-activation prerequisite for Duplicate ID creation.
- Matrix commission calculation over the Under ID chain, independent of Sponsor Referral commissions.
- Atomic idempotent Matrix commission ledger posting to the credited Main ID Income Wallet, preserving source Duplicate ID attribution.
- Main/Duplicate/consolidated Matrix commission reports and dashboard integration.
- Isolated TEST migration reconciliation and final test/QA phase.

## Environment safety

No Supabase migrations or SQL were applied. TEST and Production databases were inspected read-only. Production remains read-only; no Production or TEST data was changed. No test suite, type-check, build, browser QA, or deployment was run in this development batch.
