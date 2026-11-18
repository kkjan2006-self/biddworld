# Admin report and notification contract reconciliation — 2026-11-18

Branch: `completion-work`
Checkpoint HEAD: `2e9f21ba132575cef8d06a8834543e7762f126c5`

## Auction bid report

Frontend: `src/components/AdminAuctionBidReport.tsx`

- Calls `admin_list_auction_bids_page` with named args `p_search`, `p_status`, `p_from`, `p_to`, `p_limit`, `p_offset`.
- Source definition: `20261118310000_admin_auction_bid_reporting.sql`, signature `(text,uuid,text,timestamptz,timestamptz,integer,integer)`.
- `p_auction_id` is defaulted and may be omitted; supplied argument names and types match.
- Consumed row fields match the SQL projection: bid/auction identifiers and title, currency, Main ID/member name, amount and wallet debits, status, timestamp.
- Frontend page size 100 matches the SQL maximum 100. Export loops through pages and has a one-million offset safety cap.
- The report excludes internal idempotency keys and is Admin-authorized with explicit anon/public revocation and authenticated EXECUTE grant.

## Fixed Bid entry report

Frontend: `src/components/AdminFixedBidEntryReport.tsx`

- Calls `admin_list_fixed_bid_entries_page` with named args `p_search`, `p_status`, `p_from`, `p_to`, `p_limit`, `p_offset`.
- Source definition: `20261118320000_admin_fixed_bid_entry_reporting.sql`, signature `(text,uuid,text,timestamptz,timestamptz,integer,integer)`.
- `p_campaign_id` is defaulted and may be omitted; supplied argument names and types match.
- Consumed row fields match the SQL projection: entry/campaign identifiers and title/status, Main ID/member name, entry amount/status, timestamp.
- Frontend page size 100 matches SQL maximum 100. Export uses bounded pagination.
- The report excludes internal idempotency keys and is Admin-authorized with explicit anon/public revocation and authenticated EXECUTE grant.

## Admin auction and Fixed Bid catalogue exports

- `admin_list_auctions_page(text,text,integer,integer)` and `admin_list_fixed_bid_campaigns_page(text,text,integer,integer)` are defined in `20261118330000_admin_complete_auction_fixed_bid_reports.sql`.
- Admin export callers pass matching search/status/limit/offset named arguments. Both functions bound page size to 100, enforce Admin app_metadata role, use empty search_path, and have explicit grants.
- Existing Admin workspace catalogue loaders use non-paginated legacy list RPCs for the initial management view; complete filtered exports use paginated variants.

## Member notifications and Admin delivery

- Member inbox directly selects `member_notifications` with authenticated user filtering and stable timestamp/ID ordering. Table RLS in `20261116050000_member_notifications.sql` allows members to select only their own rows and Admins to select all rows.
- Member mark-read and mark-all-read actions update only `read_at`, constrained to the authenticated user's own `user_id`. SQL grants UPDATE only on `read_at`; RLS update policy is owner-only. Admin view does not expose mark-read controls, so the owner-only update policy does not conflict with the UI.
- Admin send uses `admin_send_member_notification(uuid,text,text,text,text)` from `20261118180000_notification_delivery_idempotency.sql`; named args match. The function checks Admin app_metadata, validates recipient/content/category/idempotency key, serializes duplicate requests, prevents key reuse with different content, and writes an audit record.
- In-app delivery only. Email/SMS/push are not implemented by this flow. The current Admin recipient field requires an Auth user UUID; a member lookup is a remaining UI improvement, not an RPC contract defect.

## Findings and limits

- No named-argument or consumed result-field mismatch was found in these inspected report and notification paths.
- This is source reconciliation only. It does not prove deployment, clean migration replay, or runtime authorization.
- No tests/build, browser checks, migration replay, or database writes were performed.
