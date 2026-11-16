# Production RLS, Function Grants and Trigger Audit — 2026-11-17

## Scope and method

- Target: `BiddWorld-Production`, Supabase ref `hbqatszyzqobgtauyuzy`.
- Read-only catalogue inspection of PostgreSQL `pg_class`, `pg_policies`, `pg_proc`, `pg_trigger`, ACL-derived privilege checks and function definitions.
- No RPC was executed. No table rows were read. No database writes or configuration changes were performed.

## RLS and table grants

- 21/21 ordinary `public` tables have RLS enabled.
- 0/21 tables use FORCE ROW LEVEL SECURITY.
- 20 direct public policies exist. All 20 are SELECT policies; no direct INSERT, UPDATE or DELETE policies were found.
- The 21st table, `notification_templates`, has no direct policy. Direct SELECT/INSERT/UPDATE/DELETE privileges for `anon` and `authenticated` are false in the inspected ACL snapshot. This appears deny-by-default at the table surface; do not add a broad policy merely to clear an advisor warning.
- `anon` has no direct table privileges among the inspected public tables. Authenticated direct writes are also false across the inspected public tables. Mutation flows are intended to go through RPCs.
- `audit_logs`, `notification_templates`, `referral_level_rules`, and `referral_plan_versions` are not directly selectable by authenticated users in the inspected privilege snapshot, despite policies existing on some of them. This is consistent with narrow RPC-mediated access.

## SECURITY DEFINER functions and grants

- 43/43 public functions are SECURITY DEFINER.
- All 43 have an explicit function-level search_path configuration.
- 42/43 are not executable by `anon`; one exception is `lookup_sponsor(text)`.
- All 43 are executable by `authenticated`. This is not by itself proof of a vulnerability: Admin functions inspected in the live definitions explicitly require `auth.uid()` and `auth.jwt()->'app_metadata'->>'role' = 'admin'`. The complete Admin routine set should still be reviewed function-by-function and role-by-role; do not mass-revoke authenticated execution.
- The Admin function samples inspected (duplicate ID creation, feature settings, member structure, MLM overview, platform health and admin account listing) each contain an explicit JWT app_metadata Admin-role guard and a null-user guard.
- `lookup_sponsor(text)` is the clear exception: callable by `anon`, SECURITY DEFINER, and its live body has no `auth.uid()` check. It currently returns a table containing `member_code` and `display_name`. This remains a privacy-hardening priority. The branch migration `20261116160000_minimize_public_sponsor_lookup.sql` changes the return contract, but must not be applied to Production until the full migration chain is reconciled and verified in TEST.

## Trigger inventory

Production currently has 10 non-internal public-table triggers, all calling `private.enforce_feature_gate()`:

- `bids`: before insert
- `delivery_tracking`: before insert/update
- `fixed_bid_campaigns`: before insert or status update
- `member_ids`: before insert or status/id_type update
- `package_activations`: before insert or activation_status update
- `referral_commissions`: before insert or status update
- `referrals`: before insert/update
- `wallet_transactions`: before insert
- `winning_item_payments`: before insert or status update
- `withdrawal_requests`: before insert

All three app-facing roles checked (`anon`, `authenticated`) lack CREATE privilege on `public` and `private` schemas, reducing search-path object-shadowing risk for these roles. The one legacy `place_bid` function uses `search_path=pg_catalog, public, private` rather than an empty path; keep this as a hardening/review item because it is SECURITY DEFINER, but do not change it without verifying all referenced objects and qualification behavior.

## Interpretation and follow-up

1. RLS enablement and deny-by-default direct write grants are strong baseline controls, but they do not certify each SECURITY DEFINER routine.
2. Prioritize `lookup_sponsor(text)` because it is the only anonymous-callable SECURITY DEFINER routine and returns identifying display data.
3. Review the full body and exact role conditions for all Admin RPCs, then verify the grants for every overload.
4. Review `place_bid(uuid)` search_path and compare its body with the intended idempotent source implementation.
5. Preserve `notification_templates` as direct deny-by-default unless a verified user-facing use case requires a narrowly scoped policy.
6. Continue full source/live migration reconciliation and a clean replay in a separate disposable TEST Supabase project before any Production rollout.

## Safety

This was read-only metadata inspection. No Production DDL/DML, function execution, migration, RLS/policy/grant change, trigger change, Auth setting, Storage setup, member, wallet, payment, bid or withdrawal operation was performed. The `main` branch was not modified.
