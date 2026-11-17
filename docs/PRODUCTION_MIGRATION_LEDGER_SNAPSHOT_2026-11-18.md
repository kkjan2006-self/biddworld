# Production Migration Ledger Snapshot — 2026-11-18

## Scope and safety

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)
- Isolated test project: `BiddWorld-TEST` (`yoaauthwejdgaevfvwpo`)
- Source: Supabase migration catalogue listing, read-only, on 2026-11-18.
- No SQL was executed. No migration was applied, marked applied, or deleted. No project data was read or changed.

## Exact Production ledger

Production reports these 30 applied migration entries, in version order:

| # | Version | Name |
|---:|---|---|
| 1 | 20261114161950 | secure_bid_rpc_and_signup_provisioning |
| 2 | 20261114181107 | sponsor_referral_validation_and_admin_management |
| 3 | 20261114181114 | admin_member_sponsor_listing |
| 4 | 20261114183412 | secure_admin_member_sponsor_directory |
| 5 | 20261114183454 | prevent_circular_member_sponsor_changes |
| 6 | 20261115142511 | submit_package_activation_request |
| 7 | 20261115142515 | admin_package_activation_review |
| 8 | 20261115142518 | reconcile_mlm_dashboard_statuses |
| 9 | 20261115142520 | secure_place_bid_wrapper |
| 10 | 20261115142524 | admin_feature_settings |
| 11 | 20261115144258 | admin_duplicate_id_lifecycle |
| 12 | 20261115150139 | admin_package_draft_management |
| 13 | 20261115150425 | admin_referral_plan_draft_management |
| 14 | 20261115150819 | admin_read_only_wallet_management |
| 15 | 20261115151223 | admin_read_only_withdrawal_queue |
| 16 | 20261115151455 | admin_auction_product_draft_management |
| 17 | 20261115151930 | admin_fixed_bid_campaign_draft_management |
| 18 | 20261115152119 | admin_read_only_winning_payment_register |
| 19 | 20261115152255 | admin_delivery_tracking_management |
| 20 | 20261115152743 | admin_read_only_wallet_management |
| 21 | 20261115152910 | admin_notification_template_drafts |
| 22 | 20261115153059 | admin_role_access_read_only |
| 23 | 20261115153241 | admin_platform_health_summary |
| 24 | 20261115154433 | enforce_platform_feature_switches |
| 25 | 20261115154626 | fix_feature_gate_trigger_row_access |
| 26 | 20261115154727 | extend_wallet_and_sponsor_feature_gates |
| 27 | 20261115160229 | member_withdrawal_request_and_history |
| 28 | 20261115161029 | member_placement_tree_dashboard |
| 29 | 20261115161904 | allow_members_read_scoped_feature_settings |
| 30 | 20261115163218 | admin_audit_log_pagination |

The TEST project reports zero applied migrations.

## Repository comparison

The current `completion-work` migration directory contains 49 SQL files: 46 timestamped and three legacy/unversioned files.

Two Production ledger entries are absent as source files and have no matching GitHub path history in this repository:

- `20261114181107_sponsor_referral_validation_and_admin_management`
- `20261114181114_admin_member_sponsor_listing`

Nine entries have recognizable source filenames but different version timestamps:

- `submit_package_activation_request`
- `admin_package_activation_review`
- `reconcile_mlm_dashboard_statuses`
- `secure_place_bid_wrapper`
- `admin_feature_settings`
- `admin_duplicate_id_lifecycle`
- `fix_feature_gate_trigger_row_access`
- `extend_wallet_and_sponsor_feature_gates`
- `admin_audit_log_pagination`

Four entries match both version and name exactly:

- `20261114161950_secure_bid_rpc_and_signup_provisioning`
- `20261114183412_secure_admin_member_sponsor_directory`
- `20261114183454_prevent_circular_member_sponsor_changes`
- `20261115154433_enforce_platform_feature_switches`

The remaining entries cannot be reconciled from migration names and versions alone. A matching name is not proof that the SQL bodies are identical. The Supabase migration catalogue exposes version/name metadata, not the historical SQL text.

## Engineering decision

1. Do not replay the repository migration directory as-is.
2. Do not use `0001_biddworld.sql` as a baseline; its table/column contract is incompatible with the current Production schema.
3. Do not fabricate the two missing historical migrations from their names.
4. Do not mark ledger versions as applied to make the histories appear aligned.
5. Recover exact historical SQL from a trustworthy source if available; otherwise document the unrecoverable gap and build a separately reviewed clean-install baseline from verified schema/function/policy/trigger/index/grant evidence.
6. Replay only the curated baseline and forward migrations on TEST after it is complete. Keep Production read-only.

## What this snapshot proves — and does not prove

It proves the exact 30 version/name rows currently reported by the Production migration catalogue and the zero-row TEST ledger at the time of inspection. It does not reveal the SQL body of any applied migration, establish that same-named files are equivalent, or certify that the current branch can be replayed from an empty database.
