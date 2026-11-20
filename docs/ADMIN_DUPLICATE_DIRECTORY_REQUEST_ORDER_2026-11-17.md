# Admin Duplicate ID directory request ordering — 2026-11-17

## Changes
- Added a dedicated request-generation counter for the Duplicate ID directory.
- Workspace refreshes and search changes invalidate older directory loads.
- Load-more captures the current search and offset before requesting the next page.
- Stale page responses, errors and loading cleanup cannot overwrite a newer directory request.

## Verification
- Added `tests/admin-duplicate-directory-request-order.test.ts`.
- CI on the latest branch commit is the verification gate.
- No Production database or member records were changed.
