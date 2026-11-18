# Clean-install baseline incompatibility audit — 2026-11-18

## Executive finding
The current migration folder does not define a proven clean-install chain. In particular, the first baseline `0001_biddworld.sql` creates a legacy schema, while the immediately following timestamped migration `20261114161950_secure_bid_rpc_and_signup_provisioning.sql` expects the newer schema. No migration between those two files converts the baseline to the newer shape.

This is a source-level incompatibility, not a database runtime test. The isolated TEST project was confirmed by read-only catalogue queries to have zero public tables, zero public functions, no Supabase migration-history table and zero Storage buckets. No migrations were applied.

## Concrete schema mismatch

| Object | Baseline in `0001_biddworld.sql` | First timestamp migration expects |
|---|---|---|
| `public.member_ids` | `user_id`; no `owner_user_id` or `status` column | inserts/selects `owner_user_id`, `id_type`, `status` |
| `public.profiles` | no `main_member_id` or `phone` column | updates `main_member_id`; later signup replacement writes `phone` |
| `public.wallet_accounts` | `user_id` foreign key | `member_id` foreign key and unique `(member_id,wallet_type)` |
| `public.referrals` | includes `referred_user_id`, `main_member_id`; no `source_member_id` | later sponsor migration writes `source_member_id` |
| `public.package_activations` | `activation_no`, `status` | later migrations use `activation_number`, `payment_status`, `activation_status` |

The first timestamp migration's Auth trigger function inserts into `member_ids(owner_user_id,...)` and updates `profiles.main_member_id`. These columns are not created by the baseline. Therefore a fresh database created by `0001_biddworld.sql` cannot satisfy that migration's function body/trigger behavior without a schema-conversion step.

## Other baseline observations
- `0002_place_bid_rpc.sql` is a legacy bid RPC that directly uses the old `wallet_accounts.user_id` shape and is superseded by later private implementation/wrapper and idempotency work. It must not be treated as the current authoritative bidding implementation.
- `001_initial_schema.sql` is empty (one newline); it contributes no schema.
- Production's historical migration ledger is a separate lineage. Its recovered historical SQL is archived as evidence under `supabase/audit/production-ledger/`, not as a replayable baseline.
- Production must not be reset or replayed from the repository folder. No guessed migration history should be inserted.

## Required remediation design (not executed)
1. Treat the current `0001_biddworld.sql` as a legacy snapshot, not as an approved clean-install baseline.
2. Reconstruct the canonical schema from the latest intended source contracts and complete table/constraint/index/RLS/function/trigger inventory.
3. Choose one of two explicit paths: (a) a new, versioned clean-install baseline that directly creates the canonical schema, or (b) a documented legacy baseline plus a complete, ordered conversion migration. Do not silently rewrite historical applied files without confirming all environments and consumers.
4. Resolve the empty `001_initial_schema.sql` and legacy `0002_place_bid_rpc.sql` treatment in the documented bootstrap sequence.
5. Replay the chosen sequence against the empty isolated TEST project only after source review. Capture each migration result and compare the resulting schema with the read-only Production inventory.
6. Keep Production and TEST unchanged until the canonical bootstrap plan is reviewed and explicitly authorized.

## Safety and validation status
- Production: read-only; no writes.
- TEST: read-only catalogue inspection only; no tables/functions/buckets and no migrations applied.
- No build, frontend tests, SQL execution of migrations, Auth actions, Storage writes or wallet activity.
- Runtime clean-install status remains unverified and blocked by the source-level baseline mismatch.
