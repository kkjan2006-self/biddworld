# BiddWorld clean-install reconstruction (candidate)

This folder contains a schema-only baseline candidate reconstructed from read-only Production PostgreSQL catalogue evidence on 2026-11-18.

## Safety and status

- Target reference used for metadata capture: `hbqatszyzqobgtauyuzy` (Production).
- No application rows, member records, wallet balances, payment records, credentials, or secrets were exported.
- No Production or TEST writes were performed.
- `production_schema_baseline_candidate.sql` is **not yet an approved executable migration**. Do not run it against Production.
- Final replay and all integration testing are deliberately deferred until the complete development phase, as requested.
- The isolated TEST project remains the only permitted target for eventual replay.

## What the candidate contains

- 21 public tables and their 175 column definitions, defaults, identity attributes and nullability.
- 110 constraints.
- 28 non-constraint indexes (constraint-backed indexes are created by the constraints).
- 21 RLS enable statements and 20 exact public RLS policies.
- 47 current app-owned public/private function definitions with their captured search_path clauses.
- 11 application triggers, including the app-owned trigger on Supabase-managed `auth.users`.
- Captured table, sequence and function execution grants.

## Forward migration set

The Production schema snapshot already represents the live state through the Production ledger at the capture time. Therefore the historical migrations at/before `20261115163218` must not be replayed on top of this baseline. The same-name audit-log source migration `20261115180000_admin_audit_log_pagination.sql` is also excluded because its effect is already represented in the captured Production state.

The ordered source-only forward migration candidates are listed in `forward-migrations.txt`. This list is a review manifest, not proof that every migration is dependency-safe. Review source order and cross-file prerequisites before turning it into a CLI-executable chain.

## Required before calling this a canonical baseline

1. Review all 47 function definitions and ACLs against the current source and the recovered historical ledger archive.
2. Reconcile the 11 triggers and their private trigger functions.
3. Verify extension/schema prerequisites supplied by Supabase.
4. Verify any generated/identity sequences and their ownership/defaults.
5. Review the two Storage bucket migrations in the forward set.
6. Reconcile forward migration dependencies and duplicate effects.
7. At the final testing phase, replay only on the isolated TEST project and compare all catalogues, RLS, grants, RPC contracts and Storage policies.
8. Never apply this candidate to Production.

The baseline is intentionally a snapshot of Production's current schema, not a restoration of Production data and not a substitute for the historical SQL evidence archive under `supabase/audit/production-ledger/`.
