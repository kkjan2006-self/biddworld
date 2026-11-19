# Automatic Matrix Placement — 2026-11-19

## Implemented on completion-work

- Added migration `20261119300000_automatic_duplicate_matrix_placement.sql` and follow-up placement hardening migrations `20261119330000` and `20261119340000`.
- Matrix Width, Placement Depth and Commission Depth are independent package-specific plan settings. Width supports 2–100; each depth supports 1–50.
- Admin Duplicate ID creation uses a one-argument RPC. The browser cannot submit an Under ID or placement parent.
- Creation requires the owner's second package activation to be approved and active and an active Matrix plan for that activation's package.
- The database performs breadth-first, next-empty-slot placement within the owner's Main ID placement tree, using the plan's width and placement depth. Owner IDs are excluded from their own Duplicate-ID placement chain.
- Creation is serialized with the member graph advisory lock, respects the Duplicate ID feature switch, creates the ID as Pending and records the automatic parent, position, plan and activation in the audit log.
- The Admin Duplicate ID switch takes the same advisory lock before changing the setting. This closes the race where an in-flight creation could pass the old setting while an Admin disables creation.
- The Sponsor Referral graph remains separate from the Under-ID placement tree.

## Matrix commissions and reporting — now integrated

- The Matrix commission engine traverses only `placement_parent_id`, independently of Sponsor Referral relationships.
- Source Duplicate IDs remain identifiable in commission rows while credits are attributed to the linked eligible Main ID Income Wallet.
- Admin posting is transactional and idempotent, with ledger identity checks; reversal is ledger-backed and audited.
- Admin Matrix Plans, Matrix Commission Register, member Matrix commission summary and member dashboard integration are connected to their dedicated RPCs.
- `matrix_commissions_enabled` is exposed through the Admin feature switch and remains protected by the existing server-side condition. Automatic placement and winner-selection configuration are not exposed as ready controls.

## Safety / execution status

- Source-only. No migration has been applied to TEST or Production; no member, wallet, package activation or commission data was changed.
- Tests, type-check, build, browser QA and E2E remain deferred to the final QA phase.
- The complete clean-install chain still requires isolated TEST reconciliation and replay before any live use.
