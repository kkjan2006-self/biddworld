# Production RLS, grants, SECURITY DEFINER and scheduler review — 2026-11-16

## Scope and safety
Read-only catalogue inspection of Production project `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`). No DDL/DML, role grants, settings, Auth users, wallet or financial records were changed.

## SECURITY DEFINER inventory
- 47 SECURITY DEFINER functions were found in the inspected `public` and `private` schemas.
- 43 are executable by `authenticated`; only one is executable by `anon`: `public.lookup_sponsor(text)`.
- Private schema USAGE: authenticated=true, anon=false. Private helper function ACLs are restricted to postgres (and service_role only where required); the member bid helper is not directly executable by authenticated users.
- Most public Admin RPCs grant EXECUTE to authenticated and contain an explicit `auth.uid()` plus Admin app_metadata role check. Function-by-function body review remains incomplete; this inventory is not proof all 43 are safe.
- `lookup_sponsor` remains the sole anonymous SECURITY DEFINER RPC and returns active Main ID member code and display name. This confirms the sponsor enumeration/privacy review item.

## Table privileges and RLS
- All 20 ordinary public tables inspected have RLS enabled; none has FORCE ROW LEVEL SECURITY.
- Authenticated has SELECT grants on public tables only; no direct INSERT, UPDATE, DELETE or TRUNCATE grants were found for authenticated.
- The authenticated SELECT policies inspected are owner-scoped for member data (profiles, member IDs, bids, activations, wallets, wallet transactions, withdrawals, winning payments, delivery tracking) or status-scoped for public catalogue data (active packages, published products, scheduled/live/ended auctions and fixed-bid campaigns).
- `audit_logs` SELECT is restricted to Admin/support/finance role metadata.
- `app_settings` SELECT policy exposes a small set of feature flags to authenticated users and allows Admin/support/finance broader reads.
- `notification_templates` has RLS enabled but no direct policies; authenticated has no table grant. Access is therefore unavailable through direct authenticated table reads, with Admin RPCs providing the intended route.
- No FORCE RLS is configured. SECURITY DEFINER functions owned by postgres can bypass RLS; their internal identity and role checks are therefore critical.

## Authentication trigger
- `auth.users` has one BiddWorld trigger: `on_biddworld_auth_user_created`, invoking `private.handle_new_auth_user()` after insert.
- The private handler is postgres-owned and not directly callable by anon/authenticated via function ACL.
- Full handler behavior and error/retry semantics should be separately tested in a disposable test project before launch; do not create test users in Production.

## Scheduler / automatic close
- The Production catalogue has no `pg_cron`, `pg_net`, `pgmq` or `pg_timetable` extension installed.
- The `cron.job` relation does not exist. No database-native scheduled job inventory is therefore available in this project snapshot.
- This means there is no evidence of a Production database scheduler for time-based auction close or fixed-bid campaign close. A browser countdown is not a substitute. Before enabling time-based close, deploy and verify a trusted scheduler/worker with idempotent locking and audit logging, using an approved deployment plan.

## Findings / launch gates
1. Keep financial features locked: previous audits found package approval and feature setting RPCs missing trusted owner-level financial approval checks.
2. Keep `lookup_sponsor` public only if product/privacy review explicitly accepts disclosure; otherwise remove anon execute, add rate limiting and abuse monitoring through a reviewed migration.
3. Complete line-by-line audit of all 43 authenticated-callable SECURITY DEFINER functions, especially Admin reads/writes, profile/member visibility and any service-role execution paths.
4. Review whether FORCE RLS is appropriate for tables touched by privileged functions; do not enable it blindly because postgres-owned SECURITY DEFINER functions currently rely on bypass behavior.
5. Build and test an actual server-side scheduler/worker before auction/fixed-bid time-based auto-close is considered implemented.
6. Test auth-user trigger provisioning, rollback, duplicate event handling and retry behavior in an isolated test project only.

This is a catalogue and focused security review, not a complete security audit or launch certification.
