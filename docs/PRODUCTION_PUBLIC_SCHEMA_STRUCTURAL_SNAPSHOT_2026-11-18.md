# Production public-schema structural snapshot — 2026-11-18
## Scope and safety
Read-only catalogue snapshot of Production project `hbqatszyzqobgtauyuzy`. No application rows or user details exported. No DDL/DML, no migration, no TEST or Production write, no build or test. Definitions are schema metadata only.

## Structural counts
- Public base tables: 21; RLS enabled: 21/21.
- Columns: 175.
- Constraints: 110 (21 primary keys, 34 foreign keys, 11 unique, 44 check).
- Indexes: 60 (34 unique).
- RLS policies: 20 across 20 tables; all are SELECT policies.
- Direct table grants to `authenticated`: SELECT on 17 tables only; no INSERT/UPDATE/DELETE table grants.
- Direct table grants to `anon`: none.
- `audit_logs_id_seq`: USAGE granted to anon, authenticated, postgres and service_role.
- Public views: none found in information_schema.views.

## Table columns and defaults

### `app_settings`
```sql
setting_key text NOT NULL
setting_value jsonb NOT NULL
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `auctions`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
product_id uuid NOT NULL
title text NOT NULL
description text
starts_at timestamp with time zone
ends_at timestamp with time zone
status text NOT NULL DEFAULT 'draft'::text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
image_url text
category text
currency character(3) NOT NULL DEFAULT 'INR'::bpchar
starting_price numeric(14,2) NOT NULL DEFAULT 0
current_price numeric(14,2) NOT NULL DEFAULT 0
minimum_increment numeric(14,2) NOT NULL DEFAULT 1
```

### `audit_logs`
```sql
id bigint NOT NULL
actor_user_id uuid
action text NOT NULL
entity_type text NOT NULL
entity_id uuid
details jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `bids`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
auction_id uuid NOT NULL
member_id uuid NOT NULL
bid_amount numeric(14,2) NOT NULL
bid_wallet_debit numeric(14,2) NOT NULL DEFAULT 0
income_wallet_debit numeric(14,2) NOT NULL DEFAULT 0
status text NOT NULL DEFAULT 'accepted'::text
idempotency_key text NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `delivery_tracking`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
winning_item_payment_id uuid NOT NULL
carrier text
tracking_number text
status text NOT NULL DEFAULT 'pending'::text
shipped_at timestamp with time zone
delivered_at timestamp with time zone
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `fixed_bid_campaigns`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
product_id uuid NOT NULL
title text NOT NULL
description text
status text NOT NULL DEFAULT 'draft'::text
configuration jsonb NOT NULL DEFAULT '{}'::jsonb
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `fixed_bids`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
campaign_id uuid NOT NULL
member_id uuid NOT NULL
bid_amount numeric(14,2) NOT NULL
status text NOT NULL DEFAULT 'submitted'::text
idempotency_key text NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `member_ids`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
owner_user_id uuid NOT NULL
main_member_id uuid
member_code text NOT NULL
id_type text NOT NULL
status text NOT NULL DEFAULT 'pending'::text
placement_parent_id uuid
placement_position text
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `notification_templates`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
name text NOT NULL
channel text NOT NULL
subject text
body text NOT NULL
is_active boolean NOT NULL DEFAULT false
created_by uuid NOT NULL
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `package_activations`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
member_id uuid NOT NULL
package_id uuid NOT NULL
activation_number integer NOT NULL
amount_paid numeric(14,2) NOT NULL
currency character(3) NOT NULL DEFAULT 'INR'::bpchar
payment_status text NOT NULL DEFAULT 'pending'::text
activation_status text NOT NULL DEFAULT 'pending'::text
payment_reference text
submitted_at timestamp with time zone NOT NULL DEFAULT now()
verified_at timestamp with time zone
verified_by uuid
bid_wallet_credit numeric(14,2) NOT NULL DEFAULT 0
```

### `packages`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
name text NOT NULL
description text
price numeric(14,2) NOT NULL
currency character(3) NOT NULL DEFAULT 'INR'::bpchar
bid_wallet_credit numeric(14,2) NOT NULL DEFAULT 0
is_active boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `products`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
name text NOT NULL
description text
image_path text
category text
status text NOT NULL DEFAULT 'draft'::text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `profiles`
```sql
id uuid NOT NULL
main_member_id uuid
display_name text
phone text
status text NOT NULL DEFAULT 'pending'::text
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `referral_commissions`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
package_activation_id uuid NOT NULL
plan_version_id uuid NOT NULL
level_number integer NOT NULL
beneficiary_member_id uuid NOT NULL
credited_main_member_id uuid
amount numeric(14,2) NOT NULL
status text NOT NULL DEFAULT 'pending'::text
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `referral_level_rules`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
plan_version_id uuid NOT NULL
level_number integer NOT NULL
reward_type text NOT NULL
reward_value numeric(14,4) NOT NULL
eligibility_rule jsonb NOT NULL DEFAULT '{}'::jsonb
```

### `referral_plan_versions`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
package_id uuid NOT NULL
version_number integer NOT NULL
is_active boolean NOT NULL DEFAULT false
created_at timestamp with time zone NOT NULL DEFAULT now()
created_by uuid
```

### `referrals`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
referred_member_id uuid NOT NULL
referrer_member_id uuid
source_member_id uuid
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `wallet_accounts`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
member_id uuid NOT NULL
wallet_type text NOT NULL
balance numeric(14,2) NOT NULL DEFAULT 0
currency character(3) NOT NULL DEFAULT 'INR'::bpchar
created_at timestamp with time zone NOT NULL DEFAULT now()
updated_at timestamp with time zone NOT NULL DEFAULT now()
```

### `wallet_transactions`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
wallet_account_id uuid NOT NULL
member_id uuid NOT NULL
transaction_type text NOT NULL
direction text NOT NULL
amount numeric(14,2) NOT NULL
balance_after numeric(14,2)
reference_type text
reference_id uuid
idempotency_key text
description text
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `winning_item_payments`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
auction_id uuid
fixed_bid_campaign_id uuid
winner_member_id uuid NOT NULL
amount numeric(14,2) NOT NULL
status text NOT NULL DEFAULT 'pending'::text
paid_at timestamp with time zone
created_at timestamp with time zone NOT NULL DEFAULT now()
```

### `withdrawal_requests`
```sql
id uuid NOT NULL DEFAULT gen_random_uuid()
member_id uuid NOT NULL
amount numeric(14,2) NOT NULL
currency character(3) NOT NULL DEFAULT 'INR'::bpchar
status text NOT NULL DEFAULT 'pending'::text
payout_details jsonb
requested_at timestamp with time zone NOT NULL DEFAULT now()
reviewed_at timestamp with time zone
reviewed_by uuid
rejection_reason text
```

## Constraints

- `app_settings.app_settings_pkey` — PRIMARY KEY: `PRIMARY KEY (setting_key)`

- `auctions.auctions_current_price_check` — CHECK: `CHECK (current_price >= 0::numeric)`

- `auctions.auctions_minimum_increment_check` — CHECK: `CHECK (minimum_increment > 0::numeric)`

- `auctions.auctions_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `auctions.auctions_product_id_fkey` — FOREIGN KEY: `FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT`

- `auctions.auctions_starting_price_check` — CHECK: `CHECK (starting_price >= 0::numeric)`

- `auctions.auctions_status_check` — CHECK: `CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'live'::text, 'paused'::text, 'ended'::text, 'cancelled'::text]))`

- `audit_logs.audit_logs_actor_user_id_fkey` — FOREIGN KEY: `FOREIGN KEY (actor_user_id) REFERENCES auth.users(id) ON DELETE SET NULL`

- `audit_logs.audit_logs_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `bids.bids_auction_id_fkey` — FOREIGN KEY: `FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT`

- `bids.bids_bid_amount_check` — CHECK: `CHECK (bid_amount > 0::numeric)`

- `bids.bids_bid_wallet_debit_check` — CHECK: `CHECK (bid_wallet_debit >= 0::numeric)`

- `bids.bids_idempotency_key_key` — UNIQUE: `UNIQUE (idempotency_key)`

- `bids.bids_income_wallet_debit_check` — CHECK: `CHECK (income_wallet_debit >= 0::numeric)`

- `bids.bids_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `bids.bids_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `bids.bids_status_check` — CHECK: `CHECK (status = ANY (ARRAY['accepted'::text, 'rejected'::text, 'voided'::text]))`

- `delivery_tracking.delivery_tracking_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `delivery_tracking.delivery_tracking_status_check` — CHECK: `CHECK (status = ANY (ARRAY['pending'::text, 'packed'::text, 'shipped'::text, 'in_transit'::text, 'delivered'::text, 'returned'::text]))`

- `delivery_tracking.delivery_tracking_winning_item_payment_id_fkey` — FOREIGN KEY: `FOREIGN KEY (winning_item_payment_id) REFERENCES winning_item_payments(id) ON DELETE RESTRICT`

- `fixed_bid_campaigns.fixed_bid_campaigns_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `fixed_bid_campaigns.fixed_bid_campaigns_product_id_fkey` — FOREIGN KEY: `FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT`

- `fixed_bid_campaigns.fixed_bid_campaigns_status_check` — CHECK: `CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'live'::text, 'paused'::text, 'ended'::text, 'cancelled'::text]))`

- `fixed_bids.fixed_bids_bid_amount_check` — CHECK: `CHECK (bid_amount > 0::numeric)`

- `fixed_bids.fixed_bids_campaign_id_fkey` — FOREIGN KEY: `FOREIGN KEY (campaign_id) REFERENCES fixed_bid_campaigns(id) ON DELETE RESTRICT`

- `fixed_bids.fixed_bids_idempotency_key_key` — UNIQUE: `UNIQUE (idempotency_key)`

- `fixed_bids.fixed_bids_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `fixed_bids.fixed_bids_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `fixed_bids.fixed_bids_status_check` — CHECK: `CHECK (status = ANY (ARRAY['submitted'::text, 'accepted'::text, 'rejected'::text, 'voided'::text]))`

- `member_ids.member_ids_id_type_check` — CHECK: `CHECK (id_type = ANY (ARRAY['main'::text, 'duplicate'::text]))`

- `member_ids.member_ids_main_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (main_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `member_ids.member_ids_member_code_key` — UNIQUE: `UNIQUE (member_code)`

- `member_ids.member_ids_owner_user_id_fkey` — FOREIGN KEY: `FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE RESTRICT`

- `member_ids.member_ids_owner_user_id_id_type_id_key` — UNIQUE: `UNIQUE (owner_user_id, id_type, id)`

- `member_ids.member_ids_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `member_ids.member_ids_placement_parent_id_fkey` — FOREIGN KEY: `FOREIGN KEY (placement_parent_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `member_ids.member_ids_status_check` — CHECK: `CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'closed'::text]))`

- `notification_templates.notification_template_subject_check` — CHECK: `CHECK (channel = 'email'::text AND subject IS NOT NULL AND length(btrim(subject)) >= 1 AND length(btrim(subject)) <= 160 OR channel <> 'email'::text AND subject IS NULL)`

- `notification_templates.notification_templates_body_check` — CHECK: `CHECK (length(btrim(body)) >= 1 AND length(btrim(body)) <= 5000)`

- `notification_templates.notification_templates_channel_check` — CHECK: `CHECK (channel = ANY (ARRAY['in_app'::text, 'email'::text, 'sms'::text]))`

- `notification_templates.notification_templates_created_by_fkey` — FOREIGN KEY: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`

- `notification_templates.notification_templates_name_check` — CHECK: `CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 100)`

- `notification_templates.notification_templates_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `package_activations.package_activations_activation_number_check` — CHECK: `CHECK (activation_number > 0)`

- `package_activations.package_activations_activation_status_check` — CHECK: `CHECK (activation_status = ANY (ARRAY['pending'::text, 'active'::text, 'rejected'::text, 'cancelled'::text]))`

- `package_activations.package_activations_amount_paid_check` — CHECK: `CHECK (amount_paid >= 0::numeric)`

- `package_activations.package_activations_bid_wallet_credit_check` — CHECK: `CHECK (bid_wallet_credit >= 0::numeric)`

- `package_activations.package_activations_member_id_activation_number_key` — UNIQUE: `UNIQUE (member_id, activation_number)`

- `package_activations.package_activations_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `package_activations.package_activations_package_id_fkey` — FOREIGN KEY: `FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE RESTRICT`

- `package_activations.package_activations_payment_status_check` — CHECK: `CHECK (payment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'refunded'::text]))`

- `package_activations.package_activations_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `package_activations.package_activations_verified_by_fkey` — FOREIGN KEY: `FOREIGN KEY (verified_by) REFERENCES auth.users(id) ON DELETE SET NULL`

- `packages.packages_bid_wallet_credit_check` — CHECK: `CHECK (bid_wallet_credit >= 0::numeric)`

- `packages.packages_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `packages.packages_price_check` — CHECK: `CHECK (price >= 0::numeric)`

- `products.products_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `products.products_status_check` — CHECK: `CHECK (status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text]))`

- `profiles.profiles_id_fkey` — FOREIGN KEY: `FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE`

- `profiles.profiles_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `profiles.profiles_status_check` — CHECK: `CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'closed'::text]))`

- `referral_commissions.referral_commissions_amount_check` — CHECK: `CHECK (amount >= 0::numeric)`

- `referral_commissions.referral_commissions_beneficiary_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (beneficiary_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `referral_commissions.referral_commissions_credited_main_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (credited_main_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `referral_commissions.referral_commissions_level_number_check` — CHECK: `CHECK (level_number > 0)`

- `referral_commissions.referral_commissions_package_activation_id_fkey` — FOREIGN KEY: `FOREIGN KEY (package_activation_id) REFERENCES package_activations(id) ON DELETE RESTRICT`

- `referral_commissions.referral_commissions_package_activation_id_level_number_ben_key` — UNIQUE: `UNIQUE (package_activation_id, level_number, beneficiary_member_id)`

- `referral_commissions.referral_commissions_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `referral_commissions.referral_commissions_plan_version_id_fkey` — FOREIGN KEY: `FOREIGN KEY (plan_version_id) REFERENCES referral_plan_versions(id) ON DELETE RESTRICT`

- `referral_commissions.referral_commissions_status_check` — CHECK: `CHECK (status = ANY (ARRAY['pending'::text, 'credited'::text, 'reversed'::text]))`

- `referral_level_rules.referral_level_rules_level_number_check` — CHECK: `CHECK (level_number > 0)`

- `referral_level_rules.referral_level_rules_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `referral_level_rules.referral_level_rules_plan_version_id_fkey` — FOREIGN KEY: `FOREIGN KEY (plan_version_id) REFERENCES referral_plan_versions(id) ON DELETE CASCADE`

- `referral_level_rules.referral_level_rules_plan_version_id_level_number_key` — UNIQUE: `UNIQUE (plan_version_id, level_number)`

- `referral_level_rules.referral_level_rules_reward_type_check` — CHECK: `CHECK (reward_type = ANY (ARRAY['fixed'::text, 'percentage'::text]))`

- `referral_level_rules.referral_level_rules_reward_value_check` — CHECK: `CHECK (reward_value >= 0::numeric)`

- `referral_plan_versions.referral_plan_versions_created_by_fkey` — FOREIGN KEY: `FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL`

- `referral_plan_versions.referral_plan_versions_package_id_fkey` — FOREIGN KEY: `FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE RESTRICT`

- `referral_plan_versions.referral_plan_versions_package_id_version_number_key` — UNIQUE: `UNIQUE (package_id, version_number)`

- `referral_plan_versions.referral_plan_versions_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `referral_plan_versions.referral_plan_versions_version_number_check` — CHECK: `CHECK (version_number > 0)`

- `referrals.referrals_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `referrals.referrals_referred_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (referred_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `referrals.referrals_referred_member_id_key` — UNIQUE: `UNIQUE (referred_member_id)`

- `referrals.referrals_referrer_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (referrer_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `referrals.referrals_source_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (source_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `wallet_accounts.wallet_accounts_balance_check` — CHECK: `CHECK (balance >= 0::numeric)`

- `wallet_accounts.wallet_accounts_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `wallet_accounts.wallet_accounts_member_id_wallet_type_key` — UNIQUE: `UNIQUE (member_id, wallet_type)`

- `wallet_accounts.wallet_accounts_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `wallet_accounts.wallet_accounts_wallet_type_check` — CHECK: `CHECK (wallet_type = ANY (ARRAY['bid'::text, 'income'::text]))`

- `wallet_transactions.wallet_transactions_amount_check` — CHECK: `CHECK (amount > 0::numeric)`

- `wallet_transactions.wallet_transactions_balance_after_check` — CHECK: `CHECK (balance_after >= 0::numeric)`

- `wallet_transactions.wallet_transactions_direction_check` — CHECK: `CHECK (direction = ANY (ARRAY['credit'::text, 'debit'::text]))`

- `wallet_transactions.wallet_transactions_idempotency_key_key` — UNIQUE: `UNIQUE (idempotency_key)`

- `wallet_transactions.wallet_transactions_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `wallet_transactions.wallet_transactions_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `wallet_transactions.wallet_transactions_wallet_account_id_fkey` — FOREIGN KEY: `FOREIGN KEY (wallet_account_id) REFERENCES wallet_accounts(id) ON DELETE RESTRICT`

- `winning_item_payments.winning_item_payments_amount_check` — CHECK: `CHECK (amount > 0::numeric)`

- `winning_item_payments.winning_item_payments_auction_id_fkey` — FOREIGN KEY: `FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT`

- `winning_item_payments.winning_item_payments_check` — CHECK: `CHECK (((auction_id IS NOT NULL)::integer + (fixed_bid_campaign_id IS NOT NULL)::integer) = 1)`

- `winning_item_payments.winning_item_payments_fixed_bid_campaign_id_fkey` — FOREIGN KEY: `FOREIGN KEY (fixed_bid_campaign_id) REFERENCES fixed_bid_campaigns(id) ON DELETE RESTRICT`

- `winning_item_payments.winning_item_payments_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `winning_item_payments.winning_item_payments_status_check` — CHECK: `CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'refunded'::text]))`

- `winning_item_payments.winning_item_payments_winner_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (winner_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `withdrawal_requests.withdrawal_requests_amount_check` — CHECK: `CHECK (amount > 0::numeric)`

- `withdrawal_requests.withdrawal_requests_member_id_fkey` — FOREIGN KEY: `FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT`

- `withdrawal_requests.withdrawal_requests_pkey` — PRIMARY KEY: `PRIMARY KEY (id)`

- `withdrawal_requests.withdrawal_requests_reviewed_by_fkey` — FOREIGN KEY: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL`

- `withdrawal_requests.withdrawal_requests_status_check` — CHECK: `CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'paid'::text, 'cancelled'::text]))`


## Index definitions

- `app_settings.app_settings_pkey`: `CREATE UNIQUE INDEX app_settings_pkey ON public.app_settings USING btree (setting_key)`

- `auctions.auctions_pkey`: `CREATE UNIQUE INDEX auctions_pkey ON public.auctions USING btree (id)`

- `auctions.auctions_product_id_idx`: `CREATE INDEX auctions_product_id_idx ON public.auctions USING btree (product_id)`

- `auctions.auctions_public_status_ends_idx`: `CREATE INDEX auctions_public_status_ends_idx ON public.auctions USING btree (status, ends_at)`

- `audit_logs.audit_logs_actor_user_id_idx`: `CREATE INDEX audit_logs_actor_user_id_idx ON public.audit_logs USING btree (actor_user_id)`

- `audit_logs.audit_logs_pkey`: `CREATE UNIQUE INDEX audit_logs_pkey ON public.audit_logs USING btree (id)`

- `bids.bids_auction_id_idx`: `CREATE INDEX bids_auction_id_idx ON public.bids USING btree (auction_id)`

- `bids.bids_idempotency_key_key`: `CREATE UNIQUE INDEX bids_idempotency_key_key ON public.bids USING btree (idempotency_key)`

- `bids.bids_member_id_idx`: `CREATE INDEX bids_member_id_idx ON public.bids USING btree (member_id)`

- `bids.bids_pkey`: `CREATE UNIQUE INDEX bids_pkey ON public.bids USING btree (id)`

- `delivery_tracking.delivery_tracking_payment_id_idx`: `CREATE INDEX delivery_tracking_payment_id_idx ON public.delivery_tracking USING btree (winning_item_payment_id)`

- `delivery_tracking.delivery_tracking_pkey`: `CREATE UNIQUE INDEX delivery_tracking_pkey ON public.delivery_tracking USING btree (id)`

- `fixed_bid_campaigns.fixed_bid_campaigns_pkey`: `CREATE UNIQUE INDEX fixed_bid_campaigns_pkey ON public.fixed_bid_campaigns USING btree (id)`

- `fixed_bid_campaigns.fixed_bid_campaigns_product_id_idx`: `CREATE INDEX fixed_bid_campaigns_product_id_idx ON public.fixed_bid_campaigns USING btree (product_id)`

- `fixed_bids.fixed_bids_campaign_id_idx`: `CREATE INDEX fixed_bids_campaign_id_idx ON public.fixed_bids USING btree (campaign_id)`

- `fixed_bids.fixed_bids_idempotency_key_key`: `CREATE UNIQUE INDEX fixed_bids_idempotency_key_key ON public.fixed_bids USING btree (idempotency_key)`

- `fixed_bids.fixed_bids_member_id_idx`: `CREATE INDEX fixed_bids_member_id_idx ON public.fixed_bids USING btree (member_id)`

- `fixed_bids.fixed_bids_pkey`: `CREATE UNIQUE INDEX fixed_bids_pkey ON public.fixed_bids USING btree (id)`

- `member_ids.member_ids_main_member_id_idx`: `CREATE INDEX member_ids_main_member_id_idx ON public.member_ids USING btree (main_member_id)`

- `member_ids.member_ids_member_code_key`: `CREATE UNIQUE INDEX member_ids_member_code_key ON public.member_ids USING btree (member_code)`

- `member_ids.member_ids_owner_user_id_id_type_id_key`: `CREATE UNIQUE INDEX member_ids_owner_user_id_id_type_id_key ON public.member_ids USING btree (owner_user_id, id_type, id)`

- `member_ids.member_ids_pkey`: `CREATE UNIQUE INDEX member_ids_pkey ON public.member_ids USING btree (id)`

- `member_ids.member_ids_placement_parent_id_idx`: `CREATE INDEX member_ids_placement_parent_id_idx ON public.member_ids USING btree (placement_parent_id)`

- `notification_templates.notification_templates_pkey`: `CREATE UNIQUE INDEX notification_templates_pkey ON public.notification_templates USING btree (id)`

- `package_activations.package_activations_member_id_activation_number_key`: `CREATE UNIQUE INDEX package_activations_member_id_activation_number_key ON public.package_activations USING btree (member_id, activation_number)`

- `package_activations.package_activations_package_id_idx`: `CREATE INDEX package_activations_package_id_idx ON public.package_activations USING btree (package_id)`

- `package_activations.package_activations_payment_reference_ci_uidx`: `CREATE UNIQUE INDEX package_activations_payment_reference_ci_uidx ON public.package_activations USING btree (lower(btrim(payment_reference))) WHERE ((payment_reference IS NOT NULL) AND (btrim(payment_reference) <> ''::text))`

- `package_activations.package_activations_payment_reference_uidx`: `CREATE UNIQUE INDEX package_activations_payment_reference_uidx ON public.package_activations USING btree (lower(payment_reference)) WHERE ((payment_reference IS NOT NULL) AND (btrim(payment_reference) <> ''::text))`

- `package_activations.package_activations_pkey`: `CREATE UNIQUE INDEX package_activations_pkey ON public.package_activations USING btree (id)`

- `package_activations.package_activations_verified_by_idx`: `CREATE INDEX package_activations_verified_by_idx ON public.package_activations USING btree (verified_by)`

- `packages.packages_pkey`: `CREATE UNIQUE INDEX packages_pkey ON public.packages USING btree (id)`

- `products.products_pkey`: `CREATE UNIQUE INDEX products_pkey ON public.products USING btree (id)`

- `profiles.profiles_pkey`: `CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id)`

- `referral_commissions.referral_commissions_beneficiary_member_id_idx`: `CREATE INDEX referral_commissions_beneficiary_member_id_idx ON public.referral_commissions USING btree (beneficiary_member_id)`

- `referral_commissions.referral_commissions_credited_main_member_id_idx`: `CREATE INDEX referral_commissions_credited_main_member_id_idx ON public.referral_commissions USING btree (credited_main_member_id)`

- `referral_commissions.referral_commissions_package_activation_id_level_number_ben_key`: `CREATE UNIQUE INDEX referral_commissions_package_activation_id_level_number_ben_key ON public.referral_commissions USING btree (package_activation_id, level_number, beneficiary_member_id)`

- `referral_commissions.referral_commissions_pkey`: `CREATE UNIQUE INDEX referral_commissions_pkey ON public.referral_commissions USING btree (id)`

- `referral_commissions.referral_commissions_plan_version_id_idx`: `CREATE INDEX referral_commissions_plan_version_id_idx ON public.referral_commissions USING btree (plan_version_id)`

- `referral_level_rules.referral_level_rules_pkey`: `CREATE UNIQUE INDEX referral_level_rules_pkey ON public.referral_level_rules USING btree (id)`

- `referral_level_rules.referral_level_rules_plan_version_id_level_number_key`: `CREATE UNIQUE INDEX referral_level_rules_plan_version_id_level_number_key ON public.referral_level_rules USING btree (plan_version_id, level_number)`

- `referral_plan_versions.referral_plan_versions_created_by_idx`: `CREATE INDEX referral_plan_versions_created_by_idx ON public.referral_plan_versions USING btree (created_by)`

- `referral_plan_versions.referral_plan_versions_package_id_version_number_key`: `CREATE UNIQUE INDEX referral_plan_versions_package_id_version_number_key ON public.referral_plan_versions USING btree (package_id, version_number)`

- `referral_plan_versions.referral_plan_versions_pkey`: `CREATE UNIQUE INDEX referral_plan_versions_pkey ON public.referral_plan_versions USING btree (id)`

- `referrals.referrals_pkey`: `CREATE UNIQUE INDEX referrals_pkey ON public.referrals USING btree (id)`

- `referrals.referrals_referred_member_id_key`: `CREATE UNIQUE INDEX referrals_referred_member_id_key ON public.referrals USING btree (referred_member_id)`

- `referrals.referrals_referrer_member_id_idx`: `CREATE INDEX referrals_referrer_member_id_idx ON public.referrals USING btree (referrer_member_id)`

- `referrals.referrals_source_member_id_idx`: `CREATE INDEX referrals_source_member_id_idx ON public.referrals USING btree (source_member_id)`

- `wallet_accounts.wallet_accounts_member_id_wallet_type_key`: `CREATE UNIQUE INDEX wallet_accounts_member_id_wallet_type_key ON public.wallet_accounts USING btree (member_id, wallet_type)`

- `wallet_accounts.wallet_accounts_pkey`: `CREATE UNIQUE INDEX wallet_accounts_pkey ON public.wallet_accounts USING btree (id)`

- `wallet_transactions.wallet_transactions_idempotency_key_key`: `CREATE UNIQUE INDEX wallet_transactions_idempotency_key_key ON public.wallet_transactions USING btree (idempotency_key)`

- `wallet_transactions.wallet_transactions_member_id_idx`: `CREATE INDEX wallet_transactions_member_id_idx ON public.wallet_transactions USING btree (member_id)`

- `wallet_transactions.wallet_transactions_pkey`: `CREATE UNIQUE INDEX wallet_transactions_pkey ON public.wallet_transactions USING btree (id)`

- `wallet_transactions.wallet_transactions_wallet_account_id_idx`: `CREATE INDEX wallet_transactions_wallet_account_id_idx ON public.wallet_transactions USING btree (wallet_account_id)`

- `winning_item_payments.winning_item_payments_auction_id_idx`: `CREATE INDEX winning_item_payments_auction_id_idx ON public.winning_item_payments USING btree (auction_id)`

- `winning_item_payments.winning_item_payments_campaign_id_idx`: `CREATE INDEX winning_item_payments_campaign_id_idx ON public.winning_item_payments USING btree (fixed_bid_campaign_id)`

- `winning_item_payments.winning_item_payments_pkey`: `CREATE UNIQUE INDEX winning_item_payments_pkey ON public.winning_item_payments USING btree (id)`

- `winning_item_payments.winning_item_payments_winner_member_id_idx`: `CREATE INDEX winning_item_payments_winner_member_id_idx ON public.winning_item_payments USING btree (winner_member_id)`

- `withdrawal_requests.withdrawal_requests_member_id_idx`: `CREATE INDEX withdrawal_requests_member_id_idx ON public.withdrawal_requests USING btree (member_id)`

- `withdrawal_requests.withdrawal_requests_pkey`: `CREATE UNIQUE INDEX withdrawal_requests_pkey ON public.withdrawal_requests USING btree (id)`

- `withdrawal_requests.withdrawal_requests_reviewed_by_idx`: `CREATE INDEX withdrawal_requests_reviewed_by_idx ON public.withdrawal_requests USING btree (reviewed_by)`


## Row Level Security policies

### `app_settings.app_settings_read_scoped`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `((setting_key = ANY (ARRAY['bidding_enabled'::text, 'fixed_bid_enabled'::text, 'withdrawals_enabled'::text, 'duplicate_ids_enabled'::text, 'winner_selection_configured'::text])) OR (COALESCE(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text), ''::text) = ANY (ARRAY['admin'::text, 'support'::text, 'finance'::text])))`
- WITH CHECK: ``

### `auctions.visible_auctions_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(status = ANY (ARRAY['scheduled'::text, 'live'::text, 'ended'::text]))`
- WITH CHECK: ``

### `audit_logs.audit_logs_admin_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(COALESCE(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text), ''::text) = ANY (ARRAY['admin'::text, 'support'::text, 'finance'::text]))`
- WITH CHECK: ``

### `bids.bids_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = bids.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `delivery_tracking.delivery_tracking_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM (winning_item_payments p
     JOIN member_ids m ON ((m.id = p.winner_member_id)))
  WHERE ((p.id = delivery_tracking.winning_item_payment_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `fixed_bid_campaigns.visible_fixed_campaigns_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(status = ANY (ARRAY['scheduled'::text, 'live'::text, 'ended'::text]))`
- WITH CHECK: ``

### `fixed_bids.fixed_bids_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = fixed_bids.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `member_ids.member_ids_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = owner_user_id)`
- WITH CHECK: ``

### `package_activations.package_activations_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = package_activations.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `packages.active_packages_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(is_active = true)`
- WITH CHECK: ``

### `products.published_products_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(status = 'published'::text)`
- WITH CHECK: ``

### `profiles.profiles_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(( SELECT auth.uid() AS uid) = id)`
- WITH CHECK: ``

### `referral_commissions.referral_commissions_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referral_commissions.beneficiary_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referral_commissions.credited_main_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))))`
- WITH CHECK: ``

### `referral_level_rules.referral_rules_active_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM referral_plan_versions p
  WHERE ((p.id = referral_level_rules.plan_version_id) AND p.is_active)))`
- WITH CHECK: ``

### `referral_plan_versions.referral_plans_active_read`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `is_active`
- WITH CHECK: ``

### `referrals.referrals_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referrals.referred_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referrals.referrer_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))))`
- WITH CHECK: ``

### `wallet_accounts.wallet_accounts_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = wallet_accounts.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `wallet_transactions.wallet_transactions_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = wallet_transactions.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `winning_item_payments.winning_payments_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = winning_item_payments.winner_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``

### `withdrawal_requests.withdrawals_select_own`
- Command: `SELECT`; roles: `{authenticated}`
- USING: `(EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = withdrawal_requests.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: ``


## Direct table grants (API roles)

- `app_settings` — `authenticated`: SELECT

- `app_settings` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `auctions` — `authenticated`: SELECT

- `auctions` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `audit_logs` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `bids` — `authenticated`: SELECT

- `bids` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `delivery_tracking` — `authenticated`: SELECT

- `delivery_tracking` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `fixed_bid_campaigns` — `authenticated`: SELECT

- `fixed_bid_campaigns` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `fixed_bids` — `authenticated`: SELECT

- `fixed_bids` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `member_ids` — `authenticated`: SELECT

- `member_ids` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `notification_templates` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `package_activations` — `authenticated`: SELECT

- `package_activations` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `packages` — `authenticated`: SELECT

- `packages` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `products` — `authenticated`: SELECT

- `products` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `profiles` — `authenticated`: SELECT

- `profiles` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `referral_commissions` — `authenticated`: SELECT

- `referral_commissions` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `referral_level_rules` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `referral_plan_versions` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `referrals` — `authenticated`: SELECT

- `referrals` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `wallet_accounts` — `authenticated`: SELECT

- `wallet_accounts` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `wallet_transactions` — `authenticated`: SELECT

- `wallet_transactions` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `winning_item_payments` — `authenticated`: SELECT

- `winning_item_payments` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE

- `withdrawal_requests` — `authenticated`: SELECT

- `withdrawal_requests` — `service_role`: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE


## Sequence usage grants

- `audit_logs_id_seq` — `anon`: USAGE

- `audit_logs_id_seq` — `authenticated`: USAGE

- `audit_logs_id_seq` — `postgres`: USAGE

- `audit_logs_id_seq` — `service_role`: USAGE


## Replay cautions
- This is a structural evidence snapshot, not executable DDL and not a replacement for a canonical baseline.
- Auth foreign keys must continue to reference Supabase-managed `auth.users`; do not recreate the auth schema.
- The 20 SELECT policies do not imply that client table writes are allowed. Production exposes member/admin writes through RPCs; preserve the actual function ACLs and authorization checks.
- All 21 public tables have RLS enabled, but `notification_templates` and `audit_logs` have no authenticated table SELECT grant/policy path for general members.
- The sequence usage grants are recorded as observed, not changed. Evaluate whether `audit_logs_id_seq` should be callable by anon/authenticated in the eventual baseline; do not modify Production as part of this audit.
- Recreate indexes and constraints in dependency-aware order; indexes backing primary/unique constraints are already represented by those constraints and should not be duplicated.
