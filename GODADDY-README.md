BIDDWORLD — GODADDY HOSTING PACKAGE

PACKAGE CONTENTS
- website/: production React/Vite website built for a root domain (base path /).
- database/migrations/: Supabase database migration SQL files.
- No passwords, Supabase service-role keys, or private credentials are included.

GODADDY WEBSITE UPLOAD
1. Use GoDaddy Linux Web Hosting with cPanel (or another static-file hosting plan).
2. Extract this ZIP on your computer.
3. Open cPanel File Manager -> public_html.
4. Upload the CONTENTS of the website/ folder into public_html (including .htaccess and assets).
5. Visit your domain over HTTPS.

IMPORTANT BACKEND REQUIREMENT
BiddWorld uses Supabase for authentication and database operations. Website files alone are not the complete backend.
Before public launch, apply the database migrations in database/migrations/ to the linked Supabase project in filename order, after reviewing them and taking a backup. Do not run them blindly on a database with existing data. The production project may already contain some migrations; reconcile its migration history first to avoid reapplying schema changes.
The frontend uses only the public Supabase publishable key. Never put a Supabase service_role/secret key in website files.

ADMIN ACCOUNT
This package does not create an Admin user or invent a password. After database setup, create the intended account through the website and verify its email. An authorized Supabase project owner must then assign app_metadata role=admin using Supabase Auth user management. Do not set admin access from browser code.

FUNCTIONAL LIMITATIONS
Auction bidding remains disabled until an Admin enables it and configures valid live auctions. Fixed-bid and winner/payment workflows must be configured and verified before being offered to members. Package activation, referral commissions, withdrawals and other money-related features must be validated against the live database and business rules before accepting real payments.

SECURITY / GO-LIVE CHECKLIST
- Enable HTTPS and confirm the domain points to this hosting account.
- Configure Supabase Auth allowed redirect URLs for the final domain.
- Confirm RLS is enabled and review policies and RPC grants.
- Reconcile/apply migrations in a backup-first controlled deployment.
- Create and verify the first Admin account; test role-protected routes and RPCs.
- Test signup, sponsor lookup, wallets, package activation, Admin approval and audit logs.
- Keep bidding disabled until auction rules and Admin configuration are complete.
- Do not accept real payments until all financial flows have passed end-to-end tests.

This package is a deployable frontend plus database migration source. It is not a claim that the production backend/Admin account is fully provisioned.
