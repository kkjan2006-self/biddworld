# Production Frontend RPC Contract Audit — 2026-11-17

## Scope and method

- Repository: `kkjan2006-self/biddworld`
- Branch and source snapshot: `completion-work` at `825057437428160e87810ac7976607b40545991b`
- Supabase target: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)
- Read-only comparison of literal `.rpc(...)` calls across the React UI with `pg_proc` routine names, identity arguments and result types in Production.
- No database writes, migrations, Auth changes, Storage changes, or member/financial operations were performed.

## Summary

The React UI contains **44 distinct literal RPC names**. The live Production catalogue currently exposes **41 distinct public function names** (43 overloads/routines in the earlier catalogue snapshot). Name presence alone is insufficient: several UI calls target functions not present in Production, and three existing names have incompatible argument or result contracts.

## UI RPCs absent from the Production catalogue

| UI RPC | Source migration intended to provide it | User-facing impact |
|---|---|---|
| `public_list_active_products_page` | `20261116120000_public_product_catalogue_search.sql` | Product catalogue page/search cannot use its current paged RPC |
| `member_get_my_identity` | `20261115203000_member_identity_summary.sql` | Member identity/sponsor summary cannot load |
| `member_list_my_ids` | `20261115230000_duplicate_under_id_placement_attribution.sql` | Member ID list and placement details cannot load |
| `member_update_my_profile` | `20261115190000_member_profile_self_service.sql` | Profile self-service update RPC unavailable |
| `admin_list_members_sponsors_page` | `20261116090000_admin_members_sponsors_pagination.sql` | Current paged Admin member directory unavailable |
| `admin_list_duplicate_ids_page` | `20261116110000_admin_duplicate_id_pagination.sql` | Current paged Admin Duplicate ID directory unavailable |
| `admin_set_product_active` | `20261116020000_admin_product_management_and_media.sql` | Admin product publish/unpublish RPC unavailable |
| `get_my_mlm_dashboard_page` | `20261116100000_member_genealogy_pagination.sql` | Current paged referral dashboard RPC unavailable; legacy `get_my_mlm_dashboard()` exists instead |

The corresponding legacy names `admin_list_members_sponsors()`, `admin_list_duplicate_ids()`, and `get_my_mlm_dashboard()` exist, but are not drop-in replacements for the current paged UI contracts.

## Existing names with incompatible contracts

1. **`admin_create_duplicate_member_id`**
   - UI calls with `p_main_member_code` and `p_under_member_code`.
   - Production currently exposes only `admin_create_duplicate_member_id(p_main_member_code text)`.
   - The placement-aware two-argument branch migration is not deployed.

2. **`place_bid`**
   - UI calls with `p_auction_id` and `p_idempotency_key`.
   - Production currently exposes only `place_bid(p_auction_id uuid)`.
   - The source migration `20261116190000_bid_request_idempotency.sql` replaces the legacy one-argument function with the idempotent two-argument contract. The live call will not match until the forward migration is properly rehearsed and approved.

3. **`lookup_sponsor`**
   - UI/source migration expects a boolean result.
   - Production currently returns `TABLE(member_code text, display_name text)`.
   - The live function therefore does not satisfy the current UI's original `data === true` check. The UI now accepts either the boolean contract or an exact matching Main-ID row from the legacy table contract; it never renders the legacy display name. The source privacy migration still needs a safe deployment after migration reconciliation.

## Additional backend observations

- Production has no Storage buckets in the current snapshot, while Admin product media upload expects a `product-media` bucket. Product media upload is therefore not verified and should be treated as unavailable until Storage setup is designed and validated in a separate TEST project.
- `get_my_placement_tree()` exists in Production and the current UI calls it without arguments; this name/argument contract matches at the inspected surface. Its returned data shape still needs integration testing.
- The current source branch includes 44 SQL migration files, while the Production migration ledger has 30 applied entries and ends at `20261115163218_admin_audit_log_pagination`. Do not apply only the missing tail migrations: first reconstruct and reconcile the complete historical chain and replay it in a disposable TEST database.

## Work completed in this checkpoint

- Added `src/lib/sponsor-lookup.ts` to accept the boolean source contract and the exact legacy table response during the transition.
- Updated `src/App.tsx` to use that strict compatibility helper.
- Added `tests/sponsor-lookup-response-compat.test.ts` for boolean, legacy, mismatch and malformed responses.
- This is a frontend compatibility fix only. It does not change the Production function, grants, schema, data, or privacy exposure of the legacy function.

## Next required engineering work

1. Build a complete per-RPC contract matrix with argument names/types, return columns, grants, SECURITY DEFINER/search_path and Admin authorization checks.
2. Reconstruct the full Production migration history and compare every applied migration to the branch source and live object definitions.
3. Establish a separate disposable Supabase TEST project and replay the full migration chain from an empty database; then run Auth, member, Admin, Storage and RPC integration tests there.
4. Only after those checks, prepare a forward-only rollout sequence. Production remains read-only during this work.
