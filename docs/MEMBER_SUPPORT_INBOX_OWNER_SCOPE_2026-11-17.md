# Member inbox and support ownership-scope hardening — 2026-11-17

## Changes
- Updated the member Notifications workspace so both the first page and every continuation page explicitly filter `member_notifications.user_id` to the currently authenticated Supabase user.
- Updated the member Support workspace so both the first page and every continuation page explicitly filter `support_tickets.user_id` to the currently authenticated Supabase user.
- The filter is deliberately omitted only in the Admin workspace, which continues to use the separate Admin RLS policy and trusted Admin role.
- Both member paths now stop with a sign-in message if the current authenticated user cannot be confirmed.
- Added `tests/member-support-inbox-owner-scope.test.ts` to guard both read paths and ensure the Admin queue path remains distinct.

## Why
The existing RLS policies already enforce owner-only member reads. The explicit client-side owner filter is defense in depth, reduces unnecessary rows returned to the client, and makes the intended data scope clear at the query boundary. It does not replace or weaken database RLS.

## Verification
- GitHub Actions CI has been triggered by the branch commits; verify the newest run before treating this batch as passed.
- These are source and static regression changes. No live user data was queried or modified.
- No Supabase migrations, Production schema, member records, notifications, support tickets, settings or financial records were changed.
- Admin continues to read the Admin queue only when the caller has the trusted Admin claim and the database RLS policy permits it.
