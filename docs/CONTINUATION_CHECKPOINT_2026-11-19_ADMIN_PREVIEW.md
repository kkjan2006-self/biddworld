# Continuation checkpoint — 2026-11-19 (Admin preview access)

## Verified Preview state
- Preview site is connected to the isolated TEST Supabase project.
- The owner registered `kkjan2006@gmail.com`; the TEST Auth user exists and email confirmation is true for this existing account.
- TEST `raw_app_meta_data.role` for that exact account is `admin`.
- The owner disabled Supabase Auth Email `Confirm email` in the TEST project's Email provider settings; the dashboard displayed a successful settings update.
- The owner then signed in successfully and the Preview displayed the Admin Dashboard. This confirms the TEST Admin claim is accepted by the frontend.
- TEST-only app setting `registration_enabled=true` and `email_verification_required=false` were set. TEST trigger function was manually corrected so both new `profiles` and Main `member_ids` are created with `pending` status, matching the current allowed status constraints. TEST `products` SELECT was granted to `anon` for the published-only RLS catalogue policy. These were targeted TEST-only fixes; no Production writes were made.
- Do not repeat the signup or Admin bootstrap unless the owner asks. The account already exists and Admin login succeeded.

## Source corrections committed to `completion-work`
- Added `supabase/migrations/20261119220000_signup_status_and_public_product_select.sql` to carry the two source corrections into a clean-install path: pending signup identity statuses and SELECT grants for public/authenticated catalogue clients, with the existing published-only products RLS policy remaining the row boundary.
- Added `tests/signup-status-product-grant.test.ts` as source-contract coverage. It has not been executed.
- Updated `supabase/clean-install/forward-migrations.txt` to include the recent forward migrations from `20261119180000` through `20261119220000`, which were missing from the previous manifest.
- Latest commits in this batch:
  - `60d83c4209c3363e1fbd3c0254cbc1210d12ab0b` — signup status and product SELECT migration
  - `cbb6c6f460670fce04a2647bbb0bc6a2b259c393` — source-contract test
  - `65a103d75b53d82e30b9abe3e2935e6b4ad140c5` — forward migration manifest update

## Validation boundary
- No tests, type-check, build, browser/device QA, or migration replay were run; user requested consolidated testing at the end.
- The new migration is source-only and has not been applied to TEST or Production.
- Production Supabase remains read-only. Protected `main` remains untouched.
- Development completion is a provisional estimate only; final QA and clean-install replay remain pending.
