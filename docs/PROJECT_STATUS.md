# BiddWorld Development Status

Last updated: 2026-11-20  
Repository: `kkjan2006-self/biddworld`  
Active development branch: `completion-work`

## Development checkpoint

- Source-only development is in progress. Do not run tests, builds, type-checks, E2E, browser QA, deployment, or database replay until the owner declares development 100% complete.
- Production Supabase project `hbqatszyzqobgtauyuzy` remains read-only. TEST project `yoaauthwejdgaevfvwpo` remains unused.
- No preview deployments. All SQL changes remain forward migration source only; none are applied to a database.
- Clean-install source inventory: **151 forward + 16 excluded historical = 167 timestamped migration paths**, plus 3 legacy/unversioned SQL files.
- Source-only regression tests may be added but must remain unexecuted.

## Latest development batch

Restricted Staff Support ticket review was added end-to-end:
- Primary Admin can independently assign `support_ticket_review` through the existing Staff permission editor.
- Support ticket reads are permitted to Staff only through the explicit permission-scoped RLS policy.
- Support ticket updates remain on the audited RPC and accept only Admin or Staff with the exact permission.
- The existing Support workspace is reused for Staff reviewers; member ticket submission controls are not shown to Staff.
- Forward migration: `20261120220000_restricted_staff_support_ticket_review.sql`.
- Source-only regression file: `tests/restricted-staff-support-ticket-review.test.ts` (not executed).

## Next source-development priorities

Continue source-based frontend ↔ SQL ↔ RPC ↔ permission ↔ RLS reconciliation without recreating completed features. Prioritize:
1. Withdrawal request, Admin/Staff review scope, payout processing and member history.
2. Notifications dispatch, read/unread state and recipient authorization.
3. Matrix placement/downline, commission posting, reversals and ledger idempotency.
4. Package management, activation queues and Admin/Staff review consistency.
5. Wallet transactions, ledger/report pagination and export completeness.
6. Full Admin/Staff permission matrix and table/Storage RLS coverage.

These are review targets, not assertions that every item is incomplete. Confirm each gap against current source before changing it.


## Latest follow-up integration fix

- The Support Staff permission rollout initially left the existing Support notification trigger Admin-only. Added `20261120230000_staff_support_ticket_notifications.sql` so only Admin or Staff with `support_ticket_review` can cause the existing member status/reply notification; the global notification feature switch remains enforced.
- Source-only regression coverage: `tests/staff-support-ticket-notifications.test.ts` (not executed).
- Clean-install inventory: **151 forward + 16 excluded = 167 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Completion measurement

No defensible overall percentage is recorded here. A percentage must be calculated only after the remaining feature inventory is reconciled against implemented frontend, SQL/RPC, authorization/RLS, migration registration and source-contract coverage. Do not infer completion from migration counts or documentation entries alone.


## Latest source integrity fix

- Admin Withdrawal CSV export now applies the existing strict withdrawal parser to every page and rejects repeated Request IDs across pages even when a row's other fields change.
- Shared paged exports accept an optional stable identity key; other reports retain their existing row-content duplicate detection.
- Source-only regression assertions updated in `tests/admin-withdrawal-pagination-hardening.test.ts` (not executed). No migration or database operation was required.
