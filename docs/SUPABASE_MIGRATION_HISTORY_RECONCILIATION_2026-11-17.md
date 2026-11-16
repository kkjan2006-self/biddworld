# Supabase Migration History Reconciliation — 2026-11-17

## Scope

- Repository: `kkjan2006-self/biddworld`
- Branch snapshot: `completion-work` at `5256cdc0c035cc965d0e283ea84a172a33ef93f7`
- Supabase project inspected read-only: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)
- Source migration files: 44 total, consisting of 41 timestamped migrations and 3 legacy/unversioned SQL files.
- Production migration ledger: 30 applied entries, latest `20261115163218_admin_audit_log_pagination`.

## Reconciliation result

The Production migration ledger and current branch migration filenames are **not a one-to-one replayable history**.

- Only four entries match exactly by timestamp/version and migration name:
  - `20261114161950_secure_bid_rpc_and_signup_provisioning`
  - `20261114183412_secure_admin_member_sponsor_directory`
  - `20261114183454_prevent_circular_member_sponsor_changes`
  - `20261115154433_enforce_platform_feature_switches`
- Nine migrations share a recognizable name but have different version timestamps between the ledger and branch:
  - `submit_package_activation_request`
  - `admin_package_activation_review`
  - `reconcile_mlm_dashboard_statuses`
  - `secure_place_bid_wrapper`
  - `admin_feature_settings`
  - `admin_duplicate_id_lifecycle`
  - `fix_feature_gate_trigger_row_access`
  - `extend_wallet_and_sponsor_feature_gates`
  - `admin_audit_log_pagination`
- The remaining ledger entries and branch files cannot be paired from version/name metadata alone. This does **not** prove that the underlying SQL is absent: some migrations may have been applied through the Supabase SQL editor or under a different generated version.
- The three unversioned legacy SQL files cannot be placed into the applied order from filenames alone.

## Live schema evidence captured (read-only)

- Production `public.bids.idempotency_key` exists, is NOT NULL, and has a unique index `bids_idempotency_key_key`.
- Production still exposes only `public.place_bid(p_auction_id uuid)`; the current source expects `place_bid(p_auction_id uuid, p_idempotency_key text)`.
- This demonstrates why the migration ledger alone is insufficient: at least part of the idempotency schema is present, but the callable RPC contract remains on the older signature.
- Production `member_ids` already contains `placement_parent_id` and `placement_position`, but `admin_create_duplicate_member_id` remains the one-argument function and therefore does not match the current placement-aware UI contract.
- Production `lookup_sponsor(text)` still returns a table with member code and display name, while current source migration changes it to a boolean-only result. The frontend compatibility patch now handles both shapes without rendering the legacy display name.
- Production currently has zero Storage buckets; the product-media upload feature is not ready for live verification.

## Deployment and test decision

Do **not** run the current branch migrations directly against Production and do not mark old ledger rows as applied to make the history look aligned.

Required next work:

1. Obtain or reconstruct the exact SQL that was applied for each of the 30 Production ledger entries, including migrations run manually outside the checked-in migration directory.
2. Compare every relevant live function definition, trigger, policy, constraint, index and grant against both that applied SQL and the current branch definitions.
3. Create/use a separate disposable Supabase TEST project and replay a deliberately curated, ordered baseline plus forward migrations from a clean database.
4. Test the RPC signatures and returned JSON/table shapes against the actual frontend call sites in TEST.
5. Prepare a forward-only Production change set only after the TEST replay and regression suite pass. Do not edit the Production migration ledger as a substitute for applying and verifying SQL.

## Safety record

This was a read-only inspection. No Production DDL/DML, migration, ledger edit, Auth setting, Storage bucket, member, wallet, payment, bid or withdrawal operation was performed. `main` was not modified.
