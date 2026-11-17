# Supabase Migration History Reconciliation — 2026-11-17

## Scope

- Repository: `kkjan2006-self/biddworld`
- Branch snapshot: `completion-work` at `9616aad1da2689d98865cfcbede3b469e4c4f4d1` (rechecked 2026-11-17)
- Supabase project inspected read-only: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)
- Source migration files: 49 total, consisting of 46 timestamped migrations and 3 legacy/unversioned SQL files (recounted from the current branch tree).
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

## Additional RPC implementation drift observed

Further read-only inspection of the live function definitions found:

- `public.member_create_withdrawal_request(numeric,jsonb)` checks authentication, amount format, feature switch, Income Wallet balance and open requests, but the live definition does **not** verify that the caller's Main ID belongs to that user and has `status='active'`. The branch migration `20261116140000_require_active_main_id_for_withdrawals.sql` adds that ownership-and-active-state check. It is not deployed.
- `public.member_list_my_withdrawals()` currently returns the complete stored `payout_details` JSON. Branch migration `20261116170000_minimize_member_withdrawal_payout_data.sql` changes the response to the payout method label only. The member UI currently renders only the method label, but the live RPC response still carries the wider object.
- `public.admin_list_duplicate_ids()` currently returns a non-paginated legacy response without placement-parent details. The current Admin UI calls `admin_list_duplicate_ids_page`, which is absent from Production. The placement-aware and paginated branch migrations remain TEST-only.
- `public.get_my_placement_tree()` exists with no arguments and its JSON keys (`root_member_code`, `tree`) and tree fields match the inspected current PlacementTree component. This is a limited contract match; runtime integration has not been performed.

These are source/live drift observations, not a statement that the branch migrations are ready to apply. Keep Production read-only until exact SQL history and a clean TEST replay are available.


## Latest verification checkpoint — 2026-11-17

- Re-read the exact Production migration ledger: 30 entries, latest `20261115163218_admin_audit_log_pagination`.
- Re-read the isolated `BiddWorld-TEST` migration ledger: zero entries; no migration has been applied there.
- Recounted the current `completion-work` migration directory: 49 SQL files (46 timestamped plus 3 legacy/unversioned). The prior 44-file count in this document was stale.
- The four exact timestamp/name matches and nine recognizable-name/different-timestamp pairs remain unchanged. The larger current source inventory does not establish that additional files were applied in Production.
- CI run [44045900591](https://github.com/kkjan2006-self/biddworld/actions/runs/44045900591) passed dependency installation, security reporting, tests, TypeScript and production build for commit `9616aad1da2689d98865cfcbede3b469e4c4f4d1`.
- No SQL was executed, no migrations were applied, and no Production or TEST data was changed in this checkpoint.

### Next bulk engineering gate

The migration replay cannot safely proceed from filenames. The missing evidence is the actual SQL body for the 30 Production ledger versions (including manually applied SQL), plus the exact current definitions for every dependent function, trigger, policy, constraint, index and grant. Reconstruct that evidence first; then produce one curated clean-install baseline and replay it on TEST. Do not use `0001_biddworld.sql` as the baseline, do not mark migrations as applied, and do not make a guessed compatibility shim for the live one-argument bid RPC.
