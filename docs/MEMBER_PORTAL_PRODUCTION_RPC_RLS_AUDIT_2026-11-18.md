# Member Portal Production RPC and RLS audit — 2026-11-18

Branch reviewed: `completion-work` (starting HEAD `fe93d89908bc9623f67882f11c16587a08608ceb`).

## Scope

Inspected direct Supabase calls in:
- `src/components/Account.tsx`
- `src/components/Packages.tsx`
- `src/components/Support.tsx`
- `src/components/Notifications.tsx`
- `src/components/FixedBid.tsx`
- `src/components/Referrals.tsx`
- `src/components/PlacementTree.tsx`
- `src/components/WalletHistory.tsx`
- `src/App.tsx`

Compared selected RPC names and table RLS/policies against Production via read-only PostgreSQL catalogue queries.

## Production RPC presence findings

| Frontend RPC | Production catalogue |
|---|---|
| `get_my_placement_tree()` | Present |
| `lookup_sponsor(text)` | Present |
| `member_create_withdrawal_request(numeric,jsonb)` | Present |
| `member_list_my_withdrawals()` | Present |
| `place_bid(uuid)` | Present |
| `member_get_my_identity()` | Not present |
| `member_list_my_ids()` | Not present |
| `member_pay_winning_item_payment(...)` | Not present |
| `member_update_my_profile(...)` | Not present |
| `member_join_fixed_bid_campaign(...)` | Not present |
| `member_submit_support_ticket(...)` | Not present |
| `admin_update_support_ticket(...)` | Not present |
| `admin_send_member_notification(...)` | Not present |
| `get_my_mlm_dashboard_page(...)` | Not present |
| `public_list_active_products_page(...)` | Not present |
| `submit_package_activation_with_receipt(...)` | Not present |

The absent RPCs are not necessarily absent from the repository source; several are delivered by later source-only migrations. Their absence from Production confirms that current branch frontend functionality is ahead of deployed Production. Do not treat source presence as live availability.

The current frontend calls `place_bid` with an idempotency argument, while Production currently exposes only `place_bid(uuid)`. A compatible source migration exists in the branch; the mismatch remains a deployment prerequisite, not a reason to alter Production now.

## Direct table access and Production RLS

| Table | Present in Production | RLS | Existing policy |
|---|---:|---:|---|
| `profiles` | Yes | Enabled | `profiles_select_own` |
| `app_settings` | Yes | Enabled | `app_settings_read_scoped` |
| `package_activations` | Yes | Enabled | `package_activations_select_own` |
| `wallet_accounts` | Yes | Enabled | `wallet_accounts_select_own` |
| `bids` | Yes | Enabled | `bids_select_own` |
| `fixed_bids` | Yes | Enabled | `fixed_bids_select_own` |
| `referral_commissions` | Yes | Enabled | `referral_commissions_select_own` |
| `winning_item_payments` | Yes | Enabled | `winning_payments_select_own` |
| `delivery_tracking` | Yes | Enabled | `delivery_tracking_select_own` |
| `packages` | Yes | Enabled | `active_packages_read` |
| `wallet_transactions` | Yes | Enabled | `wallet_transactions_select_own` |
| `auctions` | Yes | Enabled | `visible_auctions_read` |
| `fixed_bid_campaigns` | Yes | Enabled | `visible_fixed_campaigns_read` |
| `support_tickets` | Not found | — | — |
| `member_notifications` | Not found | — | — |

All 13 listed existing direct-query tables have RLS enabled and one policy each in the inspected Production catalogue. This inventory does not prove the policies' complete predicates or runtime behavior; those require policy-definition inspection and TEST impersonation tests.

## Next required work

1. Recover full Production policy definitions and column contracts for all directly queried tables.
2. Reconcile each absent RPC with source migration history and the clean-install dependency graph.
3. Verify the idempotent `place_bid` contract in isolated TEST after the baseline is ready.
4. Reconstruct and replay a canonical migration baseline only on TEST.
5. Run authenticated Member and Admin RLS tests only after development is complete.

No tests, build, migration replay, or database writes were performed. Production and TEST remain unchanged.


## Follow-up: exact policy predicates and frontend query alignment

Inspected the exact Production policy predicates for the 13 existing Member-facing tables and traced the corresponding frontend queries. Owner-scoped policies consistently join through `member_ids.owner_user_id = auth.uid()` for wallet, bid, fixed-bid, activation, commission, winning-payment and delivery data. `profiles` is scoped to `auth.uid() = id`. Public catalogue reads are constrained to active packages and visible auction/campaign states.

A concrete settings-read mismatch was found:
- Production `app_settings_read_scoped` allowed members to read only `bidding_enabled`, `fixed_bid_enabled`, `withdrawals_enabled`, `duplicate_ids_enabled`, and `winner_selection_configured` (Admin/Support/Finance retain role-scoped access).
- The current frontend also reads `package_activations_enabled` and `minimum_withdrawal_amount` directly as an authenticated member. Those keys were not in the Production member allow-list, so those reads would be denied by RLS.

Added source-only migration `20261118240000_member_public_feature_settings_read.sql` to extend the existing policy's member-readable allow-list with exactly those two non-sensitive settings while preserving the existing role visibility. This migration has NOT been applied to Production or TEST.

Also reviewed source-only Support and Notification RLS:
- Support ticket SELECT is owner-or-Admin; INSERT is owner-bound; UPDATE is Admin-only.
- Notification SELECT is owner-or-Admin; INSERT is Admin-only; UPDATE is limited to the owner marking their own notification read.
These tables are not present in the current Production catalogue, so these are source definitions, not deployed Production protections.

No test/build or migration replay was run. Policy behavior still requires isolated TEST role/identity tests.


## Current-head source-only delta — 2026-11-19

The following RPCs and return contracts were added or replaced after the 2026-11-18 inventory. These are repository source definitions on `completion-work`; they are not assertions about the current Production or TEST catalogs.

### Admin

| RPC | Current source contract | Source |
|---|---|---|
| `admin_list_product_submissions_page(integer,timestamptz,uuid)` | Pending submissions, stable `created_at,id` keyset, 50-row default, `has_more` | `20261119470000_admin_product_submission_keyset_pagination.sql` |
| `admin_review_product_submission_with_images(uuid,text,text,text[])` | Admin-only approval/rejection; validates and publishes 1–8 public image objects; writes audit row | `20261119480000_product_gallery_publication.sql` |
| `admin_post_matrix_commissions(uuid)` | Posts pending commission rows for one package activation through the wallet ledger | `20261119310000_matrix_commission_engine.sql` |
| `admin_reverse_matrix_commission(uuid,text)` | Reverses a credited commission with a required reason and matching ledger reversal | `20261119310000_matrix_commission_engine.sql` |
| `admin_get_feature_settings()`, `admin_set_feature_setting(text,boolean)` | Consolidated current feature list; Duplicate-ID advisory lock retained; Matrix switch included and server-conditioned; removed email/unused switches | `20261119530000_remove_email_verification_switch.sql` |

### Member and public catalogue

| RPC | Current source contract | Source |
|---|---|---|
| `member_list_own_product_submissions_page(integer,timestamptz,uuid)` | Authenticated owner-only, descending keyset, signed private images generated page-by-page in UI | `20261119490000_member_product_submission_keyset_pagination.sql` |
| `member_list_my_wallet_fund_requests_page(integer,timestamptz,uuid)` | Main-ID-owned Add Money history, descending keyset, bounded pages | `20261119510000_member_wallet_funding_history_pagination.sql` |
| `member_list_my_withdrawals_page(integer,timestamptz,uuid)` | Main-ID-owned withdrawal history, descending keyset, bounded pages | `20261119520000_member_withdrawal_history_pagination.sql` |
| `member_submit_product_listing(text,text,text,text[],jsonb)`, `member_update_product_submission(uuid,text,text,text,text[],jsonb)` | Per-member advisory lock; rejects duplicate pending normalized titles on both create and edit paths | `20261119550000_prevent_duplicate_pending_product_submissions.sql` |
| `submit_package_activation_with_receipt(uuid,text,text)` | Requires an existing private receipt owned by the signed-in user before activation is created | `20261119500000_require_package_activation_receipt.sql` |
| `public_list_active_products_page(text,integer,integer)` | Returns published product details and complete image gallery, including stable `has_more` | `20261119480000_product_gallery_publication.sql` |

### RLS, Storage and client alignment

- The public catalogue function is SECURITY INVOKER. The source migration now grants only the required product columns to `anon` and replaces the published-product read policy with an `anon,authenticated` policy constrained to `status='published'`. The gallery column is granted by the gallery migration. This source policy does not make pending submissions public.
- Member product submission images remain in the private `product-submission-media` bucket. Owner history uses short-lived signed URLs; Admin moderation can read the private objects. Approval copies all images to the public `product-media` bucket. The UI retains uploaded images if the moderation RPC outcome is uncertain.
- Package receipts remain private; the activation RPC verifies the path's first folder is the authenticated user's UID and verifies the object exists.
- The BiddWorld email-verification switch and resend-confirmation UI were removed. The Supabase Auth provider-level Confirm Email setting remains an environment configuration and is not changed by SQL.
- Admin feature switches and the settings RPC response/allowlist were statically compared: all 14 visible switches match the response, allowlist and enabled-key set. Matrix commissions are ready in the UI and remain behind the server-side feature condition.

### Verification boundary

No tests, type-check, build, migration replay, Storage request, role-impersonation test or browser/Android test was run for this delta. All new migrations are registered in the ordered forward manifest. Verify against isolated TEST only after the development-complete gate and explicit migration authorization; Production remains read-only.
