# BiddWorld frontend ↔ live RPC contract and Supabase Advisor review — 2026-11-16

## Snapshot identity

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Source HEAD reviewed: `6cb98f56369a3816dd7ebe08f55bd7dddf7dbc81`
- Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`), PostgreSQL 17.11, `ap-south-1`
- Source migrations: 42 files.
- Production migration ledger: 30 rows.
- Exact timestamp-prefix matches: 4; 26 Production ledger versions have no same-version source filename.
- CI for reviewed HEAD: GitHub Actions run `43800939405`, conclusion `success`.

All Production inspection in this review was read-only. No SQL writes, migrations, settings changes, Auth changes, Storage operations, member-data changes, or financial actions were performed.

## Frontend RPC calls versus live Production catalogue

RPC calls were extracted from all ten current React source surfaces (`App.tsx`, Account, Admin, FixedBid, Notifications, Packages, PlacementTree, Referrals, Support and WalletHistory) and compared with the live `public` function catalogue.

### Calls without a matching live Production RPC contract

| Frontend call | Live Production status | Risk / dependency |
|---|---|---|
| `public_list_active_products_page` | Missing | Public Products page cannot use its branch RPC contract against current Production |
| `member_get_my_identity` | Missing | Member identity panel unavailable against live DB |
| `member_list_my_ids` | Missing | Member Main/Duplicate ID list unavailable against live DB |
| `member_update_my_profile` | Missing | Profile self-service save unavailable against live DB |
| `admin_list_members_sponsors_page` | Missing | New Admin pagination contract unavailable |
| `admin_list_duplicate_ids_page` | Missing | New Duplicate-ID pagination contract unavailable |
| `admin_set_product_active` | Missing | Product publish/hide action unavailable against live DB |
| `get_my_mlm_dashboard_page` | Missing | Paginated member genealogy contract unavailable |

### Signature mismatch

- Frontend calls `admin_create_duplicate_member_id(p_main_member_code, p_under_member_code)`.
- Production exposes only `admin_create_duplicate_member_id(p_main_member_code text)`.
- The source branch migration `20261115230000_duplicate_under_id_placement_attribution.sql` adds the Under / Placement ID argument and attribution fields. The current UI and live database are therefore not contract-compatible until an owner-approved and reconciled rollout.

### Existing live calls with behavior or constraints that remain different

- `admin_save_referral_plan_draft(uuid,jsonb)` exists, but Production enforces exactly five rules. Source migration `20261116030000_admin_configurable_referral_plan_depth.sql` changes this to configurable depth. This is not deployed.
- `lookup_sponsor(text)` exists, but Production returns a member code and display name. Source migration `20261116160000_minimize_public_sponsor_lookup.sql` changes the result to a boolean. This is not deployed.
- Other matching function names/signature families are not proof of body-level behavioral equivalence, authorization safety, response-shape compatibility or correct data semantics.

## Supabase Security Advisor — fresh snapshot

1. `rls_enabled_no_policy`: one table, `public.notification_templates`, has RLS enabled and no direct policies. It appears intended for RPC-only access; confirm all grants and Admin RPC paths remain tightly authorized.
2. `anon_security_definer_function_executable`: one finding, `public.lookup_sponsor(text)`, callable by `anon` as SECURITY DEFINER. This is an intentional signup lookup route in the current design, but it currently returns display-name information and should be minimized and rate-limited.
3. `authenticated_security_definer_function_executable`: 43 findings. These functions are callable by authenticated users as SECURITY DEFINER. This is expected for RPC-mediated access only if every function enforces trusted identity, Admin role where required, ownership, input validation and safe side-effects. The Advisor finding is a review signal, not proof that every routine is exploitable.
4. `auth_leaked_password_protection`: leaked-password protection is disabled. This Auth hardening change requires owner approval; it was not changed.

## Supabase Performance Advisor — fresh snapshot

1. One unindexed foreign key: `notification_templates.created_by` (`notification_templates_created_by_fkey`).
2. Seventeen indexes were reported unused at observation time, across auctions, audit logs, bids, delivery tracking, Fixed Bid, member IDs, package activations, referral commissions/plans, referrals, wallet transactions, winning payments and withdrawals.

Do not drop the 17 indexes based on this snapshot alone. Low traffic and Advisor sampling windows can make valid indexes appear unused. Review query plans and production workload before any index change. Assess the missing FK index against write/read patterns and rollout safety.

## Additional live lifecycle findings already recorded

The branch also contains `docs/PRODUCTION_RPC_LIFECYCLE_RETRY_FINDINGS_2026-11-16.md`, which records further read-only findings: inactive signup cannot submit a package request through the current live function; bid retries do not reuse a stable client idempotency key; withdrawal RPC lacks active Main-ID/min-max checks and does not reserve balance; all 21 public tables have RLS enabled but RLS is not forced. These are test/reconciliation dependencies, not permission to change Production.

## Migration reconciliation — confirmed counts

- Branch contains 42 SQL migration files, including two legacy/non-timestamp files.
- Production migration ledger contains 30 rows.
- Only 4 source filename timestamp prefixes exactly match Production ledger versions.
- 26 Production ledger versions have no same-version source filename.
- The 26 are not necessarily missing features; some may have equivalent source SQL under different timestamps or historical SQL absent from the repository. No semantic equivalence is assumed.
- Never replay baseline migrations or blindly replay the current source migration directory into Production.
- Recover authoritative applied SQL for missing historical versions or reconstruct and independently review live object definitions. Build a forward-only reconciliation plan from actual catalog diffs.

## Critical operational and financial blocks

- Production currently has package activation, Bid Wallet and Income Wallet feature settings set true, while `financial_model_approved` is absent.
- The live package approval RPC can approve an activation and credit Bid Wallet; the source-only financial interlock is not deployed.
- Do not approve package activations, post credits/commissions, place bids, process withdrawals, or settle winners in Production.
- Retain the inactive draft package only. Its ₹3,000 revenue versus ₹3,500 Bid Wallet credit plus up to ₹1,000 referral obligations implies a potential ₹1,500 deficit before expenses.
- No owner financial approval was supplied; no Production setting or schema change was made.

## Next safe engineering work

1. Add source-side contract tests for every frontend RPC argument and response shape.
2. Add a machine-readable expected RPC manifest and read-only live-drift checker that never exposes member data.
3. Complete manual body-by-body authorization review for every SECURITY DEFINER function, including 43 authenticated-callable routines and anon sponsor lookup.
4. Resolve missing source migration history and prepare a forward-only rollout/reconciliation plan.
5. Rehearse migrations in a disposable non-Production PostgreSQL/Supabase environment. If no zero-cost disposable environment is available, leave integration validation blocked.
6. Keep Auth settings, indexes, Production schema, financial settings and Storage unchanged until reviewed and explicitly approved.

## Verification boundary

This review confirms source/live RPC contract gaps and current Advisor findings only. It is not an E2E test, live application certification, migration rehearsal, penetration test, or launch approval.
