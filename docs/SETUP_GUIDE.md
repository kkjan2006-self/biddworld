# BiddWorld setup and deployment guide

## 1. Requirements
- Node.js 20+
- GitHub account with access to `kkjan2006-self/biddworld`
- Supabase production project
- Hosting account such as Vercel or Netlify

## 2. Local development
1. Download or clone this repository.
2. Run `npm install`.
3. Copy `.env.example` to `.env`.
4. Set `VITE_SUPABASE_URL` to the Supabase project URL.
5. Set `VITE_SUPABASE_PUBLISHABLE_KEY` to the project's publishable key (or the legacy anon key variable if required).
6. Run `npm run dev`.
7. Run `npm test`, `npm run typecheck` and `npm run build`.

Never place a service-role or secret key in a browser environment variable, GitHub commit, screenshot or chat.

## 3. Supabase configuration
Use the existing production project only after checking its project reference. Do not apply the fresh baseline schema blindly to an existing database.
- Confirm Auth email settings and allowed redirect URLs.
- Confirm the signup trigger provisions exactly one Main ID and two zero-balance wallets.
- Confirm RLS is enabled on every exposed table and user reads are scoped to the authenticated member.
- Confirm all financial writes go through reviewed server-side RPCs/functions.
- Keep bidding disabled until test accounts, wallet edge cases, concurrency and auction timing have been verified.
- Set the production site's exact URL in Supabase Auth redirect allow-list.

## 4. Deploy with Vercel
1. Sign in to Vercel and choose **Add New → Project**.
2. Import `kkjan2006-self/biddworld` from GitHub.
3. Framework preset: **Vite**. Build command: `npm run build`. Output directory: `dist`.
4. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` under Project Settings → Environment Variables. Use Production, Preview and Development scopes as appropriate.
5. Deploy. Review the build log; do not treat a successful deployment as proof that financial workflows are production-ready.
6. Add the deployed domain in Vercel and configure the DNS records Vercel displays at your domain registrar.
7. Add the final HTTPS domain to Supabase Auth redirect URLs and test sign-up, sign-in and sign-out.

## 5. GitHub Actions
The repository CI runs dependency installation, tests, TypeScript checking and the Vite production build on pushes. Review the latest run in the repository's Actions tab before merging or deploying.

## 6. Launch gate
Read [PRODUCTION_CHECKLIST.md](./PRODUCTION_CHECKLIST.md) and [REMAINING_WORK.md](./REMAINING_WORK.md). Do not accept real payments or enable withdrawals, referral credits, fixed-bid settlement or winner payments until those flows have been implemented, reviewed and tested. Obtain appropriate legal, tax, consumer-protection and payment-provider advice for the operating jurisdictions.
