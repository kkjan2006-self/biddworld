# Production migration ledger recovery archive

Exact SQL statement text retained in Production project's `supabase_migrations.schema_migrations` for all 30 recorded versions.

## Safety
- Historical evidence only; this is not an approved clean-install chain.
- Stored under `supabase/audit/`, outside `supabase/migrations/`, so Supabase CLI will not discover/apply these files automatically.
- Do not run this archive wholesale against Production or TEST.
- No application/member rows or secrets were exported; SQL was recovered from migration-history metadata.
- Reconcile dependencies and compare the reconstructed schema before moving anything into the executable migration directory.

## Source comparison
- 13 ledger entries have a same-name file in the current migration directory.
- 4 same-version-prefix files differ in content from the actual Production ledger SQL.
- 9 same-name source files have a different timestamp prefix, though their SQL text matches the ledger entry.
- 17 ledger names have no same-name source file.
- All 30 exact historical versions are archived here without overwriting current source.

Project: `hbqatszyzqobgtauyuzy`  
Branch: `completion-work`  
Parent commit: `4c221b2b6c02b58f0496b142acbc3e6dc0e169c7`
