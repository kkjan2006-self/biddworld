# Production-to-Frontend RPC and Schema Contract Diff — 2026-11-18

## Scope and source revisions

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Frontend inventory snapshot: `6004a2ab95c8dac0f06235a87bf0bc64703dcc09`
- Production Supabase: `hbqatszyzqobgtauyuzy` — PostgreSQL 17.11, ACTIVE_HEALTHY
- TEST Supabase: `yoaauthwejdgaevfvwpo` — PostgreSQL 17.12, ACTIVE_HEALTHY
- All database inspection in this audit used read-only catalogue queries. No application rows, member records, or transaction records were queried.

## Current live schema evidence

| Item | Production observation |
|---|---:|
| Public base tables | 21 |
| Public tables with RLS enabled | 21 / 21 |
| Public constraints | 110 |
| Public indexes | 60 |
| Public RLS policies | 20 |
| Policy commands | SELECT only |
| Non-internal application triggers | 10 |
| Public functions | 43 |
| Public functions marked SECURITY DEFINER | 43 |
| Public functions with explicit function settings | 43 |
| Storage buckets | 0 |
| TEST applied migrations | 0 |
| TEST public tables | 0 |

Additional privilege observations:
- No direct table grants to `anon` were returned for public application tables.
- `authenticated` has direct SELECT on 17 public tables; no direct INSERT/UPDATE/DELETE table grants were returned.
- `service_role` has full table privileges on the 21 public tables.
- All 20 public RLS policies are SELECT policies. The table with no direct policy remains deny-by-default at the table privilege surface.
- `lookup_sponsor(text)` is the only inspected public function with `anon` EXECUTE; it is SECURITY DEFINER and returns `member_code` and `display_name`. The source privacy-minimization migration is not deployed.
- The deployed `private.place_bid(uuid)` implementation has a non-empty `search_path` setting (`pg_catalog, public`) and creates its own random request key.

These are catalogue observations, not a replayable baseline or a certification of every routine's runtime behavior.

## Frontend RPC contract comparison

The refreshed source inventory contains 70 unique literal RPC names across the ten React surfaces. Comparing those names with the live Production public function catalogue found:

- 35 names present in Production.
- 35 names absent from Production.
- Two important live signature differences are detailed below.
- A matching function name does not establish matching argument names, return shape, authorization behavior, or semantics.

### RPC names used by the current frontend but absent from Production

```text
admin_activate_referral_plan
admin_adjust_member_wallet
admin_draw_fixed_bid_winners
admin_finalize_auction
admin_get_minimum_withdrawal_amount
admin_list_duplicate_ids_page
admin_list_members_sponsors_page
admin_list_package_activations_page
admin_list_referral_commissions_page
admin_post_referral_commissions
admin_publish_package
admin_reverse_referral_commission
admin_review_withdrawal_request
admin_save_fixed_bid_campaign
admin_send_member_notification
admin_set_auction_status
admin_set_fixed_bid_campaign_status
admin_set_main_member_status
admin_set_minimum_withdrawal_amount
admin_set_product_active
admin_set_user_admin_role
admin_update_member_profile
admin_update_support_ticket
get_my_mlm_dashboard_page
member_get_my_identity
member_join_fixed_bid_campaign
member_list_my_ids
member_pay_winning_item_payment
member_submit_support_ticket
member_update_my_profile
public_list_active_products_page
public_list_active_auctions_page
public_list_fixed_bid_campaigns_page
public_list_active_packages_page
submit_package_activation_with_receipt
```

The current branch has source migrations for these new contracts, but they have not been applied to Production. The 35 missing source contracts are enumerated by `tests/frontend-missing-rpc-source-coverage.test.ts`; the public auction catalogue was added in `20261118280000_public_auction_catalogue_page.sql`. They must be included in the curated clean-install plan and verified against TEST before the frontend can be treated as integrated with the live database.

## Confirmed signature and behavior drift

### Public Fixed Bid and package catalogues

- The Fixed Bid page previously queried `public.fixed_bid_campaigns` directly. It now uses `public_list_fixed_bid_campaigns_page(text,text,integer,integer)`, which exposes only published-product campaigns and member-facing configuration fields; Admin-only refund and campaign-cap settings are not returned.
- The Packages page previously queried `public.packages` directly. It now uses `public_list_active_packages_page(integer,integer)`, which returns only active packages and the fields required by the public package cards.
- The Packages page reads `package_activations_enabled` only after confirming an authenticated session; anonymous visitors see the package catalogue but cannot start an activation request.
- Both new RPCs are source-only and have not been applied to Production or TEST.


### Public auction catalogue

- The public website previously queried `public.auctions` directly, but Production has no anonymous table SELECT grants.
- The source branch now uses `public_list_active_auctions_page(integer,integer)`, a restricted SECURITY DEFINER RPC that returns only published-product live/scheduled listing fields.
- Source migration `20261118280000_public_auction_catalogue_page.sql` is not deployed to Production; until the curated migration package is deployed, the new frontend RPC is not available against the live database.

### Auction bidding

- Production exposes `public.place_bid(uuid)`.
- Current frontend submits `p_auction_id` and `p_idempotency_key`.
- The live wrapper forwards only the auction UUID to `private.place_bid(uuid)`.
- The live private implementation generates a random key internally rather than accepting the caller's retry key.
- Source migration `20261116190000_bid_request_idempotency.sql` is not in the Production migration ledger.

### Duplicate ID creation

- Production exposes `admin_create_duplicate_member_id(text)`.
- Current source expects a Main ID code and an Under ID / placement target.
- The source placement-attribution and serialization migrations are not deployed in Production.

### Referral plan editor

- Production `admin_save_referral_plan_draft(uuid,jsonb)` requires exactly five rules and rejects levels outside 1–5.
- Current source migration `20261116030000_admin_configurable_referral_plan_depth.sql` supports 1–20 sequential levels.
- The current frontend editor therefore does not match the live Production contract.

### Feature-setting implementation

- The live `admin_set_feature_setting(text,boolean)` definition predates the latest source-side approval interlock.
- Source migration `20261116080000_financial_activity_lockdown.sql` is not in the Production migration ledger.
- Do not infer live database enforcement from the presence of the newer migration in GitHub.

### Storage

- Production currently has zero Storage buckets.
- Source migrations define product-media and package-receipt Storage setup and policies.
- Those source contracts have not been deployed or verified in TEST.

## Clean-install baseline decision

1. Do not apply the 69 timestamped migration files wholesale to an empty database.
2. Do not use the incompatible legacy `0001_biddworld.sql` baseline or the old one-argument `0002_place_bid_rpc.sql`.
3. Preserve the current Production schema evidence as a read-only reference only.
4. Reconstruct a clean-install baseline from exact table columns, identity/default metadata, constraints, indexes, RLS policies, grants, private/public function definitions, triggers, extensions and required Supabase-managed dependencies.
5. Map every source migration to the live object definitions it changes. Same-name migrations with different timestamps must be body-compared; filename similarity is not proof of equivalence.
6. Include the 53 ordered forward candidates and 16 explicitly excluded historical files in the reviewed migration partition; include current source-only migrations after their prerequisites are reconciled.
7. Replay only the curated baseline and forward chain in TEST, then compare resulting catalogue definitions and run synthetic-data integration tests.
8. Keep Production read-only throughout this process.

## Verification boundary

- GitHub Actions run #934 passed on source commit `3b311c77e18cc24fd76830bf2780d8e2b6fa3b17`: 102/102 test files, 423/423 tests, TypeScript check and Vite production build. Run #935 also passed the new production-only dependency audit gate: 0 production vulnerabilities; the all-dependency audit still reports 12 high, 0 critical findings in development tooling.
- That CI run does not test live Supabase RPCs or migration replay.
- No Production or TEST SQL writes, migrations, Storage changes, or application data changes were performed for this audit.
- No project completion percentage increase is claimed from this metadata comparison.
