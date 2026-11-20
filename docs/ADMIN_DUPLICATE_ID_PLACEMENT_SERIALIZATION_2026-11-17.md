# Admin Duplicate ID placement creation serialization — 2026-11-17

## Change
- Added `20261117110000_serialize_admin_duplicate_id_placement.sql`.
- The Admin-only two-argument creation RPC now takes a transaction-scoped advisory lock before reading the feature setting or locking Main / Under ID rows.
- This serializes the low-frequency placement graph mutation and avoids cross-request row-lock inversion when concurrent requests touch overlapping IDs in opposite order.
- Retains active Main ID and active Under ID validation, the cross-owner placement rule, Pending creation, placement parent attribution, audit logging, empty search_path and authenticated-only grant.

## Verification boundary
- Added `tests/admin-duplicate-placement-serialization.test.ts` to protect lock ordering and the existing authorization / placement contract.
- This is a static source-contract test, not a live two-session PostgreSQL concurrency test.
- Migration is source-only. It has not been applied to Production; do not apply it until the historical migration chain is reconciled and rehearsed in a disposable TEST project.
- No Production schema, data, settings, accounts, wallets or financial records were changed.
