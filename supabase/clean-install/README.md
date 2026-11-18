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

Ordered forward candidates are listed in `forward-migrations.txt` (56 files at this checkpoint). The 16 timestamped source files whose effects are already captured in the baseline are explicitly listed in `excluded-historical-migrations.txt`; do not replay those on top of the baseline. The repository test suite checks that every timestamped migration file is accounted for exactly once. This is a review manifest, not proof of dependency safety or successful replay.

## Remaining work before canonical status
1. Review all captured function definitions and ACLs against current source and the recovered historical SQL archive.
2. Reconcile trigger functions, trigger order, extension dependencies and identity sequence ownership.
3. Review every forward migration dependency and any repeated object replacement.
4. Include Storage bucket/policy migrations from the forward set.
5. At the final testing phase, replay only on TEST and compare schema, functions, RLS, grants and Storage; then run synthetic-data integration tests.
6. Never apply this candidate to Production.

This candidate reconstructs schema, not Production data. Historical SQL evidence remains archived under `supabase/audit/production-ledger/`.
