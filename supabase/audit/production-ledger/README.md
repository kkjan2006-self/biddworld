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

## Semantic comparison of the four same-version-prefix files

A second comparison removed SQL comments and whitespace before comparing the 4 files whose repository filename already matched a Production version:
- `20261114183412_secure_admin_member_sponsor_directory.sql`: normalized SQL matches the ledger exactly; the raw difference is comments/formatting only.
- `20261114183454_prevent_circular_member_sponsor_changes.sql`: normalized SQL matches the ledger exactly; the raw difference is comments/formatting only.
- `20261115154433_enforce_platform_feature_switches.sql`: normalized SQL matches the ledger exactly; the raw difference is comments/formatting only.
- `20261114161950_secure_bid_rpc_and_signup_provisioning.sql`: **normalized SQL differs materially**. The Production ledger version moves the already-existing `public.place_bid(uuid)` into `private` with `ALTER FUNCTION ... SET SCHEMA`, while the current source file defines/recreates the private implementation. The historical migration therefore assumes an earlier public function exists in the baseline. The legacy `0002_place_bid_rpc.sql` does define a public function, but it uses incompatible legacy table columns and statuses and cannot be treated as the matching Production prerequisite.

This confirms that the exact Production ledger archive is the reliable historical record, while a fresh-install baseline must first recreate the correct pre-ledger Production object contracts. Do not replace the current source file automatically and do not replay the old `0002` file as a shortcut.
