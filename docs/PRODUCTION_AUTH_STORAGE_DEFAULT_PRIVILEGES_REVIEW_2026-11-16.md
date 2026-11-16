# Production Auth provisioning, Storage and source-only remediation review — 2026-11-16

## Scope and safety
Read-only inspection of Production Auth trigger, Storage catalogue, bucket metadata and default privileges, plus source-branch migration review. No Production writes, grants, bucket changes, migrations, Auth-user creation or financial activity occurred.

## Auth signup trigger — live behavior
Production trigger `auth.users.on_biddworld_auth_user_created` invokes postgres-owned `private.handle_new_auth_user()` after Auth user insertion.
- Checks `registration_enabled`; registration is rejected when false.
- Reads `sponsor_referrals_enabled`; when enabled, validates requested/default sponsor as an active Main ID.
- Creates or updates the profile with status **active**.
- Creates a Main ID with status **active**.
- Creates zero-balance Bid and Income Wallet accounts.
- Creates referral linkage when sponsor is configured.
- Uses an empty search_path and fully-qualified table references; direct EXECUTE is restricted to postgres.
- Trigger operations run in the Auth insert transaction, so an exception aborts the Auth user insert as well.
- No Production test users were created. End-to-end behavior, duplicate/retry paths and signup rollback still require disposable TEST project verification.

Important lifecycle mismatch: live Production signup creates active profile/Main ID before package verification, while the source branch contains `20261116150000_enforce_inactive_signup_until_verified.sql` to create them as inactive. This source migration is not evidence of a live Production change.

## Source-only remediations discovered
Three relevant branch migrations exist but are not applied to Production:
1. `20261116150000_enforce_inactive_signup_until_verified.sql`: makes new profile and Main ID inactive until verification; preserves registration/sponsor switches.
2. `20261116160000_minimize_public_sponsor_lookup.sql`: changes anonymous sponsor lookup to return a boolean only (no member code/name). It still grants anon/authenticated EXECUTE, so IP/API rate limiting remains an edge/gateway responsibility.
3. `20261116190000_bid_request_idempotency.sql`: introduces client-supplied stable request key, advisory lock and replay result for duplicate bid requests. Requires disposable database migration tests and API/client integration before use.

The source branch also contains `20261116080000_financial_activity_lockdown.sql`, which adds database-level financial approval triggers and fail-closed feature settings. It is source-only and must not be blindly applied: it explicitly sets several live app settings to false and changes multiple RPCs/triggers. Full source-vs-live schema reconciliation and owner-approved rollout are mandatory.

## Storage findings
- Storage tables inspected have RLS enabled.
- No Storage RLS policies were returned by `pg_policies` for schema `storage`.
- `storage.buckets` currently returns no bucket rows.
- The Storage catalogue includes `storage.objects` with authenticated/anon table ACL entries, but absent RLS policies means direct row access is not granted by policy. This needs verification via supported Storage API tests in a disposable project; do not infer that direct table ACLs alone allow object access.
- No current application storage buckets are configured in this Production snapshot. Receipt uploads and product media therefore require a deliberate bucket and policy design before those features can be considered operational.

## Default privilege finding — high priority
Production `pg_default_acl` contains broad default grants for `public` schema objects owned by both `supabase_admin` and `postgres`:
- future tables: anon/authenticated receive broad CRUD privileges;
- future functions: anon/authenticated receive EXECUTE;
- future sequences: anon/authenticated receive usage/select/update.
Current explicit table grants and RLS reduce the exposure of existing objects, but these defaults create a migration hazard: newly created objects can become reachable unless each migration explicitly revokes privileges and configures least privilege/RLS.
Do not alter platform-managed global defaults without a controlled, owner-approved plan. Every new migration should explicitly set object grants and RLS, and tests should assert anon/authenticated cannot write directly.

## Required next work
1. Reconcile the three source-only signup/sponsor/idempotency migrations against the actual Production function signatures, table constraints and API client.
2. Validate signup lifecycle and Auth rollback in a disposable TEST Supabase project.
3. Validate the idempotency migration against live auction schema in TEST, including key replay, key reuse by another member, concurrent duplicate requests, and wallet-ledger exactly-once behavior.
4. Design private receipt/product-media buckets with narrowly scoped Storage policies and file validation before enabling uploads.
5. Establish migration templates/tests that explicitly revoke broad default grants on every new table/function/sequence and assert RLS policies.
6. Do not apply any source migration to Production without full reconciliation and explicit owner approval.

This focused review is not a complete security audit or launch certification.
