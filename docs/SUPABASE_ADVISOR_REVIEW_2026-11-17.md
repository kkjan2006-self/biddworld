# Supabase Advisor Review — 2026-11-17

## Scope and safety

- Read-only review of Supabase Security and Performance Advisor results for `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`) and `BiddWorld-TEST` (`yoaauthwejdgaevfvwpo`).
- Production function catalogues and definitions were inspected with SELECT-only catalogue queries to distinguish generic SECURITY DEFINER warnings from missing authorization checks.
- No DDL, DML, RPC invocation, migration, Auth, Storage, wallet, payment, member or bidding operation was performed.

## Production — Security Advisor

| Finding | Severity | Count | Interpretation |
|---|---|---:|---|
| RLS enabled, no policy | INFO | 1 | `notification_templates` has RLS enabled and no table policies. Direct Data API access is denied by default; Admin reads/writes are through guarded RPCs. This is a restrictive configuration, not evidence of public exposure. |
| Public can execute SECURITY DEFINER | WARN | 1 | `lookup_sponsor(text)` is the only anon-executable SECURITY DEFINER function found. It returns only the active Main ID's member code and display name. It does not return phone, email, wallet, payment or account details. This is still a public lookup surface and should be kept minimal/rate-limited; the source privacy migration changes its response contract and must be TEST-rehearsed before deployment. |
| Authenticated can execute SECURITY DEFINER | WARN | 43 | Generic advisor warning for authenticated EXECUTE privileges. The live catalogue review found all 36 Admin overloads include both auth UID and JWT app_metadata Admin-role guard markers; all 36 are non-executable by anon. Other member-facing functions derive identity from auth.uid(). This static check does not replace role-by-role behavior tests. |
| Leaked password protection disabled | WARN | 1 | Supabase Auth's compromised-password protection is currently off. This is an Auth dashboard setting, not a schema migration. No setting was changed. |

### SECURITY DEFINER interpretation

The advisor flags a function because authenticated users can invoke it; it cannot determine from the grant alone whether the function body performs correct authorization. In this project, Admin RPCs are intentionally callable by authenticated sessions and must enforce Admin authorization internally. The inspected Admin overloads all have the required identity and app_metadata role guard markers, and anon cannot execute them. Do not revoke EXECUTE from the Admin RPC family wholesale: that would break the intended Admin client architecture without addressing function-body correctness. Continue individual behavior tests in TEST.

The one anon-executable function is `lookup_sponsor(text)`. Its present response is limited to member code and display name, but it remains a public enumeration/lookup endpoint. Review rate limiting and the pending privacy-minimization migration in TEST before any production rollout.

## Production — Performance Advisor

| Finding | Severity | Count | Interpretation |
|---|---|---:|---|
| Unindexed foreign key | INFO | 1 | `notification_templates.created_by` has no covering index. Consider a forward-only index migration after confirming query and write patterns. |
| Unused indexes | INFO | 17 | The Advisor reports 17 indexes not used in the observed statistics window. Do not drop them based only on this snapshot: the project is still low-activity and several indexes support foreign-key joins or future workflows. Re-evaluate after representative traffic and query-plan review. |

## TEST project

- Security Advisor: no findings.
- Performance Advisor: no findings.
- TEST currently has no applied migrations and no application schema. The empty result is expected and is **not** evidence that the application schema is secure or performant.

## Recommended actions

1. Keep Production read-only while migration history and source/live contracts are reconciled.
2. In TEST, verify the public sponsor lookup response is minimal and abuse-resistant; do not expose personal contact or financial information.
3. Add role-matrix integration tests for Admin RPCs using member, unauthenticated, and Admin JWT contexts. Static presence of an Admin role check is necessary but not sufficient.
4. Review `notification_templates` intended access. Keep the table policy-free if all access should remain RPC-mediated; otherwise add narrowly scoped policies only after the exact access model is documented.
5. Evaluate enabling leaked-password protection through the Auth dashboard after checking current sign-up/reset behavior. No change was made in this audit.
6. Add the missing `notification_templates.created_by` index only in a reviewed forward migration if the relationship is queried or parent deletes/updates need efficient enforcement.
7. Do not remove the 17 reported unused indexes until query plans, foreign-key requirements, and representative traffic justify each removal.

## Verification boundary

This report captures Advisor output and static catalogue evidence at 2026-11-17. It does not certify all SECURITY DEFINER function behavior, RLS row isolation, Auth settings, runtime performance, or production readiness.
