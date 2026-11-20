# Member dashboard automatic initial loading — 2026-11-17

## Issue found
The Account component defined its asynchronous `load()` routine and exposed a manual Refresh button, but did not invoke the routine when the component mounted. The initial loading state could therefore remain visible until a member manually refreshed.

## Change
- Added a mount effect that invokes `load()` when the member dashboard opens.
- Retained the manual Refresh action for subsequent reloads.
- Kept existing authenticated profile lookup and Main-ID-scoped history queries unchanged.

## Verification
- Added `tests/member-dashboard-initial-load.test.ts` to assert the mount effect, manual refresh, loading cleanup and existing member data scoping.
- CI must complete successfully on the latest branch commit before this batch is marked fully verified.
- No Production database, account, wallet or member records were changed.
