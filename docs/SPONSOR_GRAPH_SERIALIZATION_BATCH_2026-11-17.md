# Sponsor graph concurrency hardening — 2026-11-17

## Change
- Added forward-only migration `20261117100000_serialize_admin_sponsor_graph_changes.sql`.
- The Admin sponsor correction RPC now obtains a transaction-scoped PostgreSQL advisory lock before reading the member/sponsor rows or traversing the referral graph.
- A single graph-wide lock intentionally serializes this low-frequency Admin operation. This closes the check-then-write race where two concurrent sponsor edits could each pass a cycle check against the same pre-update graph.
- Preserved the existing recursive downline cycle check, self-sponsor rejection, active Main ID sponsor requirement, audit-log insert, empty search_path, and authenticated-only execute grant with an in-function trusted Admin role check.
- Added `tests/admin-sponsor-graph-serialization.test.ts` to verify lock ordering and retained authorization/cycle guards.

## Verification and rollout
- GitHub Actions CI is running for the new commits; see the branch's latest workflow runs for final status.
- The regression test is a source-level migration contract test. It is not a live two-session concurrency test.
- No disposable TEST Supabase project is currently evidenced as connected, so PostgreSQL migration replay and concurrent transaction testing remain pending.
- This migration is committed to `completion-work` only and has NOT been applied to Production. No Production rows, schema, settings, or financial state were changed.
- Do not merge to `main` or deploy this migration until the complete ordered migration chain has been replayed and verified in a disposable non-Production database.
