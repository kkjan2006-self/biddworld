# Member account refresh concurrency — 2026-11-17

## Changes
- Each account refresh now receives a monotonically increasing request generation.
- A newer refresh supersedes older in-flight reads; stale responses cannot overwrite newer profile, wallet, or history data.
- Request ownership is checked after authentication, profile, identity, settings, account-history, and delivery reads.
- Obsolete requests cannot clear the loading indicator belonging to the current refresh.
- Component cleanup invalidates outstanding requests and prevents post-unmount state updates.

## Verification
- Added `tests/member-account-refresh-concurrency.test.ts` for generation checks, post-await guards, loading-state ownership, and unmount invalidation.
- CI on the latest branch commit is required before this batch is marked verified.
- No Production database or member data was changed.
