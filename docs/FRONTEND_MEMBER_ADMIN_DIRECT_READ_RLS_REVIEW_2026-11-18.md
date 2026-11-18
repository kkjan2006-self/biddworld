# Frontend Member/Admin direct-read and RLS review — 2026-11-18

## Scope

Source-reviewed these frontend paths and their corresponding clean-install baseline policies / forward policy migrations:

- `src/App.tsx`: member profile and wallet summary reads; public catalogue reads and sponsor lookup.
- `src/components/Account.tsx`: member identity, IDs, withdrawals, profile changes and winner-payment actions.
- `src/components/Packages.tsx`: package catalogue, package-activation feature switch and activation submission.
- `src/components/WalletHistory.tsx`: member profile lookup and wallet transaction history/export.
- `src/components/Referrals.tsx`, `PlacementTree.tsx`, `FixedBid.tsx`: member graph and Fixed Bid reads/actions.
- `src/components/Notifications.tsx`, `Support.tsx`: owner/Admin inbox reads and audited write paths.
- `src/components/Admin.tsx`, `AdminAuctionBidReport.tsx`, `AdminFixedBidEntryReport.tsx`: Admin dashboard, report and mutation callers.

This is a focused source review, not an exhaustive proof of every table grant or live Production policy.

## Confirmed access boundaries

### Member direct reads

- `profiles_select_own` restricts authenticated profile SELECT to `id = auth.uid()`. App wallet-summary and WalletHistory profile lookups filter to the current authenticated user.
- `wallet_accounts_select_own` and `wallet_transactions_select_own` derive ownership through `member_ids.owner_user_id = auth.uid()`. WalletHistory additionally filters to the Main ID obtained from the caller's own profile. This protects duplicate/Main-ID wallet rows at the policy boundary rather than relying only on client filters.
- `app_settings_read_scoped` exposes only the seven explicitly allowlisted public/member feature switches and minimum-withdrawal setting to authenticated members; Admin/Support/Finance roles retain their scoped access. The Packages component reads only `package_activations_enabled`, which is on that allowlist.
- Package and public catalogue data use bounded public/member RPCs. Member identity, IDs, withdrawals, referral dashboard, placement tree and Fixed Bid campaign data use member-scoped RPCs rather than direct unrestricted table reads.
- Notification reads use direct SELECT under owner/Admin RLS. Single-item and bulk member read-state changes use the existing owner-scoped UPDATE policy; Admin delivery is through the audited idempotent RPC.
- Support ticket reads use owner/Admin RLS; member submission and Admin response/status changes use audited RPCs.

### Admin access and writes

- The inspected Admin dashboard and report components use Admin-authorized RPCs for member, wallet, package, referral, auction, Fixed Bid, delivery, notification, audit and report data.
- Inspected Admin mutations use RPCs; no direct Admin table INSERT/UPDATE/DELETE path was found in the reviewed component call sites.
- The earlier support/notification write restriction candidate #67 closes unused direct authenticated write grants where the UI already relies on audited RPCs.

## Findings

- No additional evidenced direct-read ownership or Admin direct-table-write defect was found in this focused slice.
- Wallet transaction history is paginated at 100 rows and export currently retrieves all matching visible ledger rows in batches of 500 before applying client-side date/type/direction filters. This is functionally consistent with the owner RLS boundary, but large-account export efficiency and server-side filtered export remain an enhancement item, not an authorization defect.
- This review does not establish exact live Production table grants, service_role ACL parity, or effective policies after migration replay. Those remain for the final isolated TEST verification and separately documented ACL reconciliation.

## Verification boundary

Static source and migration-policy inspection only. No tests/build/CI, SQL execution, migration replay, live Supabase reads/writes or database changes. Production `hbqatszyzqobgtauyuzy` remains read-only; TEST `yoaauthwejdgaevfvwpo` remains untouched. Consolidated testing remains deferred until development is 100% complete.
