# BiddWorld migration baseline audit — corrected with TEST snapshot

Date: 2026-11-19
Branch: `completion-work`

## Correction to the initial source-only finding

The initial source-only observation that the legacy `0001_biddworld.sql` shape might be the effective database baseline was incomplete. A read-only inspection of the intended TEST Supabase project (`yoaauthwejdgaevfvwpo`) has now established that TEST uses the dedicated clean-install baseline path, not a raw replay beginning at `0001_biddworld.sql`.

TEST migration history reports 89 applied migrations. Its first entry is `20261119062230 biddworld_clean_install_schema_baseline`, followed by the ordered forward migrations, and the latest applied migration is `20261119063113 20261119170000_admin_open_ended_auction_status`.

The live TEST schema confirms the current column model for the core tables:

- `member_ids`: `owner_user_id`, `main_member_id`, `placement_parent_id`, `placement_position`
- `package_activations`: `member_id`, `activation_number`, `amount_paid`, `payment_status`, `activation_status`
- `wallet_accounts`: `member_id`
- `wallet_transactions`: `member_id`, `direction`, `reference_type`, `reference_id`
- `audit_logs`: `actor_user_id`, `details`
- `profiles`: `main_member_id`

Therefore, the earlier statement that the TEST baseline might still be using the legacy schema is **not supported** and is superseded by this read-only evidence. The legacy `0001_biddworld.sql` and `0002_place_bid_rpc.sql` are not the baseline path used by this TEST environment.

## Remaining unapplied branch migrations

The repository's `supabase/clean-install/forward-migrations.txt` already includes the newer migrations. TEST currently stops at `20261119170000_admin_open_ended_auction_status`; the later branch migrations are not yet present in TEST:

- `20261119180000_fix_auction_image_path_regex.sql`
- `20261119190000_wallet_funding_staff_permission.sql`
- `20261119200000_seed_signup_feature_defaults.sql`
- `20261119210000_allow_signup_when_feature_setting_missing.sql`
- `20261119220000_signup_status_and_public_product_select.sql`
- `20261119230000_registration_email_verification_off_by_default.sql`
- `20261119240000_admin_email_verification_feature_setting.sql`
- `20261119250000_enable_in_app_notifications_feature.sql`
- `20261119260000_enable_existing_feature_workflow_switches.sql`
- `20261119270000_block_duplicate_creation_when_disabled.sql`
- `20261119280000_matrix_plan_configuration.sql`
- `20261119300000_automatic_duplicate_matrix_placement.sql`
- `20261119310000_matrix_commission_engine.sql`
- `20261119320000_member_matrix_commission_summary.sql`

The TEST schema currently has no `matrix_plan_versions` or `matrix_commissions` tables, consistent with the Matrix migrations not yet being applied. This is an unapplied-feature state, not evidence of a legacy core-schema mismatch.

## Safe boundary

- This was read-only inspection of TEST migration history and public table metadata. No application/member/financial rows were queried.
- No SQL writes, schema changes, migration applications, tests, builds, type-checks, or browser/mobile QA were performed.
- Production was not queried or modified.
- Do not replay `0001_biddworld.sql` or `0002_place_bid_rpc.sql` on the current TEST environment.
- Keep Matrix feature switches OFF until its migrations are separately reviewed and the final QA phase is authorized.
