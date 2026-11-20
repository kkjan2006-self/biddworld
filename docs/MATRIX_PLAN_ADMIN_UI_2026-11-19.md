# Matrix Plan Admin UI — 2026-11-19

## Implemented on completion-work

- Dedicated **Matrix Plans** entry under Admin → Money & Packages, separate from Sponsor Referral Commissions.
- Package selection and package-specific version history.
- Matrix Width (2–100), Placement Depth (1–50) and Commission Depth (1–50) are separate controls; custom widths are supported.
- Per-level enable/disable, Fixed Amount / Percentage reward values and eligibility-rule JSON.
- Saving creates an inactive version through `admin_save_matrix_plan_draft`; activation requires explicit Admin confirmation and calls `admin_activate_matrix_plan`.
- Published packages are read-only in the editor, matching the database contract.
- Automatic Duplicate ID placement uses the selected package's active Matrix plan and does not accept a client-supplied Under ID. It requires the second approved/active package activation and fills the next available slot breadth-first within the owner's placement tree.
- Duplicate ID creation and the feature switch are serialized using the same graph advisory lock.
- Matrix commissions use the Under ID chain independently from Sponsor Referrals. Admin can review, post and reverse Matrix commissions; member dashboards show a separate Matrix commission summary.
- Direct anon/authenticated access to Matrix plan tables is revoked; Admin access uses role-checked RPCs.
- Regression sources include `tests/admin-matrix-plans-ui.test.ts`, `tests/automatic-duplicate-placement-owner-guard.test.ts`, `tests/matrix-commission-engine.test.ts` and Matrix report/dashboard tests. Not executed in this development-only phase.

## Remaining work

- Canonical clean-install migration dependency review and isolated TEST replay remain pending.
- Full tests, type-check, production build, browser/mobile and end-to-end QA are deferred until the development phase is complete.

## Environment safety

No Supabase migrations or SQL were applied. TEST and Production databases were not changed. No deployment was performed; protected `main` remains unchanged.
