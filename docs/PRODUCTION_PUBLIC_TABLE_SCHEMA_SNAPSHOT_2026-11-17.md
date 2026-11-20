# Production public-table schema snapshot (catalogue metadata only)

Date: 2026-11-17  
Project: BiddWorld-Production (`hbqatszyzqobgtauyuzy`)  
Branch context: `completion-work`  
Source: Supabase table catalogue via verbose read-only listing.

## Scope and safety

This snapshot records table names, columns, data types, nullability/defaults, primary keys, foreign-key relationships, and RLS-enabled flags. It does not export table rows, credentials, Auth identities, wallet balances, payment data, or member information. It is catalogue metadata only.

No SQL writes, migrations, RPC calls, policy changes, or Production data changes were performed.

## Table inventory

Total public tables returned: **21**.

### `public.profiles`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL; `main_member_id` uuid NULL; `display_name` text NULL; `phone` text NULL; `status` text NOT NULL DEFAULT `'pending'::text` CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'closed'::text])); `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `profiles_id_fkey`: id → auth.users(id)

### `public.member_ids`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `owner_user_id` uuid NOT NULL; `main_member_id` uuid NULL; `member_code` text NOT NULL UNIQUE; `id_type` text NOT NULL CHECK (id_type = ANY (ARRAY['main'::text, 'duplicate'::text])); `status` text NOT NULL DEFAULT `'pending'::text` CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'closed'::text])); `placement_parent_id` uuid NULL; `placement_position` text NULL; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `member_ids_main_member_id_fkey`: main_member_id → public.member_ids(id); `member_ids_owner_user_id_fkey`: owner_user_id → auth.users(id); `member_ids_placement_parent_id_fkey`: placement_parent_id → public.member_ids(id); `package_activations_member_id_fkey`: member_id → public.member_ids(id); `wallet_accounts_member_id_fkey`: member_id → public.member_ids(id); `wallet_transactions_member_id_fkey`: member_id → public.member_ids(id); `referrals_referred_member_id_fkey`: referred_member_id → public.member_ids(id); `referrals_referrer_member_id_fkey`: referrer_member_id → public.member_ids(id); `referrals_source_member_id_fkey`: source_member_id → public.member_ids(id); `referral_commissions_beneficiary_member_id_fkey`: beneficiary_member_id → public.member_ids(id); `referral_commissions_credited_main_member_id_fkey`: credited_main_member_id → public.member_ids(id); `bids_member_id_fkey`: member_id → public.member_ids(id); `fixed_bids_member_id_fkey`: member_id → public.member_ids(id); `withdrawal_requests_member_id_fkey`: member_id → public.member_ids(id); `winning_item_payments_winner_member_id_fkey`: winner_member_id → public.member_ids(id)

### `public.packages`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `name` text NOT NULL; `description` text NULL; `price` numeric NOT NULL CHECK (price >= 0::numeric); `currency` character NOT NULL DEFAULT `'INR'::bpchar`; `bid_wallet_credit` numeric NOT NULL DEFAULT `0` CHECK (bid_wallet_credit >= 0::numeric); `is_active` boolean NOT NULL DEFAULT `false`; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `referral_plan_versions_package_id_fkey`: package_id → public.packages(id); `package_activations_package_id_fkey`: package_id → public.packages(id)

### `public.package_activations`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `member_id` uuid NOT NULL; `package_id` uuid NOT NULL; `activation_number` integer NOT NULL CHECK (activation_number > 0); `amount_paid` numeric NOT NULL CHECK (amount_paid >= 0::numeric); `currency` character NOT NULL DEFAULT `'INR'::bpchar`; `payment_status` text NOT NULL DEFAULT `'pending'::text` CHECK (payment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'refunded'::text])); `activation_status` text NOT NULL DEFAULT `'pending'::text` CHECK (activation_status = ANY (ARRAY['pending'::text, 'active'::text, 'rejected'::text, 'cancelled'::text])); `payment_reference` text NULL; `submitted_at` timestamp with time zone NOT NULL DEFAULT `now()`; `verified_at` timestamp with time zone NULL; `verified_by` uuid NULL; `bid_wallet_credit` numeric NOT NULL DEFAULT `0` CHECK (bid_wallet_credit >= 0::numeric)
- Foreign keys: `package_activations_member_id_fkey`: member_id → public.member_ids(id); `package_activations_verified_by_fkey`: verified_by → auth.users(id); `package_activations_package_id_fkey`: package_id → public.packages(id); `referral_commissions_package_activation_id_fkey`: package_activation_id → public.package_activations(id)

### `public.wallet_accounts`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `member_id` uuid NOT NULL; `wallet_type` text NOT NULL CHECK (wallet_type = ANY (ARRAY['bid'::text, 'income'::text])); `balance` numeric NOT NULL DEFAULT `0` CHECK (balance >= 0::numeric); `currency` character NOT NULL DEFAULT `'INR'::bpchar`; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `wallet_accounts_member_id_fkey`: member_id → public.member_ids(id); `wallet_transactions_wallet_account_id_fkey`: wallet_account_id → public.wallet_accounts(id)

### `public.wallet_transactions`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `wallet_account_id` uuid NOT NULL; `member_id` uuid NOT NULL; `transaction_type` text NOT NULL; `direction` text NOT NULL CHECK (direction = ANY (ARRAY['credit'::text, 'debit'::text])); `amount` numeric NOT NULL CHECK (amount > 0::numeric); `balance_after` numeric NULL CHECK (balance_after >= 0::numeric); `reference_type` text NULL; `reference_id` uuid NULL; `idempotency_key` text NULL UNIQUE; `description` text NULL; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `wallet_transactions_wallet_account_id_fkey`: wallet_account_id → public.wallet_accounts(id); `wallet_transactions_member_id_fkey`: member_id → public.member_ids(id)

### `public.referral_plan_versions`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `package_id` uuid NOT NULL; `version_number` integer NOT NULL CHECK (version_number > 0); `is_active` boolean NOT NULL DEFAULT `false`; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `created_by` uuid NULL
- Foreign keys: `referral_plan_versions_created_by_fkey`: created_by → auth.users(id); `referral_plan_versions_package_id_fkey`: package_id → public.packages(id); `referral_commissions_plan_version_id_fkey`: plan_version_id → public.referral_plan_versions(id); `referral_level_rules_plan_version_id_fkey`: plan_version_id → public.referral_plan_versions(id)

### `public.referral_level_rules`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `plan_version_id` uuid NOT NULL; `level_number` integer NOT NULL CHECK (level_number > 0); `reward_type` text NOT NULL CHECK (reward_type = ANY (ARRAY['fixed'::text, 'percentage'::text])); `reward_value` numeric NOT NULL CHECK (reward_value >= 0::numeric); `eligibility_rule` jsonb NOT NULL DEFAULT `'{}'::jsonb`
- Foreign keys: `referral_level_rules_plan_version_id_fkey`: plan_version_id → public.referral_plan_versions(id)

### `public.referrals`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `referred_member_id` uuid NOT NULL UNIQUE; `referrer_member_id` uuid NULL; `source_member_id` uuid NULL; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `referrals_referred_member_id_fkey`: referred_member_id → public.member_ids(id); `referrals_source_member_id_fkey`: source_member_id → public.member_ids(id); `referrals_referrer_member_id_fkey`: referrer_member_id → public.member_ids(id)

### `public.referral_commissions`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `package_activation_id` uuid NOT NULL; `plan_version_id` uuid NOT NULL; `level_number` integer NOT NULL CHECK (level_number > 0); `beneficiary_member_id` uuid NOT NULL; `credited_main_member_id` uuid NULL; `amount` numeric NOT NULL CHECK (amount >= 0::numeric); `status` text NOT NULL DEFAULT `'pending'::text` CHECK (status = ANY (ARRAY['pending'::text, 'credited'::text, 'reversed'::text])); `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `referral_commissions_package_activation_id_fkey`: package_activation_id → public.package_activations(id); `referral_commissions_plan_version_id_fkey`: plan_version_id → public.referral_plan_versions(id); `referral_commissions_beneficiary_member_id_fkey`: beneficiary_member_id → public.member_ids(id); `referral_commissions_credited_main_member_id_fkey`: credited_main_member_id → public.member_ids(id)

### `public.products`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `name` text NOT NULL; `description` text NULL; `image_path` text NULL; `category` text NULL; `status` text NOT NULL DEFAULT `'draft'::text` CHECK (status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text])); `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `fixed_bid_campaigns_product_id_fkey`: product_id → public.products(id); `auctions_product_id_fkey`: product_id → public.products(id)

### `public.auctions`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `product_id` uuid NOT NULL; `title` text NOT NULL; `description` text NULL; `starts_at` timestamp with time zone NULL; `ends_at` timestamp with time zone NULL; `status` text NOT NULL DEFAULT `'draft'::text` CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'live'::text, 'paused'::text, 'ended'::text, 'cancelled'::text])); `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`; `image_url` text NULL; `category` text NULL; `currency` character NOT NULL DEFAULT `'INR'::bpchar`; `starting_price` numeric NOT NULL DEFAULT `0` CHECK (starting_price >= 0::numeric); `current_price` numeric NOT NULL DEFAULT `0` CHECK (current_price >= 0::numeric); `minimum_increment` numeric NOT NULL DEFAULT `1` CHECK (minimum_increment > 0::numeric)
- Foreign keys: `auctions_product_id_fkey`: product_id → public.products(id); `bids_auction_id_fkey`: auction_id → public.auctions(id); `winning_item_payments_auction_id_fkey`: auction_id → public.auctions(id)

### `public.fixed_bid_campaigns`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `product_id` uuid NOT NULL; `title` text NOT NULL; `description` text NULL; `status` text NOT NULL DEFAULT `'draft'::text` CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'live'::text, 'paused'::text, 'ended'::text, 'cancelled'::text])); `configuration` jsonb NOT NULL DEFAULT `'{}'::jsonb`; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `winning_item_payments_fixed_bid_campaign_id_fkey`: fixed_bid_campaign_id → public.fixed_bid_campaigns(id); `fixed_bid_campaigns_product_id_fkey`: product_id → public.products(id); `fixed_bids_campaign_id_fkey`: campaign_id → public.fixed_bid_campaigns(id)

### `public.bids`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `auction_id` uuid NOT NULL; `member_id` uuid NOT NULL; `bid_amount` numeric NOT NULL CHECK (bid_amount > 0::numeric); `bid_wallet_debit` numeric NOT NULL DEFAULT `0` CHECK (bid_wallet_debit >= 0::numeric); `income_wallet_debit` numeric NOT NULL DEFAULT `0` CHECK (income_wallet_debit >= 0::numeric); `status` text NOT NULL DEFAULT `'accepted'::text` CHECK (status = ANY (ARRAY['accepted'::text, 'rejected'::text, 'voided'::text])); `idempotency_key` text NOT NULL UNIQUE; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `bids_member_id_fkey`: member_id → public.member_ids(id); `bids_auction_id_fkey`: auction_id → public.auctions(id)

### `public.fixed_bids`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `campaign_id` uuid NOT NULL; `member_id` uuid NOT NULL; `bid_amount` numeric NOT NULL CHECK (bid_amount > 0::numeric); `status` text NOT NULL DEFAULT `'submitted'::text` CHECK (status = ANY (ARRAY['submitted'::text, 'accepted'::text, 'rejected'::text, 'voided'::text])); `idempotency_key` text NOT NULL UNIQUE; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `fixed_bids_campaign_id_fkey`: campaign_id → public.fixed_bid_campaigns(id); `fixed_bids_member_id_fkey`: member_id → public.member_ids(id)

### `public.withdrawal_requests`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `member_id` uuid NOT NULL; `amount` numeric NOT NULL CHECK (amount > 0::numeric); `currency` character NOT NULL DEFAULT `'INR'::bpchar`; `status` text NOT NULL DEFAULT `'pending'::text` CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'paid'::text, 'cancelled'::text])); `payout_details` jsonb NULL; `requested_at` timestamp with time zone NOT NULL DEFAULT `now()`; `reviewed_at` timestamp with time zone NULL; `reviewed_by` uuid NULL; `rejection_reason` text NULL
- Foreign keys: `withdrawal_requests_member_id_fkey`: member_id → public.member_ids(id); `withdrawal_requests_reviewed_by_fkey`: reviewed_by → auth.users(id)

### `public.winning_item_payments`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `auction_id` uuid NULL; `fixed_bid_campaign_id` uuid NULL; `winner_member_id` uuid NOT NULL; `amount` numeric NOT NULL CHECK (amount > 0::numeric); `status` text NOT NULL DEFAULT `'pending'::text` CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'refunded'::text])); `paid_at` timestamp with time zone NULL; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `winning_item_payments_winner_member_id_fkey`: winner_member_id → public.member_ids(id); `delivery_tracking_winning_item_payment_id_fkey`: winning_item_payment_id → public.winning_item_payments(id); `winning_item_payments_fixed_bid_campaign_id_fkey`: fixed_bid_campaign_id → public.fixed_bid_campaigns(id); `winning_item_payments_auction_id_fkey`: auction_id → public.auctions(id)

### `public.delivery_tracking`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `winning_item_payment_id` uuid NOT NULL; `carrier` text NULL; `tracking_number` text NULL; `status` text NOT NULL DEFAULT `'pending'::text` CHECK (status = ANY (ARRAY['pending'::text, 'packed'::text, 'shipped'::text, 'in_transit'::text, 'delivered'::text, 'returned'::text])); `shipped_at` timestamp with time zone NULL; `delivered_at` timestamp with time zone NULL; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `delivery_tracking_winning_item_payment_id_fkey`: winning_item_payment_id → public.winning_item_payments(id)

### `public.audit_logs`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` bigint NOT NULL; `actor_user_id` uuid NULL; `action` text NOT NULL; `entity_type` text NOT NULL; `entity_id` uuid NULL; `details` jsonb NOT NULL DEFAULT `'{}'::jsonb`; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `audit_logs_actor_user_id_fkey`: actor_user_id → auth.users(id)

### `public.app_settings`
- RLS enabled: **yes**
- Primary key: setting_key
- Columns: `setting_key` text NOT NULL; `setting_value` jsonb NOT NULL; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: none

### `public.notification_templates`
- RLS enabled: **yes**
- Primary key: id
- Columns: `id` uuid NOT NULL DEFAULT `gen_random_uuid()`; `name` text NOT NULL CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 100); `channel` text NOT NULL CHECK (channel = ANY (ARRAY['in_app'::text, 'email'::text, 'sms'::text])); `subject` text NULL; `body` text NOT NULL CHECK (length(btrim(body)) >= 1 AND length(btrim(body)) <= 5000); `is_active` boolean NOT NULL DEFAULT `false`; `created_by` uuid NOT NULL; `created_at` timestamp with time zone NOT NULL DEFAULT `now()`; `updated_at` timestamp with time zone NOT NULL DEFAULT `now()`
- Foreign keys: `notification_templates_created_by_fkey`: created_by → auth.users(id)


## Important limitation

This is not a replayable baseline. The table listing may not expose every object needed for a faithful clean install, including all check/exclusion constraints, indexes, enum types, policies, grants, triggers, views, sequences, storage configuration, and full function bodies. These must be captured and reconciled separately before constructing a canonical TEST bootstrap.

The table listing also includes the live Production schema only; no Production rows are copied or represented in this file.

## Next gate

1. Capture all remaining schema objects from catalogue metadata.
2. Match each object to an exact source migration or mark it as an unrecovered historical object.
3. Generate a clean-install baseline only after dependencies and object definitions are complete.
4. Replay in isolated TEST and compare the resulting catalogue to this snapshot.
