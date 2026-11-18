# Supabase Migration History Reconciliation — 2026-11-17

## Scope

- Repository: `kkjan2006-self/biddworld`
- Branch snapshot: `completion-work`; rechecked 2026-11-18 at `881f8cb7f99e892022bba382c46810da3b097f6f`
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
- The remaining 17 Production ledger entries have no same-name timestamped source file. Exact GitHub commit-history queries for each missing `supabase/migrations/<filename>` path returned no commits. This proves those exact files are not recoverable from the current repository history; it does not prove the SQL was never applied, because some migrations may have been run manually or under other names.
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


## 2026-11-18 exact-path recovery and current source delta

The current branch still contains 49 SQL files: 3 legacy/unversioned and 46 timestamped. The Production ledger still has 30 entries. Comparison is now classified as:

- 4 exact timestamp-and-name matches.
- 9 same-name/different-timestamp pairs.
- 17 Production ledger filenames with no corresponding source file; exact GitHub path-history lookups returned empty histories for all 17.
- 16 timestamped source files remain unmatched by Production ledger name and need object-level classification before replay.

The 17 missing Production filenames must not be recreated from their migration names. Current live catalog metadata can recover final object definitions, but not the historical migration intent/order or the original transaction boundaries.

### Source definitions for known live/frontend contract gaps

The following current-branch source migrations define RPCs that are still absent from Production:

| Missing Production RPC | Current source migration |
|---|---|
| `public_list_active_products_page(text,integer,integer)` | `20261116120000_public_product_catalogue_search.sql` |
| `member_get_my_identity()` | `20261115203000_member_identity_summary.sql` |
| `member_list_my_ids()` | `20261115230000_duplicate_under_id_placement_attribution.sql` |
| `member_update_my_profile(text,text)` | `20261115190000_member_profile_self_service.sql` |
| `admin_list_members_sponsors_page(text,integer,integer)` | `20261116090000_admin_members_sponsors_pagination.sql` |
| `admin_list_duplicate_ids_page(text,integer,integer)` | `20261116110000_admin_duplicate_id_pagination.sql` |
| `get_my_mlm_dashboard_page(integer,integer,text,integer)` | `20261116100000_member_genealogy_pagination.sql` |
| `admin_set_product_active(uuid,boolean)` | `20261116020000_admin_product_management_and_media.sql` |
| `admin_update_member_profile(text,text,text)` | `20261117120000_admin_update_member_profile.sql` |

The source branch also changes two live RPC signatures:

- `place_bid(uuid)` → `place_bid(uuid,text)` in `20261116190000_bid_request_idempotency.sql`.
- `admin_create_duplicate_member_id(text)` → `admin_create_duplicate_member_id(text,text)` in `20261117110000_serialize_admin_duplicate_id_placement.sql`.

It narrows two disclosure contracts:

- `lookup_sponsor(text)`: Production returns `member_code, display_name`; source returns a boolean.
- `member_list_my_withdrawals()`: Production returns full `payout_details`; source retains only the payout method label.

Production has 21 public tables and 20 SELECT-only RLS policies, 10 feature-gate triggers, 43 public functions/overloads, and four private helper functions. All 21 tables have RLS enabled. `support_tickets` and `member_notifications` are not yet present in Production; source migrations create them. The `product-media` Storage bucket is also absent.

### Clean-install baseline decision

The legacy `0001_biddworld.sql` is incompatible with the live schema (for example, it uses `profiles.email/role` and `member_ids.user_id` rather than current `owner_user_id`); `0002_place_bid_rpc.sql` is the legacy one-argument bid RPC; `001_initial_schema.sql` is empty. None is a trustworthy baseline.

A separate final-state baseline must be assembled from complete verified schema evidence, including all 21 table definitions, 110 constraints, 60 indexes, 20 policies, 10 triggers, 43 public function/overload definitions, private helper definitions, ACLs/grants, and the source-only forward changes. TEST remains empty until that baseline is reviewed and replayed. Production remains SELECT-only/read-only.


## 2026-11-18 — New feature migration inventory

The source tree now contains 55 SQL files (3 legacy/unversioned plus 52 timestamped). The six new timestamped feature migrations are documented in `docs/TEST_DATABASE_BOOTSTRAP_AUDIT_2026-11-17.md`. They add Fixed Bid entry/draw/settlement, package publication and referral commission calculation/posting/reversal, Admin withdrawal review and Income Wallet reservation/release, auction lifecycle/winner finalization/refunds, Admin wallet adjustments, and configurable minimum withdrawal validation.

All six are source-only. Do not apply them to Production or to the empty TEST project until the reviewed clean-install baseline and dependency order are complete. The historical Production ledger reconciliation counts (30 entries; 4 exact matches, 9 name-only matches, 17 unrecovered filenames) are unchanged by these new source files.


## 2026-11-18 — Current source inventory

The latest branch tree contains 60 SQL files (3 legacy/unversioned plus 57 timestamped). Eleven new timestamped migrations dated 2026-11-18 have been added after the original 49-file inventory. Production ledger reconciliation remains 30 entries: 4 exact matches, 9 same-name/different-timestamp matches and 17 unrecovered historical filenames. The 11 new migrations are not applied to either database and do not alter that historical comparison. Build a canonical baseline and dependency review before any TEST replay.


## 2026-11-18 — Updated source count

The latest branch contains 61 SQL files (3 legacy/unversioned plus 58 timestamped). Twelve new 2026-11-18 source migrations now cover Fixed Bid, referral commissions, withdrawals, auctions, wallet adjustments, Main ID lifecycle, receipt uploads, Primary Admin roles, support, notifications and package activation history. These are not applied to either Supabase project; original Production ledger reconciliation remains unchanged.


## 2026-11-18 — Exact Production ledger SQL recovery

A read-only query of `supabase_migrations.schema_migrations` returned the exact `statements` array for all 30 Production migration versions. All 30 rows had one stored SQL statement. A source comparison found:
- 4 entries whose repository filename already had the exact Production version prefix, but whose current file contents differed from the stored Production SQL.
- 9 entries whose SQL text exactly matched a same-name repository file, but the repository file used a different timestamp prefix.
- 17 entries with no same-name file in the migration directory.

All 30 exact historical SQL statements have now been preserved as separate files under `supabase/audit/production-ledger/`, outside `supabase/migrations/`. This archive is deliberately non-executable by normal Supabase CLI migration discovery and does not overwrite any current migration source.

- Archive files verified in GitHub tree: 31 (30 SQL snapshots + README).
- Archive commit: `d872d6cb25d1931e5152e7f16e121a3f877fcfe5`.
- This closes the historical SQL recovery gap for the 30 currently applied Production ledger rows.
- It does **not** yet establish a canonical clean-install chain: source divergence, dependency ordering, schema objects, extension prerequisites, and later source-only migrations still require reconciliation.
- No Production or TEST database writes, migration replay, tests or builds were performed.
