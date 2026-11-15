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
- A follow-up exact ACL audit on 2026-11-15 supersedes the preliminary grant observation above: `information_schema.role_table_grants` and `has_table_privilege` show that `authenticated` currently has **SELECT only** on the exposed tables where it has table grants; no authenticated INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES or TRIGGER privilege was found on the 20-table public inventory. The preliminary statement that authenticated had broad DML grants was incorrect and must not be used as a basis for a revoke migration. `service_role` has its expected broad table privileges; it must never be exposed to the browser.
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


### Frontend query and exact privilege audit (2026-11-15)

The current React source was inspected for every `.from()` and `.rpc()` call. Direct table reads are limited to:
- `auctions` (public live/scheduled listing query)
- `profiles` (current user's Main ID and account profile)
- `wallet_accounts` (current user's Main ID wallet balances)
- `member_ids` (current user's member IDs)
- `package_activations` (current user's Main ID activation history)
- `packages` (active package catalogue)
- `fixed_bid_campaigns` (published campaign listing; joined `products`)
- `wallet_transactions` (current user's Main ID history)

The current UI uses RPCs for sponsor lookup, bidding, package activation submission, member MLM dashboard, admin sponsor/member reports, audit-log listing and package activation review. The Admin component has no direct table `.from()` query in the inspected source.

Live Production RLS policies for the eight direct-read tables are SELECT-only:
- `profiles`, `member_ids`, `wallet_accounts`, `wallet_transactions` and `package_activations` are scoped to the authenticated user's own profile/member IDs.
- `packages` is restricted to active packages.
- `auctions` and `fixed_bid_campaigns` are restricted to scheduled/live/ended rows.
The source's auction query selects only live/scheduled rows, which is consistent with its policy.

An exact ACL check of `information_schema.role_table_grants` and `has_table_privilege` found that `authenticated` has SELECT only on the tables where it has grants; no authenticated DML/TRUNCATE/REFERENCES/TRIGGER privileges were present on the inspected public tables. The broad authenticated-DML warning in the earlier preliminary review has therefore been corrected above. Do **not** create a revoke migration from that preliminary statement.

The inspected RPC ACLs show `authenticated:EXECUTE` on the reviewed member/admin functions; `lookup_sponsor` additionally allows `anon:EXECUTE` for signup sponsor lookup. Admin RPCs must retain their explicit `app_metadata.role='admin'` checks. This audit did not change any grants, policies, functions or Production data.


### Production RPC inventory and frontend compatibility audit (2026-11-15)

A complete read-only catalog of non-extension application functions in the live Production database found eight exposed `public` RPCs and two application functions in the non-exposed `private` schema:

- `public.admin_get_member_structure()`
- `public.admin_get_mlm_overview()`
- `public.admin_list_members_sponsors()`
- `public.admin_set_default_sponsor(text)`
- `public.admin_set_member_sponsor(text,text)`
- `public.get_my_mlm_dashboard()`
- `public.lookup_sponsor(text)`
- `public.place_bid(uuid)`
- `private.handle_new_auth_user()` (signup trigger)
- `private.place_bid(uuid)` (bid implementation)

The current frontend also calls these RPCs, but no matching function was found in the live Production catalog:
- `submit_package_activation`
- `admin_list_pending_activations`
- `admin_list_audit_logs`
- `admin_review_package_activation`

This means the package activation request/review and admin audit-log UI paths are not backed by the corresponding live Production RPCs at the time of this inspection. Treat those flows as unavailable in Production; do not describe them as deployed or test them against live users until a reviewed migration is applied. The repository contains candidate SQL, but the production migration history/schema drift must be reconciled first.

The public SECURITY DEFINER functions inspected have an empty search_path and schema-qualified object references. Admin report and sponsor-management functions enforce a non-null `auth.uid()` plus `auth.jwt()->'app_metadata'->>'role' = 'admin'`; `get_my_mlm_dashboard()` requires authentication and derives the member ID from the caller's own profile. `lookup_sponsor(text)` remains intentionally callable by anon for signup lookup and returns a single exact-match active Main ID's code and display name; rate limiting and enumeration/privacy review remain launch requirements. The public `place_bid(uuid)` wrapper is SECURITY INVOKER and delegates to `private.place_bid(uuid)`, which is SECURITY DEFINER with a fixed search_path and performs the authenticated bidding checks and atomic wallet debit.

The only non-internal application trigger found on `auth.users` is `on_biddworld_auth_user_created`, which invokes `private.handle_new_auth_user()`. It creates the profile, Main ID and zero-balance wallets, and validates the requested/default sponsor according to the bootstrap rules documented above.

The Supabase security advisor currently reports one anon-callable SECURITY DEFINER function (`lookup_sponsor`) and seven authenticated-callable SECURITY DEFINER public functions. These are warnings for review, not proof of an authorization bypass; the reviewed admin functions have explicit role checks.

No Production schema, function, grant, trigger, or data was changed during this audit. The missing frontend RPCs and dashboard status mismatch are deployment blockers to resolve only after the full migration drift review and explicit deployment approval.


## Current recovery snapshot — 2026-11-15 (supersedes earlier snapshot statements above)

### Repository and CI

- Latest verified application-code commit on main: 0f75647a7d023a2bc76ff837eee0b1966e907168. The subsequent recovery-audit documentation update is committed on main.
- The latest GitHub Actions CI run 43736583121 completed successfully: all 36 existing tests passed, and TypeScript type-check plus Vite production build passed.
- The latest preview/package workflow 43736583153 completed successfully, including GitHub Pages preview build, Pages artifact upload, GoDaddy root-domain build, GoDaddy package artifact upload and the final Deploy to GitHub Pages job. The workflow reports success; the GoDaddy package is a build artifact only and has not been deployed to GoDaddy.
- The latest source fixes corrected an unmatched Admin JSX closing tag, two Admin TypeScript typing errors, and the Supabase embedded wallet relation type/export access. These changes are committed; no existing feature was intentionally removed.
- Dependency installation currently reports 6 npm audit findings (2 moderate, 2 high, 2 critical). The repository root does not currently include a package-lock.json, so dependency reproducibility and the full advisory details remain to be addressed. Do not run npm audit fix --force blindly.

### Live BiddWorld-Production snapshot

All checks below were read-only and targeted only project hbqatszyzqobgtauyuzy (BiddWorld-Production, ap-south-1, PostgreSQL 17). No production data, schema, grants, policies, or functions were changed during this audit.

- Auth users: 2; profiles: 2; member IDs: 2; audit log rows: 2.
- Package activations, wallet transactions, referral commissions, products, auctions, Fixed Bid campaigns, bids, Fixed Bid entries, withdrawals, winning payments and delivery records: 0 each.
- Public schema inventory: 21 ordinary tables; all 21 have RLS enabled. notification_templates is the current advisor finding with RLS enabled but no table policy; its intended access is through the Admin-only RPC, and direct table access should remain closed unless a reviewed policy is added.
- Supabase migration history now returns 30 applied versions (not the five shown in the earlier snapshot). The repository migration directory and live history still use differing version/name sets, so full migration reconciliation remains required; do not replay baseline migrations or fabricate history rows.
- The live database currently contains submit_package_activation, admin_list_pending_activations, admin_review_package_activation, admin_list_audit_logs_page and the recent Admin module RPCs. This supersedes the earlier statement that those activation/audit RPCs were absent. Continue to verify every RPC body and its grant/authorization rather than relying on existence alone.
- Exactly one Auth account currently has the Admin app_metadata role, and it matches the owner-requested primary Admin account. No password or credential was inspected or changed.
- The intended BiddWorld 1:5 Growth Package exists at ₹3,000 with ₹3,500 Bid Wallet credit and is inactive. A second inactive package row with an anomalous name also exists; preserve both until its origin and intended disposition are reviewed. No package was activated.
- Current feature settings: registration, sponsor referrals, package activations, Bid Wallet and Income Wallet settings are true; bidding, referral commissions, withdrawals, Fixed Bid, duplicate IDs, winning payments, delivery tracking, notifications and winner-selection configuration are false. The target package is inactive, so no active package is available for activation. Do not infer that a true wallet setting authorizes a financial workflow.

### Current security and backend-gate findings

- Security advisors currently report 43 authenticated-callable SECURITY DEFINER function findings and one anon-callable finding (lookup_sponsor). These are review findings, not proof that every function is exploitable. Admin RPCs inspected explicitly check the caller's app_metadata.role = admin; member RPCs must be reviewed individually. lookup_sponsor intentionally supports anonymous signup lookup and returns an exact active Main ID code/display name, but needs rate-limit and enumeration/privacy review before launch.
- Leaked-password protection is disabled in Supabase Auth and should be enabled in project Auth settings before public launch.
- Performance advisors report one unindexed foreign key on notification_templates.created_by and 23 unused-index observations. Do not drop indexes solely because they are currently unused; the project has very low traffic/data volume.
- private.place_bid() checks bidding_enabled and atomically debits Bid Wallet first then Income Wallet, but currently does not separately enforce the bid_wallet_enabled and income_wallet_enabled settings. Bidding is OFF, which blocks live bids today; add explicit wallet-feature checks during the reviewed forward-only backend reconciliation.
- private.submit_package_activation() checks that the selected package is active and prevents duplicate payment references, but does not itself check package_activations_enabled. All current packages are inactive, which prevents requests today; enforce the switch server-side before any package can be activated.
- member_create_withdrawal_request() checks withdrawals_enabled, but full minimum/maximum/fee rules, bank verification, reservation/debit semantics, Admin review and payout settlement are not complete. Withdrawals remain OFF.
- No commission posting engine, fixed-bid participation/winner algorithm, auction settlement, winning-payment settlement or actual payout provider has been activated.

### Immediate next development priorities

1. Complete a file-by-file source inventory and refresh this document after each verified batch.
2. Review every SECURITY DEFINER function and feature-switch enforcement; prepare only forward-only migration changes after reconciling the 30 live migration records against repository SQL.
3. Fix package activation and wallet feature-gate gaps in repository SQL/tests, without applying unreviewed SQL to Production.
4. Add lockfile and inspect/resolve dependency advisories without forced major upgrades.
5. Expand tests beyond the current 36 unit tests to isolated RPC/security integration tests and Android browser checks.
6. Finish Member Dashboard gaps (duplicate-ID attribution, sponsor details, notifications, account security) and Admin report/filter/export gaps without replacing existing modules.


## Follow-up recovery and preservation audit — 2026-11-15

This section supersedes conflicting earlier snapshots in this document and records the additional owner-requested development preserved after the main recovery prompt.

### Owner development preserved from GitHub history

The following work remains in the current main branch; it was not replaced or rolled back:

- Admin package draft create/edit (feb4cee), versioned five-level referral plan drafts (e09f434), read-only wallet balances/ledger (a42bf64, 7598be2), read-only withdrawal queue (6a0e5d0), product/auction drafts (5d46af9), Fixed Bid drafts (b013737), winning payment register (2566186), delivery tracking (2e81aac), Admin CSV exports (5b64477, 9d40de7), notification-template drafts (583c065), read-only Admin access view (9c33d64) and system-health panel (8583214).
- Platform Settings UI and server-side feature gates (15da896, 9404740), plus responsive Telugu explanations and mobile layout fixes.
- Member dashboard live genealogy/wallet data (2f4ebcf), withdrawal request UI (5077546), auction/Fixed Bid/report activity (bdaa5bf), placement tree and commission history (af053c0), one-section-at-a-time navigation (8bec18a, 327eab5), dashboard summary cards (88117fc, de0611d), personal CSV report (bfaca0a), transaction filters/export (d8efcad) and paginated wallet history (3aed363).
- Admin wallet-ledger pagination (b52477c), withdrawal queue pagination (2f5de43), audit-log date filters (2fc65d8) and server-side audit pagination (b01a6f7, 5f3d45f).
- Existing visual and navigation decisions from the preceding Admin and Member Dashboard redesign commits are preserved.

### Follow-up defects corrected

- Removed a redundant placeholder Admin wallet section that reused id="admin-wallets" alongside the real read-only wallet ledger. The real ledger module and its data loading remain intact. There is now exactly one Admin wallet section target.
- The Member Wallet History already fetched 100-row pages but did not render a control to request the next page. Added the “Load 100 more transactions” control, retaining wallet/direction filters and CSV export.
- Added Member “Winner & Delivery History” using the member's own winning_item_payments and delivery_tracking RLS policies.
- Added Member Account Security: authenticated password update through Supabase Auth and global session sign-out. No password is stored in BiddWorld.
- Added navigation regression tests for unique Admin targets, Member section targets, wallet pagination, and member-scoped winner/delivery/security paths.

### Latest code and automated verification

- Latest inspected main commit: ce1520f4b107123212bb1f9d5e5bffe020fe59ad.
- Latest CI run for that commit: 43738110894 — success; 6 test files and 40 tests passed; TypeScript type-check and Vite production build passed.
- The immediately preceding application-code commit c298491094c709c01c1df1306abacc18586f20f1 includes the Member Winner/Delivery and Account Security implementation. The latest commit after it adds the regression test.
- GitHub Pages/GoDaddy build workflow for the latest commit was still running at the time of this audit. Do not claim the newest preview deployment is complete until its deploy job reports success. The GoDaddy package is only a generated artifact, not a GoDaddy deployment.

### Current Production data and configuration

Read-only checks were performed only against BiddWorld-Production (hbqatszyzqobgtauyuzy). No production records, schema, settings, policies, grants or functions were changed in this follow-up.

- 21 public tables; RLS is enabled on all 21.
- Current observed rows: 2 Auth users, 2 profiles, 2 member IDs, 2 packages, 4 wallet accounts, 1 referral-plan version with 5 rules, 1 referral relationship, 2 audit-log rows and 16 app settings.
- Package activations, wallet transactions, referral commissions, products, auctions, Fixed Bid campaigns/entries, bids, withdrawals, winning payments and delivery records remain at zero.
- The intended BiddWorld 1:5 Growth Package remains inactive: ₹3,000 price / ₹3,500 Bid Wallet credit. Its version-1 referral plan is inactive and contains five fixed ₹200 level rules, each requiring an active Main ID and capped at depth 5.
- A second inactive package row named ", basic package" remains in Production at ₹3,000 / ₹2,500 Bid Wallet credit. It has not been edited or deleted; confirm its origin and intended disposition before changing it.
- Current settings: registration, sponsor referrals, package activations, Bid Wallet and Income Wallet are true; automatic placement, duplicate IDs, referral commissions, withdrawals, bidding, Fixed Bid, winner selection, winning payments, delivery tracking and notifications are false.
- Package activations being true does not make the intended package purchasable while that package remains inactive.

### Corrected backend feature-gate review

The live database has private.enforce_feature_gate() triggers on member IDs, referrals, package activations, wallet transactions, bids, referral commissions, withdrawals, Fixed Bid campaigns, winning payments and delivery tracking.

These triggers enforce the matching server-side setting, including:
- Package activation insert/activation requires package_activations_enabled.
- Bid and Income Wallet transaction inserts require their corresponding wallet switch.
- Bid creation requires bidding_enabled and validates each wallet debit against the matching wallet switch.
- Sponsor referral writes, duplicate ID activation, credited commissions, withdrawals, live Fixed Bid campaigns, paid winning payments and delivery changes are gated by their server-side settings.

Therefore, earlier statements that the current package-activation and bid wallet switches were not enforced by the backend are superseded: the triggers are present and their definitions were read from Production. private.place_bid() performs the atomic wallet debit; the database triggers add the wallet-specific switch checks. No live bid was attempted.

admin_set_feature_setting() permits enabling only the currently whitelisted, implemented settings: registration, sponsor referrals, duplicate IDs, package activations, Bid Wallet, Income Wallet and delivery tracking. It rejects enabling unfinished workflows such as referral commission payouts, withdrawals, bidding, Fixed Bid, winner selection, winning payments and notifications.

### Remaining work and launch blockers

1. Migration reproducibility: Production reports 30 applied migration versions while the repository currently contains 19 SQL migration files. The mapping and clean-database replay path are not yet verified. Do not replay baseline migrations, fabricate migration history or reset Production. Reconstruct and reconcile the missing/combined migration source before adding further Production DDL.
2. Dependencies: no root package-lock.json; the last dependency audit reported 6 findings (2 moderate, 2 high, 2 critical). Review advisories and lock exact dependency versions without forced major upgrades.
3. Security: leaked-password protection remains disabled in Supabase Auth. Security advisor SECURITY DEFINER findings need function-by-function review; the reviewed Admin RPCs check app_metadata.role='admin', member RPCs derive data from auth.uid(), and the public place_bid / submit_package_activation wrappers delegate to private functions that authenticate. lookup_sponsor is intentionally callable by anon for signup lookup and still needs rate-limit/enumeration review.
4. Performance: one missing index on notification_templates.created_by; 23 unused-index notices. Do not drop indexes based only on low-traffic unused-index notices.
5. Admin gaps: wallet balances/ledger are read-only; withdrawal queue is read-only; reports export currently loaded records as CSV rather than a complete paginated/date-filtered historical report set; notification templates are inactive drafts; role/access screen is read-only; a dedicated Security Audit view remains to be completed.
6. Package and commission gaps: package editor currently manages inactive name/description/price/Bid Wallet credit drafts, not full benefits/visibility/effective-date/activation-rule management. Referral-plan UI currently edits fixed amounts; the database supports fixed/percentage rule types, but the commission posting engine and historical immutable commission snapshots still need full implementation and isolated tests.
7. Financial workflows: withdrawal minimum/maximum/fees, bank verification, reserved-balance semantics, Admin review and payout settlement are incomplete. Keep withdrawals OFF. No real commission engine/payout is active.
8. Auction and Fixed Bid: product/auction and Fixed Bid draft creation exists. Reserve-price schema, auction publishing and live status controls, participant/bid registers, concurrency/winner calculation and Fixed Bid entry/participant/winner rules remain incomplete. Keep bidding and Fixed Bid OFF.
9. Winner/payment/delivery: winner and payment register is read-only; no winner selection or settlement is active. Admin delivery tracking is limited to paid winning-payment records; member read-only delivery history is now available. Address collection and courier-provider integration remain external/incomplete. Keep winning payments and delivery tracking OFF until the complete flow is tested.
10. Notifications: template drafts exist, but no in-app notification event table, recipient delivery/read workflow or notification center is implemented. Keep notifications OFF.
11. Member gaps: profile, IDs, packages, wallets, network, placement, transactions, commissions, auction/Fixed Bid activity, withdrawals, personal CSV, winner/delivery history and account security are represented. Notification center and any future sponsor/contact details not exposed by the current member-scoped RLS/RPCs remain pending.
12. Final validation: Android-device responsive and end-to-end workflow tests still need to be performed. Domain and GoDaddy hosting remain unpurchased and undeployed.

