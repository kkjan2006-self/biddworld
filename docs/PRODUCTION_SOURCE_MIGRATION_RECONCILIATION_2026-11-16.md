# Production ↔ source migration reconciliation

Audit date: 2026-11-16  
Repository branch: `completion-work`  
Audited source HEAD: `5d46bfbd87814c7f3901f0d15d5a474039926dc7`  
Production Supabase project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)

## Executive result

The Production migration ledger contains **30 entries**. The repository currently contains **43 SQL migration files**: 40 timestamped files and 3 legacy/unversioned baseline files.

The lists do not form a safe, directly replayable migration sequence:

| Classification | Count | Meaning |
|---|---:|---|
| Exact version and name match | 4 | Same timestamp and migration slug in both places |
| Same migration slug, different timestamp | 9 | Likely renamed/retimed history; SQL equivalence has not yet been established |
| Production ledger entry with no same-slug source file | 17 | Applied Production migration has no matching filename in this branch |
| Timestamped source migration absent from Production by version and slug | 27 | Source file is not recorded in the current Production ledger |
| Unversioned source SQL files | 3 | Legacy/baseline files; never replay as migrations without a deliberate rebuild plan |

These categories are filename/ledger comparisons, **not proof that SQL bodies are equivalent or that a source migration is safe to apply**.

## Exact version and name matches (4)

- `20261114161950_secure_bid_rpc_and_signup_provisioning`
- `20261114183412_secure_admin_member_sponsor_directory`
- `20261114183454_prevent_circular_member_sponsor_changes`
- `20261115154433_enforce_platform_feature_switches`

## Same slug, different timestamp (9)

| Production ledger version | Slug | Source filename |
|---|---|---|
| 20261115142511 | submit_package_activation_request | 20261115010000_submit_package_activation_request.sql |
| 20261115142515 | admin_package_activation_review | 20261115020000_admin_package_activation_review.sql |
| 20261115142518 | reconcile_mlm_dashboard_statuses | 20261115074500_reconcile_mlm_dashboard_statuses.sql |
| 20261115142520 | secure_place_bid_wrapper | 20261115090000_secure_place_bid_wrapper.sql |
| 20261115142524 | admin_feature_settings | 20261115130000_admin_feature_settings.sql |
| 20261115144258 | admin_duplicate_id_lifecycle | 20261115150000_admin_duplicate_id_lifecycle.sql |
| 20261115154626 | fix_feature_gate_trigger_row_access | 20261115154434_fix_feature_gate_trigger_row_access.sql |
| 20261115154727 | extend_wallet_and_sponsor_feature_gates | 20261115154510_extend_wallet_and_sponsor_feature_gates.sql |
| 20261115163218 | admin_audit_log_pagination | 20261115180000_admin_audit_log_pagination.sql |

Do not mark these as reconciled until each Production object/function/policy/trigger and the source SQL body are compared.

## Production ledger entries without a same-slug source file (17)

- `20261114181107_sponsor_referral_validation_and_admin_management`
- `20261114181114_admin_member_sponsor_listing`
- `20261115150139_admin_package_draft_management`
- `20261115150425_admin_referral_plan_draft_management`
- `20261115150819_admin_read_only_wallet_management`
- `20261115151223_admin_read_only_withdrawal_queue`
- `20261115151455_admin_auction_product_draft_management`
- `20261115151930_admin_fixed_bid_campaign_draft_management`
- `20261115152119_admin_read_only_winning_payment_register`
- `20261115152255_admin_delivery_tracking_management`
- `20261115152743_admin_read_only_wallet_management`
- `20261115152910_admin_notification_template_drafts`
- `20261115153059_admin_role_access_read_only`
- `20261115153241_admin_platform_health_summary`
- `20261115160229_member_withdrawal_request_and_history`
- `20261115161029_member_placement_tree_dashboard`
- `20261115161904_allow_members_read_scoped_feature_settings`

Some of these capabilities may be represented by other source migrations or later source code. That must be verified from SQL/object definitions; do not recreate or replay them based only on names.

## Timestamped source migrations not represented by Production version or slug (27)

- `20261114200000_save_registration_phone.sql`
- `20261114230000_mlm_dashboard_genealogy.sql`
- `20261115000000_admin_member_structure_reports.sql`
- `20261115190000_member_profile_self_service.sql`
- `20261115203000_member_identity_summary.sql`
- `20261115220000_inactive_until_verified_package_activation.sql`
- `20261115230000_duplicate_under_id_placement_attribution.sql`
- `20261116000000_financial_approval_guard.sql`
- `20261116010000_public_active_product_catalogue.sql`
- `20261116020000_admin_product_management_and_media.sql`
- `20261116030000_admin_configurable_referral_plan_depth.sql`
- `20261116040000_admin_auction_draft_management.sql`
- `20261116041000_member_support_tickets.sql`
- `20261116050000_member_notifications.sql`
- `20261116060000_support_ticket_notifications.sql`
- `20261116070000_delivery_tracking_backend.sql`
- `20261116080000_financial_activity_lockdown.sql`
- `20261116090000_admin_members_sponsors_pagination.sql`
- `20261116100000_member_genealogy_pagination.sql`
- `20261116110000_admin_duplicate_id_pagination.sql`
- `20261116120000_public_product_catalogue_search.sql`
- `20261116130000_restore_admin_report_rpc_authorization.sql`
- `20261116140000_require_active_main_id_for_withdrawals.sql`
- `20261116150000_enforce_inactive_signup_until_verified.sql`
- `20261116160000_minimize_public_sponsor_lookup.sql`
- `20261116170000_minimize_member_withdrawal_payout_data.sql`
- `20261116190000_bid_request_idempotency.sql`

**Important:** “Not represented in the ledger” does not prove every object described by a migration is absent. Inspect the live schema, policies, functions, triggers, grants and settings before proposing any rollout.

## Unversioned source files (3)

- `0001_biddworld.sql`
- `0002_place_bid_rpc.sql`
- `001_initial_schema.sql`

These are legacy/baseline files and must not be replayed against the existing Production database.

## Mandatory reconciliation sequence

1. Preserve the current Production database and migration ledger; keep all queries read-only during this audit.
2. For the 17 Production-only ledger entries, retrieve and compare live function definitions, table changes, policies, triggers, grants and related settings. Recover historical SQL from repository history/backups if available; do not invent original migration bodies.
3. For the 9 retimed migrations, compare source SQL against current Production object definitions and establish whether the timestamp change is only bookkeeping or a material change.
4. For the 27 source-only migrations, classify each as already represented by equivalent live objects, safely pending, obsolete, superseded, or requiring a new reviewed migration.
5. Pay particular attention to financial safeguards. The source financial approval/lockdown migrations are not in the Production ledger. Do not assume their database interlocks protect Production.
6. Produce a reviewed forward-only rollout plan with explicit preconditions, backups, verification queries and rollback/compensation strategy. Never rewrite migration history or blindly apply the source directory.

## Safety status at audit time

- No Production migration was applied and no schema, settings, Auth, Storage, member, wallet, commission, payment, bid, withdrawal or winner data was changed by this reconciliation.
- Keep `fixed_bid_enabled=false` and `winning_payment_enabled=false`.
- Do not enable package activation, referral commissions, wallet credits, bidding, Fixed Bid entries, winner settlement or withdrawals.
- Continue to use the connected Production project only for read-only audit until an explicit, reviewed rollout is approved.


## Live Production security and financial interlock findings — 2026-11-16

### Critical financial activation exposure (do not use package approval)

Read-only inspection of `public.app_settings`, `public.admin_review_package_activation(uuid, boolean)`, and `private.enforce_feature_gate()` found:

- `package_activations_enabled=true` and `bid_wallet_enabled=true` in Production at audit time.
- No `financial_model_approved` setting row exists in Production.
- The live SECURITY DEFINER Admin approval RPC checks the trusted Admin JWT role and, on approval, locks the activation/member/wallet rows, credits the Bid Wallet, inserts a wallet-ledger credit, and changes the activation/payment status to active/approved.
- The live feature-gate trigger checks `package_activations_enabled` for activation insertion/activation and `bid_wallet_enabled` for Bid Wallet ledger writes. Both settings were true at audit time, so these existing checks do not provide the requested financial-owner approval lock.
- The source-only `20261116000000_financial_approval_guard.sql` / `20261116080000_financial_activity_lockdown.sql` is not present in the Production migration ledger. The source UI lock is not a substitute for a database-side Production guard.

**Operational warning:** Do not approve package activations or use the Production Admin package-review action until a reviewed financial interlock is reconciled and installed through an explicitly approved rollout. This audit did not change settings, apply SQL, approve/reject requests, or write wallet/member data. The user has not authorized Production changes, so no attempt was made to switch either feature setting off.

### Other read-only security catalogue observations

- All 21 ordinary tables in the `public` schema have RLS enabled. None of these 21 tables currently has FORCE ROW LEVEL SECURITY enabled.
- `notification_templates` has RLS enabled and zero direct table policies in the inspected catalogue; direct table access therefore remains denied by RLS unless a privileged path is used.
- `fixed_bids` has an owner-scoped SELECT policy only; no INSERT policy was found. Keep Fixed Bid entry submission unavailable.
- Ten feature-gate triggers were found on `bids`, `delivery_tracking`, `fixed_bid_campaigns`, `member_ids`, `package_activations`, `referral_commissions`, `referrals`, `wallet_transactions`, `winning_item_payments`, and `withdrawal_requests`.
- The inspected public Admin RPC signatures deny EXECUTE to `anon`; authenticated execution is granted and the inspected Admin SECURITY DEFINER functions perform trusted `app_metadata.role='admin'` checks. Continue to audit each function body and its grants individually; RLS enabled alone is not proof of complete security.
- Production settings at audit time: `bidding_enabled=false`, `fixed_bid_enabled=false`, `withdrawals_enabled=false`, `winning_payment_enabled=false`, `referral_commissions_enabled=false`, `duplicate_ids_enabled=false`, `winner_selection_configured=false`; `package_activations_enabled=true`, `bid_wallet_enabled=true`, `sponsor_referrals_enabled=true`, `income_wallet_enabled=true`, `registration_enabled=true`. No `financial_model_approved` setting row was returned.

These are point-in-time catalogue observations, not a penetration test or launch certification.
