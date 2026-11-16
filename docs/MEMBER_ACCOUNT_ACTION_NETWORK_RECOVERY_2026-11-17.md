# Member account action network recovery — 2026-11-17

## Changes
- Withdrawal submission now catches rejected network requests and always releases its submitting state.
- Email-change requests now handle thrown network failures and always release their loading state.
- Password-change requests now handle thrown network failures and always release their loading state.
- Global sign-out now reports network failures and always releases the shared security action state.
- Existing Supabase error messages, successful action messaging, validation and account flows are retained.

## Verification
- Added `tests/member-account-action-network-recovery.test.ts` to check exception handling and guaranteed loading-state cleanup in all four actions.
- CI must pass on the latest branch commit before the batch is considered fully verified.
- No Production database, wallet, member records, Auth configuration or live accounts were changed.
