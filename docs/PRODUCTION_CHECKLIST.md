# Production readiness checklist

BiddWorld is a runnable frontend and development database baseline. It is **not yet a complete production financial platform**. The latest commit `ad8b94138d97e2bf1483418cf95b8629672a660f` has a successful GitHub Actions CI run and a successful GitHub Pages preview deployment. Vercel checks remain blocked by the provider's build-rate limit (retry in 24 hours); this does not invalidate the successful GitHub Actions build or Pages preview.

## Included in the repository

- Responsive React + TypeScript + Vite marketplace interface.
- Supabase email/password sign-up and sign-in.
- Auction and wallet read UI; bidding calls a server-side RPC with auction/wallet locking and Bid Wallet-first debit logic.
- Admin dashboard with member search, sponsor management, MLM overview and member structure reporting.
- Package payment reference/UTR submission UI with normalization and pending status; admin pending-activation review UI.
- Admin audit-log RPC/UI with search, filtering and CSV export.
- CSV formula-injection protection and unit tests for core helpers.
- SQL baseline, RLS policies and client-side use of the Supabase publishable/anon key.

## Database deployment status

- The package activation/admin review migration has been rollback-tested as SQL but **has not been applied to the production Supabase project**.
- Do not treat package activation, wallet credit, or audit RPCs as live until the migration is safely applied and verified against the intended production project.
- The first trusted administrator and default sponsor/Main ID still require secure provisioning.
- Keep service-role/secret keys out of frontend code and environment variables exposed to Vite.


## Verified production migration drift (2026-11-15)

A read-only inspection of the configured **BiddWorld-Production** project found a migration-history mismatch. Its Supabase migration history currently records only these five versions: `20261114161950`, `20261114181107`, `20261114181114`, `20261114183412`, and `20261114183454`. The repository contains no migration files for versions `20261114181107` and `20261114181114`. Repository migrations from `20261114200000` onward are not recorded in that production migration history, even though the live schema already contains a number of their newer columns and structures. Therefore, neither replaying the full repository migration directory nor simply marking files as applied is safe.

The live `get_my_mlm_dashboard()` and `admin_get_mlm_overview()` functions still compare `package_activations.payment_status` to `verified`, while the current repository's package-review workflow writes `approved`. The repository migration `20261115020000_admin_package_activation_review.sql` corrects those comparisons, but it is not recorded as applied in production. Its SQL was tested inside a transaction and rolled back; no persistent production change was made.

**Required next step:** reconstruct the missing historical migrations and compare every live object/function/policy with the repository before preparing a forward-only reconciliation migration. Do not apply baseline migrations, insert migration-history rows, or change production functions until that review is complete and explicitly approved.

## Still required before launch

1. Apply and verify pending migrations in staging, then production; review SECURITY DEFINER authorization, grants, RLS, idempotency and ledger writes.
2. Provision the first administrator through a trusted out-of-band process; no admin role assignment UI exists.
3. Complete receipt upload/storage policies if receipts are required beyond a payment reference/UTR.
4. Define and implement referral plan eligibility, trigger timing, version snapshots, approval and atomic commission posting.
5. Define duplicate-ID generation, admin toggle, placement traversal/slots and concurrency-safe Main-ID attribution.
6. Obtain owner-defined fixed-bid entry, tie, winner and settlement rules before implementation.
7. Obtain owner-defined auction close, tie, extension, cancellation and settlement rules before implementation.
8. Implement Income Wallet winning-item payment, delivery updates and notifications.
9. Define withdrawals (enable switch, min/max, approval/rejection/refund) and integrate a real payout provider; none is currently implemented.
10. Add rate limits, abuse prevention, monitoring, backups, privacy/terms/legal review and support workflows.
11. Expand unit/integration/browser E2E tests and complete independent security review.

## Explicitly not implemented

- No payment gateway or actual money transfer.
- No withdrawal payout.
- No automatic referral commission posting.
- No duplicate-ID generation or team placement.
- No fixed-bid winner algorithm or settlement.
- No auction winner settlement.
- No admin role assignment UI.

Do not enable bidding in production until backend authorization and real transaction scenarios have been reviewed and tested. Unknown business rules must remain disabled rather than being guessed.


### Signup migration regression caught before deployment

The pending `20261114200000_save_registration_phone.sql` originally replaced the Auth signup trigger without carrying forward the sponsor-referral validation/default-sponsor linking logic already present in Production (from the historical sponsor migrations `20261114181107` and `20261114181114`). Applying that version would have silently stopped validating/linking the submitted sponsor referral ID and default sponsor. The repository migration has now been corrected to preserve the live sponsor-validation behavior while saving the registration phone. The corrected SQL was executed inside a transaction and rolled back successfully; Production remains unchanged. This is a code correction, not a production deployment.


## Additional production security review (2026-11-15)

A further read-only review of live Production function definitions, execute ACLs and Supabase security advisors confirmed:

- The signup trigger is in the non-exposed `private` schema, runs as SECURITY DEFINER with an empty search_path, and its execute ACL is limited to the database owner. The trigger validates an explicitly supplied active Main ID sponsor, otherwise resolves the configured default sponsor, and only permits the no-sponsor bootstrap case when there are no active Main IDs. The live trigger also stores the registration phone and creates the Main ID wallets.
- Admin RPCs inspected (`admin_get_member_structure`, `admin_get_mlm_overview`, `admin_list_members_sponsors`, `admin_set_default_sponsor`, `admin_set_member_sponsor`) check a non-null authenticated user and the `app_metadata.role = admin` claim before privileged work. Their authenticated EXECUTE grants are therefore intentional; the advisor warnings alone do not establish an authorization bypass.
- `lookup_sponsor(text)` is intentionally callable by `anon` and `authenticated` for signup sponsor lookup. It returns only an exact-match active Main ID's member code and display name. However, it is an externally callable SECURITY DEFINER endpoint and has no rate limit in the function; add abuse/rate-limit protection and review enumeration/privacy risk before public launch. Do not revoke anon access without first changing the signup flow.
- Production advisor findings currently include one anon-callable SECURITY DEFINER function (`lookup_sponsor`) and seven authenticated-callable SECURITY DEFINER functions. The admin functions inspected include explicit app_metadata admin checks; `get_my_mlm_dashboard` checks authentication and derives the member from the caller's own profile. Continue reviewing every function body and its grants before launch.
- Live Production dashboard functions still use `payment_status = 'verified'` for activation counts, while the current repository activation approval flow uses `approved'`. This is a confirmed live reporting mismatch; correct it through a reviewed forward-only migration after full drift reconciliation, not by editing Production ad hoc.
- Live `app_settings` currently contains `bidding_enabled = false` (JSON boolean). No default sponsor setting is present, and the live `member_ids` table currently has zero rows. First-admin provisioning and default-sponsor bootstrap therefore remain unresolved.

No Production data or schema was changed during this review. Advisor findings are documented for triage; no blanket grant revocation or policy changes were made.


### Latest repository verification (2026-11-15)

- GitHub Actions CI run **99** completed successfully for `ad8b94138d97e2bf1483418cf95b8629672a660f`.
- GitHub Pages preview deployment run **67** completed successfully for the same commit.
- Vercel checks for that commit still report provider build-rate limiting. Treat Vercel as not deployed until a successful Vercel check appears.
- The repository migration `20261115020000_admin_package_activation_review.sql` combines package-activation schema/RPC work with dashboard function replacements. Although its dashboard definitions correct the `verified` → `approved` status mismatch, do not run this entire migration against Production merely to fix the dashboard: Production migration history and live schema are already divergent. Extract and validate a narrow forward-only dashboard reconciliation only after the full object/schema drift review.
- No Production migration or data change was made during this step.


### Public-schema table privilege review (2026-11-15)

Read-only inspection of the live Production `public` schema found:

- All 20 ordinary public tables inspected have RLS enabled. No table without RLS was found in this inventory.
- No ordinary public views were returned by the current `pg_views` query.
- The `authenticated` role has broad table-level privileges (including INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES and TRIGGER) on many exposed business tables. The currently inspected RLS policy set is predominantly SELECT-only and contains no member-facing write policies for those tables, so RLS currently blocks direct writes; however, the broad grants are unnecessary exposure and weaken defense-in-depth if a write policy is added accidentally later.
- The frontend source files inspected contain no direct Supabase `.insert()`, `.update()`, `.upsert()` or `.delete()` calls; privileged writes are intended to go through RPCs.
- Candidate hardening: revoke direct DML/DDL-like table privileges from `authenticated` on public business tables, then explicitly grant only the SELECT access required by the frontend and keep privileged mutations inside audited SECURITY DEFINER RPCs with strict authorization checks. Before drafting the migration, verify every frontend query and each RPC execution context so this does not break legitimate reads or privileged flows.
- RLS is enabled but not forced on these tables. This is not by itself a vulnerability for ordinary API roles; table owners and SECURITY DEFINER functions can bypass RLS, so privileged function review remains necessary.

This was an inventory only. No grants, policies, tables, functions, or data were changed in Production.


### Live RPC/function consistency review (2026-11-15)

Further read-only inspection of live Production function bodies and table constraints confirmed these concrete status mismatches:

- `admin_get_mlm_overview()` counts package activations with `payment_status='verified'`, but the live `package_activations_payment_status_check` permits only `pending`, `approved`, `rejected`, and `refunded`. Therefore its verified activation count will always be zero.
- `get_my_mlm_dashboard()` uses the same obsolete `payment_status='verified'` predicate for active package activations; this count will also be zero even for approved activations.
- `admin_get_mlm_overview()` sums commissions with status in `('credited','paid')`, but live `referral_commissions_status_check` permits only `pending`, `credited`, and `reversed`. The 'paid' branch is unreachable; credited rows are still counted.
- This is distinct from `winning_item_payments`, whose separate status constraint legitimately includes `paid`; do not conflate the two status domains.

Security review details:
- Live `lookup_sponsor(text)` is SECURITY DEFINER, callable by anon and authenticated, and returns only one exact active Main ID code and display name. It has no evident input-size bound or database-side rate limit in its body. Signup currently depends on anonymous sponsor lookup, so do not revoke anon execution without replacing that flow.
- `private.handle_new_auth_user()` is SECURITY DEFINER, has an empty search_path, and EXECUTE is limited to postgres. It reads signup metadata for the sponsor code, validates an active Main ID, supports configured default sponsor, and allows bootstrap only before any active Main ID exists.
- `private.place_bid(uuid)` is SECURITY DEFINER with fixed search_path and authenticated execution; it checks auth.uid(), the bidding_enabled setting, an active Main ID, auction timing/status, locks the auction and wallets, and atomically debits Bid Wallet then Income Wallet. Public wrapper `public.place_bid(uuid)` is SECURITY INVOKER.
- Admin sponsor-management and reporting RPCs inspected explicitly require an authenticated user with app_metadata.role='admin'. However, `admin_get_member_structure()` and `admin_get_mlm_overview()` require an admin role; the role-check pattern is consistent with the reviewed RPC set.

These findings are documented for a narrow future forward-only correction. No Production functions, grants, constraints, or data were changed.


### Narrow MLM dashboard status reconciliation prepared (2026-11-15)

- Added `supabase/migrations/20261115074500_reconcile_mlm_dashboard_statuses.sql` as a forward-only, narrowly scoped correction for the two live dashboard RPCs.
- The correction changes activation reporting from the impossible `payment_status='verified'` predicate to the live allowed value `approved`, retaining the active-activation filter.
- It removes the unreachable `paid` branch from referral commission totals because the live `referral_commissions` constraint permits only `pending`, `credited`, and `reversed`. The separate winning-item payment status domain is unchanged.
- Both full function definitions were reconstructed from the inspected live Production definitions; authorization checks, SECURITY DEFINER mode, and empty search_path are preserved.
- The SQL was executed inside `BEGIN ... ROLLBACK` against BiddWorld-Production and completed successfully. The transaction was rolled back; **no Production function or data change was persisted**.
- This migration is committed to the repository only. It has **not** been applied to Production. Do not apply until the complete production drift review is finished and deployment is explicitly approved.
- Supabase's current database-function guidance recommends a fixed search_path for SECURITY DEFINER functions; the existing empty search_path and schema-qualified references were retained. See https://supabase.com/docs/guides/database/functions.
- The November 2026 Supabase breaking-change review found no current database-function change affecting this SQL. The notable CLI v3 local-by-default behavior is relevant only if/when the CLI is used for deployment.
