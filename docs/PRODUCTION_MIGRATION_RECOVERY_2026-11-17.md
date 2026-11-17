# Production migration recovery — sponsor and duplicate-ID evidence

Date: 2026-11-17  
Branch: `completion-work`  
Scope: read-only evidence collection; no production writes.

## Confirmed migration-ledger gap

The live Production migration ledger contains these two historical entries for which no matching SQL file exists in the current repository migration directory:

| Version | Applied migration name | Source status |
|---|---|---|
| `20261114181107` | `sponsor_referral_validation_and_admin_management` | Missing from current source tree |
| `20261114181114` | `admin_member_sponsor_listing` | Missing from current source tree |

GitHub path history for the two exact expected source paths returned no commits. Therefore the original SQL bodies cannot be recovered from the current branch's file history. Do not recreate files with those historical timestamps based only on their names.

The source does contain later sponsor-related migrations:
- `20261114183412_secure_admin_member_sponsor_directory.sql`
- `20261114183454_prevent_circular_member_sponsor_changes.sql`

Their existence does not prove they reproduce all behavior from the two missing historical migrations.

## Evidence bundle

The companion file `supabase/audit/production_migration_recovery.sql` contains SELECT-only catalog queries for:
- exact live sponsor and duplicate-ID RPC overload definitions, return types, security flags, settings and ACLs;
- relevant table columns/defaults;
- constraints, RLS policies, table grants, triggers and trigger function definitions;
- relevant index definitions.

Run it only as read-only catalog inspection. It intentionally does not query or export member/customer rows and contains no DDL, DML, RPC invocation or migration-ledger update.

## Recovery sequence

1. Export the full result sets from the read-only evidence bundle without member data.
2. Compare each live object with all current source migrations and tests.
3. Recover the missing historical SQL from an authoritative backup/export if available. If unavailable, mark the historical source as irrecoverable; do not fabricate it.
4. Design a new, forward-only reconciliation migration with a new timestamp after its dependencies have been reviewed.
5. Replay the complete proposed clean-install chain in isolated TEST and compare resulting catalog objects with the live Production snapshot.
6. Run role/ownership/RLS, sponsor-cycle, duplicate-placement concurrency and rollback tests in TEST.
7. Only after a separate explicit approval, plan a controlled Production deployment. Never replay the repository migration folder wholesale or insert guessed migration-history rows.

## Current limitation

The isolated TEST project has no applied migrations or application schema. The complete canonical bootstrap chain is still unresolved. This evidence bundle is a reproducible inspection aid, not a migration or proof of application behavior.
