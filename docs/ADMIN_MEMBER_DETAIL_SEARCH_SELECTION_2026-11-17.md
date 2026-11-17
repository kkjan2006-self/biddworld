# Admin member detail selection and search consistency — 2026-11-17

- Both Admin member-directory search inputs now clear the currently selected member-detail panel immediately when the search query changes.
- This prevents a detail panel selected from an earlier result set from remaining visible while the directory is transitioning to a different search result set.
- Explicit View details selection remains available for records in the currently displayed list.
- Added `tests/admin-member-detail-search-selection.test.ts` to protect both search entry points and explicit selection.
- This is a client-side consistency improvement only. It does not change member status, account lifecycle, database records, RPC contracts, or Production.
- Static source-contract coverage; live Supabase member reads and role-gated UI were not exercised by this test.
