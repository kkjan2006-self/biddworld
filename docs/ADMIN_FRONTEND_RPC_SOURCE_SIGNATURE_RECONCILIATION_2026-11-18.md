# Admin frontend RPC/source signature reconciliation — 2026-11-18

## Scope
- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Starting checkpoint recorded in `PROJECT_STATUS.md`: `966d052e2ae64a9f926b2cb5b78a5bebfd5b6bd5`
- Read-only source inspection of `src/components/Admin.tsx`, `src/components/Packages.tsx`, `src/components/FixedBid.tsx`, `src/components/Account.tsx`, the clean-install baseline candidate, and selected forward migrations.
- No SQL was executed; no tests/build were run; Production and TEST were not modified.

## Verified frontend-to-source signatures

The following selected call contracts were compared by RPC name and named argument keys against the source definitions:

| Frontend RPC | Source signature |
|---|---|
| `admin_save_referral_plan_draft` | `(uuid,jsonb)` |
| `admin_list_members_sponsors_page` | `(text,integer,integer)` |
| `admin_list_duplicate_ids_page` | `(text,integer,integer)` |
| `admin_activate_referral_plan` | `(uuid,uuid)` |
| `admin_publish_package` | `(uuid,boolean)` |
| `admin_post_referral_commissions` | `(uuid)` |
| `admin_reverse_referral_commission` | `(uuid,text)` |
| `admin_list_referral_commissions_page` | `(integer,integer,text,integer)` |
| `admin_review_withdrawal_request` | `(uuid,text,text)` |
| `admin_set_auction_status` | `(uuid,text)` |
| `admin_finalize_auction` | `(uuid)` |
| `admin_adjust_member_wallet` | `(text,text,text,numeric,text,text)` |
| `admin_get_minimum_withdrawal_amount` | `()` |
| `admin_set_minimum_withdrawal_amount` | `(numeric)` |
| `admin_set_main_member_status` | `(text,text,text)` |
| `admin_set_user_admin_role` | `(text,boolean,text)` |
| `admin_list_package_activations_page` | `(text,integer,integer)` |
| `admin_save_notification_template` | `(uuid,text,text,text,text)` |
| `admin_list_auctions_page` | `(text,text,integer,integer)` |
| `admin_list_fixed_bid_campaigns_page` | `(text,text,integer,integer)` |
| `admin_draw_fixed_bid_winners` | `(uuid)` |
| `admin_save_fixed_bid_campaign` | `(uuid,uuid,text,text,numeric,numeric,integer,integer,integer,timestamptz,timestamptz,boolean)` |

Also verified the Admin package-review call maps to baseline `admin_review_package_activation(uuid,boolean)`; the member package flow uses `submit_package_activation_with_receipt(uuid,text,text)`; and the Fixed Bid member flow uses `member_join_fixed_bid_campaign(uuid,text)`.

## Findings
- No named-argument/signature mismatch was found in this inspected subset.
- `admin_list_wallet_accounts` intentionally retains a no-argument overload and a paginated `(integer,integer)` overload. The Admin page passes `p_limit` and `p_offset`, selecting the paginated contract.
- `admin_list_wallet_transactions` retains `(integer,integer)` and wallet-specific `(uuid,integer,integer)` overloads. The wallet-specific first argument is required (not defaulted), so the Admin call with only `p_limit`/`p_offset` does not create the suspected named-argument ambiguity.
- Matching signatures do not prove correct result-field mapping, grants, RLS, authorization, or runtime PostgREST resolution. Those remain for later semantic review and final TEST validation.
- This was a partial contract reconciliation, not a complete audit of every frontend RPC call.

## Source evidence inspected
- `src/components/Admin.tsx`
- `src/components/Packages.tsx`
- `src/components/FixedBid.tsx`
- `src/components/Account.tsx`
- `supabase/clean-install/production_schema_baseline_candidate.sql`
- Selected migrations: referral-plan depth, Admin member/duplicate pagination, Fixed Bid campaign lifecycle, referral commission engine, withdrawal review/minimum, auction settlement, wallet adjustment, Main ID lifecycle, Admin role management, package activation reporting, Admin accounts/health, recovered Admin read RPCs, MLM dashboard pagination, auction/fixed-bid reports and secure draw.

## Validation boundary
- Source inspection only. No migration replay, database writes, tests, build, browser checks, or CI rerun.
- Production remains read-only; TEST remains unchanged.
