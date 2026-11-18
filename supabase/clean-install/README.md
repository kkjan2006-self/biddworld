# BiddWorld clean-install reconstruction (candidate)

Schema-only baseline candidate reconstructed from read-only Production PostgreSQL catalogue evidence captured on 2026-11-18.

## Safety and status
- Metadata source: Production `hbqatszyzqobgtauyuzy` (ap-south-1, PostgreSQL 17.11).
- No application rows, member records, wallet balances, payment records, credentials or secrets were exported.
- No Production or TEST writes were performed.
- `production_schema_baseline_candidate.sql` is **not an approved executable migration**. Never execute it against Production.
- Final replay and all integration tests are deferred until development completion; isolated TEST is the only permitted replay target.
- Supabase-managed schemas are prerequisites and are not recreated.

## Captured object inventory
- 21 public tables and 175 column definitions.
- 110 constraints and 28 non-constraint indexes.
- 21 RLS enable statements and 20 exact public RLS policies.
- 47 public/private function definitions, including captured search_path clauses.
- 11 application triggers, including the app-owned trigger on `auth.users`.
- Table, sequence and function grants; function/sequence default PUBLIC grants are revoked before explicit grants.

## Forward migration manifest
The baseline represents the current Production schema at capture time. Do not replay historical migrations at/before `20261115163218` on top of it. The source migration `20261115180000_admin_audit_log_pagination.sql` is excluded because its effect is already represented in the captured state.

Ordered forward candidates are listed in `forward-migrations.txt` (**70 files at the current branch checkpoint**). The 16 timestamped source files whose effects are already captured in the baseline are explicitly listed in `excluded-historical-migrations.txt`; do not replay those on top of the baseline. Together they account for all **86 timestamped migrations** in the current directory exactly once. The directory also contains three legacy/unversioned SQL files, all disqualified from clean installation. The repository test suite checks that every timestamped migration file is accounted for exactly once. This is a review manifest, not proof of dependency safety or successful replay.

## Remaining work before canonical status
1. Review all captured function definitions and ACLs against current source and the recovered historical SQL archive. Public function EXECUTE counts align with the Production inventory (43 authenticated, anon only public.lookup_sponsor(text)); read-only Production evidence confirms service_role EXECUTE on all 43 public functions. The candidate intentionally narrows audit_logs_id_seq to service_role USAGE only; effective permissions still require final TEST replay. See docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md.
2. Source review now confirms 43 public SECURITY DEFINER/search_path declarations, all 36 Admin auth predicates, four private function boundaries and 11 trigger dependencies are coherent in the candidate; see `docs/CLEAN_INSTALL_BASELINE_SECURITY_DEFINER_TRIGGER_REVIEW_2026-11-18.md`. Platform prerequisites (`auth.users` and Supabase `extensions` schema) must exist before replay. The candidate's least-privilege sequence grant is documented; exact effective grants require final TEST replay.
3. Review every forward migration dependency and any repeated object replacement.
4. Storage bucket/policy migrations, Admin pending-queue receipt-path integration, legacy receipt-read policy tightening, and Main/Duplicate placement-tree traversal are included in the forward set; final TEST replay and access verification remain pending.
5. At the final testing phase, replay only on TEST and compare schema, functions, RLS, grants and Storage; then run synthetic-data integration tests. CI is intentionally not triggered by `completion-work` pushes; the final verification workflow runs on `main` pushes / PRs to `main` and uses `npm ci`.
6. Never apply this candidate to Production.

This candidate reconstructs schema, not Production data. Historical SQL evidence remains archived under `supabase/audit/production-ledger/`.

## Current static reconciliation checkpoint

See [`docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md`](../../docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md) for the current focused migration dependency, lockfile/advisory, CI sequencing and PWA source review.

See [`docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`](../../docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md) for the verified 89-file inventory, baseline object counts, migration sequencing observations, Storage policy final-state dependency, and the current CI result. Function ACL findings are recorded in [`docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md`](../../docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md). All findings are source-level only; no TEST or Production replay has occurred. The member Main-ID lifecycle serialization review is recorded in [`docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md`](../../docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md).


## Canonical clean-install path clarification (source-only)

The legacy `supabase/migrations/0001_biddworld.sql` schema is not the clean-install starting point and must not be combined with the current forward chain. The intended candidate path under review is the schema-only `production_schema_baseline_candidate.sql`, followed by the ordered entries in `forward-migrations.txt`. Static comparison confirms that the candidate defines the canonical columns used by the first forward migrations, including `profiles.phone`, `profiles.main_member_id`, `member_ids.owner_user_id/id_type/status`, `wallet_accounts.member_id`, `referrals.source_member_id`, and `package_activations.activation_number/payment_status/activation_status`. This resolves the specific old-legacy-shape mismatch for this candidate path, but does not prove every dependency or SQL body compiles. Candidate approval and TEST replay remain pending.


The support-ticket and member-notification frontend write paths were reconciled against table grants and RLS. Direct support-ticket INSERT/UPDATE and direct notification INSERT were unnecessary because the UI uses audited, idempotent RPCs. Forward candidate #67 removes table-level support INSERT/UPDATE and notification INSERT grants. Follow-up candidate #68 explicitly removes the residual support-ticket column-level INSERT/UPDATE grants left by the original migration. Owner/Admin SELECT and owner-scoped notification read-state UPDATE remain; audited idempotent RPCs are the intended support write paths. See `docs/SUPPORT_TICKET_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`. See [`docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md`](../../docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md).


## Notification column privilege follow-up (#69)

The original member-notification migration separately granted column-level INSERT on (user_id, title, message, category). Candidate #67 revoked table-level INSERT only; the Admin-only RLS insert policy still allowed an Admin to bypass the audited/idempotent delivery RPC if the column grant survived. Candidate #69 explicitly revokes both table-level and column-level INSERT from authenticated. Owner-scoped UPDATE(read_at) remains intentionally available for members marking notifications as read. See [the notification column privilege follow-up](../../docs/MEMBER_NOTIFICATION_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md). The ordered forward manifest now contains 70 candidates + 16 excluded timestamped migrations + 3 legacy SQL files = 89 SQL files. Source-only; no replay or database verification has occurred.


## Fixed Bid public rules projection (#70)

`20261119000000_fixed_bid_public_rules_projection.sql` replaces the restricted public catalogue RPC projection to include `max_entries_total` and `refund_non_winners`, alongside the existing entry amount, winner payment, per-member limit, winner count and schedule. These are the published campaign rules consumed by the Member Fixed Bid catalogue. The RPC remains a bounded, stable, title-search/status-filtered projection over published products and scheduled/live/ended campaigns; it does not grant direct anonymous table reads. It retains explicit EXECUTE grants only for `anon` and `authenticated`. This is source review only; PostgreSQL replay and runtime access verification remain pending.
