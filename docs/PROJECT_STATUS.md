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


## Latest source integrity fix

- Member withdrawal creation now validates the exact success response from the SQL RPC, including UUID request identity, `pending` status and the server's bounded minimum amount, before clearing submitted form fields.
- Added source-only regression coverage in `tests/member-withdrawal-create-response-integrity.test.ts` (not executed). No SQL migration or database operation was required.


## 2026-11-20 — Notification read-action persistence reconciliation

- Member single-notification read updates now request the persisted row and only update local inbox state from its returned `read_at`; when the row was concurrently removed or already changed, the inbox is refreshed instead of displaying an unconfirmed success.
- Bulk Mark All Read now reconciles only the exact IDs and timestamps returned by the database, rejecting malformed or duplicate response identities rather than optimistically marking every loaded row as read.
- Added `tests/notification-read-action-persistence.test.ts` as source-only regression coverage. Not executed. No SQL migration was required; the existing owner-scoped `UPDATE(read_at)` policy and SELECT grant already support the response projection.
- No tests/build/type-check/E2E/browser QA, database access or migration replay, deployment or `main` changes. Production remains read-only and TEST remains unused.

## 2026-11-20 — Matrix placement regression source repair

- Corrected an undeclared source variable in the final Matrix upline traversal regression case: assertions now inspect the existing `migration` source binding.
- This repairs the regression test's source-level reference without changing Matrix placement, commission, wallet or RPC behavior. Test remains unexecuted.
- No migration or clean-install manifest change was required.


## 2026-11-20 — Clean-install regression source syntax repair

- Repaired literal backslash-n characters embedded in the migration-manifest version-uniqueness test block; real source line breaks now separate the TypeScript statements.
- Assertion behavior and the existing 151-forward / 16-excluded migration inventory are unchanged. Test remains unexecuted.


## 2026-11-20 — Notification keyset response ordering hardening

- Initial and continuation inbox pages now require strict descending (created_at,id) order; continuation rows must also fall strictly before the existing cursor before they can be appended.
- Added source-only assertions to tests/notifications-response-integrity.test.ts; not executed. No migration or database change required.


## Latest source-only regression alignment

- Reconciled `tests/member-package-activation-response-integrity.test.ts` with the current receipt cleanup guard in `Packages.tsx`. The test now verifies that cleanup occurs only before the activation RPC or after a definite coded rejection; ambiguous RPC outcomes preserve the uploaded receipt. Added explicit assertions for the attempt/rejection flags.
- Regression source remains unexecuted. No runtime, SQL migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## Latest Admin package activation queue hardening

- The Admin pending-activation client now validates row identity and payment/receipt fields, strict descending `(submitted_at,id)` ordering, full continuation pages and exact cursor-to-final-row agreement. Load-more responses must be strictly older than the previous cursor and may not overlap loaded IDs.
- Added source-only assertions in `tests/admin-package-activation-keyset-pagination.test.ts`; not executed. No migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## Latest Fixed Bid catalogue integrity update

- The Fixed Bid campaign client now validates strict descending `(created_at,id)` ordering in every page and enforces the same tuple boundary between offset pages before appending. This detects page shifts/overlaps caused by concurrent catalogue changes and directs the member to refresh.
- Reconciled the pagination test's `hasMore` assertion with the current source and added source-only ordering/boundary assertions. No test/build/type-check/E2E/browser QA/deployment/database operation was performed.


## 2026-11-20 — Admin withdrawal queue ordering and cursor-boundary integrity

- The Admin withdrawal RPC returns rows ordered by descending `(requested_at,id)`. The UI previously rejected duplicate request IDs across offset pages but did not independently verify that the server preserved this ordering or that a continuation page began strictly before the last loaded request.
- Extended the shared withdrawal response parser to validate strict descending tuple order within every page and across the loaded-page boundary before appending. Out-of-order or shifted pages now fail closed and require a refresh.
- Added source-only regression assertions in `tests/admin-withdrawal-pagination-hardening.test.ts`; not executed. No SQL migration, manifest, database, build, type-check, E2E, browser QA or deployment operation was performed.
