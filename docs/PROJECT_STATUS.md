# BiddWorld Development Status

Last updated: 2026-11-20  
Repository: `kkjan2006-self/biddworld`  
Active development branch: `completion-work`

## Development checkpoint

- Source-only development is in progress. Do not run tests, builds, type-checks, E2E, browser QA, deployment, or database replay until the owner declares development 100% complete.
- Production Supabase project `hbqatszyzqobgtauyuzy` remains read-only. TEST project `yoaauthwejdgaevfvwpo` remains unused.
- No preview deployments. All SQL changes remain forward migration source only; none are applied to a database.
- Clean-install source inventory: **152 forward + 16 excluded historical = 168 timestamped migration paths**, plus 3 legacy/unversioned SQL files.
- Source-only regression tests may be added but must remain unexecuted.

## Latest development batch
## Latest source-only batch — notification response contract hardening (2026-11-20)

- Notification inbox and Realtime INSERT/UPDATE events now validate notification and recipient identities as UUIDs, enforce the database-supported category set (`general`, `account`, `support`, `security`), and enforce title/message bounds matching the `member_notifications` table constraints. Optional Admin recipient labels are bounded before rendering.
- The same shared parser protects initial loads, keyset continuation pages and Realtime events; member owner matching, existing ordering/cursor checks, unread filtering and delivery idempotency remain unchanged.
- Extended `tests/notifications-response-integrity.test.ts` with source-only assertions for identity, category and content bounds. Not executed. No SQL migration or database change.

## Latest source-only batch — Admin withdrawal lifecycle visibility (2026-11-20)

- The Admin Withdrawal Management summary previously showed only total loaded requests and Pending review. It now separately counts Approved (reserved), Paid, Rejected and Cancelled rows as well, so all five persisted lifecycle states are visible without changing queue filtering, pagination or review behavior.
- Terminal Rejected, Paid and Cancelled rows remain read-only; only Pending and Approved requests retain the existing review controls. Added source-only assertions for all lifecycle counts and terminal-state action gating in tests/admin-withdrawal-pagination-hardening.test.ts; not executed. No SQL migration or database change.


Restricted Staff Support ticket review was added end-to-end:
- Primary Admin can independently assign `support_ticket_review` through the existing Staff permission editor.
- Support ticket reads are permitted to Staff only through the explicit permission-scoped RLS policy.
- Support ticket updates remain on the audited RPC and accept only Admin or Staff with the exact permission.
- The existing Support workspace is reused for Staff reviewers; member ticket submission controls are not shown to Staff.
- Forward migration: `20261120220000_restricted_staff_support_ticket_review.sql`.
- Source-only regression file: `tests/restricted-staff-support-ticket-review.test.ts` (not executed).

Latest follow-up source work now also includes the Staff Support notification trigger, Matrix reversal replay identity, strict page-order/cursor validation across Fixed Bid, Admin Package Activation, Notifications, Wallet and withdrawal histories, and repaired source-only regression assertions. The three user-supplied Fixed Bid sample product images are present under `public/sample-products/`; the smartphone image was subsequently replaced with a higher-resolution version. Current branch HEAD is recorded in the latest verified commit and completion register.

## Latest source-only batch — withdrawal lifecycle status contract reconciliation (2026-11-20)

- Reconciled both member and Admin withdrawal response parsers against the canonical baseline constraint and Admin list RPC: the database permits `cancelled` alongside `pending`, `approved`, `rejected` and `paid`, but both frontend parsers previously rejected it and would fail the entire page if a cancelled request appeared.
- Both parsers now accept the full database status set. Admin withdrawal CSV status filter includes Cancelled; member history shows a separate Cancelled count and a non-active status treatment. Cancelled records remain read-only; no review or payout action is offered.
- Updated source-only regression assertions in `tests/admin-withdrawal-pagination-hardening.test.ts` and `tests/member-withdrawal-history-pagination.test.ts`. Not executed. No SQL migration was needed because `cancelled` is already in the canonical database constraint. No tests/build/type-check/E2E/browser QA/database/deployment operations were run.

## Latest source-only batch — complete personal report integrity (2026-11-20)

- The complete personal CSV previously included only the currently loaded first 50 withdrawal-history rows. It now retrieves every page through the owner-scoped member_list_my_withdrawals_page RPC, advances using the exact (requested_at,id) keyset cursor, validates each page against all prior rows, and stops only on a valid terminal page.
- Other report sources (activations, auction bids, Fixed Bid entries, referral commissions, winning payments and delivery tracking) now validate strict descending (timestamp,id) ordering within and across every 500-row offset page, in addition to duplicate-ID checks. This rejects shifted/overlapping page boundaries before export.
- Added source-only regression assertions in tests/member-report-complete-export.test.ts; not executed. No migration or database change. No tests, build, type-check, E2E, browser QA or deployment was run.
- Remaining priorities: project-wide frontend RPC/signature reconciliation, full clean-install dependency/body reconciliation, remaining permission/RLS/Storage gaps and source-contract coverage.
- Branch at batch start: faadfe50bb6b0932873565f75c1164aeee5b4899; this batch is committed only to completion-work.

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
- Clean-install inventory: **152 forward + 16 excluded = 168 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Completion measurement

No defensible overall percentage is recorded here. A percentage must be calculated only after the remaining feature inventory is reconciled against implemented frontend, SQL/RPC, authorization/RLS, migration registration and source-contract coverage. Do not infer completion from migration counts or documentation entries alone.


## 2026-11-20 — Restricted Staff Support workspace integration gap closed

- The dedicated Staff workspace now recognizes `support_ticket_review` and renders the existing Support review UI only for that explicit claim. This closes the mismatch between the Primary Admin permission editor / Support RLS / Support tab and the Staff workspace permission filter.
- Extended the existing source-only regression test; not executed. No SQL migration or manifest inventory change required.

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


## 2026-11-20 — My Team and Matrix summary failure isolation

- The My Team dashboard and its optional Matrix commission summary are now treated as independent RPC contracts. A rejected/failed Matrix summary request no longer discards a successfully loaded Sponsor team dashboard.
- Matrix summary failures are surfaced as a non-blocking status message; the dashboard retains its own error handling and retry behavior. Refresh resets the summary warning and retries both requests.
- Added source-only regression coverage in `tests/member-team-matrix-summary-isolation.test.ts`; not executed. No SQL migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Notification realtime insertion and keyset ordering

- Live notification INSERT events are now merged into the inbox using the same descending `(created_at,id)` tuple order enforced by the initial and continuation page parsers. Previously, every realtime event was prepended, so a delayed/older event could move ahead of newer records and invalidate the visible keyset cursor.
- Existing IDs are replaced rather than duplicated, and the inbox remains capped at 100 loaded rows. Realtime inserts signal that a continuation page may be needed after the oldest visible row is displaced.
- Added source-only regression coverage in `tests/notifications-response-integrity.test.ts`; not executed. No SQL migration or database operation was required.
- No tests/build/type-check/E2E/browser QA, database access or migration replay, deployment or `main` changes. Production remains read-only and TEST remains unused.


## 2026-11-20 — Wallet history page ordering and cursor integrity

- Member Wallet History now validates strict descending `(created_at,id)` order on every loaded page and requires each continuation page to fall strictly before the previous page cursor. A reordered or shifted page fails closed instead of silently displaying a misleading transaction sequence.
- The full wallet CSV export applies the same per-page ordering and cursor-boundary checks, in addition to its existing duplicate transaction-ID detection, so export cannot silently skip or repeat rows when the underlying page order changes.
- Added source-only assertions in `tests/wallet-history-keyset-pagination.test.ts`; not executed. No SQL migration or database operation was required.
- No tests/build/type-check/E2E/browser QA, database access or migration replay, deployment or `main` changes. Production remains read-only and TEST remains unused.


## 2026-11-20 — Admin Matrix commission report page and export ordering integrity

- The Admin Matrix commission RPC orders records by descending `(created_at,id)`, but its client previously checked only duplicate IDs and continuation metadata. It did not independently validate each page's tuple ordering or ensure the next offset page was strictly older than the previous page cursor.
- Added strict per-page descending tuple validation and cursor-boundary validation to Load More and complete CSV export. Shifted, overlapping or reordered pages now fail closed rather than silently omitting or repeating commission records.
- Added source-only assertions in `tests/admin-matrix-commissions-source-integrity.test.ts`; not executed. No SQL migration or database operation was required.
- No tests/build/type-check/E2E/browser QA, database access or migration replay, deployment or `main` changes. Production remains read-only and TEST remains unused.


## 2026-11-20 — Matrix commission reversal replay identity

- Idempotent reversal replay responses now include the exact commission UUID. Admin UI validates the UUID for both new reversals and replays instead of accepting an omitted identity.
- Forward migration: `20261120240000_matrix_commission_reversal_replay_identity.sql`; registered in clean-install manifest. Source-only coverage added to `tests/admin-matrix-commission-actions.test.ts` and not executed.
- Inventory: 152 forward + 16 excluded = 168 timestamped migration paths, plus 3 legacy/unversioned SQL files. No migration was applied; Production remains read-only and TEST remains unused.
- Tests, builds, type-check, E2E, browser QA and database replay were not run.


## 2026-11-20 — Fixed Bid product image frame rendering

- Shared `.fixedBidVisual img` styling now fills the complete product frame with `object-fit: cover` and block layout for full catalogue and compact homepage cards.
- Added source-only regression coverage in `tests/fixed-bid-image-frame-rendering.test.ts`; not executed. Repository asset audit found no sample product images, so the three sample fixtures still require the separately requested AI-generated images.
- No database, migration replay, tests, build, type-check, E2E, browser QA or deployment. Production/TEST unchanged; `main` unchanged.


## 2026-11-20 — Supplied Fixed Bid sample product images

- Added optimized user-provided WebP images for Smartphone, Mixer Grinder and Smartwatch under `public/sample-products/` and assigned each to its corresponding sample Fixed Bid fixture.
- Updated image URL resolution to serve Vite base-path public assets directly, including GitHub Pages `/biddworld-preview/`, instead of requesting them from Supabase Storage. Shared by homepage compact cards, catalogue cards and details gallery.
- Added source-only regression assertions in `tests/fixed-bid-sample-images.test.ts`; not executed. The uploaded Mixer Grinder image contains a visible Vecteezy watermark.
- No DB changes, migrations, tests/build/type-check/E2E/browser QA or deployment. Production/TEST unchanged; `main` unchanged.


## Latest Support ticket pagination integrity

- Source audit found Support initial, continuation and full CSV export pages trusted the database's descending `(updated_at,id)` order without independently validating page order or the continuation cursor boundary.
- Added strict descending tuple validation to every Support page and export batch; continuation pages must start strictly before the prior cursor. Existing owner scoping, Staff/Admin review scope, duplicate-ID checks and full-page continuation behavior are preserved.
- Added `tests/support-ticket-pagination-integrity.test.ts` as source-only regression coverage; not executed. No SQL migration or database operation was required.


## Latest Admin wallet response-contract hardening

- Admin wallet account and ledger pages previously validated only record IDs and a subset of numeric values. Added strict response parsers for UUID identities, Main ID references, wallet type, currency, transaction direction/type, timestamps, nullable references and non-negative balances.
- Initial and continuation pages now use the same parsers; continuation pages fail closed on any overlap with already loaded IDs instead of silently dropping repeated rows.
- Added source-only regression coverage in `tests/admin-wallet-page-response-integrity.test.ts`; not executed. No SQL migration or database operation was required.


## Latest Admin wallet numeric precision integrity

- Closed a response-validation gap where JavaScript numeric coercion allowed null or numeric-string wallet balances to pass as valid numbers. Admin wallet account balances and ledger amounts/balance-after values now require actual finite numbers, non-negative/positive values as appropriate, database-scale bounds, and cent precision before display or export.
- Extended `tests/admin-wallet-page-response-integrity.test.ts` with source-only assertions for null/coercion, upper-bound and sub-cent rejection. Not executed. No SQL migration or database operation was required; no tests/build/type-check/E2E/browser QA or deployment was run.


## Latest Staff package activation cursor-boundary integrity

- Hardened Staff package-activation pagination so each continuation page must begin strictly before the prior page's final `(submitted_at,id)` cursor in descending order. Existing row-order, final-row cursor matching and duplicate/overlap checks remain in place.
- Added source-only regression assertions in `tests/staff-package-activation-review-contract.test.ts`; not executed. No SQL migration or database operation was required.


## Latest Admin Income Wallet funding cursor-boundary integrity

- Hardened the Admin Income Wallet funding review queue so every continuation page must begin strictly after the previous page's final ascending `(created_at,id)` cursor. A page with unseen IDs but overlapping or regressing timestamp/ID range is now rejected before rows, receipt links or cursor state are appended.
- Added source-only regression assertions in `tests/admin-wallet-funding-page-contract.test.ts`; not executed. No SQL migration or database operation was required.


## Latest Admin auction submission pagination boundary integrity

- Hardened the Admin auction moderation queue: continuation pages must start strictly after the previous `(created_at,id)` cursor; full pages must contain exactly 50 records and the returned cursor must match the final row; terminal pages must not return cursor values. Malformed pagination responses are rejected before image signing or queue updates.
- Added source-only regression assertions in `tests/admin-auction-submission-page-runtime-contract.test.ts`; not executed. No SQL or database change.


## Latest Admin withdrawal export boundary hardening

- Complete Admin withdrawal CSV export now validates strict descending `(requested_at,id)` ordering across page boundaries by passing each parsed page as the next page's cursor context. Reordered/shifted pages with unseen IDs fail closed before export.
- Added source-only assertions in `tests/admin-withdrawal-pagination-hardening.test.ts`; not executed. No SQL migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Member account history page-boundary integrity

- Hardened the shared member history loader used by package activations, auction bids, Fixed Bid entries, sponsor commissions and winning-payment history. Every continuation page now validates record identity and timestamp, strict descending (timestamp,id) ordering within the page and against the previously loaded boundary, and rejects any duplicate/overlap before appending.
- Package activations use their actual `submitted_at` ordering key; the other four histories use `created_at`. Invalid pages stop pagination and require a refresh rather than being silently filtered while the offset advances.
- Added `tests/member-account-history-pagination-integrity.test.ts` as source-only regression coverage; not executed. No migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Member Matrix commission history integrity

- Reconciled the member Matrix history client with the authoritative `member_list_my_matrix_commissions_page` SQL ordering (`created_at DESC, id DESC`). Initial and continuation pages now share one strict parser that validates UUID identity, level, source attribution, positive finite amount, status and timestamp; it also rejects duplicate IDs and ordering regressions within/across pages before display.
- Invalid continuation pages now stop further pagination and require a refresh instead of leaving a repeatedly failing cursor active. The initial page is validated before being placed into member state.
- Added `tests/member-matrix-commission-history-integrity.test.ts` as source-only regression coverage; not executed. No migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Admin referral commission filtered pagination

- Corrected the commission register so status and level filters are sent to the server for both the first page and every continuation page; changing either filter now reloads the register from offset zero. This prevents a filtered view from silently continuing through unfiltered records and showing incomplete or misleading results.
- Strengthened the shared commission-page parser against malformed UUIDs, invalid activation IDs, levels outside 1–20, unsupported statuses, malformed timestamps, duplicate IDs, inconsistent has-more metadata, and strict descending `(created_at,id)` ordering across page boundaries matching the SQL RPC.
- Added `tests/admin-referral-commission-filter-pagination-integrity.test.ts` as source-only regression coverage; not executed. No migration, database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Staff activation queue concurrency hardening

- Fixed the package activation review queue request lock so both refresh/reset and continuation requests acquire the same lock before asynchronous work begins.
- A superseded request can no longer release the lock owned by a newer refresh. Only the currently active request generation clears loading state and releases the lock; stale responses remain unable to update the queue.
- Added source-only regression coverage in `tests/staff-package-activation-request-lock-integrity.test.ts`. Not executed. No database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Admin Income Wallet funding queue concurrency hardening

- Unified refresh and continuation request locking in the Admin Income Wallet funding review queue. Previously, a refresh could clear the continuation lock while an older page request was still running, allowing overlapping requests and cursor/state races.
- Every queue load now acquires the same lock before asynchronous work; a concurrent refresh or continuation is ignored until the active request completes. Only the current request generation releases the lock, while stale responses remain blocked from changing the queue.
- Added source-only regression coverage in `tests/admin-wallet-funding-request-lock-integrity.test.ts`. Not executed. No database, build, type-check, E2E, browser QA or deployment operation was performed.


## 2026-11-20 — Admin auction submission queue concurrency hardening

- Serialized refresh and Load More requests in the Admin auction submission review queue with a single shared request lock. A refresh can no longer clear an in-flight pagination lock and allow overlapping requests or cursor races.
- The active request generation alone releases the lock. Component cleanup invalidates pending load generations so responses completing after unmount cannot update the queue.
- Added source-only regression coverage in `tests/admin-auction-review-request-lock-integrity.test.ts`. Not executed. No database, build, type-check, E2E, browser QA or deployment operation was performed.
