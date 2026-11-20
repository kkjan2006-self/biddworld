# Production sponsor and Duplicate ID live-contract audit

Date: 2026-11-17
Branch: `completion-work`
Method: SELECT-only PostgreSQL catalogue inspection against Production. No member/customer rows were queried.

## Verified live RPC definitions

| RPC | Live Production contract | Source branch contract |
|---|---|---|
| `admin_set_member_sponsor(text,text)` | Returns void; SECURITY DEFINER; empty search_path; authenticated EXECUTE; admin role checked inside function | Same signature; latest source migration adds graph-wide transaction advisory lock |
| `admin_create_duplicate_member_id(text)` | One text argument; returns jsonb; SECURITY DEFINER; empty search_path; authenticated EXECUTE; admin role checked inside function | Later source migration replaces it with two text arguments (Main ID + Under ID), drops old one-arg overload |
| `admin_list_members_sponsors()` | No arguments; returns member_code, display_name, phone, sponsor_code, created_at; capped at 500 rows | Frontend has a paginated sponsor-directory path; live function is not the paginated signature |
| `lookup_sponsor(text)` | Returns member_code and display_name; SECURITY DEFINER; anon EXECUTE is granted | Source privacy migration must be compared before deployment; this is a public pre-auth lookup |

### Critical behavior mismatch

Production `admin_set_member_sponsor(text,text)` performs its recursive descendant-cycle check but does not acquire the graph-wide advisory lock present in source migration `20261117100000_serialize_admin_sponsor_graph_changes.sql`. Two concurrent Admin changes can therefore both evaluate against a pre-update graph. The source migration is not deployed.

Production `admin_create_duplicate_member_id(text)` only attaches a new pending Duplicate ID to its Main ID; it does not accept or store a selected Under ID. The source two-argument contract and serialization migration are not deployed.

Do not create a client fallback to the one-argument RPC: that would silently discard the requested Under ID placement behavior.

## Verified live schema details

- `public.member_ids` contains `owner_user_id`, `main_member_id`, `member_code`, `id_type`, `status`, `placement_parent_id`, and `placement_position`.
- `member_ids.id_type` is constrained to `main` or `duplicate`; status is constrained to `pending`, `active`, `suspended`, or `closed`.
- `member_ids.main_member_id` and `placement_parent_id` reference `member_ids(id)` with ON DELETE RESTRICT.
- `member_ids.member_code` is unique. Indexes exist for `main_member_id` and `placement_parent_id`.
- The live `member_ids` RLS policy permits authenticated users to SELECT rows where `owner_user_id=auth.uid()`; no direct Admin-wide SELECT policy was found in this targeted policy query. Admin directory access is via SECURITY DEFINER RPCs.
- The live `audit_logs` SELECT policy allows authenticated roles admin, support and finance. Service role has table grants; authenticated direct write grants were not present in the returned grant list.
- A BEFORE INSERT OR UPDATE OF status,id_type trigger on `member_ids` calls `private.enforce_feature_gate()`. It blocks activation of Duplicate IDs when `duplicate_ids_enabled` is false.
- RPC ACLs inspected: sponsor and duplicate-ID Admin functions are executable by authenticated and service_role, not anon/public; the public `lookup_sponsor(text)` function is executable by anon, authenticated and service_role. All inspected SECURITY DEFINER functions use an empty search_path and check the Admin JWT role where applicable.

## Interpretation and boundaries

- The live Production catalogue confirms that some later source migrations are not reflected in Production.
- The two-argument Duplicate ID placement feature is not live in Production even though the database already has placement columns.
- Sponsor graph concurrency protection is not live in Production.
- These are catalogue-level findings, not proof from concurrent transactions or browser E2E tests.
- The source migration chain remains unreconciled and isolated TEST remains empty. Do not apply any source migrations to Production or TEST until the clean-install baseline is reconstructed and replayed.
- No Production writes, schema changes, RLS changes, RPC calls, member rows, wallet rows or financial transactions were performed in this audit.

## Next actions

1. Reconcile the live RPC definitions with every migration that creates/replaces them, including the missing historical sponsor migrations.
2. Resolve the source-only two-argument Duplicate ID contract and confirm intended Under ID placement semantics against approved product rules.
3. Reconstruct a canonical baseline and replay it from zero in isolated TEST.
4. Run actual PostgreSQL concurrency tests for sponsor graph changes and Duplicate ID placement in TEST.
5. Only after clean-install and regression gates pass, prepare a separately reviewed deployment plan. Production remains untouched.
