# Authentication request resilience — 2026-11-17

## Changes
- Registration and sign-in now catch rejected network requests and always clear the shared busy state in a `finally` block.
- Password reset and confirmation-email resend now report network failures and always release their respective busy indicators.
- Password recovery now handles both returned Supabase errors and thrown network errors. A successful password update is retained even if the best-effort local sign-out subsequently fails.
- Registration and sign-in now trim the email address before submitting it.
- Existing sponsor validation, password checks, redirect URL behavior and inactive-until-verified signup messaging are retained.
- Added `tests/auth-network-failure-recovery.test.ts` for the request lifecycle and retained validation behavior.

## Verification
- CI was triggered for the source, test and documentation commits; verify the newest branch run before treating the batch as passed.
- The tests are static source-contract tests; they do not simulate Supabase Auth network failures against a live Auth server.
- No account credentials, member records, Auth users, Supabase settings, Production data or schema were changed.
