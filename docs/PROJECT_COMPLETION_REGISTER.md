# Project Completion Register

## 2026-11-17 — Fixed Bid catalogue server-side filtering

- Replaced client-only filtering of the first 50 loaded campaigns with server-side campaign-title search and status filtering before pagination.
- Search/status changes now restart at offset zero; debounced title search avoids issuing a request for every keystroke.
- Stable ordering and bounded 50-row pagination are retained. Load-more requests append only to the current filter result set.
- Stale requests are invalidated when filters change or the component unmounts; the catalogue remains read-only.
- This is a functional catalogue improvement, not completion of Fixed Bid entry, draw, refunds or settlement.
- Verification: 80 test files / 307 tests passed in CI; TypeScript initially caught a select-value typing issue, corrected in the follow-up commit; final CI result pending.
- Production Supabase was not modified and no migration was applied.
\n\n## 2026-11-17 — Referral plan draft version editor\n\n- Added a safe way to load an existing inactive package's fixed-reward referral plan into the editor as a starting point for a new version. Existing versions are never overwritten.\n- Active-package plans, unsupported reward types and non-sequential level definitions are refused rather than silently altered.\n- The editor now validates fixed rewards against the database RPC range (greater than zero and at most ₹100,000) before submission.\n- Saving still creates an inactive version only; commission calculation, posting and activation are unchanged.\n- Regression tests added. CI first caught a literal newline escape in the inserted helper; corrected in follow-up commit and rechecked. Production Supabase untouched; no migration applied.\n

## 2026-11-17 — Support queue status filtering

- Support ticket status selection is now applied in the Supabase query before 100-row pagination for both member and Admin views.
- Changing status reloads the matching result set from offset zero, so older open/in-progress/resolved/closed tickets are not hidden behind the first 100 mixed-status records.
- Text search remains explicitly limited to loaded records; member ownership continues to be enforced by the user filter and database RLS.
- Regression test verifies both paginated queries apply the selected status. Production Supabase was not modified.


## 2026-11-17 — Notifications inbox server-side filters

- Unread-only (member) and category filters are now applied in the Supabase query before pagination, for both the first page and Load more.
- Filter changes restart loading from the first page through the existing request invalidation flow; member ownership remains scoped to the signed-in user and RLS.
- Category choices come from the database-supported category set, so categories are available even when none occur in the first 100 records.
- Text search remains limited to loaded records and is labelled accordingly. Regression tests cover both paginated query paths.
- Production Supabase was not modified; no migration was applied.


## 2026-11-17 — TEST database bootstrap audit

- Created and verified the isolated `BiddWorld-TEST` project (`yoaauthwejdgaevfvwpo`, `ap-south-1`, PostgreSQL 17.12, `ACTIVE_HEALTHY`).
- TEST database is still empty: no migrations or public tables applied.
- Audited the current branch migration inventory and found 47 SQL files (3 legacy/unversioned and 44 timestamped); the prior migration matrix's 43-file inventory is stale.
- Found that `0001_biddworld.sql` does not match the current Production schema expected by later migrations (`user_id` versus `owner_user_id` and `user_id` versus `member_id`); `0002_place_bid_rpc.sql` is the old one-argument bid RPC, and `001_initial_schema.sql` is empty.
- Decision: do not replay the legacy baseline or apply timestamped migrations to TEST until a canonical clean-install bootstrap is reconciled. Production remains read-only and unchanged.
- Detailed findings and next steps: `docs/TEST_DATABASE_BOOTSTRAP_AUDIT_2026-11-17.md`.
