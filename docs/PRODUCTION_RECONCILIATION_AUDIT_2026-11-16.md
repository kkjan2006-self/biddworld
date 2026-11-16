# BiddWorld Production Reconciliation Audit — 2026-11-16

## Scope and safety

This is a read-only snapshot of the connected `BiddWorld-Production` project (`hbqatszyzqobgtauyuzy`) and the `completion-work` source branch. No SQL DDL/DML, migrations, settings, Storage operations, or Production data changes were executed. The audit does not constitute a security certification or a test run.

## Current source branch

- Branch: `completion-work`
- Audited HEAD before this audit document: `fe68fd9b25e9368ced8ad456a881cb4d9f39abf4`
- Recent source-only migrations include financial approval guard, public product catalogue, Admin product/media management, configurable referral plan depth, member profile self-service, member identity summary, and Duplicate ID Under-ID placement attribution.

## UI-to-Production RPC reconciliation

The frontend RPC inventory was compared with the live public function catalogue.

### Frontend RPCs not currently present in Production

- `member_get_my_identity()`
- `member_list_my_ids()`
- `member_update_my_profile(text,text)`
- `admin_set_product_active(uuid,boolean)`

These are defined by source migrations or planned Admin product management code, but the connected Production function catalogue does not currently expose them. Member identity/profile/ID features and product publish/hide must not be described as live-ready until the matching migrations are reviewed and applied by the owner.

### RPC signature mismatch

- Production currently exposes `admin_create_duplicate_member_id(p_main_member_code text)`.
- The branch's `20261115230000_duplicate_under_id_placement_attribution.sql` intentionally replaces it with `admin_create_duplicate_member_id(p_main_member_code text,p_under_member_code text)`, sets `placement_parent_id`, returns `under_member_code`, and updates the Admin list RPC to return placement information.
- The Admin UI now matches the branch migration's two-argument signature and requires an active Under / Placement ID. It will not work against the currently deployed one-argument Production RPC until the migration is owner-approved and applied.

### Present but restricted / older behavior

- `admin_save_referral_plan_draft` exists in Production, but the branch's `20261116030000_admin_configurable_referral_plan_depth.sql` is not present in the Production migration history. Production remains subject to the existing five-level restriction until the branch migration is reviewed and applied.
- `admin_list_auction_products` and `admin_save_product_draft` exist in the live function catalogue; `admin_set_product_active` does not.

## Production migration history versus branch

The Production migration history does not include these later branch migrations:

- `20261115190000_member_profile_self_service.sql`
- `20261115203000_member_identity_summary.sql`
- `20261115230000_duplicate_under_id_placement_attribution.sql`
- `20261116000000_financial_approval_guard.sql`
- `20261116010000_public_active_product_catalogue.sql`
- `20261116020000_admin_product_management_and_media.sql`
- `20261116030000_admin_configurable_referral_plan_depth.sql`

The production migration ledger contains earlier migrations with related feature names under different version identifiers. Do not assume that a matching feature label means the later branch migration has been applied; reconcile actual function definitions, policies, triggers, and Storage state before any rollout.

## Read-only RLS observations

- `member_ids`, `profiles`, `wallet_accounts`, `wallet_transactions`, and `withdrawal_requests` currently expose owner-scoped authenticated SELECT policies.
- `products` has an authenticated SELECT policy restricted to `status='published'`.
- This snapshot does not inspect every table/policy, Storage bucket/policy, trigger, grant, or edge function. Full security review remains pending.

## Financial safety blockers

The current Production settings snapshot reports:

- `package_activations_enabled=true`
- `bid_wallet_enabled=true`
- `income_wallet_enabled=true`
- `referral_commissions_enabled=false`
- `withdrawals_enabled=false`
- `bidding_enabled=false`
- `fixed_bid_enabled=false`
- `winning_payment_enabled=false`
- `duplicate_ids_enabled=false`
- `automatic_placement_enabled=false`

The `financial_model_approved` setting is absent from the current settings snapshot. The source-only database guard migration has not been applied. The Admin frontend's package-approval lock is not a substitute for a server-side database guard. Treat package approval, wallet credits, commissions, withdrawals, bidding debits, and winning payments as blocked until the owner-approved financial/legal review and reviewed server-side guard are in place. Do not change Production settings as part of this work.

## Next implementation dependencies

1. Finish member account/profile/identity integration against the branch migrations; keep member identity and profile fields server-controlled.
2. Reconcile Duplicate ID placement creation/list/status workflows against the two-argument branch migration.
3. Reconcile product publish/hide and media policies with the actual Production Storage state before rollout.
4. Complete auction and fixed-bid lifecycle, including validation, timing, anti-abuse, and winner settlement; keep financial execution disabled.
5. Reconcile Admin referral plan depth, package request review, and financial interlock.
6. Only after implementation completion, run the requested full test matrix and security review. Do not claim passing tests before execution.
7. Owner approval is required before applying any Production migration or changing any financial setting. Domain/hosting purchase remains deferred.

## Verification status

- Production inspection: read-only SQL catalogue queries only.
- Source code inspection: completed for frontend RPC call inventory and relevant migration definitions.
- Tests: not run, intentionally deferred until implementation completion as requested.
- Production migrations/data/settings: untouched.

## Direct Production catalogue snapshot — 2026-11-16 (read-only)

A fresh read-only Supabase catalogue inspection was performed after the source audit above:

- Project BiddWorld-Production is reachable and reports ACTIVE_HEALTHY on PostgreSQL 17.11 in ap-south-1.
- The public schema currently contains 21 application tables. All 21 report RLS enabled.
- The live migration ledger contains 30 applied migrations; its latest entry is 20261115163218_admin_audit_log_pagination.
- The current source-only migrations dated 20261116 and the other branch-forward migrations listed above are not represented in that live ledger.
- The live schema contains the core member, package, wallet, referral, auction, fixed-bid, withdrawal, winning-payment, delivery, audit, settings and notification-template tables. Table presence and RLS-enabled status alone do not prove that every policy, grant, trigger, function or workflow is correct.
- The live database contains existing member/package/wallet rows. No row contents were modified, no DDL/DML was issued, and no migration was applied during this inspection.

### Current gate

Implementation can continue on completion-work using source-only changes. The Production integration is not rollout-ready until the branch migration set is reconciled against the live schema and function signatures, the financial interlock is installed through an owner-approved rollout, and the deferred test/security phase is completed. The 21/21 RLS result must not be represented as a complete security review.

## Expanded read-only security and grant review — 2026-11-16

- Reconfirmed 21 public application tables and RLS enabled on all 21.
- Supabase Security Advisor reports 43 authenticated-callable SECURITY DEFINER function signatures, one anon-callable SECURITY DEFINER function (lookup_sponsor), one RLS-enabled table with no direct policies (notification_templates), and leaked-password protection disabled.
- A read-only pg_proc inventory found trusted auth.uid() and app_metadata role checks in the Admin SECURITY DEFINER function bodies inspected at inventory level; member dashboard/withdrawal functions use authenticated-user checks. This is not a substitute for a full manual review of every function body.
- lookup_sponsor(text) is intentionally callable by anon for signup validation and returns an active Main ID and display name. Enumeration/rate limiting and data minimization remain a security review item.
- notification_templates has no direct RLS policy; access is intended through Admin-checked RPCs. Confirm all grants and RPC access remain aligned.
- Authenticated direct table grants on package_activations, wallet_accounts, wallet_transactions, withdrawal_requests and winning_item_payments are SELECT-only in the inspected Production grant snapshot. Financial writes occur through privileged RPCs/triggers, so the Admin approval RPC and database interlock are critical.
- Performance Advisor reports one unindexed FK on notification_templates.created_by and 17 unused indexes. Do not drop unused indexes without workload review.
- Production still has package_activations_enabled=true, bid_wallet_enabled=true, and income_wallet_enabled=true; financial_model_approved is absent. The new expanded interlock and feature-toggle approval check are source-only and NOT applied. Do not approve package activation, credit wallets, post commissions, place bids, enter Fixed Bid, process withdrawals or settle winners in Production.
- No Production settings, rows, schema, Storage objects or migrations were changed in this audit.

## Latest verified source checkpoint — 2026-11-16

- Source HEAD aaffdcdb4dad8dc08bef885d2b310adf5123d529 passed GitHub Actions run 43755981322: 17/17 Vitest files, TypeScript build and Vite production bundle.
- This verifies source CI only; it does not validate unapplied migrations or live Production integration.
- Vercel build-rate-limit contexts remain failures; no deployment was performed.

## Admin member directory limit confirmed — 2026-11-16

- Read-only `pg_get_functiondef` inspection confirms Production `admin_list_members_sponsors()` is a SECURITY DEFINER SQL function with trusted `app_metadata.role='admin'` check and a hard `LIMIT 500`; it has no search or pagination parameters.
- The Admin UI performs client-side search and CSV export only over those returned records. Implement a forward-only Admin-checked paginated/search RPC and update the UI before claiming complete member directory coverage.
- No Production function, table, grant, setting or data was changed.

## Latest source verification — 2026-11-16

- Commit `4b8e89f7e80f824cc5892126562603029f5f1d2e` passed GitHub Actions run `43756709964`: 20/20 Vitest files, TypeScript build and Vite bundle.
- The new Admin member directory pagination RPC migration remains unapplied; this is not live Production integration validation.
- Production remains unchanged.

## Admin member directory server-side search batch — 2026-11-16

- Commit `53bc09805e88e0ffc37108431593682a43b4326f` passed GitHub Actions run `43757646055`.
- CI verified 20/20 Vitest files, TypeScript project build and Vite 6.4.6 production bundle.
- Admin Main ID directory now sends the search term to the Admin-checked paginated RPC, searches all Main IDs server-side, loads subsequent matching pages with the same query, and exports all matching pages to CSV.
- This is still source-only integration. The new RPC migration `20261116090000_admin_members_sponsors_pagination.sql` is NOT applied to Production; live Production still has the legacy 500-row RPC. Do not use the updated UI against Production until a reviewed migration reconciliation is approved and deployed.
- No Production database, data, settings, financial records, or migrations were changed.


## Sponsor genealogy pagination CI and latest read-only snapshot — 2026-11-16

- Source batch commit `c3217f8180941cfc6c2d1c0d56841ec2edaee60b` completed GitHub Actions run `43759348588` successfully.
- CI: 21/21 Vitest files passed; TypeScript project build and Vite production bundle passed. `npm audit` reported 0 vulnerabilities at this run. This validates source code, not execution of the new SQL migration against Production.
- Added the authenticated `get_my_mlm_dashboard_page(integer,integer,text,integer)` RPC source migration and member-side server search, depth filter, 50-row pagination and Load More. The new migration remains unapplied in Production.
- Latest read-only Supabase snapshot: BiddWorld-Production ACTIVE_HEALTHY, PostgreSQL 17.11, ap-south-1; 30 applied migrations (latest `20261115163218_admin_audit_log_pagination`); 21 public tables, all 21 with RLS enabled.
- Security Advisor still flags 43 authenticated-callable SECURITY DEFINER signatures, one anon-callable SECURITY DEFINER signup lookup (`lookup_sponsor`), and leaked-password protection disabled. Performance Advisor flags one unindexed FK on `notification_templates.created_by` and 17 currently unused indexes. These require function-by-function grant/body review and workload-aware remediation; do not blanket revoke or drop indexes.
- The Production schema contains existing member/package/wallet rows. No Production SQL, DDL/DML, data, migration history, settings, Storage objects or financial records were changed during this turn.
- Production still lacks the source-only financial approval interlock; `financial_model_approved` was not present in the inspected settings. Package activation, wallet, bidding and payout controls remain blocked from owner approval. Do not enable financial operations.


## Fresh Production drift and security verification — 2026-11-16 (read-only)

A further direct read-only inspection was completed against the connected `BiddWorld-Production` project. No SQL writes, migrations, settings changes, Storage operations, or row changes were performed.

### Confirmed migration drift

- Production migration ledger currently contains **30 applied migrations**; latest is `20261115163218_admin_audit_log_pagination`.
- The branch contains forward migrations dated `20261116` that are not present in the Production ledger. The financial approval guard and expanded financial activity lockdown remain source-only.
- Production still exposes the one-argument `admin_create_duplicate_member_id(p_main_member_code text)`; the branch workflow expects the two-argument placement-aware signature. Do not use the branch Duplicate ID placement workflow against Production until its migration is owner-approved and reconciled.
- Production `place_bid` and `submit_package_activation` are SECURITY DEFINER wrappers that delegate to private SECURITY DEFINER implementations. The private implementations inspected derive the member from `auth.uid()`; bidding is additionally disabled by the current feature setting. This does not remove the need to install and verify the expanded source-only financial interlock before any financial enablement.

### Security review findings

- Catalog inventory confirms public Admin SECURITY DEFINER RPCs are executable by `authenticated` but not `anon`; the inspected Admin RPC bodies contain authenticated-user and `app_metadata.role = admin` checks. This is an inventory-level check, not a line-by-line certification of every function.
- At the time of the original read-only audit, `lookup_sponsor(text)` returned the exact-match active Main ID code and display name. The source branch subsequently adds `20261116160000_minimize_public_sponsor_lookup.sql`, which changes the response to a boolean while preserving signup compatibility. This privacy migration is not applied in Production. It does not implement server-side rate limiting; abuse throttling and enumeration controls remain launch blockers.
- Supabase Security Advisor currently reports leaked-password protection disabled. Enable it through the Auth security settings after owner review; it was not changed during this audit.
- Security Advisor reports multiple authenticated-callable SECURITY DEFINER functions. The execute grant alone is not proof of a vulnerability; every function body must be checked for authentication, ownership or trusted Admin authorization, fixed search_path and data minimization.

### Financial interlock — do not enable

- The Production settings snapshot still has `package_activations_enabled=true`, `bid_wallet_enabled=true`, and `income_wallet_enabled=true`; the `financial_model_approved` setting is absent.
- Production has not received `20261116000000_financial_approval_guard.sql` or `20261116080000_financial_activity_lockdown.sql`. The source guard is therefore not active in Production.
- Treat package approval, wallet ledger writes, commission credits, bid debits, Fixed Bid entries, withdrawals and winner settlement as prohibited until a complete forward-only migration is reconciled, independently tested and explicitly approved by the owner. Keep financial features disabled; do not infer safety from client-side locks.

### Required next actions

1. Reconcile every source migration against actual Production object definitions, not only migration version names; prepare a forward-only plan and dry-run in a safe non-production environment.
2. Review every exposed SECURITY DEFINER RPC body, especially the Admin RPCs, member withdrawal request, sponsor lookup and bid/package wrappers.
3. Add rate-limit/abuse protection for public sponsor lookup without breaking signup.
4. Owner to review and enable leaked-password protection in Auth settings.
5. Do not apply migrations or alter financial settings without explicit owner approval.


## Member data RLS spot-check — 2026-11-16 (read-only)

Reviewed live SELECT policies for `profiles`, `member_ids`, `referrals`, `wallet_accounts`, `package_activations` and `withdrawal_requests` in BiddWorld-Production. The observed authenticated SELECT policies scope profiles/member IDs to `auth.uid()`, and related rows through a member ID whose `owner_user_id=auth.uid()`; referrals allow rows where the caller owns either endpoint. No anonymous SELECT policy was returned for these six tables. This is a focused policy inventory, not a complete write-policy, column-privacy, or end-to-end RLS certification.

The same review reconfirmed Production's live `member_create_withdrawal_request` definition still lacks the source-branch active Main ID ownership guard; the new forward-only source migration remains unapplied. Production package submission also still requires an active Main ID until the pending migration chain is reconciled and applied under owner approval. Do not enable withdrawals, package approvals, wallet operations or bidding based on the source-only fixes. No Production changes made.


## Additional SECURITY DEFINER RPC review — 2026-11-16 (read-only)

Reviewed Production definitions and grants for member dashboard/tree, member withdrawal listing, duplicate-ID creation, and the public bid/package wrappers:

- `get_my_mlm_dashboard()` and `get_my_placement_tree()` require `auth.uid()`, derive the root Main ID from the caller's own profile, and use a fixed empty search_path. Their recursive traversal is depth-limited to 20 and has cycle protection. This was a source-body review, not an execution test under multiple user roles.
- `member_list_my_withdrawals()` requires authentication, derives the member ID from the caller's profile, and returns only that member's latest 100 requests. It includes `payout_details`; review whether the member UI needs the full payout JSON or whether a minimized projection is preferable. It does not itself verify that the profile's Main ID is owned by the caller; its safety depends on the integrity of `profiles.main_member_id` and profile write grants/policies, which need a separate audit.
- Production `admin_create_duplicate_member_id(text)` is Admin-gated and checks `duplicate_ids_enabled`, but only supports the one-argument signature and creates a pending duplicate without placement arguments. The branch's placement-aware flow is not Production-compatible until its migration is reconciled and owner-approved.
- Public `place_bid(uuid)` and `submit_package_activation(uuid,text)` wrappers have no inline `auth.uid()` marker because they delegate to private SECURITY DEFINER implementations. The private Production bodies were previously inspected and independently check `auth.uid()`; retain this wrapper/private-body pairing during any migration reconciliation.
- All reviewed public SECURITY DEFINER functions in the inventory had a fixed `search_path` configured. This inventory and targeted body review does not constitute a complete audit of every Admin function or every data field returned.

### Withdrawal migration compatibility note

Compared the source-only `20261116140000_require_active_main_id_for_withdrawals.sql` against the exact current Production `pg_get_functiondef` output. The migration preserves the current function signature, auth/amount/payout/feature-switch checks, Income Wallet lock and balance check, open-request guard, insert, audit record and response. Its deliberate authorization change is to verify that the profile's Main ID row is owned by `auth.uid()`, is a Main ID, and is active. This is a source review only; no non-production database execution test has yet been run, and Production remains unchanged. Do not apply it independently of the complete migration chain and explicit owner approval.


## Admin RPC + profile write-surface review — 2026-11-16 (read-only)

- Checked live privileges and RLS for `profiles` and `member_ids`: RLS is enabled; authenticated has SELECT but no direct INSERT/UPDATE/DELETE table privilege, anon has no SELECT/INSERT/UPDATE. The only observed SELECT policies are caller-owned rows (`profiles.id=auth.uid()`, `member_ids.owner_user_id=auth.uid()`). This reduces direct client-side profile mutation exposure; it is not a full column-level or Auth trigger audit.
- Reviewed ten high-impact Admin write RPCs (package approval/draft, referral-plan draft, feature settings, sponsor reassignment, duplicate status, auction draft, Fixed Bid draft, notification template and delivery tracking). Each inspected definition has a trusted `auth.uid()` plus `app_metadata.role='admin'` check and fixed empty `search_path`. This targeted sample does not certify every Admin RPC.
- **Critical financial finding:** Production `admin_review_package_activation(uuid,boolean)` is executable by authenticated callers but internally requires trusted Admin metadata. On approval it credits Bid Wallet and marks the activation approved/active. The live definition has no explicit `financial_model_approved` check. Production has no approval-guard triggers from branch migrations `20261116000000` / `20261116080000`; therefore the Admin UI lock is not sufficient protection against a privileged Admin approval. Keep this RPC unused and package approvals disabled until the database interlock migration chain is reconciled, tested in non-production and explicitly owner-approved.
- The source branch's `20261116080000_financial_activity_lockdown.sql` adds database triggers for wallet ledger inserts and activation approval updates, and prevents ordinary Admin feature switches from enabling protected financial features without trusted approval. Added a regression test asserting the Admin approval RPC is Admin-gated and the DB-level triggers cover both write paths. This is source-only and **not active in Production**.
- No Production data, settings, RPCs, policies, grants, or migrations were changed.


## Member withdrawal payout-data minimization — 2026-11-16

- The member dashboard's withdrawal history displays only the payout method label, but Production `member_list_my_withdrawals()` currently returns the full `payout_details` JSON, including stored UPI/bank identifiers that the member history UI does not need.
- Added source-only migration `20261116170000_minimize_member_withdrawal_payout_data.sql` to preserve the RPC's existing result shape while returning only `{method: ...}` in `payout_details`. This avoids a frontend contract change and reduces unnecessary exposure in the member session.
- Admin withdrawal listing still retains payout details for the authorized Admin review workflow; its Admin role gate and pagination were separately inspected.
- Added regression tests for the SQL projection and member UI usage. Migration is not applied to Production; reconcile it with the full migration chain and test on a non-production database first.


## Duplicate ID placement reconciliation — 2026-11-16

- Read-only Production inspection confirms `member_ids` already contains `main_member_id`, `placement_parent_id`, and `placement_position` columns.
- Production still exposes only `admin_create_duplicate_member_id(text)`. Its current definition creates a pending Duplicate ID attached to the owner Main ID but does not accept or set an Under / placement parent.
- Branch migration `20261115230000_duplicate_under_id_placement_attribution.sql` changes the workflow to the two-argument `admin_create_duplicate_member_id(text,text)`, separately validates the active owner Main ID and active Under ID, rejects placing a Duplicate ID under the same owner's own ID, records `placement_parent_id`, and keeps the new ID pending. The branch Admin UI now calls this two-argument flow.
- Therefore the current branch Duplicate ID creation UI is not Production-compatible until the forward migration is reconciled and applied. Do not run this UI against Production yet; the RPC signature mismatch will fail. No Production changes were made.
- Additional source review item: `admin_set_duplicate_id_status(uuid,text)` checks Admin authorization and lifecycle state, but does not revalidate the linked Main ID and placement parent when activating/reactivating a Duplicate ID. Add this to non-production integration tests and decide the intended behavior if either linked ID becomes suspended/closed before changing Production.
- Regression tests added for separate Sponsor/Under attribution, active parent validation, same-owner rejection, pending-only creation, and legacy RPC removal.

## CI verification update — 2026-11-16

- Source branch commit `e6d308437d89d3158bbca30433525baa0ee0812b` passed GitHub Actions run `43794384681`.
- CI reported 44 test files / 162 tests passing; the build step completed and npm audit reported zero vulnerabilities at that run.
- These checks validate source-level tests/build/dependency metadata only. They do not validate live Production migrations, actual Supabase Auth email delivery, browser/mobile PWA behavior, payment flows, or end-to-end financial controls.
- The inactive-until-verified migration no longer performs historical bulk status updates. Its trigger only activates the specific Main ID and profile tied to a package activation row transitioning to approved/active.
- Production remains unchanged; the financial interlock is still source-only and must be reconciled and owner-approved before rollout.


## Additional financial-approval key access review — 2026-11-16

A further read-only Production query verified the `app_settings` table grants and policies:

- `anon`: no SELECT/INSERT/UPDATE/DELETE table privileges.
- `authenticated`: SELECT only; no INSERT/UPDATE/DELETE.
- `service_role`: full table privileges (expected privileged backend role).
- The only observed RLS policy for `app_settings` is a scoped authenticated SELECT policy. It exposes a limited set of feature flags to members and broader settings to trusted Admin/Support/Finance metadata; it does not grant client-side writes.
- Production's current `admin_set_feature_setting` allowlist does not include `financial_model_approved`; the current Production function does not implement the newer source-only financial lock. The branch migration `20261116080000_financial_activity_lockdown.sql` preserves this separation: it checks the approval value and does not expose that key through the ordinary Admin feature switch RPC.
- The approval value must only be recorded through a trusted owner-controlled operational process after documented economics/legal review. Do not expose it to normal Admin toggles or user metadata. Do not set it in Production as part of this development work.

This is a targeted review of `app_settings` and the matching setting-writing functions discovered in Production, not a certification of every privileged backend pathway. Production remains unchanged.
