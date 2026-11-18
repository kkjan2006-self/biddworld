# Production public RPC security-boundary inventory — 2026-11-18

## Scope
Read-only catalogue and function-definition inspection of Production project `hbqatszyzqobgtauyuzy`. This is a static security-boundary inventory, not a full line-by-line security certification. No DDL/DML, no data rows exported, no secrets, no Production/TEST writes, no migrations, tests, builds or deployment.

## Catalogue results
- Public functions: **43**.
- SECURITY DEFINER functions: **43/43**.
- SECURITY DEFINER functions with an explicit function-level `search_path`: **43/43**.
- Functions executable by `authenticated`: **43/43**.
- Functions executable by `anon`: **1/43** — `lookup_sponsor(text)`.
- Admin-named functions (`admin_%`): **36**.
- All 36 admin-named functions reference `auth.uid()` and the JWT `app_metadata`/role claim in their function definitions.
- `lookup_sponsor(text)` is the only anon-executable SECURITY DEFINER RPC. Its current definition returns only `member_code` and a display label for an active Main ID matching the supplied code; it does not return phone/email or a member list.
- `place_bid(uuid)` is a public SECURITY DEFINER SQL wrapper delegating to `private.place_bid(uuid)`.
- `submit_package_activation(uuid,text)` is a public SECURITY DEFINER SQL wrapper delegating to `private.submit_package_activation(uuid,text)`.

## Function access and authorization observations
1. Admin-named functions are granted to authenticated, not anon. Static definition inspection found both an authenticated-user check and a role-claim reference in all 36 bodies. The eventual baseline must preserve both function ACLs and function bodies; do not replace them with generic grants.
2. The three non-admin functions that do not directly reference `auth.uid()` are:
   - `lookup_sponsor(text)`: intentionally public sponsor-code lookup, limited to one active Main ID and two display fields.
   - `place_bid(uuid)`: wrapper delegates to the private implementation; inspect and preserve private implementation's auth and wallet checks.
   - `submit_package_activation(uuid,text)`: wrapper delegates to the private implementation; preserve its member identity, feature-gate, and package checks.
3. The member-scoped functions `get_my_mlm_dashboard()`, `get_my_placement_tree()`, `member_create_withdrawal_request(numeric,jsonb)`, and `member_list_my_withdrawals()` reference `auth.uid()`.
4. Every SECURITY DEFINER function has an explicit function-level `search_path` setting in the live catalogue. Preserve the exact setting per function. Do not assume a single common search path; `place_bid(uuid)` specifically uses `pg_catalog, public, private`, while the others in the inspected inventory use an empty search path and schema-qualify dependencies.
5. Since SECURITY DEFINER bypasses normal RLS, the function bodies and ACLs are essential parts of the security boundary. Table RLS and direct table grants alone are not enough to reconstruct behavior.

## Outstanding review before clean-install baseline
- Compare every one of the 43 complete function bodies against the recovered migration archive and current source migrations, including overloads.
- Manually inspect the complete bodies for the 36 admin functions to confirm the exact role-claim predicate and reject behavior, rather than relying only on the presence of the `app_metadata` token.
- Verify every wrapper's private target exists before creating the public wrapper.
- Confirm overload resolution for the two `admin_list_wallet_accounts` signatures and two `admin_list_wallet_transactions` signatures.
- Preserve the single anon RPC only if the sponsor lookup remains an intentional public feature; do not grant anon execution to other SECURITY DEFINER functions.
- Recheck Supabase Security Advisors on the isolated TEST project after the eventual baseline is installed; do not make Production changes during this phase.

## Checkpoint
- Branch: `completion-work`.
- Production project queried read-only.
- No database writes or migration applications.
- No build or tests; final testing remains deferred until development is complete.
