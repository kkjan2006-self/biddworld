# Admin RPC source reconciliation — 2026-11-18

Branch reviewed: `completion-work`  
Checkpoint HEAD before this audit: `44ead303e45a604a3083398d9ff252411538fbb4`

## Purpose

Compare the Admin frontend's RPC calls with the migration source currently present in this branch. This is a source inventory only; it does not establish that a function is absent from the live Production database or from unrecovered historical migration SQL.

## Confirmed source definitions in reviewed migrations

| RPC | Source file |
|---|---|
| `admin_list_members_sponsors_page(text,integer,integer)` | `20261116090000_admin_members_sponsors_pagination.sql` |
| `admin_get_mlm_overview()` | `20261115020000_admin_package_activation_review.sql`, later authorization correction in `20261116130000_restore_admin_report_rpc_authorization.sql` |
| `admin_get_member_structure()` | `20261115000000_admin_member_structure_reports.sql`, later authorization correction in `20261116130000_restore_admin_report_rpc_authorization.sql` |
| `admin_list_pending_activations()` | `20261115020000_admin_package_activation_review.sql`, receipt-aware replacement in `20261118150000_package_receipt_uploads.sql` |
| `admin_list_audit_logs_page(integer,integer)` | `20261115180000_admin_audit_log_pagination.sql` |
| `admin_get_feature_settings()`, `admin_set_feature_setting(text,boolean)` | `20261115130000_admin_feature_settings.sql`, hardened replacement in `20261116080000_financial_activity_lockdown.sql` |
| `admin_list_duplicate_ids_page(text,integer,integer)` | `20261116110000_admin_duplicate_id_pagination.sql` |
| `admin_list_auction_products()`, `admin_save_product_draft(...)`, `admin_set_product_active(uuid,boolean)` | `20261116020000_admin_product_management_and_media.sql` |
| `admin_list_auctions()`, `admin_save_auction_draft(...)` | `20261116040000_admin_auction_draft_management.sql` |
| `admin_list_delivery_tracking(integer,integer)`, `admin_save_delivery_tracking(...)` | `20261116070000_delivery_tracking_backend.sql` |
| `admin_save_referral_plan_draft(uuid,jsonb)` | `20261116030000_admin_configurable_referral_plan_depth.sql` |
| `admin_list_referral_commissions_page(integer,integer,text,integer)` and commission actions | `20261118090000_package_publication_and_referral_commission_engine.sql` |
| `admin_list_fixed_bid_campaigns()` and Fixed Bid campaign actions | `20261118080000_fixed_bid_campaign_entry_draw_settlement.sql` |
| `admin_review_withdrawal_request(...)` | `20261118100000_admin_withdrawal_review_workflow.sql` |
| `admin_list_package_activations_page(...)` | `20261118190000_package_activation_history_reporting.sql` |
| `admin_list_notification_templates()`, `admin_save_notification_template(...)`, `admin_list_admin_accounts()`, `admin_get_platform_health()` | `20261118210000_admin_templates_accounts_health.sql` |
| `admin_adjust_member_wallet(...)` | `20261118120000_admin_wallet_adjustments.sql` |
| `admin_set_main_member_status(...)` | `20261118140000_admin_main_member_lifecycle.sql` |
| `admin_update_member_profile(...)` | `20261117120000_admin_update_member_profile.sql` |
| `admin_set_member_sponsor(...)` | `20261114183454_prevent_circular_member_sponsor_changes.sql` |
| `admin_create_duplicate_member_id(...)`, `admin_set_duplicate_id_status(...)` | `20261115150000_admin_duplicate_id_lifecycle.sql`, serialized placement/status hardening in later migrations |
| `admin_set_user_admin_role(...)` | `20261118160000_primary_admin_role_management.sql` |
| `admin_get_minimum_withdrawal_amount()`, `admin_set_minimum_withdrawal_amount(numeric)` | `20261118130000_withdrawal_minimum_and_server_validation.sql` |

## Recovered Production definitions

A read-only Production catalogue query retrieved the exact `pg_get_functiondef`, signature, return type, SECURITY DEFINER flag, fixed search_path and ACL for the seven previously unreconciled Admin calls:

- `admin_list_packages()` — returns JSONB package rows.
- `admin_list_referral_plans()` — returns JSONB package/version/rule records.
- `admin_list_withdrawal_requests(integer,integer)` — bounded Admin-only withdrawal report.
- `admin_list_wallet_accounts(integer,integer)` — paginated Main-ID wallet report; the existing no-argument overload was also recovered.
- `admin_list_wallet_transactions(integer,integer)` — paginated Main-ID ledger report; the existing wallet-specific `(uuid,integer,integer)` overload was also recovered.
- `admin_list_winning_item_payments(integer,integer)` — bounded winner-payment report.
- `admin_set_default_sponsor(text)` — validates an active Main ID, stores its ID in `app_settings`, and writes an Admin audit record.

Added `20261118230000_recover_admin_read_rpc_sources.sql` with these recovered definitions, fixed empty search_path, Admin checks and explicit execution grants. Return types and overloads are retained from the Production catalogue. This is source recovery, not deployment: no function was executed or replaced in Production.

The same read-only query confirmed the existing Production `get_my_placement_tree()` definition. Updated `20261118220000_member_placement_tree_rpc.sql` to preserve its exact current traversal contract (Main-ID descendants only, depth cap 20, cycle guard, and the existing JSONB response keys/order) instead of the earlier broader proposed traversal.

## Remaining reconciliation

- These recovered functions were present in Production but their source migration bodies were not located in the previously reviewed migration files. Their exact definitions are now represented in the branch's source migration.
- The full historical migration chain and canonical clean-install baseline remain unreconciled. Do not replay the branch migration directory as-is.
- The two `admin_list_wallet_transactions` overloads include defaults in the recovered Production catalogue. Verify PostgREST overload resolution for the frontend's named `p_limit`/`p_offset` call during TEST contract testing; do not remove an existing overload without a compatibility decision.

## Additional caution

- The repository's `0001_biddworld.sql` is explicitly labelled a fresh-project baseline and its simplified table definitions do not match several later Production-reconciled migrations. It is not safe to use as proof of the current Production schema.
- Do not infer RPC return contracts from TypeScript types alone.
- Recover catalog definitions with the existing read-only `supabase/audit/production_migration_recovery.sql` process, then write additive source migrations against the verified Production schema.
- Keep Production read-only. Do not replay migrations to TEST until the canonical clean-install baseline and dependency order have been established.
- No tests, builds, migration replay, or database writes were performed for this audit.
