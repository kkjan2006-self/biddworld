# BiddWorld

Mobile-first React + TypeScript + Vite auction marketplace starter integrated with Supabase Auth and PostgreSQL.

## Run locally
1. Install Node.js 20 or newer.
2. Extract the ZIP and open a terminal in this folder.
3. Run `npm install`.
4. Copy `.env.example` to `.env`.
5. Add the URL and public publishable key for the selected environment. Start with `VITE_BIDDWORLD_MODE=preview`; use `test` only with a separate disposable Supabase project. Never use Production for test records.
6. Run `npm run dev`.
7. Run `npm run build` for a production bundle.

Never put a service-role or secret key in `VITE_*` variables or frontend code. The app no longer has a hardcoded Production URL/key fallback: missing or invalid environment configuration leaves it disconnected.

## Supabase setup
The SQL files in `supabase/migrations` describe a fresh-project baseline. Your BiddWorld Supabase project already has a database foundation. **Do not blindly execute these migrations against that existing project.** Compare table definitions, policies, grants and functions first, then apply only missing changes through reviewed migrations.

## Important
This is a development baseline, not a launch-ready financial platform. Read `docs/PRODUCTION_CHECKLIST.md`. Undecided money, referral, duplicate-ID, fixed-bid and winner-selection rules are intentionally not guessed. Those features must remain disabled until implemented and reviewed.

## Environment isolation and email confirmation

- `preview`: safe disconnected preview; requires explicit Supabase configuration before connecting.
- `test`: requires a separate disposable Supabase project. The frontend refuses the known BiddWorld-Production project reference.
- `live`: only accepts the approved BiddWorld-Production project reference.
- Do not copy Production data into the test project. Create synthetic test members and records only in the isolated test project.
- Email confirmation is a Supabase Auth project setting, not a frontend preference. In the disposable TEST project only, an authorized project owner may turn **Confirm email** off under Authentication → Sign In / Providers → Email (the dashboard labels may vary). Turn it on again for LIVE and verify the production redirect URLs before launch. Never disable confirmation in Production to make test signups easier.
- Keep the test project on the free tier and within its quotas. If no separate test project is available, stay in Preview mode; do not use Production for test data.
- Financial package, wallet, referral, bid, winning-payment and withdrawal rules remain subject to their existing server-side approval gates. Environment mode is not a substitute for database authorization.
