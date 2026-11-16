# Admin member directory search race protection — 2026-11-17

## Changes
- Added a monotonically increasing request generation for Admin Main ID directory searches.
- Debounced searches, explicit Search actions and Clear actions now only commit results when they still own the latest request generation.
- Stale failures cannot overwrite the current search message; stale requests cannot clear the loading state owned by a newer request.
- The initial Admin workspace load only seeds the member directory if no newer search has started since that load began.
- Existing server-side search, pagination, filters and CSV export behavior remain intact.

## Verification
- Added `tests/admin-member-directory-search-race.test.ts` for generation ownership, initial-load coordination, manual search and Clear.
- CI on the latest branch commit is the final verification gate.
- No Production database, member records or Admin accounts were changed.
