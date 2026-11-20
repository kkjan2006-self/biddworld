# BiddWorld Production ↔ branch migration reconciliation — 2026-11-16

## Read-only snapshot

- Repository branch: `completion-work`
- Repository HEAD at refreshed source inventory: `fdf14664b52bfc2e2f7a762d6e4e956f7e4267ef`
- Source SQL migration files: **43**
- Production Supabase migration ledger rows: **30**
- Exact timestamp-prefix matches: **4** (matching migration filename timestamp only; not proof that SQL content is identical)
- Production migration versions without a same-version source filename: **26**
- This is a reconciliation inventory, not a migration execution plan. Never replay the baseline migrations, fabricate history, reset Production, or apply files by filename order alone.

## Source migration files

1. `supabase/migrations/0001_biddworld.sql`
2. `supabase/migrations/0002_place_bid_rpc.sql`
3. `supabase/migrations/001_initial_schema.sql`
4. `supabase/migrations/20261114161950_secure_bid_rpc_and_signup_provisioning.sql`
5. `supabase/migrations/20261114183412_secure_admin_member_sponsor_directory.sql`
6. `supabase/migrations/20261114183454_prevent_circular_member_sponsor_changes.sql`
7. `supabase/migrations/20261114200000_save_registration_phone.sql`
8. `supabase/migrations/20261114230000_mlm_dashboard_genealogy.sql`
9. `supabase/migrations/20261115000000_admin_member_structure_reports.sql`
10. `supabase/migrations/20261115010000_submit_package_activation_request.sql`
11. `supabase/migrations/20261115020000_admin_package_activation_review.sql`
12. `supabase/migrations/20261115074500_reconcile_mlm_dashboard_statuses.sql`
13. `supabase/migrations/20261115090000_secure_place_bid_wrapper.sql`
14. `supabase/migrations/20261115130000_admin_feature_settings.sql`
15. `supabase/migrations/20261115150000_admin_duplicate_id_lifecycle.sql`
16. `supabase/migrations/20261115154433_enforce_platform_feature_switches.sql`
17. `supabase/migrations/20261115154434_fix_feature_gate_trigger_row_access.sql`
18. `supabase/migrations/20261115154510_extend_wallet_and_sponsor_feature_gates.sql`
19. `supabase/migrations/20261115180000_admin_audit_log_pagination.sql`
20. `supabase/migrations/20261115190000_member_profile_self_service.sql`
21. `supabase/migrations/20261115203000_member_identity_summary.sql`
22. `supabase/migrations/20261115220000_inactive_until_verified_package_activation.sql`
23. `supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql`
24. `supabase/migrations/20261116000000_financial_approval_guard.sql`
25. `supabase/migrations/20261116010000_public_active_product_catalogue.sql`
26. `supabase/migrations/20261116020000_admin_product_management_and_media.sql`
27. `supabase/migrations/20261116030000_admin_configurable_referral_plan_depth.sql`
28. `supabase/migrations/20261116040000_admin_auction_draft_management.sql`
29. `supabase/migrations/20261116041000_member_support_tickets.sql`
30. `supabase/migrations/20261116050000_member_notifications.sql`
31. `supabase/migrations/20261116060000_support_ticket_notifications.sql`
32. `supabase/migrations/20261116070000_delivery_tracking_backend.sql`
33. `supabase/migrations/20261116080000_financial_activity_lockdown.sql`
34. `supabase/migrations/20261116090000_admin_members_sponsors_pagination.sql`
35. `supabase/migrations/20261116100000_member_genealogy_pagination.sql`
36. `supabase/migrations/20261116110000_admin_duplicate_id_pagination.sql`
37. `supabase/migrations/20261116120000_public_product_catalogue_search.sql`
38. `supabase/migrations/20261116130000_restore_admin_report_rpc_authorization.sql`
39. `supabase/migrations/20261116140000_require_active_main_id_for_withdrawals.sql`
40. `supabase/migrations/20261116150000_enforce_inactive_signup_until_verified.sql`
41. `supabase/migrations/20261116160000_minimize_public_sponsor_lookup.sql`
42. `supabase/migrations/20261116170000_minimize_member_withdrawal_payout_data.sql`
43. `supabase/migrations/20261116190000_bid_request_idempotency.sql`

## Production migration ledger (read-only)

| Version | Recorded name | Same-version source filename |
|---|---|---|
| `20261114161950` | `secure_bid_rpc_and_signup_provisioning` | Yes |
| `20261114181107` | `sponsor_referral_validation_and_admin_management` | No |
| `20261114181114` | `admin_member_sponsor_listing` | No |
| `20261114183412` | `secure_admin_member_sponsor_directory` | Yes |
| `20261114183454` | `prevent_circular_member_sponsor_changes` | Yes |
| `20261115142511` | `submit_package_activation_request` | No |
| `20261115142515` | `admin_package_activation_review` | No |
| `20261115142518` | `reconcile_mlm_dashboard_statuses` | No |
| `20261115142520` | `secure_place_bid_wrapper` | No |
| `20261115142524` | `admin_feature_settings` | No |
| `20261115144258` | `admin_duplicate_id_lifecycle` | No |
| `20261115150139` | `admin_package_draft_management` | No |
| `20261115150425` | `admin_referral_plan_draft_management` | No |
| `20261115150819` | `admin_read_only_wallet_management` | No |
| `20261115151223` | `admin_read_only_withdrawal_queue` | No |
| `20261115151455` | `admin_auction_product_draft_management` | No |
| `20261115151930` | `admin_fixed_bid_campaign_draft_management` | No |
| `20261115152119` | `admin_read_only_winning_payment_register` | No |
| `20261115152255` | `admin_delivery_tracking_management` | No |
| `20261115152743` | `admin_read_only_wallet_management` | No |
| `20261115152910` | `admin_notification_template_drafts` | No |
| `20261115153059` | `admin_role_access_read_only` | No |
| `20261115153241` | `admin_platform_health_summary` | No |
| `20261115154433` | `enforce_platform_feature_switches` | Yes |
| `20261115154626` | `fix_feature_gate_trigger_row_access` | No |
| `20261115154727` | `extend_wallet_and_sponsor_feature_gates` | No |
| `20261115160229` | `member_withdrawal_request_and_history` | No |
| `20261115161029` | `member_placement_tree_dashboard` | No |
| `20261115161904` | `allow_members_read_scoped_feature_settings` | No |
| `20261115163218` | `admin_audit_log_pagination` | No |

## Production ledger versions without same-version source files

- `20261114181107` — `sponsor_referral_validation_and_admin_management`
- `20261114181114` — `admin_member_sponsor_listing`
- `20261115142511` — `submit_package_activation_request`
- `20261115142515` — `admin_package_activation_review`
- `20261115142518` — `reconcile_mlm_dashboard_statuses`
- `20261115142520` — `secure_place_bid_wrapper`
- `20261115142524` — `admin_feature_settings`
- `20261115144258` — `admin_duplicate_id_lifecycle`
- `20261115150139` — `admin_package_draft_management`
- `20261115150425` — `admin_referral_plan_draft_management`
- `20261115150819` — `admin_read_only_wallet_management`
- `20261115151223` — `admin_read_only_withdrawal_queue`
- `20261115151455` — `admin_auction_product_draft_management`
- `20261115151930` — `admin_fixed_bid_campaign_draft_management`
- `20261115152119` — `admin_read_only_winning_payment_register`
- `20261115152255` — `admin_delivery_tracking_management`
- `20261115152743` — `admin_read_only_wallet_management`
- `20261115152910` — `admin_notification_template_drafts`
- `20261115153059` — `admin_role_access_read_only`
- `20261115153241` — `admin_platform_health_summary`
- `20261115154626` — `fix_feature_gate_trigger_row_access`
- `20261115154727` — `extend_wallet_and_sponsor_feature_gates`
- `20261115160229` — `member_withdrawal_request_and_history`
- `20261115161029` — `member_placement_tree_dashboard`
- `20261115161904` — `allow_members_read_scoped_feature_settings`
- `20261115163218` — `admin_audit_log_pagination`

## Reconciliation risks and required method

1. Many Production ledger versions use different timestamps from the branch source files even where the migration names are semantically similar. Similar names do not prove identical SQL or safe equivalence.
2. Production includes two migration versions `20261114181107` and `20261114181114` for which this branch has no exact source file. Recover the authoritative applied SQL or reconstruct from live object definitions and independent review; do not invent migration history.
3. Source-only 2026-11-16 migrations include financial approval/ledger interlocks, withdrawal ownership validation, signup inactive-until-verified, sponsor lookup data minimization, payout data minimization, Duplicate ID placement attribution and pagination. These are not present as same-version entries in Production.
4. Before any rollout: obtain a complete live schema/function/trigger/policy/grant snapshot; map each Production ledger row to authoritative SQL; compare every object; create a forward-only ordered reconciliation plan; replay in a disposable non-Production database; test rollback/idempotency/concurrency/RLS; obtain explicit owner approval.
5. Production has not been modified by this audit. No migrations, SQL writes, settings changes, row changes, wallet operations or Storage operations were performed.

## Critical financial gate

Keep package approval/credits, commissions, wallet ledger writes, auction bids/debits, Fixed Bid participation, withdrawals and winner settlement disabled until the economic/legal model is approved and database-level interlocks are deployed and independently tested. The retained draft economics still indicate ₹3,000 revenue versus ₹3,500 Bid Wallet credit plus up to ₹1,000 referral obligations (₹1,500 deficit before expenses).


## Refreshed branch delta — 2026-11-16

The branch inventory was refreshed at `fdf14664b52bfc2e2f7a762d6e4e956f7e4267ef`. The current tree contains **43** migration files, one more than the earlier 42-file snapshot: `20261116190000_bid_request_idempotency.sql`. The Production ledger snapshot remains the previously observed 30 rows; this branch refresh did not query or modify Production.

The new idempotency migration is source-only until a reviewed forward-only rollout is approved. Its presence does not establish that Production has the corresponding request-idempotency constraint or RPC behavior. The migration filename is not a substitute for checking live constraints, function definitions, grants, and retry semantics.

The earlier 4 exact timestamp-prefix matches and 26 Production versions without same-version source filenames remain historical results from the read-only ledger snapshot. They must be recalculated against a fresh live ledger before any rollout; do not treat this document as a current live database query.
