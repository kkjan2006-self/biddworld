# BiddWorld Production schema catalogue snapshot — 2026-11-18

## Safety and method
- Project inspected: Production `hbqatszyzqobgtauyuzy` (ap-south-1).
- Read-only catalogue queries and Supabase table metadata listing only.
- No row data was exported; no schema/data changes were made.
- This is an observed catalogue snapshot, not a replayable schema baseline.

## Verified inventory

| Catalogue item | Count |
|---|---:|
| Public base tables | 21 |
| Columns | 175 |
| Constraints | 243 |
| Indexes | 60 |
| Triggers | 17 |
| Public functions | 43 |
| RLS policies | 20 |
| Tables with RLS enabled | 21 / 21 |
| Supabase migration ledger rows | 30 |

Every one of the 21 public tables has RLS enabled. The catalogue currently reports fewer policies than tables because some tables have no directly defined policy and rely on RPC/service-side access; this requires separate privilege and RPC review.

## Public table/column inventory

Column types below are from the live Production catalogue. `?` means nullable; defaults are omitted here for compactness. Primary keys are listed separately.

| Table | Columns (type) | Primary key |
|---|---|---|
| profiles | id uuid; main_member_id uuid?; display_name text?; phone text?; status text; created_at timestamptz; updated_at timestamptz | id |
| member_ids | id uuid; owner_user_id uuid; main_member_id uuid?; member_code text; id_type text; status text; placement_parent_id uuid?; placement_position text?; created_at timestamptz | id |
| packages | id uuid; name text; description text?; price numeric; currency bpchar; bid_wallet_credit numeric; is_active bool; created_at timestamptz; updated_at timestamptz | id |
| package_activations | id uuid; member_id uuid; package_id uuid; activation_number int4; amount_paid numeric; currency bpchar; payment_status text; activation_status text; payment_reference text?; submitted_at timestamptz; verified_at timestamptz?; verified_by uuid?; bid_wallet_credit numeric | id |
| wallet_accounts | id uuid; member_id uuid; wallet_type text; balance numeric; currency bpchar; created_at timestamptz; updated_at timestamptz | id |
| wallet_transactions | id uuid; wallet_account_id uuid; member_id uuid; transaction_type text; direction text; amount numeric; balance_after numeric?; reference_type text?; reference_id uuid?; idempotency_key text?; description text?; created_at timestamptz | id |
| referral_plan_versions | id uuid; package_id uuid; version_number int4; is_active bool; created_at timestamptz; created_by uuid? | id |
| referral_level_rules | id uuid; plan_version_id uuid; level_number int4; reward_type text; reward_value numeric; eligibility_rule jsonb | id |
| referrals | id uuid; referred_member_id uuid; referrer_member_id uuid?; source_member_id uuid?; created_at timestamptz | id |
| referral_commissions | id uuid; package_activation_id uuid; plan_version_id uuid; level_number int4; beneficiary_member_id uuid; credited_main_member_id uuid?; amount numeric; status text; created_at timestamptz | id |
| products | id uuid; name text; description text?; image_path text?; category text?; status text; created_at timestamptz; updated_at timestamptz | id |
| auctions | id uuid; product_id uuid; title text; description text?; starts_at timestamptz?; ends_at timestamptz?; status text; created_at timestamptz; updated_at timestamptz; image_url text?; category text?; currency bpchar; starting_price numeric; current_price numeric; minimum_increment numeric | id |
| fixed_bid_campaigns | id uuid; product_id uuid; title text; description text?; status text; configuration jsonb; created_at timestamptz; updated_at timestamptz | id |
| bids | id uuid; auction_id uuid; member_id uuid; bid_amount numeric; bid_wallet_debit numeric; income_wallet_debit numeric; status text; idempotency_key text; created_at timestamptz | id |
| fixed_bids | id uuid; campaign_id uuid; member_id uuid; bid_amount numeric; status text; idempotency_key text; created_at timestamptz | id |
| withdrawal_requests | id uuid; member_id uuid; amount numeric; currency bpchar; status text; payout_details jsonb?; requested_at timestamptz; reviewed_at timestamptz?; reviewed_by uuid?; rejection_reason text? | id |
| winning_item_payments | id uuid; auction_id uuid?; fixed_bid_campaign_id uuid?; winner_member_id uuid; amount numeric; status text; paid_at timestamptz?; created_at timestamptz | id |
| delivery_tracking | id uuid; winning_item_payment_id uuid; carrier text?; tracking_number text?; status text; shipped_at timestamptz?; delivered_at timestamptz?; updated_at timestamptz | id |
| audit_logs | id int8; actor_user_id uuid?; action text; entity_type text; entity_id uuid?; details jsonb; created_at timestamptz | id |
| app_settings | setting_key text; setting_value jsonb; updated_at timestamptz | setting_key |
| notification_templates | id uuid; name text; channel text; subject text?; body text; is_active bool; created_by uuid; created_at timestamptz; updated_at timestamptz | id |

## Important baseline blockers

1. Repository `supabase/migrations/001_initial_schema.sql` is empty (newline only); it cannot initialize a clean database.
2. `0001_biddworld.sql` is a simplified, incompatible early schema. Examples:
   - It uses `member_ids.user_id`, while Production uses `owner_user_id`.
   - It uses `wallet_accounts.user_id`, while Production uses `member_id`.
   - It uses `bids.user_id/amount`, while Production uses `member_id/bid_amount`.
   - It defines older enum types/statuses and materially different package/referral/auction structures.
3. Production's 30 migration ledger versions do not correspond one-to-one to the current repository's 67 SQL files. Several historical timestamped source files were renamed/recovered, and 17 Production versions were previously recorded as unrecovered.
4. Source-only migrations authored during the recent completion work are not installed in Production. They must be included in the eventual clean-install source baseline, but must not be applied to Production as a shortcut.
5. The live schema includes 243 constraints, 60 indexes, 17 triggers, 43 public functions and 20 policies. Recreating only table names/columns is insufficient.

## Canonical baseline plan (not yet executed)

- Treat the live catalogue as evidence, not as permission to overwrite or dump live data.
- Recover exact definitions for all constraints, indexes, triggers, functions, policies, grants and relevant private-schema dependencies.
- Reconcile every object to the existing source migration files and record exact source ownership.
- Build a new, ordered clean-install migration chain on a separate branch or clearly isolated baseline directory.
- Compare the reconstructed schema against the live catalogue using a read-only structural diff.
- Only after development is complete, replay the baseline into the isolated TEST project and run the planned test suite.
- Never apply this reconstruction to Production during this work.

## Migration ledger versions

Production has 30 ledger rows. The observed versions are:
`20261114161950`, `20261114181107`, `20261114181114`, `20261114183412`, `20261114183454`, `20261115142511`, `20261115142515`, `20261115142518`, `20261115142520`, `20261115142524`, `20261115144258`, `20261115150139`, `20261115150425`, `20261115150819`, `20261115151223`, `20261115151455`, `20261115151930`, `20261115152119`, `20261115152255`, `20261115152743`, `20261115152910`, `20261115153059`, `20261115153241`, `20261115154433`, `20261115154626`, `20261115154727`, `20261115160229`, `20261115161029`, `20261115161904`, `20261115163218`.

## Next work
Recover complete SQL definitions in dependency order, starting with private schemas/extensions/types, then tables/constraints/indexes, triggers, functions, policies and grants. Maintain a source-to-live object reconciliation matrix. Do not guess missing definitions.
