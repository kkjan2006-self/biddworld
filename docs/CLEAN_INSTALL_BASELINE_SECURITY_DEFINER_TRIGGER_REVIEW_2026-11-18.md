# Clean-install baseline SECURITY DEFINER and trigger dependency review — 2026-11-18

## Scope

Source-only inspection of `supabase/clean-install/production_schema_baseline_candidate.sql`, cross-checked with the Production public RPC inventory and private-schema/trigger reconciliation documents. No Production or TEST database queries or writes were performed in this batch. No tests, builds, CI workflows or migration replay were run.

## Public function security review

The candidate baseline defines 47 functions: 43 public and 4 private. All 43 public functions are declared `SECURITY DEFINER` and have an explicit function-level `search_path` setting.

All 36 `public.admin_*` functions in the candidate were inspected for their authorization predicate. All 36 contain both a non-null `auth.uid()` check and an exact JWT `app_metadata.role = 'admin'` check, with a rejection path. `admin_list_members_sponsors()` is a SQL function that applies the same checks in its WHERE predicate; unauthorized callers receive no rows rather than an exception. This is still fail-closed for returned data.

The member-scoped public functions `get_my_mlm_dashboard()`, `get_my_placement_tree()`, `member_create_withdrawal_request(...)`, and `member_list_my_withdrawals()` reference `auth.uid()` in their definitions. The public `place_bid(...)` and `submit_package_activation(...)` functions are wrappers: their public wrapper bodies delegate to private implementations, which carry the member-authentication and business checks. Preserve those private targets and their order before the public wrappers in any reconstructed baseline.

`lookup_sponsor(text)` is the sole anon-executable public RPC in the recorded Production inventory. Its anon-facing result is restricted to the sponsor lookup display fields; it must not be generalized to other SECURITY DEFINER functions.

## Search path and private function boundary

The candidate retains explicit function-level search paths. Most public functions and private trigger/activation functions use an empty search path and schema-qualified application references. The `public.place_bid(...)` wrapper uses the specific `pg_catalog, public, private` path recorded in the Production inventory; do not normalize all functions to one shared setting.

The four private functions are:
- `private.enforce_feature_gate()` — trigger function.
- `private.handle_new_auth_user()` — auth signup trigger function.
- `private.place_bid(uuid)` — private bid implementation.
- `private.submit_package_activation(uuid,text)` — private activation implementation.

The baseline revokes app-facing EXECUTE privileges on all functions in `private`, then grants `service_role` EXECUTE only on `private.place_bid(uuid)`. The two trigger functions remain non-client-callable. Preserve this boundary; trigger invocation is not a reason to expose these functions as client RPCs.

## Trigger and object dependency order

The baseline defines all four private functions and the public function set before creating the trigger objects. It creates 11 application triggers:

1. `auth.users` AFTER INSERT → `private.handle_new_auth_user()`.
2. `public.bids` BEFORE INSERT → `private.enforce_feature_gate()`.
3. `public.delivery_tracking` BEFORE INSERT OR UPDATE → same feature-gate function.
4. `public.fixed_bid_campaigns` BEFORE INSERT OR UPDATE OF status → same function.
5. `public.member_ids` BEFORE INSERT OR UPDATE OF status, id_type → same function.
6. `public.package_activations` BEFORE INSERT OR UPDATE OF activation_status → same function.
7. `public.referral_commissions` BEFORE INSERT OR UPDATE OF status → same function.
8. `public.referrals` BEFORE INSERT OR UPDATE → same function.
9. `public.wallet_transactions` BEFORE INSERT → same function.
10. `public.winning_item_payments` BEFORE INSERT OR UPDATE OF status → same function.
11. `public.withdrawal_requests` BEFORE INSERT → same function.

The ten public-table triggers target the ten tables defined by the candidate. The auth trigger depends on the Supabase-managed `auth.users` table and must only be installed where the Supabase Auth schema exists. The baseline creates the app-owned `private` schema and the `pgcrypto` extension in the Supabase `extensions` schema; it must not attempt to recreate Supabase-managed `auth`, `storage`, `realtime`, `vault`, `extensions` or migration schemas. The `extensions` schema and `auth.users` are platform prerequisites.

The trigger statements occur after the corresponding trigger functions and application table definitions in the candidate. This source ordering is coherent. It does not prove successful SQL execution or validate platform-side trigger privileges; those remain part of isolated TEST replay at the final test gate.

## Baseline ACL reconciliation update

A fresh read-only Production catalogue query confirmed service_role EXECUTE on all 43 public functions, matching the candidate's 43 explicit public grants. The candidate's additional service_role grant on private.place_bid(uuid) preserves the private implementation boundary.

The same query found broad SELECT/UPDATE/USAGE grants on audit_logs_id_seq for anon, authenticated and service_role in Production, while audit_logs table privileges are limited to service_role and postgres. The candidate has been tightened to grant only USAGE to service_role and no sequence privileges to anon/authenticated. This is an intentional least-privilege deviation in the schema-only candidate; Production was not changed.

See `docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md` for exact observed ACLs and rationale.

## Conclusion

No evidenced function-authorization or trigger-order source defect was found in this pass. The 36 Admin authorization predicates, member-scoped auth checks, wrapper/private implementation boundary, explicit search paths, and 11-trigger dependency order are coherent in the candidate source. Outstanding service_role and identity-sequence ACL parity, complete function-body comparison to the historical archive, all forward migration dependencies, and TEST replay remain open. No speculative SQL change was made.
