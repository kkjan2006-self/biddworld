# BiddWorld

Mobile-first React + TypeScript + Vite auction marketplace starter integrated with Supabase Auth and PostgreSQL.

## Run locally
1. Install Node.js 20 or newer.
2. Extract the ZIP and open a terminal in this folder.
3. Run `npm install`.
4. Copy `.env.example` to `.env`.
5. Add your Supabase project URL and public anon/publishable key.
6. Run `npm run dev`.
7. Run `npm run build` for a production bundle.

Never put a service-role or secret key in `VITE_*` variables or frontend code.

## Supabase setup
The SQL files in `supabase/migrations` describe a fresh-project baseline. Your BiddWorld Supabase project already has a database foundation. **Do not blindly execute these migrations against that existing project.** Compare table definitions, policies, grants and functions first, then apply only missing changes through reviewed migrations.

## Important
This is a development baseline, not a launch-ready financial platform. Read `docs/PRODUCTION_CHECKLIST.md`. Undecided money, referral, duplicate-ID, fixed-bid and winner-selection rules are intentionally not guessed. Those features must remain disabled until implemented and reviewed.
