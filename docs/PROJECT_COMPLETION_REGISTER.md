# BiddWorld project completion register

Last source inspection: 2026-11-15  
Repository: `kkjan2006-self/biddworld`  
Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)

This register is an implementation inventory, not a claim of launch readiness. It distinguishes working UI, draft/read-only workflows, missing business logic, and work that depends on owner decisions. Do not enable money movement or alter production data while completing the remaining work.

## Existing application surfaces

| Area | Current implementation | Remaining work |
|---|---|---|
| Public marketplace | Responsive React/Vite shell, live auction listing query, full-text title/category/description search, dynamic category filter, price/ending sort, 9-item client pagination, listing detail modal with image/description/current bid/increment/end/status, contextual empty states | Product catalogue beyond auctions, public informational pages, storage-backed product media upload and server-side pagination for large catalogues |
| Authentication | Supabase email/password signup/signin, phone/name metadata, sponsor lookup, password update, global signout, password reset/recovery, self-only profile editing; registration now provisions an inactive Main ID and profile, and only an Admin-approved package activation changes inactive status to active (migration prepared, not applied) | Apply and review the lifecycle migration only after package economics/legal approval; email verification/resend UX, session expiry/error handling, account lifecycle and privacy consent |
| Member dashboard | Profile self-service editing, read-only account status, Main ID and sponsor identity (member ID, sponsor ID/name and registration date via a self-only RPC), Main/Duplicate ID listing with ownership explanation, package activation history with submitted payment reference, amount, configured Bid Wallet credit, approval/rejection status and verification date, wallets, team genealogy, bids, commissions, withdrawal history with request ID, payout method, review status/date and Admin rejection note plus request-status and loaded-amount summary, security, winner/delivery history with payment and courier-status summary and CSV export | Complete transaction/activity pagination, notification inbox, support/help, richer member settings, accessible/mobile navigation and consistent loading/error/empty states |
| Packages | Active package catalogue and payment-reference submission RPC | Receipt upload/storage and policies, member activation history UX, retry/idempotency UX review, refund/cancellation workflow and owner-approved activation rules |
| Wallet | Bid/Income balances and paginated read-only ledger; server bid RPC exists | Complete secure ledger flows for every permitted transaction, full-history member CSV statement export across paginated records; reconciliation/adjustment controls and audit detail |
| Referrals / MLM | Main-ID genealogy dashboard and summary RPC; admin sponsor correction and plan draft editor | Automatic commission calculation/posting engine, eligibility snapshots, reversal/refund handling, plan activation/version selection, complete team pagination and duplicate attribution rules |
| Duplicate IDs | Admin create pending ID with mandatory Under / Placement ID, preserve Sponsor separately, placement parent saved on the Duplicate ID, Admin queue displays Under ID and owner Main ID; member-owned ID RPC displays Sponsor and Under IDs separately | Placement-tree lineage snapshots for each qualifying package activation, automated placement-based commission attribution and reconciliation for every Admin-configured plan level (no fixed five-level limit), owner-defined limits and placement rules, concurrency-safe placement, lifecycle history; no commission or wallet posting implemented by this placement change |
| Auctions | Admin product/auction draft creation; public live/scheduled listing; bid RPC with wallet-first locking | Product media upload, complete editing/publishing/scheduling/cancel/close flow, anti-sniping/tie/extension rules, bid history; member auction activity now shows bid status counts and related auction start/end schedule and winner selection/settlement |
| Fixed Bid | Campaign read-only listing restricted to published/open statuses; admin campaign draft creation | Owner-defined entry price/charge, entry submission, caps, tie/winner algorithm, cancellation/refunds, settlement and member history with entry-status summary and campaign status/date details |
| Winning items | Member/admin read-only payment registers; delivery tracking save RPC/UI | Winner selection, Income Wallet payment/settlement, payment failure/refund handling, courier update lifecycle, notifications and member support |
| Withdrawals | Member request submission RPC and history; Admin read-only request queue | Owner-defined min/max/fees, approve/reject/review workflow, payout provider/integration, payout reconciliation, failure/refund handling and audit coverage |
| Admin members/sponsors | Member directory with client-side search over the currently loaded 500 Main IDs, CSV export, read-only detail panel (status, sponsor, registration date, placement and linked Duplicate IDs), sponsor changes/default sponsor, structure report | Server-side paginated search, editable member profile/status actions, safe account lifecycle, complete member export |
| Admin packages/payments | Package draft editor; pending activation review UI/RPC | Receipt inspection, complete activation history, reject reasons, refunds, safe publication/retirement and financial reconciliation |
| Admin reports | CSV exports for currently loaded records | Server-side filtered/date-range pagination, complete exports, wallet/commission/duplicate/team reports, printable/PDF reporting |
| Notifications | Inactive templates can be created/edited | Provider integration, recipient targeting, dispatch queue, retries, delivery logs, preferences/consent and opt-out |
| Admin access | Server-side role checks and read-only admin account list | Secure first-admin provisioning procedure and auditable role lifecycle (no client-side role assignment) |
| Settings/system health | Admin feature settings and health display; feature-group headings, labels and descriptions are now consistently English | Finish documented feature-to-backend enforcement mapping, eliminate unsafe switch combinations and document operator procedures |
| Security/operations | RLS-enabled tables, RPC-based privileged writes, audit log UI, security documentation | Complete function/grant/policy review, abuse/rate limiting, monitoring, backup/restore plan, privacy/terms/legal review and incident/support procedures |

## Confirmed high-priority incomplete items

1. **Financial/business rules are not complete.** Referral eligibility and posting timing, duplicate-ID placement, fixed-bid entry/winner rules, auction close/tie/extension rules, winning payment, withdrawal limits and payout process require explicit owner-approved definitions. Do not invent them.
2. **Several modules are intentionally drafts or read-only.** Admin auction/product, Fixed Bid and package editors create drafts; member Fixed Bid, admin withdrawals and winner payment registers are read-only; notification templates do not send messages; admin roles are read-only.
3. **No payment gateway or payout provider is integrated.** Payment reference submission is not a payment gateway. Withdrawal requests are not actual payouts.
4. **Product image handling is incomplete.** Admin product editor currently accepts an image path/URL string; no complete upload/storage workflow is present.
5. **Reporting is partial.** Most exports use only rows currently loaded in the browser; they are not full historical/server-side reports.
6. **Member experience is incomplete.** No dedicated password-reset flow, notification inbox, support workflow or complete profile-edit experience is visible in the current application.
7. **Production database and repository migration history are not reconciled.** Existing production objects must be compared carefully; never replay baseline migrations or blindly mark migrations as applied.

## Safety constraints retained

- Do not delete, overwrite or seed real production member/financial records.
- Do not use real members as test accounts or create real wallet credits, commissions or payouts.
- Keep the Growth Package and referral commissions inactive pending economic/legal review. The current draft has ₹3,000 revenue, ₹3,500 Bid Wallet credit and up to ₹1,000 referral obligations (₹1,500 deficit before costs). A new database trigger guard also blocks package approval/member activation and Bid Wallet package credits until `financial_model_approved=true`; the ordinary Admin feature-switch RPC cannot change this approval key.
- Do not turn on bidding, fixed bids, winner settlement, withdrawals, duplicate IDs or referral commissions as part of feature development.
- Keep Supabase service-role/secret keys out of frontend code.
- Do not purchase domain/hosting or upgrade paid services during development.

## Completion approach

Work through the incomplete items in dependency order: member/public experience and CRUD surfaces; admin operational tooling; non-financial backend workflows; owner-defined financial business rules and secure RPCs; then the final independent verification, testing and deployment phase. Verification/deployment is intentionally deferred until the implementation work is complete, as requested by the project owner.


## Latest implementation note

- Admin Platform Settings feature groups were translated to English to match the required English application UI. This is a presentation-only change; it does not enable any feature, alter financial rules, or change database state.


## Financial safety interlock (2026-11-15)

- Added `20261116000000_financial_approval_guard.sql` on `completion-work`.
- The migration seeds `financial_model_approved=false` without overwriting an existing operator value.
- Database triggers reject package activation approval/member activation and package-activation Bid Wallet credits while the flag is false. The rejection is transaction-atomic, so the Admin review RPC cannot partially approve or credit.
- The approval key is deliberately excluded from ordinary Admin feature toggles; only a trusted owner-approved operator procedure may change it after financial and legal/compliance review.
- Admin payment review now displays the safety lock. This migration has NOT been applied to Production; no Production data was changed.
