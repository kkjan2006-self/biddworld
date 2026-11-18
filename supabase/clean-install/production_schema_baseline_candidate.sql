-- BiddWorld verified-Production schema baseline candidate
-- Captured from read-only catalogue metadata on 2026-11-18.
-- Project: hbqatszyzqobgtauyuzy (Production, ap-south-1, PostgreSQL 17.11).
-- This file contains schema definitions only; no application/member/financial rows.
-- IMPORTANT: CANDIDATE ONLY. Do not execute against Production. Do not treat as a
-- validated clean-install migration until the final development/testing phase has
-- replayed it on the isolated TEST project and reconciled every resulting object.
-- Base state: current Production public/private application schema as observed.
-- Forward source-only migrations are listed separately in forward-migrations.txt.

begin;
set search_path = public, auth, extensions;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

-- Installed extension inventory (Supabase-managed platform extensions may already exist).
-- The application functions in this snapshot rely on pgcrypto; uuid-ossp is recorded
-- as installed on Production but is not required by the captured function definitions.
create extension if not exists pgcrypto with schema extensions;

-- 1. Public application tables (columns, types, identity/defaults, nullability).

create table public.app_settings (
  setting_key text not null,
  setting_value jsonb not null,
  updated_at timestamp with time zone default now() not null
);

create table public.auctions (
  id uuid default gen_random_uuid() not null,
  product_id uuid not null,
  title text not null,
  description text,
  starts_at timestamp with time zone,
  ends_at timestamp with time zone,
  status text default 'draft'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  image_url text,
  category text,
  currency character(3) default 'INR'::bpchar not null,
  starting_price numeric(14,2) default 0 not null,
  current_price numeric(14,2) default 0 not null,
  minimum_increment numeric(14,2) default 1 not null
);

create table public.audit_logs (
  id bigint generated always as identity not null,
  actor_user_id uuid,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null
);

create table public.bids (
  id uuid default gen_random_uuid() not null,
  auction_id uuid not null,
  member_id uuid not null,
  bid_amount numeric(14,2) not null,
  bid_wallet_debit numeric(14,2) default 0 not null,
  income_wallet_debit numeric(14,2) default 0 not null,
  status text default 'accepted'::text not null,
  idempotency_key text not null,
  created_at timestamp with time zone default now() not null
);

create table public.delivery_tracking (
  id uuid default gen_random_uuid() not null,
  winning_item_payment_id uuid not null,
  carrier text,
  tracking_number text,
  status text default 'pending'::text not null,
  shipped_at timestamp with time zone,
  delivered_at timestamp with time zone,
  updated_at timestamp with time zone default now() not null
);

create table public.fixed_bid_campaigns (
  id uuid default gen_random_uuid() not null,
  product_id uuid not null,
  title text not null,
  description text,
  status text default 'draft'::text not null,
  configuration jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.fixed_bids (
  id uuid default gen_random_uuid() not null,
  campaign_id uuid not null,
  member_id uuid not null,
  bid_amount numeric(14,2) not null,
  status text default 'submitted'::text not null,
  idempotency_key text not null,
  created_at timestamp with time zone default now() not null
);

create table public.member_ids (
  id uuid default gen_random_uuid() not null,
  owner_user_id uuid not null,
  main_member_id uuid,
  member_code text not null,
  id_type text not null,
  status text default 'pending'::text not null,
  placement_parent_id uuid,
  placement_position text,
  created_at timestamp with time zone default now() not null
);

create table public.notification_templates (
  id uuid default gen_random_uuid() not null,
  name text not null,
  channel text not null,
  subject text,
  body text not null,
  is_active boolean default false not null,
  created_by uuid not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.package_activations (
  id uuid default gen_random_uuid() not null,
  member_id uuid not null,
  package_id uuid not null,
  activation_number integer not null,
  amount_paid numeric(14,2) not null,
  currency character(3) default 'INR'::bpchar not null,
  payment_status text default 'pending'::text not null,
  activation_status text default 'pending'::text not null,
  payment_reference text,
  submitted_at timestamp with time zone default now() not null,
  verified_at timestamp with time zone,
  verified_by uuid,
  bid_wallet_credit numeric(14,2) default 0 not null
);

create table public.packages (
  id uuid default gen_random_uuid() not null,
  name text not null,
  description text,
  price numeric(14,2) not null,
  currency character(3) default 'INR'::bpchar not null,
  bid_wallet_credit numeric(14,2) default 0 not null,
  is_active boolean default false not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.products (
  id uuid default gen_random_uuid() not null,
  name text not null,
  description text,
  image_path text,
  category text,
  status text default 'draft'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.profiles (
  id uuid not null,
  main_member_id uuid,
  display_name text,
  phone text,
  status text default 'pending'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.referral_commissions (
  id uuid default gen_random_uuid() not null,
  package_activation_id uuid not null,
  plan_version_id uuid not null,
  level_number integer not null,
  beneficiary_member_id uuid not null,
  credited_main_member_id uuid,
  amount numeric(14,2) not null,
  status text default 'pending'::text not null,
  created_at timestamp with time zone default now() not null
);

create table public.referral_level_rules (
  id uuid default gen_random_uuid() not null,
  plan_version_id uuid not null,
  level_number integer not null,
  reward_type text not null,
  reward_value numeric(14,4) not null,
  eligibility_rule jsonb default '{}'::jsonb not null
);

create table public.referral_plan_versions (
  id uuid default gen_random_uuid() not null,
  package_id uuid not null,
  version_number integer not null,
  is_active boolean default false not null,
  created_at timestamp with time zone default now() not null,
  created_by uuid
);

create table public.referrals (
  id uuid default gen_random_uuid() not null,
  referred_member_id uuid not null,
  referrer_member_id uuid,
  source_member_id uuid,
  created_at timestamp with time zone default now() not null
);

create table public.wallet_accounts (
  id uuid default gen_random_uuid() not null,
  member_id uuid not null,
  wallet_type text not null,
  balance numeric(14,2) default 0 not null,
  currency character(3) default 'INR'::bpchar not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.wallet_transactions (
  id uuid default gen_random_uuid() not null,
  wallet_account_id uuid not null,
  member_id uuid not null,
  transaction_type text not null,
  direction text not null,
  amount numeric(14,2) not null,
  balance_after numeric(14,2),
  reference_type text,
  reference_id uuid,
  idempotency_key text,
  description text,
  created_at timestamp with time zone default now() not null
);

create table public.winning_item_payments (
  id uuid default gen_random_uuid() not null,
  auction_id uuid,
  fixed_bid_campaign_id uuid,
  winner_member_id uuid not null,
  amount numeric(14,2) not null,
  status text default 'pending'::text not null,
  paid_at timestamp with time zone,
  created_at timestamp with time zone default now() not null
);

create table public.withdrawal_requests (
  id uuid default gen_random_uuid() not null,
  member_id uuid not null,
  amount numeric(14,2) not null,
  currency character(3) default 'INR'::bpchar not null,
  status text default 'pending'::text not null,
  payout_details jsonb,
  requested_at timestamp with time zone default now() not null,
  reviewed_at timestamp with time zone,
  reviewed_by uuid,
  rejection_reason text
);

-- 2. Constraints (primary keys, foreign keys, unique and check constraints).

alter table public.app_settings add constraint app_settings_pkey PRIMARY KEY (setting_key);
alter table public.auctions add constraint auctions_current_price_check CHECK (current_price >= 0::numeric);
alter table public.auctions add constraint auctions_minimum_increment_check CHECK (minimum_increment > 0::numeric);
alter table public.auctions add constraint auctions_pkey PRIMARY KEY (id);
alter table public.auctions add constraint auctions_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT;
alter table public.auctions add constraint auctions_starting_price_check CHECK (starting_price >= 0::numeric);
alter table public.auctions add constraint auctions_status_check CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'live'::text, 'paused'::text, 'ended'::text, 'cancelled'::text]));
alter table public.audit_logs add constraint audit_logs_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.audit_logs add constraint audit_logs_pkey PRIMARY KEY (id);
alter table public.bids add constraint bids_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT;
alter table public.bids add constraint bids_bid_amount_check CHECK (bid_amount > 0::numeric);
alter table public.bids add constraint bids_bid_wallet_debit_check CHECK (bid_wallet_debit >= 0::numeric);
alter table public.bids add constraint bids_idempotency_key_key UNIQUE (idempotency_key);
alter table public.bids add constraint bids_income_wallet_debit_check CHECK (income_wallet_debit >= 0::numeric);
alter table public.bids add constraint bids_member_id_fkey FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.bids add constraint bids_pkey PRIMARY KEY (id);
alter table public.bids add constraint bids_status_check CHECK (status = ANY (ARRAY['accepted'::text, 'rejected'::text, 'voided'::text]));
alter table public.delivery_tracking add constraint delivery_tracking_pkey PRIMARY KEY (id);
alter table public.delivery_tracking add constraint delivery_tracking_status_check CHECK (status = ANY (ARRAY['pending'::text, 'packed'::text, 'shipped'::text, 'in_transit'::text, 'delivered'::text, 'returned'::text]));
alter table public.delivery_tracking add constraint delivery_tracking_winning_item_payment_id_fkey FOREIGN KEY (winning_item_payment_id) REFERENCES winning_item_payments(id) ON DELETE RESTRICT;
alter table public.fixed_bid_campaigns add constraint fixed_bid_campaigns_pkey PRIMARY KEY (id);
alter table public.fixed_bid_campaigns add constraint fixed_bid_campaigns_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT;
alter table public.fixed_bid_campaigns add constraint fixed_bid_campaigns_status_check CHECK (status = ANY (ARRAY['draft'::text, 'scheduled'::text, 'live'::text, 'paused'::text, 'ended'::text, 'cancelled'::text]));
alter table public.fixed_bids add constraint fixed_bids_bid_amount_check CHECK (bid_amount > 0::numeric);
alter table public.fixed_bids add constraint fixed_bids_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES fixed_bid_campaigns(id) ON DELETE RESTRICT;
alter table public.fixed_bids add constraint fixed_bids_idempotency_key_key UNIQUE (idempotency_key);
alter table public.fixed_bids add constraint fixed_bids_member_id_fkey FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.fixed_bids add constraint fixed_bids_pkey PRIMARY KEY (id);
alter table public.fixed_bids add constraint fixed_bids_status_check CHECK (status = ANY (ARRAY['submitted'::text, 'accepted'::text, 'rejected'::text, 'voided'::text]));
alter table public.member_ids add constraint member_ids_id_type_check CHECK (id_type = ANY (ARRAY['main'::text, 'duplicate'::text]));
alter table public.member_ids add constraint member_ids_main_member_id_fkey FOREIGN KEY (main_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.member_ids add constraint member_ids_member_code_key UNIQUE (member_code);
alter table public.member_ids add constraint member_ids_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE RESTRICT;
alter table public.member_ids add constraint member_ids_owner_user_id_id_type_id_key UNIQUE (owner_user_id, id_type, id);
alter table public.member_ids add constraint member_ids_pkey PRIMARY KEY (id);
alter table public.member_ids add constraint member_ids_placement_parent_id_fkey FOREIGN KEY (placement_parent_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.member_ids add constraint member_ids_status_check CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'closed'::text]));
alter table public.notification_templates add constraint notification_template_subject_check CHECK (channel = 'email'::text AND subject IS NOT NULL AND length(btrim(subject)) >= 1 AND length(btrim(subject)) <= 160 OR channel <> 'email'::text AND subject IS NULL);
alter table public.notification_templates add constraint notification_templates_body_check CHECK (length(btrim(body)) >= 1 AND length(btrim(body)) <= 5000);
alter table public.notification_templates add constraint notification_templates_channel_check CHECK (channel = ANY (ARRAY['in_app'::text, 'email'::text, 'sms'::text]));
alter table public.notification_templates add constraint notification_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);
alter table public.notification_templates add constraint notification_templates_name_check CHECK (length(btrim(name)) >= 2 AND length(btrim(name)) <= 100);
alter table public.notification_templates add constraint notification_templates_pkey PRIMARY KEY (id);
alter table public.package_activations add constraint package_activations_activation_number_check CHECK (activation_number > 0);
alter table public.package_activations add constraint package_activations_activation_status_check CHECK (activation_status = ANY (ARRAY['pending'::text, 'active'::text, 'rejected'::text, 'cancelled'::text]));
alter table public.package_activations add constraint package_activations_amount_paid_check CHECK (amount_paid >= 0::numeric);
alter table public.package_activations add constraint package_activations_bid_wallet_credit_check CHECK (bid_wallet_credit >= 0::numeric);
alter table public.package_activations add constraint package_activations_member_id_activation_number_key UNIQUE (member_id, activation_number);
alter table public.package_activations add constraint package_activations_member_id_fkey FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.package_activations add constraint package_activations_package_id_fkey FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE RESTRICT;
alter table public.package_activations add constraint package_activations_payment_status_check CHECK (payment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'refunded'::text]));
alter table public.package_activations add constraint package_activations_pkey PRIMARY KEY (id);
alter table public.package_activations add constraint package_activations_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.packages add constraint packages_bid_wallet_credit_check CHECK (bid_wallet_credit >= 0::numeric);
alter table public.packages add constraint packages_pkey PRIMARY KEY (id);
alter table public.packages add constraint packages_price_check CHECK (price >= 0::numeric);
alter table public.products add constraint products_pkey PRIMARY KEY (id);
alter table public.products add constraint products_status_check CHECK (status = ANY (ARRAY['draft'::text, 'published'::text, 'archived'::text]));
alter table public.profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.profiles add constraint profiles_pkey PRIMARY KEY (id);
alter table public.profiles add constraint profiles_status_check CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'closed'::text]));
alter table public.referral_commissions add constraint referral_commissions_amount_check CHECK (amount >= 0::numeric);
alter table public.referral_commissions add constraint referral_commissions_beneficiary_member_id_fkey FOREIGN KEY (beneficiary_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.referral_commissions add constraint referral_commissions_credited_main_member_id_fkey FOREIGN KEY (credited_main_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.referral_commissions add constraint referral_commissions_level_number_check CHECK (level_number > 0);
alter table public.referral_commissions add constraint referral_commissions_package_activation_id_fkey FOREIGN KEY (package_activation_id) REFERENCES package_activations(id) ON DELETE RESTRICT;
alter table public.referral_commissions add constraint referral_commissions_package_activation_id_level_number_ben_key UNIQUE (package_activation_id, level_number, beneficiary_member_id);
alter table public.referral_commissions add constraint referral_commissions_pkey PRIMARY KEY (id);
alter table public.referral_commissions add constraint referral_commissions_plan_version_id_fkey FOREIGN KEY (plan_version_id) REFERENCES referral_plan_versions(id) ON DELETE RESTRICT;
alter table public.referral_commissions add constraint referral_commissions_status_check CHECK (status = ANY (ARRAY['pending'::text, 'credited'::text, 'reversed'::text]));
alter table public.referral_level_rules add constraint referral_level_rules_level_number_check CHECK (level_number > 0);
alter table public.referral_level_rules add constraint referral_level_rules_pkey PRIMARY KEY (id);
alter table public.referral_level_rules add constraint referral_level_rules_plan_version_id_fkey FOREIGN KEY (plan_version_id) REFERENCES referral_plan_versions(id) ON DELETE CASCADE;
alter table public.referral_level_rules add constraint referral_level_rules_plan_version_id_level_number_key UNIQUE (plan_version_id, level_number);
alter table public.referral_level_rules add constraint referral_level_rules_reward_type_check CHECK (reward_type = ANY (ARRAY['fixed'::text, 'percentage'::text]));
alter table public.referral_level_rules add constraint referral_level_rules_reward_value_check CHECK (reward_value >= 0::numeric);
alter table public.referral_plan_versions add constraint referral_plan_versions_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.referral_plan_versions add constraint referral_plan_versions_package_id_fkey FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE RESTRICT;
alter table public.referral_plan_versions add constraint referral_plan_versions_package_id_version_number_key UNIQUE (package_id, version_number);
alter table public.referral_plan_versions add constraint referral_plan_versions_pkey PRIMARY KEY (id);
alter table public.referral_plan_versions add constraint referral_plan_versions_version_number_check CHECK (version_number > 0);
alter table public.referrals add constraint referrals_pkey PRIMARY KEY (id);
alter table public.referrals add constraint referrals_referred_member_id_fkey FOREIGN KEY (referred_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.referrals add constraint referrals_referred_member_id_key UNIQUE (referred_member_id);
alter table public.referrals add constraint referrals_referrer_member_id_fkey FOREIGN KEY (referrer_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.referrals add constraint referrals_source_member_id_fkey FOREIGN KEY (source_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.wallet_accounts add constraint wallet_accounts_balance_check CHECK (balance >= 0::numeric);
alter table public.wallet_accounts add constraint wallet_accounts_member_id_fkey FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.wallet_accounts add constraint wallet_accounts_member_id_wallet_type_key UNIQUE (member_id, wallet_type);
alter table public.wallet_accounts add constraint wallet_accounts_pkey PRIMARY KEY (id);
alter table public.wallet_accounts add constraint wallet_accounts_wallet_type_check CHECK (wallet_type = ANY (ARRAY['bid'::text, 'income'::text]));
alter table public.wallet_transactions add constraint wallet_transactions_amount_check CHECK (amount > 0::numeric);
alter table public.wallet_transactions add constraint wallet_transactions_balance_after_check CHECK (balance_after >= 0::numeric);
alter table public.wallet_transactions add constraint wallet_transactions_direction_check CHECK (direction = ANY (ARRAY['credit'::text, 'debit'::text]));
alter table public.wallet_transactions add constraint wallet_transactions_idempotency_key_key UNIQUE (idempotency_key);
alter table public.wallet_transactions add constraint wallet_transactions_member_id_fkey FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.wallet_transactions add constraint wallet_transactions_pkey PRIMARY KEY (id);
alter table public.wallet_transactions add constraint wallet_transactions_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES wallet_accounts(id) ON DELETE RESTRICT;
alter table public.winning_item_payments add constraint winning_item_payments_amount_check CHECK (amount > 0::numeric);
alter table public.winning_item_payments add constraint winning_item_payments_auction_id_fkey FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT;
alter table public.winning_item_payments add constraint winning_item_payments_check CHECK (((auction_id IS NOT NULL)::integer + (fixed_bid_campaign_id IS NOT NULL)::integer) = 1);
alter table public.winning_item_payments add constraint winning_item_payments_fixed_bid_campaign_id_fkey FOREIGN KEY (fixed_bid_campaign_id) REFERENCES fixed_bid_campaigns(id) ON DELETE RESTRICT;
alter table public.winning_item_payments add constraint winning_item_payments_pkey PRIMARY KEY (id);
alter table public.winning_item_payments add constraint winning_item_payments_status_check CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'refunded'::text]));
alter table public.winning_item_payments add constraint winning_item_payments_winner_member_id_fkey FOREIGN KEY (winner_member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.withdrawal_requests add constraint withdrawal_requests_amount_check CHECK (amount > 0::numeric);
alter table public.withdrawal_requests add constraint withdrawal_requests_member_id_fkey FOREIGN KEY (member_id) REFERENCES member_ids(id) ON DELETE RESTRICT;
alter table public.withdrawal_requests add constraint withdrawal_requests_pkey PRIMARY KEY (id);
alter table public.withdrawal_requests add constraint withdrawal_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.withdrawal_requests add constraint withdrawal_requests_status_check CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'paid'::text, 'cancelled'::text]));

-- 3. Non-constraint indexes.

CREATE INDEX auctions_public_status_ends_idx ON public.auctions USING btree (status, ends_at);
CREATE INDEX auctions_product_id_idx ON public.auctions USING btree (product_id);
CREATE INDEX audit_logs_actor_user_id_idx ON public.audit_logs USING btree (actor_user_id);
CREATE INDEX bids_auction_id_idx ON public.bids USING btree (auction_id);
CREATE INDEX bids_member_id_idx ON public.bids USING btree (member_id);
CREATE INDEX delivery_tracking_payment_id_idx ON public.delivery_tracking USING btree (winning_item_payment_id);
CREATE INDEX fixed_bid_campaigns_product_id_idx ON public.fixed_bid_campaigns USING btree (product_id);
CREATE INDEX fixed_bids_campaign_id_idx ON public.fixed_bids USING btree (campaign_id);
CREATE INDEX fixed_bids_member_id_idx ON public.fixed_bids USING btree (member_id);
CREATE INDEX member_ids_main_member_id_idx ON public.member_ids USING btree (main_member_id);
CREATE INDEX member_ids_placement_parent_id_idx ON public.member_ids USING btree (placement_parent_id);
CREATE UNIQUE INDEX package_activations_payment_reference_uidx ON public.package_activations USING btree (lower(payment_reference)) WHERE ((payment_reference IS NOT NULL) AND (btrim(payment_reference) <> ''::text));
CREATE INDEX package_activations_package_id_idx ON public.package_activations USING btree (package_id);
CREATE INDEX package_activations_verified_by_idx ON public.package_activations USING btree (verified_by);
CREATE UNIQUE INDEX package_activations_payment_reference_ci_uidx ON public.package_activations USING btree (lower(btrim(payment_reference))) WHERE ((payment_reference IS NOT NULL) AND (btrim(payment_reference) <> ''::text));
CREATE INDEX referral_commissions_beneficiary_member_id_idx ON public.referral_commissions USING btree (beneficiary_member_id);
CREATE INDEX referral_commissions_credited_main_member_id_idx ON public.referral_commissions USING btree (credited_main_member_id);
CREATE INDEX referral_commissions_plan_version_id_idx ON public.referral_commissions USING btree (plan_version_id);
CREATE INDEX referral_plan_versions_created_by_idx ON public.referral_plan_versions USING btree (created_by);
CREATE INDEX referrals_referrer_member_id_idx ON public.referrals USING btree (referrer_member_id);
CREATE INDEX referrals_source_member_id_idx ON public.referrals USING btree (source_member_id);
CREATE INDEX wallet_transactions_member_id_idx ON public.wallet_transactions USING btree (member_id);
CREATE INDEX wallet_transactions_wallet_account_id_idx ON public.wallet_transactions USING btree (wallet_account_id);
CREATE INDEX winning_item_payments_auction_id_idx ON public.winning_item_payments USING btree (auction_id);
CREATE INDEX winning_item_payments_campaign_id_idx ON public.winning_item_payments USING btree (fixed_bid_campaign_id);
CREATE INDEX winning_item_payments_winner_member_id_idx ON public.winning_item_payments USING btree (winner_member_id);
CREATE INDEX withdrawal_requests_member_id_idx ON public.withdrawal_requests USING btree (member_id);
CREATE INDEX withdrawal_requests_reviewed_by_idx ON public.withdrawal_requests USING btree (reviewed_by);

-- 4. Row Level Security.

alter table public.app_settings enable row level security;
alter table public.auctions enable row level security;
alter table public.audit_logs enable row level security;
alter table public.bids enable row level security;
alter table public.delivery_tracking enable row level security;
alter table public.fixed_bid_campaigns enable row level security;
alter table public.fixed_bids enable row level security;
alter table public.member_ids enable row level security;
alter table public.notification_templates enable row level security;
alter table public.package_activations enable row level security;
alter table public.packages enable row level security;
alter table public.products enable row level security;
alter table public.profiles enable row level security;
alter table public.referral_commissions enable row level security;
alter table public.referral_level_rules enable row level security;
alter table public.referral_plan_versions enable row level security;
alter table public.referrals enable row level security;
alter table public.wallet_accounts enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.winning_item_payments enable row level security;
alter table public.withdrawal_requests enable row level security;

-- 5. Exact Production RLS policy definitions.

create policy app_settings_read_scoped on public.app_settings as PERMISSIVE for SELECT to authenticated using (((setting_key = ANY (ARRAY['bidding_enabled'::text, 'fixed_bid_enabled'::text, 'withdrawals_enabled'::text, 'duplicate_ids_enabled'::text, 'winner_selection_configured'::text])) OR (COALESCE(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text), ''::text) = ANY (ARRAY['admin'::text, 'support'::text, 'finance'::text]))));
create policy visible_auctions_read on public.auctions as PERMISSIVE for SELECT to authenticated using ((status = ANY (ARRAY['scheduled'::text, 'live'::text, 'ended'::text])));
create policy audit_logs_admin_read on public.audit_logs as PERMISSIVE for SELECT to authenticated using ((COALESCE(((( SELECT auth.jwt() AS jwt) -> 'app_metadata'::text) ->> 'role'::text), ''::text) = ANY (ARRAY['admin'::text, 'support'::text, 'finance'::text])));
create policy bids_select_own on public.bids as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = bids.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy delivery_tracking_select_own on public.delivery_tracking as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM (winning_item_payments p
     JOIN member_ids m ON ((m.id = p.winner_member_id)))
  WHERE ((p.id = delivery_tracking.winning_item_payment_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy visible_fixed_campaigns_read on public.fixed_bid_campaigns as PERMISSIVE for SELECT to authenticated using ((status = ANY (ARRAY['scheduled'::text, 'live'::text, 'ended'::text])));
create policy fixed_bids_select_own on public.fixed_bids as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = fixed_bids.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy member_ids_select_own on public.member_ids as PERMISSIVE for SELECT to authenticated using ((( SELECT auth.uid() AS uid) = owner_user_id));
create policy package_activations_select_own on public.package_activations as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = package_activations.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy active_packages_read on public.packages as PERMISSIVE for SELECT to authenticated using ((is_active = true));
create policy published_products_read on public.products as PERMISSIVE for SELECT to authenticated using ((status = 'published'::text));
create policy profiles_select_own on public.profiles as PERMISSIVE for SELECT to authenticated using ((( SELECT auth.uid() AS uid) = id));
create policy referral_commissions_select_own on public.referral_commissions as PERMISSIVE for SELECT to authenticated using (((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referral_commissions.beneficiary_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referral_commissions.credited_main_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))));
create policy referral_rules_active_read on public.referral_level_rules as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM referral_plan_versions p
  WHERE ((p.id = referral_level_rules.plan_version_id) AND p.is_active))));
create policy referral_plans_active_read on public.referral_plan_versions as PERMISSIVE for SELECT to authenticated using (is_active);
create policy referrals_select_own on public.referrals as PERMISSIVE for SELECT to authenticated using (((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referrals.referred_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = referrals.referrer_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid)))))));
create policy wallet_accounts_select_own on public.wallet_accounts as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = wallet_accounts.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy wallet_transactions_select_own on public.wallet_transactions as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = wallet_transactions.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy winning_payments_select_own on public.winning_item_payments as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = winning_item_payments.winner_member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));
create policy withdrawals_select_own on public.withdrawal_requests as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM member_ids m
  WHERE ((m.id = withdrawal_requests.member_id) AND (m.owner_user_id = ( SELECT auth.uid() AS uid))))));

-- 6. App-owned public/private function definitions, including fixed search_path.

CREATE OR REPLACE FUNCTION private.enforce_feature_gate()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_key text; v_enabled boolean; v_wallet_type text; v_row jsonb:=to_jsonb(new); v_old jsonb:=to_jsonb(old);
begin
 if tg_table_name='member_ids' and v_row->>'id_type'='duplicate' then
  v_key:='duplicate_ids_enabled';
  if v_row->>'status'='active' then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled by administrator' using errcode='42501'; end if; end if;
 elsif tg_table_name='referrals' then v_key:='sponsor_referrals_enabled';
 elsif tg_table_name='package_activations' then
  if tg_op='INSERT' then v_key:='package_activations_enabled'; elsif v_row->>'activation_status'='active' and v_old->>'activation_status' is distinct from v_row->>'activation_status' then v_key:='package_activations_enabled'; end if;
 elsif tg_table_name='wallet_transactions' then
  select wallet_type into v_wallet_type from public.wallet_accounts where id=(v_row->>'wallet_account_id')::uuid;
  if v_wallet_type='bid' then v_key:='bid_wallet_enabled'; elsif v_wallet_type='income' then v_key:='income_wallet_enabled'; end if;
 elsif tg_table_name='bids' then
  v_key:='bidding_enabled'; select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'Bidding is disabled by administrator' using errcode='42501'; end if;
  if coalesce((v_row->>'bid_wallet_debit')::numeric,0)>0 then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key='bid_wallet_enabled'; if not coalesce(v_enabled,false) then raise exception 'Bid Wallet is disabled' using errcode='42501'; end if; end if;
  if coalesce((v_row->>'income_wallet_debit')::numeric,0)>0 then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key='income_wallet_enabled'; if not coalesce(v_enabled,false) then raise exception 'Income Wallet is disabled' using errcode='42501'; end if; end if; return new;
 elsif tg_table_name='referral_commissions' then
  if v_row->>'status'='credited' then v_key:='referral_commissions_enabled'; if not exists(select 1 from public.package_activations a where a.id=(v_row->>'package_activation_id')::uuid and a.payment_status='approved' and a.activation_status='active') then raise exception 'Referral commission requires an approved active package activation' using errcode='23514'; end if; end if;
 elsif tg_table_name='withdrawal_requests' then v_key:='withdrawals_enabled';
 elsif tg_table_name='fixed_bid_campaigns' then if v_row->>'status' in ('live','active','published') then v_key:='fixed_bid_enabled'; end if;
 elsif tg_table_name='winning_item_payments' then if v_row->>'status'='paid' then v_key:='winning_payment_enabled'; end if;
 elsif tg_table_name='delivery_tracking' then v_key:='delivery_tracking_enabled';
 end if;
 if v_key is not null then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'This action is disabled by the BiddWorld administrator (%)',v_key using errcode='42501'; end if; end if;
 return new;
end; $function$

CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_member_id uuid; v_member_code text; v_sponsor_id uuid; v_sponsor_code text; v_default text; v_requested text; v_registration_enabled boolean; v_sponsor_enabled boolean;
begin
 select coalesce((setting_value #>> '{}')::boolean,false) into v_registration_enabled from public.app_settings where setting_key='registration_enabled';
 if not coalesce(v_registration_enabled,false) then raise exception 'New member registration is currently disabled' using errcode='55000'; end if;
 select coalesce((setting_value #>> '{}')::boolean,false) into v_sponsor_enabled from public.app_settings where setting_key='sponsor_referrals_enabled';
 insert into public.profiles(id,display_name,phone,status) values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),split_part(coalesce(new.email,''),'@',1)),nullif(new.raw_user_meta_data->>'phone',''),'active') on conflict(id) do update set display_name=excluded.display_name,phone=excluded.phone;
 if coalesce(v_sponsor_enabled,false) then
  v_requested:=nullif(trim(coalesce(new.raw_user_meta_data->>'sponsor_referral_id','')),'');
  if v_requested is not null then select id,member_code into v_sponsor_id,v_sponsor_code from public.member_ids where upper(member_code)=upper(v_requested) and id_type='main' and status='active'; if v_sponsor_id is null then raise exception 'Invalid Sponsor Referral ID'; end if;
  else select setting_value #>> '{}' into v_default from public.app_settings where setting_key='default_sponsor_member_id';
   if v_default is not null then v_sponsor_id:=v_default::uuid; select member_code into v_sponsor_code from public.member_ids where id=v_sponsor_id and id_type='main' and status='active'; if v_sponsor_code is null then raise exception 'Default administrator sponsor is not configured correctly'; end if;
   elsif exists(select 1 from public.member_ids where id_type='main' and status='active') then raise exception 'Default administrator sponsor has not been configured'; end if;
  end if;
 end if;
 v_member_code:='BW'||upper(substr(replace(pg_catalog.gen_random_uuid()::text,'-',''),1,10));
 insert into public.member_ids(owner_user_id,member_code,id_type,status) values(new.id,v_member_code,'main','active') on conflict do nothing returning id into v_member_id;
 if v_member_id is null then select id into v_member_id from public.member_ids where owner_user_id=new.id and id_type='main' limit 1; end if;
 if v_member_id is not null then update public.profiles set main_member_id=v_member_id where id=new.id; insert into public.wallet_accounts(member_id,wallet_type,balance) values(v_member_id,'bid',0),(v_member_id,'income',0) on conflict(member_id,wallet_type) do nothing; if v_sponsor_id is not null then insert into public.referrals(referred_member_id,referrer_member_id,source_member_id) values(v_member_id,v_sponsor_id,v_sponsor_id) on conflict(referred_member_id) do nothing; end if; end if;
 return new;
end; $function$

CREATE OR REPLACE FUNCTION private.place_bid(p_auction_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_auction public.auctions%rowtype;
  v_bid_wallet public.wallet_accounts%rowtype;
  v_income_wallet public.wallet_accounts%rowtype;
  v_amount numeric(14,2);
  v_bid_debit numeric(14,2);
  v_income_debit numeric(14,2);
  v_enabled boolean := false;
  v_key text := gen_random_uuid()::text;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;

  select coalesce((setting_value #>> '{}')::boolean,false)
    into v_enabled from public.app_settings where setting_key='bidding_enabled';
  if not coalesce(v_enabled,false) then
    raise exception 'Bidding is disabled by administrator';
  end if;

  select id into v_member_id
    from public.member_ids
    where owner_user_id=v_uid and id_type='main' and status='active'
    limit 1;
  if v_member_id is null then raise exception 'An active main member ID is required'; end if;

  select * into v_auction from public.auctions
    where id=p_auction_id for update;
  if not found or v_auction.status <> 'live'
     or v_auction.starts_at is null or v_auction.ends_at is null
     or now() < v_auction.starts_at or now() >= v_auction.ends_at then
    raise exception 'Auction is not open';
  end if;

  v_amount := v_auction.current_price + v_auction.minimum_increment;

  select * into v_bid_wallet from public.wallet_accounts
    where member_id=v_member_id and wallet_type='bid' for update;
  select * into v_income_wallet from public.wallet_accounts
    where member_id=v_member_id and wallet_type='income' for update;
  if v_bid_wallet.id is null or v_income_wallet.id is null then
    raise exception 'Wallets unavailable';
  end if;

  v_bid_debit := least(v_bid_wallet.balance,v_amount);
  v_income_debit := v_amount-v_bid_debit;
  if v_income_wallet.balance < v_income_debit then
    raise exception 'Insufficient combined wallet balance';
  end if;

  update public.wallet_accounts set balance=balance-v_bid_debit,updated_at=now()
    where id=v_bid_wallet.id;
  update public.wallet_accounts set balance=balance-v_income_debit,updated_at=now()
    where id=v_income_wallet.id;

  if v_bid_debit > 0 then
    insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
    values(v_bid_wallet.id,v_member_id,'auction_bid','debit',v_bid_debit,v_bid_wallet.balance-v_bid_debit,'auction',p_auction_id,v_key||':bid','Auction bid wallet debit');
  end if;
  if v_income_debit > 0 then
    insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
    values(v_income_wallet.id,v_member_id,'auction_bid','debit',v_income_debit,v_income_wallet.balance-v_income_debit,'auction',p_auction_id,v_key||':income','Auction income wallet debit');
  end if;

  insert into public.bids(auction_id,member_id,bid_amount,bid_wallet_debit,income_wallet_debit,status,idempotency_key)
  values(p_auction_id,v_member_id,v_amount,v_bid_debit,v_income_debit,'accepted',v_key);
  update public.auctions set current_price=v_amount,updated_at=now() where id=p_auction_id;

  return jsonb_build_object('success',true,'bid_amount',v_amount,'bid_idempotency_key',v_key);
end;
$function$

CREATE OR REPLACE FUNCTION private.submit_package_activation(p_package_id uuid, p_payment_reference text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_package public.packages%rowtype;
  v_activation_id uuid;
  v_activation_number integer;
  v_reference text := btrim(coalesce(p_payment_reference, ''));
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if length(v_reference) < 6 or length(v_reference) > 80
     or v_reference !~ '^[A-Za-z0-9./_-]+$' then
    raise exception 'Enter a valid payment reference (6 to 80 letters or numbers)';
  end if;

  select id into v_member_id
    from public.member_ids
   where owner_user_id = v_uid and id_type = 'main' and status = 'active'
   for update;
  if v_member_id is null then
    raise exception 'An active Main ID is required to request package activation';
  end if;

  select * into v_package from public.packages
   where id = p_package_id and is_active = true for share;
  if not found then raise exception 'This package is not available'; end if;

  if exists (select 1 from public.package_activations
      where lower(btrim(payment_reference)) = lower(v_reference)) then
    raise exception 'This payment reference has already been submitted';
  end if;

  select coalesce(max(activation_number), 0) + 1 into v_activation_number
    from public.package_activations where member_id = v_member_id;

  insert into public.package_activations
    (member_id, package_id, activation_number, amount_paid, currency,
     bid_wallet_credit, payment_status, activation_status, payment_reference, submitted_at)
  values
    (v_member_id, v_package.id, v_activation_number, v_package.price, v_package.currency,
     v_package.bid_wallet_credit, 'pending', 'pending', v_reference, now())
  returning id into v_activation_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (v_uid, 'package_activation_submitted', 'package_activation', v_activation_id,
    jsonb_build_object('package_id', v_package.id, 'member_id', v_member_id,
      'payment_reference', v_reference, 'amount', v_package.price,
      'bid_wallet_credit', v_package.bid_wallet_credit, 'currency', v_package.currency));

  return jsonb_build_object('success', true, 'activation_id', v_activation_id,
    'activation_number', v_activation_number, 'payment_status', 'pending',
    'activation_status', 'pending');
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_create_duplicate_member_id(p_main_member_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_main public.member_ids%rowtype;
  v_code text;
  v_id uuid;
  v_enabled boolean;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled
  from public.app_settings where setting_key='duplicate_ids_enabled';
  if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled in Platform Settings'; end if;
  select * into v_main from public.member_ids
  where upper(member_code)=upper(trim(p_main_member_code)) and id_type='main' and status='active'
  for update;
  if not found then raise exception 'Active Main ID not found'; end if;
  loop
    v_code := 'BWD' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,9));
    exit when not exists(select 1 from public.member_ids where member_code=v_code);
  end loop;
  insert into public.member_ids(owner_user_id,main_member_id,member_code,id_type,status)
  values(v_main.owner_user_id,v_main.id,v_code,'duplicate','pending')
  returning id into v_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_created','member_ids',v_id,
    jsonb_build_object('member_code',v_code,'main_member_id',v_main.id,'main_member_code',v_main.member_code,'status','pending'));
  return jsonb_build_object('id',v_id,'member_code',v_code,'main_member_code',v_main.member_code,'status','pending');
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_get_feature_settings()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_result jsonb;
begin
  if auth.uid() is null
     or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  select coalesce(jsonb_object_agg(setting_key,setting_value),'{}'::jsonb)
    into v_result
    from public.app_settings
   where setting_key = any(array[
     'registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled',
     'automatic_placement_enabled','package_activations_enabled',
     'referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled',
     'withdrawals_enabled','bidding_enabled','fixed_bid_enabled',
     'winner_selection_configured','winning_payment_enabled',
     'delivery_tracking_enabled','notifications_enabled'
   ]);
  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_get_member_structure()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  with recursive sponsor_tree(member_id, depth, path) as (
    select r.referred_member_id, 1, array[r.referrer_member_id, r.referred_member_id]
    from public.referrals r
    join public.member_ids m on m.id = r.referred_member_id and m.id_type = 'main'
    where exists (
      select 1 from public.member_ids root
      where root.id = r.referrer_member_id and root.id_type = 'main'
        and root.main_member_id is null
    )
    union all
    select r.referred_member_id, st.depth + 1, st.path || r.referred_member_id
    from sponsor_tree st
    join public.referrals r on r.referrer_member_id = st.member_id
    join public.member_ids m on m.id = r.referred_member_id and m.id_type = 'main'
    where st.depth < 20 and not r.referred_member_id = any(st.path)
  ),
  ids as (
    select mi.id, mi.member_code, mi.id_type, mi.status, mi.created_at,
      owner.display_name,
      main.member_code as main_member_code,
      parent.member_code as placement_parent_code,
      mi.placement_position
    from public.member_ids mi
    left join public.profiles owner on owner.id = mi.owner_user_id
    left join public.member_ids main on main.id = coalesce(mi.main_member_id, mi.id)
    left join public.member_ids parent on parent.id = mi.placement_parent_id
  ),
  levels as (
    select depth, count(*)::integer as member_count
    from sponsor_tree group by depth
  )
  select jsonb_build_object(
    'total_ids', (select count(*) from ids),
    'main_ids', (select count(*) from ids where id_type = 'main'),
    'duplicate_ids', (select count(*) from ids where id_type = 'duplicate'),
    'placement_assigned', (select count(*) from ids where placement_parent_code is not null and placement_position is not null),
    'ids', coalesce((select jsonb_agg(to_jsonb(i) order by i.created_at, i.member_code) from ids i), '[]'::jsonb),
    'sponsor_levels', coalesce((select jsonb_agg(jsonb_build_object('level', depth, 'members', member_count) order by depth) from levels), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_get_mlm_overview()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required';
  end if;
  return jsonb_build_object(
    'total_members',(select count(*) from public.member_ids where id_type='main'),
    'active_members',(select count(*) from public.member_ids where id_type='main' and status='active'),
    'direct_relationships',(select count(*) from public.referrals),
    'pending_activations',(select count(*) from public.package_activations where payment_status='pending'),
    'verified_activations',(select count(*) from public.package_activations where payment_status='approved'),
    'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where status='credited'),
    'withdrawal_pending',(select count(*) from public.withdrawal_requests where status='pending'),
    'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',m.member_code,'display_name',coalesce(nullif(p.display_name,''),'Member'),'status',m.status,'created_at',m.created_at,'sponsor_code',s.member_code) order by m.created_at desc),'[]'::jsonb)
      from public.member_ids m join public.profiles p on p.id=m.owner_user_id
      left join public.referrals r on r.referred_member_id=m.id
      left join public.member_ids s on s.id=r.referrer_member_id
      where m.id_type='main' limit 500)
  );
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_get_platform_health()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_tables int; v_rls_enabled int; v_rls_missing int; v_last_audit timestamptz; v_settings int;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 select count(*)::int,count(*) filter(where c.relrowsecurity)::int,count(*) filter(where not c.relrowsecurity)::int
 into v_tables,v_rls_enabled,v_rls_missing
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind='r';
 select max(created_at) into v_last_audit from public.audit_logs;
 select count(*)::int into v_settings from public.app_settings;
 return jsonb_build_object('public_tables',v_tables,'rls_enabled_tables',v_rls_enabled,'tables_without_rls',v_rls_missing,'settings_count',v_settings,'last_audit_at',v_last_audit,'checked_at',now());
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_admin_accounts()
 RETURNS TABLE(user_id uuid, email text, created_at timestamp with time zone, last_sign_in_at timestamp with time zone, app_role text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select u.id,u.email,u.created_at,u.last_sign_in_at,coalesce(u.raw_app_meta_data->>'role','member')
 from auth.users u
 where coalesce(u.raw_app_meta_data->>'role','')='admin'
 and u.deleted_at is null
 order by u.created_at;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_auction_products()
 RETURNS TABLE(product_id uuid, name text, description text, image_path text, category text, status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 return query select p.id,p.name,p.description,p.image_path,p.category,p.status from public.products p order by p.created_at desc;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_list_auctions()
 RETURNS TABLE(auction_id uuid, product_id uuid, title text, description text, image_url text, category text, currency text, starting_price numeric, current_price numeric, minimum_increment numeric, starts_at timestamp with time zone, ends_at timestamp with time zone, status text, product_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 return query select a.id,a.product_id,a.title,a.description,a.image_url,a.category,a.currency::text,a.starting_price,a.current_price,a.minimum_increment,a.starts_at,a.ends_at,a.status,p.name from public.auctions a join public.products p on p.id=a.product_id order by a.created_at desc;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_list_audit_logs(p_limit integer DEFAULT 100)
 RETURNS TABLE(id bigint, actor_user_id uuid, actor_name text, action text, entity_type text, entity_id uuid, details jsonb, created_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required';
 end if;
 return query
 select a.id,a.actor_user_id,coalesce(nullif(p.display_name,''),'System'),a.action,
        a.entity_type,a.entity_id,a.details,a.created_at
 from public.audit_logs a
 left join public.profiles p on p.id=a.actor_user_id
 order by a.created_at desc,a.id desc
 limit greatest(1,least(coalesce(p_limit,100),200));
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_audit_logs_page(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(id bigint, actor_user_id uuid, actor_name text, action text, entity_type text, entity_id uuid, details jsonb, created_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required';
 end if;
 return query
 select a.id,a.actor_user_id,coalesce(nullif(p.display_name,''),'System'),
        a.action,a.entity_type,a.entity_id,a.details,a.created_at
 from public.audit_logs a
 left join public.profiles p on p.id=a.actor_user_id
 order by a.created_at desc,a.id desc
 limit greatest(1,least(coalesce(p_limit,100),200))
 offset greatest(0,coalesce(p_offset,0));
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_delivery_tracking(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(tracking_id uuid, payment_id uuid, member_code text, winner_name text, item_title text, amount numeric, payment_status text, carrier text, tracking_number text, status text, shipped_at timestamp with time zone, delivered_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Invalid pagination values' using errcode='22023'; end if;
 return query
 select d.id,w.id,m.member_code,p.display_name,coalesce(a.title,fc.title),w.amount,w.status,d.carrier,d.tracking_number,d.status,d.shipped_at,d.delivered_at,d.updated_at
 from public.delivery_tracking d join public.winning_item_payments w on w.id=d.winning_item_payment_id
 join public.member_ids m on m.id=w.winner_member_id left join public.profiles p on p.id=m.owner_user_id
 left join public.auctions a on a.id=w.auction_id left join public.fixed_bid_campaigns fc on fc.id=w.fixed_bid_campaign_id
 order by d.updated_at desc,d.id desc limit p_limit offset p_offset;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_list_duplicate_ids()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',d.id,'member_code',d.member_code,'status',d.status,'created_at',d.created_at,
    'main_member_id',m.id,'main_member_code',m.member_code,
    'display_name',p.display_name,'phone',p.phone
  ) order by d.created_at desc),'[]'::jsonb)
  into v_result
  from public.member_ids d
  join public.member_ids m on m.id=d.main_member_id and m.id_type='main'
  left join public.profiles p on p.id=d.owner_user_id
  where d.id_type='duplicate';
  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_fixed_bid_campaigns()
 RETURNS TABLE(campaign_id uuid, product_id uuid, product_name text, title text, description text, status text, configuration jsonb, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 return query select c.id,c.product_id,p.name,c.title,c.description,c.status,c.configuration,c.created_at,c.updated_at
 from public.fixed_bid_campaigns c join public.products p on p.id=c.product_id order by c.created_at desc;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_list_members_sponsors()
 RETURNS TABLE(member_code text, display_name text, phone text, sponsor_code text, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select m.member_code, coalesce(p.display_name,''), coalesce(p.phone,''),
         coalesce(s.member_code,''), m.created_at
  from public.member_ids m
  join public.profiles p on p.id=m.owner_user_id
  left join public.referrals r on r.referred_member_id=m.id
  left join public.member_ids s on s.id=r.referrer_member_id
  where m.id_type='main'
    and auth.uid() is not null
    and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  order by m.created_at desc
  limit 500;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_notification_templates()
 RETURNS TABLE(id uuid, name text, channel text, subject text, body text, is_active boolean, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query select t.id,t.name,t.channel,t.subject,t.body,t.is_active,t.created_at,t.updated_at
 from public.notification_templates t order by t.updated_at desc;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_packages()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'name',p.name,'description',p.description,'price',p.price,
    'currency',p.currency,'bid_wallet_credit',p.bid_wallet_credit,
    'is_active',p.is_active,'created_at',p.created_at,'updated_at',p.updated_at
  ) order by p.created_at desc),'[]'::jsonb)
  into v_result from public.packages p;
  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_pending_activations()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', a.id,
    'activation_number', a.activation_number,
    'member_code', m.member_code,
    'member_name', p.display_name,
    'package_name', pkg.name,
    'amount_paid', a.amount_paid,
    'currency', a.currency,
    'bid_wallet_credit', a.bid_wallet_credit,
    'payment_reference', a.payment_reference,
    'submitted_at', a.submitted_at
  ) order by a.submitted_at), '[]'::jsonb)
  into v_result
  from public.package_activations a
  join public.member_ids m on m.id = a.member_id
  join auth.users u on u.id = m.owner_user_id
  left join public.profiles p on p.id = u.id
  join public.packages pkg on pkg.id = a.package_id
  where a.payment_status = 'pending' and a.activation_status = 'pending';

  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_referral_plans()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_result jsonb;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'package_id',p.id,'package_name',p.name,'package_active',p.is_active,
  'plan_id',v.id,'version_number',v.version_number,'plan_active',v.is_active,
  'rules',coalesce((select jsonb_agg(jsonb_build_object('level',r.level_number,'reward_type',r.reward_type,'reward_value',r.reward_value,'eligibility_rule',r.eligibility_rule) order by r.level_number) from public.referral_level_rules r where r.plan_version_id=v.id),'[]'::jsonb)
 ) order by p.created_at desc,v.version_number desc),'[]'::jsonb)
 into v_result from public.packages p left join public.referral_plan_versions v on v.package_id=p.id;
 return v_result;
end;$function$

CREATE OR REPLACE FUNCTION public.admin_list_wallet_accounts()
 RETURNS TABLE(wallet_account_id uuid, member_id uuid, member_code text, id_type text, display_name text, wallet_type text, balance numeric, currency text, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  return query
  select w.id, w.member_id, m.member_code, m.id_type,
         p.display_name, w.wallet_type, w.balance, w.currency::text, w.updated_at
  from public.wallet_accounts w
  join public.member_ids m on m.id = w.member_id
  left join public.profiles p on p.id = m.owner_user_id
  order by m.member_code, w.wallet_type;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_wallet_accounts(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(wallet_account_id uuid, member_id uuid, member_code text, wallet_type text, balance numeric, currency text, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select wa.id,wa.member_id,mi.member_code,wa.wallet_type,wa.balance,wa.currency,wa.updated_at
 from public.wallet_accounts wa
 join public.member_ids mi on mi.id=wa.member_id
 where mi.id_type='main'
 order by wa.updated_at desc,mi.member_code
 limit greatest(1,least(coalesce(p_limit,100),500))
 offset greatest(coalesce(p_offset,0),0);
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_wallet_transactions(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(transaction_id uuid, member_id uuid, member_code text, wallet_type text, transaction_type text, direction text, amount numeric, balance_after numeric, reference_type text, reference_id uuid, description text, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select wt.id,wt.member_id,mi.member_code,wa.wallet_type,wt.transaction_type,wt.direction,wt.amount,wt.balance_after,wt.reference_type,wt.reference_id,wt.description,wt.created_at
 from public.wallet_transactions wt
 join public.member_ids mi on mi.id=wt.member_id
 left join public.wallet_accounts wa on wa.id=wt.wallet_account_id
 where mi.id_type='main'
 order by wt.created_at desc
 limit greatest(1,least(coalesce(p_limit,100),500))
 offset greatest(coalesce(p_offset,0),0);
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_wallet_transactions(p_wallet_account_id uuid DEFAULT NULL::uuid, p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(transaction_id uuid, wallet_account_id uuid, member_code text, wallet_type text, transaction_type text, direction text, amount numeric, balance_after numeric, description text, reference_type text, reference_id uuid, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 200 or p_offset is null or p_offset < 0 or p_offset > 1000000 then
    raise exception 'Invalid pagination values' using errcode = '22023';
  end if;

  return query
  select t.id, t.wallet_account_id, m.member_code, w.wallet_type,
         t.transaction_type, t.direction, t.amount, t.balance_after,
         t.description, t.reference_type, t.reference_id, t.created_at
  from public.wallet_transactions t
  join public.wallet_accounts w on w.id = t.wallet_account_id
  join public.member_ids m on m.id = t.member_id
  where p_wallet_account_id is null or t.wallet_account_id = p_wallet_account_id
  order by t.created_at desc, t.id desc
  limit p_limit offset p_offset;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_list_winning_item_payments(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(payment_id uuid, winner_member_code text, winner_name text, auction_title text, fixed_bid_title text, amount numeric, status text, paid_at timestamp with time zone, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Invalid pagination values' using errcode='22023'; end if;
 return query
 select w.id,m.member_code,p.display_name,a.title,fc.title,w.amount,w.status,w.paid_at,w.created_at
 from public.winning_item_payments w
 join public.member_ids m on m.id=w.winner_member_id
 left join public.profiles p on p.id=m.owner_user_id
 left join public.auctions a on a.id=w.auction_id
 left join public.fixed_bid_campaigns fc on fc.id=w.fixed_bid_campaign_id
 order by w.created_at desc,w.id desc limit p_limit offset p_offset;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_list_withdrawal_requests(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(request_id uuid, member_code text, display_name text, amount numeric, currency text, status text, payout_details jsonb, requested_at timestamp with time zone, reviewed_at timestamp with time zone, reviewed_by uuid, rejection_reason text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select r.id,m.member_code,p.display_name,r.amount,r.currency::text,r.status,r.payout_details,
        r.requested_at,r.reviewed_at,r.reviewed_by,r.rejection_reason
 from public.withdrawal_requests r
 join public.member_ids m on m.id=r.member_id
 left join public.profiles p on p.id=m.owner_user_id
 order by r.requested_at desc,r.id desc
 limit p_limit offset p_offset;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_review_package_activation(p_activation_id uuid, p_approve boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_activation public.package_activations%rowtype;
  v_member public.member_ids%rowtype;
  v_wallet public.wallet_accounts%rowtype;
  v_new_balance numeric(14,2);
  v_key text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  select * into v_activation from public.package_activations
   where id = p_activation_id for update;
  if not found then raise exception 'Activation request not found'; end if;
  if v_activation.payment_status <> 'pending' or v_activation.activation_status <> 'pending' then
    raise exception 'This activation request has already been reviewed';
  end if;

  select * into v_member from public.member_ids
   where id = v_activation.member_id for update;
  if not found or v_member.id_type <> 'main' then
    raise exception 'Activation must belong to a Main ID';
  end if;

  if p_approve then
    select * into v_wallet from public.wallet_accounts
     where member_id = v_member.id and wallet_type = 'bid' for update;
    if not found then raise exception 'Bid Wallet is unavailable'; end if;

    v_new_balance := v_wallet.balance + v_activation.bid_wallet_credit;
    if v_activation.bid_wallet_credit > 0 then
      update public.wallet_accounts set balance = v_new_balance, updated_at = now()
       where id = v_wallet.id;
      v_key := 'package-activation:' || v_activation.id::text || ':bid-credit';
      insert into public.wallet_transactions
        (wallet_account_id, member_id, transaction_type, direction, amount,
         balance_after, reference_type, reference_id, idempotency_key, description)
      values
        (v_wallet.id, v_member.id, 'package_activation_credit', 'credit',
         v_activation.bid_wallet_credit, v_new_balance, 'package_activation',
         v_activation.id, v_key, 'Verified package activation Bid Wallet credit');
    end if;

    update public.package_activations
       set payment_status = 'approved', activation_status = 'active',
           verified_at = now(), verified_by = v_uid
     where id = v_activation.id;

    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
    values (v_uid, 'package_activation_approved', 'package_activation', v_activation.id,
      jsonb_build_object('member_id', v_member.id, 'bid_wallet_credit',
        v_activation.bid_wallet_credit, 'wallet_balance_after', v_new_balance));
    return jsonb_build_object('success', true, 'status', 'approved',
      'bid_wallet_credit', v_activation.bid_wallet_credit,
      'wallet_balance', v_new_balance);
  else
    update public.package_activations
       set payment_status = 'rejected', activation_status = 'rejected',
           verified_at = now(), verified_by = v_uid
     where id = v_activation.id;
    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
    values (v_uid, 'package_activation_rejected', 'package_activation', v_activation.id,
      jsonb_build_object('member_id', v_member.id, 'payment_reference', v_activation.payment_reference));
    return jsonb_build_object('success', true, 'status', 'rejected');
  end if;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_save_auction_draft(p_auction_id uuid, p_product_id uuid, p_title text, p_description text, p_image_url text, p_category text, p_starting_price numeric, p_minimum_increment numeric, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_product_id is null or not exists(select 1 from public.products where id=p_product_id and status='draft') then raise exception 'Select a draft product' using errcode='22023'; end if;
 if length(trim(coalesce(p_title,'')))<3 or length(trim(p_title))>180 then raise exception 'Auction title must be 3 to 180 characters' using errcode='22023'; end if;
 if coalesce(p_starting_price,-1)<0 or coalesce(p_minimum_increment,0)<=0 then raise exception 'Invalid starting price or bid increment' using errcode='22023'; end if;
 if p_starts_at is not null and p_ends_at is not null and p_ends_at<=p_starts_at then raise exception 'End time must be after start time' using errcode='22023'; end if;
 if p_auction_id is null then
  insert into public.auctions(product_id,title,description,image_url,category,currency,starting_price,current_price,minimum_increment,starts_at,ends_at,status)
  values(p_product_id,trim(p_title),nullif(trim(coalesce(p_description,'')),''),nullif(trim(coalesce(p_image_url,'')),''),nullif(trim(coalesce(p_category,'')),''),'INR',p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,p_ends_at,'draft') returning id into v_id;
 else
  update public.auctions set product_id=p_product_id,title=trim(p_title),description=nullif(trim(coalesce(p_description,'')),''),image_url=nullif(trim(coalesce(p_image_url,'')),''),category=nullif(trim(coalesce(p_category,'')),''),starting_price=p_starting_price,current_price=p_starting_price,minimum_increment=p_minimum_increment,starts_at=p_starts_at,ends_at=p_ends_at,updated_at=now()
  where id=p_auction_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'Only existing draft auctions can be edited' using errcode='22023'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(auth.uid(),case when p_auction_id is null then 'auction.draft_created' else 'auction.draft_updated' end,'auction',v_id,jsonb_build_object('title',trim(p_title),'status','draft'));
 return v_id;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_save_delivery_tracking(p_tracking_id uuid, p_payment_id uuid, p_carrier text, p_tracking_number text, p_status text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid; v_old_status text;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_status not in ('pending','packed','shipped','in_transit','delivered','returned') then raise exception 'Invalid delivery status' using errcode='22023'; end if;
 if length(coalesce(p_carrier,''))>120 or length(coalesce(p_tracking_number,''))>180 then raise exception 'Carrier or tracking number is too long' using errcode='22023'; end if;
 if p_tracking_id is null then
  if p_payment_id is null or not exists(select 1 from public.winning_item_payments where id=p_payment_id and status='paid') then raise exception 'Delivery can only be created for a verified paid winning-item payment' using errcode='22023'; end if;
  if exists(select 1 from public.delivery_tracking where winning_item_payment_id=p_payment_id) then raise exception 'Delivery tracking already exists for this payment' using errcode='23505'; end if;
  insert into public.delivery_tracking(winning_item_payment_id,carrier,tracking_number,status,shipped_at,delivered_at)
  values(p_payment_id,nullif(trim(coalesce(p_carrier,'')),''),nullif(trim(coalesce(p_tracking_number,'')),''),p_status,case when p_status in ('shipped','in_transit','delivered') then now() else null end,case when p_status='delivered' then now() else null end) returning id into v_id;
 else
  select d.status into v_old_status from public.delivery_tracking d join public.winning_item_payments w on w.id=d.winning_item_payment_id where d.id=p_tracking_id and w.status='paid' for update of d;
  if not found then raise exception 'Tracking record not found or payment is not verified paid' using errcode='22023'; end if;
  update public.delivery_tracking set carrier=nullif(trim(coalesce(p_carrier,'')),''),tracking_number=nullif(trim(coalesce(p_tracking_number,'')),''),status=p_status,
   shipped_at=case when p_status in ('shipped','in_transit','delivered') then coalesce(shipped_at,now()) else shipped_at end,
   delivered_at=case when p_status='delivered' then coalesce(delivered_at,now()) else null end,updated_at=now()
  where id=p_tracking_id returning id into v_id;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(auth.uid(),'delivery.tracking_saved','delivery_tracking',v_id,jsonb_build_object('status',p_status,'carrier',nullif(trim(coalesce(p_carrier,'')),''),'tracking_number',nullif(trim(coalesce(p_tracking_number,'')),'')));
 return v_id;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_save_fixed_bid_campaign_draft(p_campaign_id uuid, p_product_id uuid, p_title text, p_description text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_product_id is null or not exists(select 1 from public.products where id=p_product_id and status='draft') then raise exception 'Select a draft product' using errcode='22023'; end if;
 if length(trim(coalesce(p_title,'')))<3 or length(trim(p_title))>180 then raise exception 'Campaign title must be 3 to 180 characters' using errcode='22023'; end if;
 if length(coalesce(p_description,''))>5000 then raise exception 'Description is too long' using errcode='22023'; end if;
 if p_campaign_id is null then
  insert into public.fixed_bid_campaigns(product_id,title,description,status,configuration)
  values(p_product_id,trim(p_title),nullif(trim(coalesce(p_description,'')),''),'draft','{}'::jsonb) returning id into v_id;
 else
  update public.fixed_bid_campaigns set product_id=p_product_id,title=trim(p_title),description=nullif(trim(coalesce(p_description,'')),''),updated_at=now()
  where id=p_campaign_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'Only existing draft campaigns can be edited' using errcode='22023'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_campaign_id is null then 'fixed_bid_campaign.draft_created' else 'fixed_bid_campaign.draft_updated' end,'fixed_bid_campaign',v_id,jsonb_build_object('title',trim(p_title),'status','draft'));
 return v_id;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_save_notification_template(p_id uuid, p_name text, p_channel text, p_subject text, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 if length(btrim(coalesce(p_name,''))) not between 2 and 100
  or p_channel not in ('in_app','email','sms')
  or length(btrim(coalesce(p_body,''))) not between 1 and 5000
  or (p_channel='email' and length(btrim(coalesce(p_subject,''))) not between 1 and 160)
 then raise exception 'Invalid notification template details'; end if;
 if p_id is null then
  insert into public.notification_templates(name,channel,subject,body,is_active,created_by)
  values(btrim(p_name),p_channel,case when p_channel='email' then btrim(p_subject) else null end,btrim(p_body),false,auth.uid())
  returning id into v_id;
 else
  update public.notification_templates t set name=btrim(p_name),channel=p_channel,
   subject=case when p_channel='email' then btrim(p_subject) else null end,
   body=btrim(p_body),updated_at=now()
  where t.id=p_id returning t.id into v_id;
  if v_id is null then raise exception 'Template not found'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_id is null then 'notification_template_created' else 'notification_template_updated' end,'notification_template',v_id,
 jsonb_build_object('name',btrim(p_name),'channel',p_channel,'is_active',false));
 return v_id;
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_save_package_draft(p_package_id uuid, p_name text, p_description text, p_price numeric, p_bid_wallet_credit numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid := auth.uid(); v_id uuid; v_old public.packages%rowtype;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  if p_name is null or length(trim(p_name)) < 3 or length(trim(p_name)) > 120 then
    raise exception 'Package name must contain 3 to 120 characters';
  end if;
  if p_price is null or p_price <= 0 or p_price > 10000000 then
    raise exception 'Package price must be greater than zero and within the allowed limit';
  end if;
  if p_bid_wallet_credit is null or p_bid_wallet_credit < 0 or p_bid_wallet_credit > 10000000 then
    raise exception 'Bid Wallet credit must be zero or greater and within the allowed limit';
  end if;
  if p_package_id is null then
    insert into public.packages(name,description,price,currency,bid_wallet_credit,is_active)
    values(trim(p_name),nullif(trim(coalesce(p_description,'')),''),p_price,'INR',p_bid_wallet_credit,false)
    returning id into v_id;
    insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
    values(v_uid,'package_draft_created','packages',v_id,jsonb_build_object('name',trim(p_name),'price',p_price,'bid_wallet_credit',p_bid_wallet_credit,'is_active',false));
  else
    select * into v_old from public.packages where id=p_package_id for update;
    if not found then raise exception 'Package not found'; end if;
    if v_old.is_active then raise exception 'Active packages cannot be edited through the draft editor'; end if;
    update public.packages set name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),price=p_price,bid_wallet_credit=p_bid_wallet_credit,updated_at=now()
    where id=p_package_id returning id into v_id;
    insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
    values(v_uid,'package_draft_updated','packages',v_id,jsonb_build_object('old_price',v_old.price,'new_price',p_price,'old_bid_wallet_credit',v_old.bid_wallet_credit,'new_bid_wallet_credit',p_bid_wallet_credit));
  end if;
  return (select jsonb_build_object('id',p.id,'name',p.name,'description',p.description,'price',p.price,'currency',p.currency,'bid_wallet_credit',p.bid_wallet_credit,'is_active',p.is_active) from public.packages p where p.id=v_id);
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_save_product_draft(p_product_id uuid, p_name text, p_description text, p_image_path text, p_category text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if length(trim(coalesce(p_name,'')))<2 or length(trim(p_name))>160 then raise exception 'Product name must be 2 to 160 characters' using errcode='22023'; end if;
 if length(coalesce(p_description,''))>5000 or length(coalesce(p_image_path,''))>2048 or length(coalesce(p_category,''))>100 then raise exception 'Product details exceed allowed length' using errcode='22023'; end if;
 if p_product_id is null then
  insert into public.products(name,description,image_path,category,status) values(trim(p_name),nullif(trim(coalesce(p_description,'')),''),nullif(trim(coalesce(p_image_path,'')),''),nullif(trim(coalesce(p_category,'')),''),'draft') returning id into v_id;
 else
  update public.products set name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),image_path=nullif(trim(coalesce(p_image_path,'')),''),category=nullif(trim(coalesce(p_category,'')),''),status='draft',updated_at=now() where id=p_product_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'Only existing draft products can be edited' using errcode='22023'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(auth.uid(),case when p_product_id is null then 'product.draft_created' else 'product.draft_updated' end,'product',v_id,jsonb_build_object('name',trim(p_name)));
 return v_id;
end; $function$

CREATE OR REPLACE FUNCTION public.admin_save_referral_plan_draft(p_package_id uuid, p_rules jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_version integer; v_plan_id uuid; v_package public.packages%rowtype; v_rule jsonb; v_level integer; v_type text; v_value numeric;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required'; end if;
 select * into v_package from public.packages where id=p_package_id for update;
 if not found then raise exception 'Package not found'; end if;
 if v_package.is_active then raise exception 'Referral plan drafts can only be changed for inactive packages'; end if;
 if jsonb_typeof(p_rules)<>'array' or jsonb_array_length(p_rules)<>5 then raise exception 'Exactly five level rules are required'; end if;
 select coalesce(max(version_number),0)+1 into v_version from public.referral_plan_versions where package_id=p_package_id;
 insert into public.referral_plan_versions(package_id,version_number,is_active,created_by) values(p_package_id,v_version,false,v_uid) returning id into v_plan_id;
 for v_rule in select value from jsonb_array_elements(p_rules) loop
  v_level:=(v_rule->>'level')::integer; v_type:=v_rule->>'reward_type'; v_value:=(v_rule->>'reward_value')::numeric;
  if v_level not between 1 and 5 or v_type not in ('fixed','percentage') or v_value<=0 or v_value>100000 then raise exception 'Invalid level rule'; end if;
  if exists(select 1 from public.referral_level_rules where plan_version_id=v_plan_id and level_number=v_level) then raise exception 'Duplicate level'; end if;
  insert into public.referral_level_rules(plan_version_id,level_number,reward_type,reward_value,eligibility_rule)
  values(v_plan_id,v_level,v_type,v_value,jsonb_build_object('requires_active_main_id',true,'max_depth',5));
 end loop;
 if (select count(*) from public.referral_level_rules where plan_version_id=v_plan_id)<>5 then raise exception 'All five levels must be provided'; end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'referral_plan_draft_created','referral_plan_versions',v_plan_id,jsonb_build_object('package_id',p_package_id,'version_number',v_version,'rules',p_rules));
 return jsonb_build_object('plan_id',v_plan_id,'version_number',v_version,'is_active',false);
end;$function$

CREATE OR REPLACE FUNCTION public.admin_set_default_sponsor(p_member_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid := auth.uid(); v_member_id uuid; v_code text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select id, member_code into v_member_id, v_code
  from public.member_ids
  where upper(member_code)=upper(trim(p_member_code))
    and id_type='main' and status='active';
  if v_member_id is null then raise exception 'Active Main Sponsor ID not found'; end if;
  insert into public.app_settings(setting_key,setting_value,updated_at)
  values ('default_sponsor_member_id',to_jsonb(v_member_id::text),now())
  on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'default_sponsor_changed','app_settings',v_member_id,jsonb_build_object('member_code',v_code));
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_set_duplicate_id_status(p_duplicate_id uuid, p_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_row public.member_ids%rowtype;
  v_old_status text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  if p_status is null or p_status not in ('active','suspended','closed') then
    raise exception 'Status must be active, suspended or closed';
  end if;
  select * into v_row from public.member_ids
  where id=p_duplicate_id and id_type='duplicate'
  for update;
  if not found then raise exception 'Duplicate ID not found'; end if;
  if v_row.status='closed' and p_status<>'closed' then
    raise exception 'Closed Duplicate IDs cannot be reactivated; create a new Duplicate ID instead';
  end if;
  v_old_status:=v_row.status;
  update public.member_ids set status=p_status where id=p_duplicate_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_status_changed','member_ids',p_duplicate_id,
    jsonb_build_object('member_code',v_row.member_code,'main_member_id',v_row.main_member_id,'old_status',v_old_status,'new_status',p_status));
  return jsonb_build_object('id',p_duplicate_id,'member_code',v_row.member_code,'old_status',v_old_status,'status',p_status);
end;
$function$

CREATE OR REPLACE FUNCTION public.admin_set_feature_setting(p_setting_key text, p_enabled boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_enabled_keys text[]:=array['registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled','package_activations_enabled','bid_wallet_enabled','income_wallet_enabled','delivery_tracking_enabled'];
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_enabled is null then raise exception 'A true/false value is required'; end if;
 if p_setting_key is null or p_setting_key<>all(array['registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled','automatic_placement_enabled','package_activations_enabled','referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled','winner_selection_configured','winning_payment_enabled','delivery_tracking_enabled','notifications_enabled']) then raise exception 'Unsupported feature setting' using errcode='22023'; end if;
 if p_enabled and not (p_setting_key=any(v_enabled_keys)) then raise exception 'Cannot enable % yet: its complete backend workflow and verification are not implemented. It remains safely disabled.',p_setting_key using errcode='55000'; end if;
 insert into public.app_settings(setting_key,setting_value,updated_at) values(p_setting_key,to_jsonb(p_enabled),now()) on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
 insert into public.audit_logs(actor_user_id,action,entity_type,details) values(v_uid,'feature_setting_changed','app_settings',jsonb_build_object('setting_key',p_setting_key,'enabled',p_enabled));
 return jsonb_build_object('success',true,'setting_key',p_setting_key,'enabled',p_enabled);
end; $function$

CREATE OR REPLACE FUNCTION public.admin_set_member_sponsor(p_member_code text, p_sponsor_code text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_sponsor_id uuid;
  v_old_sponsor uuid;
  v_code text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select id into v_member_id from public.member_ids
   where upper(member_code)=upper(trim(p_member_code)) and id_type='main';
  if v_member_id is null then raise exception 'Member Main ID not found'; end if;
  select id,member_code into v_sponsor_id,v_code from public.member_ids
   where upper(member_code)=upper(trim(p_sponsor_code)) and id_type='main' and status='active';
  if v_sponsor_id is null then raise exception 'Active Sponsor Main ID not found'; end if;
  if v_member_id=v_sponsor_id then raise exception 'A member cannot sponsor themselves'; end if;

  if exists (
    with recursive descendants(member_id,path) as (
      select r.referred_member_id, array[v_member_id,r.referred_member_id]
      from public.referrals r where r.referrer_member_id=v_member_id
      union all
      select r.referred_member_id, d.path || r.referred_member_id
      from descendants d
      join public.referrals r on r.referrer_member_id=d.member_id
      where not r.referred_member_id=any(d.path)
    )
    select 1 from descendants where member_id=v_sponsor_id
  ) then
    raise exception 'The selected sponsor is already in this member downline; circular referral is not allowed';
  end if;

  select referrer_member_id into v_old_sponsor from public.referrals where referred_member_id=v_member_id;
  insert into public.referrals(referred_member_id,referrer_member_id,source_member_id)
  values(v_member_id,v_sponsor_id,v_sponsor_id)
  on conflict(referred_member_id) do update
    set referrer_member_id=excluded.referrer_member_id,source_member_id=excluded.source_member_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'member_sponsor_changed','member_ids',v_member_id,
    jsonb_build_object('old_sponsor_member_id',v_old_sponsor,'new_sponsor_member_id',v_sponsor_id,'new_sponsor_code',v_code));
end;
$function$

CREATE OR REPLACE FUNCTION public.get_my_mlm_dashboard()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_main uuid;
  v_result jsonb;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  select main_member_id into v_main from public.profiles where id=v_uid;
  if v_main is null then raise exception 'Main Member ID is not available'; end if;

  with recursive downline(member_id,parent_id,depth,path) as (
    select r.referred_member_id,r.referrer_member_id,1,array[v_main,r.referred_member_id]
      from public.referrals r
      join public.member_ids m on m.id=r.referred_member_id and m.id_type='main'
     where r.referrer_member_id=v_main
    union all
    select r.referred_member_id,r.referrer_member_id,d.depth+1,d.path||r.referred_member_id
      from downline d
      join public.referrals r on r.referrer_member_id=d.member_id
      join public.member_ids m on m.id=r.referred_member_id and m.id_type='main'
     where d.depth<20 and not r.referred_member_id=any(d.path)
  ),
  member_data as (
    select d.member_id,d.parent_id,d.depth,mi.member_code,
           coalesce(nullif(p.display_name,''),'Member') as display_name,
           mi.status,mi.created_at,
           parent.member_code as sponsor_code
      from downline d
      join public.member_ids mi on mi.id=d.member_id
      join public.profiles p on p.id=mi.owner_user_id
      left join public.member_ids parent on parent.id=d.parent_id
  )
  select jsonb_build_object(
    'main_member_code',(select member_code from public.member_ids where id=v_main),
    'direct_referrals',(select count(*) from member_data where depth=1),
    'total_downline',(select count(*) from member_data),
    'active_members',(select count(*) from member_data where status='active'),
    'active_activations',(select count(*) from public.package_activations pa join public.member_ids mi on mi.id=pa.member_id where mi.id=v_main and pa.payment_status='approved' and pa.activation_status='active'),
    'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where credited_main_member_id=v_main and status='credited'),
    'bid_wallet',(select coalesce(balance,0) from public.wallet_accounts where member_id=v_main and wallet_type='bid'),
    'income_wallet',(select coalesce(balance,0) from public.wallet_accounts where member_id=v_main and wallet_type='income'),
    'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',member_code,'display_name',display_name,'status',status,'created_at',created_at,'depth',depth,'sponsor_code',sponsor_code) order by depth,created_at),'[]'::jsonb) from member_data)
  ) into v_result;
  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.get_my_placement_tree()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid := auth.uid();
  v_main uuid;
  v_result jsonb;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  select p.main_member_id into v_main
  from public.profiles p where p.id = v_uid;
  if v_main is null then raise exception 'Main Member ID is not available'; end if;

  with recursive placement(member_id, parent_id, depth, path) as (
    select mi.id, mi.placement_parent_id, 0, array[mi.id]
    from public.member_ids mi
    where mi.id = v_main and mi.id_type = 'main'
    union all
    select child.id, child.placement_parent_id, parent.depth + 1, parent.path || child.id
    from placement parent
    join public.member_ids child on child.placement_parent_id = parent.member_id
    where child.id_type = 'main'
      and parent.depth < 20
      and not child.id = any(parent.path)
  )
  select jsonb_build_object(
    'root_member_code', (select member_code from public.member_ids where id = v_main),
    'tree', coalesce((
      select jsonb_agg(jsonb_build_object(
        'member_code', mi.member_code,
        'display_name', coalesce(nullif(p.display_name, ''), 'Member'),
        'status', mi.status,
        'depth', pl.depth,
        'placement_position', mi.placement_position,
        'created_at', mi.created_at
      ) order by pl.depth, mi.placement_position nulls last, mi.created_at)
      from placement pl
      join public.member_ids mi on mi.id = pl.member_id
      join public.profiles p on p.id = mi.owner_user_id
    ), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$function$

CREATE OR REPLACE FUNCTION public.lookup_sponsor(p_member_code text)
 RETURNS TABLE(member_code text, display_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select m.member_code, coalesce(nullif(p.display_name,''), m.member_code)
  from public.member_ids m
  join public.profiles p on p.id = m.owner_user_id
  where upper(m.member_code) = upper(trim(p_member_code))
    and m.id_type = 'main' and m.status = 'active'
  limit 1;
$function$

CREATE OR REPLACE FUNCTION public.member_create_withdrawal_request(p_amount numeric, p_payout_details jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_member uuid; v_balance numeric; v_id uuid;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then raise exception 'Enter a valid withdrawal amount'; end if;
 if p_payout_details is null or jsonb_typeof(p_payout_details)<>'object' or length(p_payout_details::text)>2000 then raise exception 'Valid payout details are required'; end if;
 if coalesce((select (setting_value#>>'{}')::boolean from public.app_settings where setting_key='withdrawals_enabled'),false) is not true then raise exception 'Withdrawals are currently disabled' using errcode='55000'; end if;
 select main_member_id into v_member from public.profiles where id=v_uid;
 if v_member is null then raise exception 'Main Member ID is required'; end if;
 select balance into v_balance from public.wallet_accounts where member_id=v_member and wallet_type='income' for update;
 if v_balance is null or v_balance<p_amount then raise exception 'Insufficient Income Wallet balance'; end if;
 if exists(select 1 from public.withdrawal_requests where member_id=v_member and status in ('pending','approved','processing')) then raise exception 'An open withdrawal request already exists'; end if;
 insert into public.withdrawal_requests(member_id,amount,currency,status,payout_details) values(v_member,p_amount,'INR','pending',p_payout_details) returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(v_uid,'member_withdrawal_requested','withdrawal_requests',v_id,jsonb_build_object('amount',p_amount));
 return jsonb_build_object('success',true,'request_id',v_id,'status','pending');
end $function$

CREATE OR REPLACE FUNCTION public.member_list_my_withdrawals()
 RETURNS TABLE(request_id uuid, amount numeric, currency character, status text, payout_details jsonb, requested_at timestamp with time zone, reviewed_at timestamp with time zone, rejection_reason text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_uid uuid:=auth.uid(); v_member uuid;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select main_member_id into v_member from public.profiles where id=v_uid;
 if v_member is null then return; end if;
 return query select w.id,w.amount,w.currency,w.status,w.payout_details,w.requested_at,w.reviewed_at,w.rejection_reason from public.withdrawal_requests w where w.member_id=v_member order by w.requested_at desc limit 100;
end $function$

CREATE OR REPLACE FUNCTION public.place_bid(p_auction_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public', 'private'
AS $function$
  select private.place_bid(p_auction_id);
$function$

CREATE OR REPLACE FUNCTION public.submit_package_activation(p_package_id uuid, p_payment_reference text)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select private.submit_package_activation(p_package_id, p_payment_reference);
$function$

-- 7. Trigger definitions (public tables and auth.users app trigger).

CREATE TRIGGER on_biddworld_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION private.handle_new_auth_user();
CREATE TRIGGER enforce_bid_wallet_and_bidding_features BEFORE INSERT ON bids FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_delivery_tracking_feature BEFORE INSERT OR UPDATE ON delivery_tracking FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_fixed_bid_feature BEFORE INSERT OR UPDATE OF status ON fixed_bid_campaigns FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_duplicate_id_feature BEFORE INSERT OR UPDATE OF status, id_type ON member_ids FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_package_activation_feature BEFORE INSERT OR UPDATE OF activation_status ON package_activations FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_referral_commission_feature BEFORE INSERT OR UPDATE OF status ON referral_commissions FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_sponsor_referral_feature BEFORE INSERT OR UPDATE ON referrals FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_package_wallet_credit_feature BEFORE INSERT ON wallet_transactions FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_winning_payment_feature BEFORE INSERT OR UPDATE OF status ON winning_item_payments FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();
CREATE TRIGGER enforce_withdrawal_feature BEFORE INSERT ON withdrawal_requests FOR EACH ROW EXECUTE FUNCTION private.enforce_feature_gate();

-- 8. Schema usage grants and table/sequence/function ACLs.

grant usage on schema public to anon, authenticated, service_role;
revoke all on all tables in schema public from public, anon, authenticated, service_role;
grant SELECT on table public.app_settings to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.app_settings to service_role;
grant SELECT on table public.auctions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.auctions to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.audit_logs to service_role;
grant SELECT on table public.bids to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.bids to service_role;
grant SELECT on table public.delivery_tracking to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.delivery_tracking to service_role;
grant SELECT on table public.fixed_bid_campaigns to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.fixed_bid_campaigns to service_role;
grant SELECT on table public.fixed_bids to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.fixed_bids to service_role;
grant SELECT on table public.member_ids to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.member_ids to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.notification_templates to service_role;
grant SELECT on table public.package_activations to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.package_activations to service_role;
grant SELECT on table public.packages to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.packages to service_role;
grant SELECT on table public.products to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.products to service_role;
grant SELECT on table public.profiles to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.profiles to service_role;
grant SELECT on table public.referral_commissions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.referral_commissions to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.referral_level_rules to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.referral_plan_versions to service_role;
grant SELECT on table public.referrals to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.referrals to service_role;
grant SELECT on table public.wallet_accounts to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.wallet_accounts to service_role;
grant SELECT on table public.wallet_transactions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.wallet_transactions to service_role;
grant SELECT on table public.winning_item_payments to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.winning_item_payments to service_role;
grant SELECT on table public.withdrawal_requests to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on table public.withdrawal_requests to service_role;
grant USAGE on sequence public.audit_logs_id_seq to anon;
grant USAGE on sequence public.audit_logs_id_seq to authenticated;
grant USAGE on sequence public.audit_logs_id_seq to service_role;
grant execute on function public.admin_create_duplicate_member_id(text) to authenticated;
grant execute on function public.admin_create_duplicate_member_id(text) to service_role;
grant execute on function public.admin_get_feature_settings() to authenticated;
grant execute on function public.admin_get_feature_settings() to service_role;
grant execute on function public.admin_get_member_structure() to authenticated;
grant execute on function public.admin_get_member_structure() to service_role;
grant execute on function public.admin_get_mlm_overview() to authenticated;
grant execute on function public.admin_get_mlm_overview() to service_role;
grant execute on function public.admin_get_platform_health() to authenticated;
grant execute on function public.admin_get_platform_health() to service_role;
grant execute on function public.admin_list_admin_accounts() to authenticated;
grant execute on function public.admin_list_admin_accounts() to service_role;
grant execute on function public.admin_list_auction_products() to authenticated;
grant execute on function public.admin_list_auction_products() to service_role;
grant execute on function public.admin_list_auctions() to authenticated;
grant execute on function public.admin_list_auctions() to service_role;
grant execute on function public.admin_list_audit_logs_page(integer,integer) to authenticated;
grant execute on function public.admin_list_audit_logs_page(integer,integer) to service_role;
grant execute on function public.admin_list_audit_logs(integer) to authenticated;
grant execute on function public.admin_list_audit_logs(integer) to service_role;
grant execute on function public.admin_list_delivery_tracking(integer,integer) to authenticated;
grant execute on function public.admin_list_delivery_tracking(integer,integer) to service_role;
grant execute on function public.admin_list_duplicate_ids() to authenticated;
grant execute on function public.admin_list_duplicate_ids() to service_role;
grant execute on function public.admin_list_fixed_bid_campaigns() to authenticated;
grant execute on function public.admin_list_fixed_bid_campaigns() to service_role;
grant execute on function public.admin_list_members_sponsors() to authenticated;
grant execute on function public.admin_list_members_sponsors() to service_role;
grant execute on function public.admin_list_notification_templates() to authenticated;
grant execute on function public.admin_list_notification_templates() to service_role;
grant execute on function public.admin_list_packages() to authenticated;
grant execute on function public.admin_list_packages() to service_role;
grant execute on function public.admin_list_pending_activations() to authenticated;
grant execute on function public.admin_list_pending_activations() to service_role;
grant execute on function public.admin_list_referral_plans() to authenticated;
grant execute on function public.admin_list_referral_plans() to service_role;
grant execute on function public.admin_list_wallet_accounts() to authenticated;
grant execute on function public.admin_list_wallet_accounts() to service_role;
grant execute on function public.admin_list_wallet_accounts(integer,integer) to authenticated;
grant execute on function public.admin_list_wallet_accounts(integer,integer) to service_role;
grant execute on function public.admin_list_wallet_transactions(integer,integer) to authenticated;
grant execute on function public.admin_list_wallet_transactions(integer,integer) to service_role;
grant execute on function public.admin_list_wallet_transactions(uuid,integer,integer) to authenticated;
grant execute on function public.admin_list_wallet_transactions(uuid,integer,integer) to service_role;
grant execute on function public.admin_list_winning_item_payments(integer,integer) to authenticated;
grant execute on function public.admin_list_winning_item_payments(integer,integer) to service_role;
grant execute on function public.admin_list_withdrawal_requests(integer,integer) to authenticated;
grant execute on function public.admin_list_withdrawal_requests(integer,integer) to service_role;
grant execute on function public.admin_review_package_activation(uuid,boolean) to authenticated;
grant execute on function public.admin_review_package_activation(uuid,boolean) to service_role;
grant execute on function public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,timestamp with time zone,timestamp with time zone) to authenticated;
grant execute on function public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,timestamp with time zone,timestamp with time zone) to service_role;
grant execute on function public.admin_save_delivery_tracking(uuid,uuid,text,text,text) to authenticated;
grant execute on function public.admin_save_delivery_tracking(uuid,uuid,text,text,text) to service_role;
grant execute on function public.admin_save_fixed_bid_campaign_draft(uuid,uuid,text,text) to authenticated;
grant execute on function public.admin_save_fixed_bid_campaign_draft(uuid,uuid,text,text) to service_role;
grant execute on function public.admin_save_notification_template(uuid,text,text,text,text) to authenticated;
grant execute on function public.admin_save_notification_template(uuid,text,text,text,text) to service_role;
grant execute on function public.admin_save_package_draft(uuid,text,text,numeric,numeric) to authenticated;
grant execute on function public.admin_save_package_draft(uuid,text,text,numeric,numeric) to service_role;
grant execute on function public.admin_save_product_draft(uuid,text,text,text,text) to authenticated;
grant execute on function public.admin_save_product_draft(uuid,text,text,text,text) to service_role;
grant execute on function public.admin_save_referral_plan_draft(uuid,jsonb) to authenticated;
grant execute on function public.admin_save_referral_plan_draft(uuid,jsonb) to service_role;
grant execute on function public.admin_set_default_sponsor(text) to authenticated;
grant execute on function public.admin_set_default_sponsor(text) to service_role;
grant execute on function public.admin_set_duplicate_id_status(uuid,text) to authenticated;
grant execute on function public.admin_set_duplicate_id_status(uuid,text) to service_role;
grant execute on function public.admin_set_feature_setting(text,boolean) to authenticated;
grant execute on function public.admin_set_feature_setting(text,boolean) to service_role;
grant execute on function public.admin_set_member_sponsor(text,text) to authenticated;
grant execute on function public.admin_set_member_sponsor(text,text) to service_role;
grant execute on function public.get_my_mlm_dashboard() to authenticated;
grant execute on function public.get_my_mlm_dashboard() to service_role;
grant execute on function public.get_my_placement_tree() to authenticated;
grant execute on function public.get_my_placement_tree() to service_role;
grant execute on function public.lookup_sponsor(text) to anon;
grant execute on function public.lookup_sponsor(text) to authenticated;
grant execute on function public.lookup_sponsor(text) to service_role;
grant execute on function public.member_create_withdrawal_request(numeric,jsonb) to authenticated;
grant execute on function public.member_create_withdrawal_request(numeric,jsonb) to service_role;
grant execute on function public.member_list_my_withdrawals() to authenticated;
grant execute on function public.member_list_my_withdrawals() to service_role;
grant execute on function public.place_bid(uuid) to authenticated;
grant execute on function public.place_bid(uuid) to service_role;
grant execute on function private.place_bid(uuid) to service_role;
grant execute on function public.submit_package_activation(uuid,text) to authenticated;
grant execute on function public.submit_package_activation(uuid,text) to service_role;

commit;
