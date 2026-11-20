# Member, Package and Fixed Bid frontend/RPC contract reconciliation — 2026-11-18

## Scope and safety
- Repository: `kkjan2006-self/biddworld`, branch: `completion-work`.
- Read-only inspection of `src/components/Account.tsx`, `src/components/Packages.tsx`, `src/components/FixedBid.tsx` and the corresponding final migration definitions.
- No application source was changed; no tests/build were run; no SQL was executed. Production and TEST were not modified.

## Contracts checked

| Frontend RPC | SQL definition in final source | Contract result |
|---|---|---|
| `member_get_my_identity()` | `20261115203000_member_identity_summary.sql` | JSON keys `created_at`, `main_member_code`, `sponsor_member_code`, `sponsor_display_name` match Account profile extension fields. |
| `member_update_my_profile(p_display_name,p_phone)` | `20261115190000_member_profile_self_service.sql` | Both named arguments and JSON response keys `display_name`, `phone` match. |
| `member_list_my_ids()` | `20261118200000_member_identity_ids_rpc.sql` | Seven returned columns match the Account `Member` shape, including optional `placement_parent_code`. |
| `member_list_my_withdrawals()` | Clean-install baseline candidate | Returned `request_id`, amount, currency, status, payout details, request/review timestamps and rejection reason match `WithdrawalRow`. |
| `member_create_withdrawal_request(p_amount,p_payout_details)` | `20261118260000_secure_withdrawal_payout_details_validation.sql` (final replacement) | Named arguments match. UI's UPI and Bank Transfer object shapes match the final server allow-list and validation. |
| `member_pay_winning_item_payment(p_payment_id,p_idempotency_key)` | `20261118080000_fixed_bid_campaign_entry_draw_settlement.sql` | Named arguments match; UI relies only on success/error and the RPC returns JSON status. SQL debits Income Wallet only. |
| `public_list_active_packages_page(p_limit,p_offset)` | `20261118300000_public_package_catalogue_page.sql` | All six returned fields match `PackageItem`; page bounds match UI limit 100. |
| `submit_package_activation_with_receipt(p_package_id,p_payment_reference,p_receipt_path)` | `20261118150000_package_receipt_uploads.sql` | Named arguments match; optional receipt path is explicitly supplied as null or member-owned uploaded path. |
| `public_list_fixed_bid_campaigns_page(p_search,p_status,p_limit,p_offset)` | `20261118290000_public_fixed_bid_catalogue_page.sql` | Returned id/title/description/status/created_at/configuration/product match `Campaign` and nested UI fields. UI page size 50 matches SQL maximum. |
| `member_join_fixed_bid_campaign(p_campaign_id,p_idempotency_key)` | `20261118080000_fixed_bid_campaign_entry_draw_settlement.sql` | Named arguments and consumed JSON fields `entry_id`, `entry_amount`, `replayed` match. |
| `member_create_withdrawal_request(p_amount,p_payout_details)` | Final secure validation migration | Final version validates the exact two supported payout methods, rejects unexpected JSON keys, checks active Main ID and Income Wallet balance, and prevents a second open request. |

## Additional semantic observations
- `member_get_my_identity` is bound to `auth.uid()`; it accepts no caller-supplied member identifier.
- `member_list_my_ids` filters by `owner_user_id = auth.uid()`; the final seven-column return shape is the one consumed by Account.
- Fixed Bid public catalogue projects a restricted configuration JSON object; the displayed component consumes only those projected keys. The UI's optional `max_entries_total` and `refund_non_winners` type members are not currently displayed/consumed by this component.
- The member withdrawal request function's final migration is `20261118260000`, not the earlier looser implementation in `20261118130000`. Preserve timestamp order so the strict validation replacement is final.
- Withdrawal request concurrency is serialized by locking the member's Income Wallet row before checking for an existing pending/approved request. The UI also guards same-page duplicate submission.
- The shared winner-payment RPC verifies ownership and records the debit against the Income Wallet; the Account UI's success/error handling is compatible with its JSON result.

## Findings / disposition
- No named-argument mismatch or consumed result-field mismatch was found in this inspected Member/Package/Fixed Bid subset.
- No source correction is justified by this subset; changing code without a demonstrated defect would create unnecessary regression risk.
- This does not prove PostgREST runtime resolution, RLS, grants, trigger execution, Storage delivery, or deployed Production state. Those require the deferred TEST/final validation phase.
- This is a focused source contract review, not a full audit of every Member frontend table select or every RPC in the repository.

## Validation boundary
Source inspection only. No tests, build, browser checks, migration replay, or database writes.
