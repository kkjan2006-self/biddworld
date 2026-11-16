# BiddWorld project completion register

Last source inspection: 2026-11-16  
Repository: `kkjan2006-self/biddworld`  
Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)

This register is an implementation inventory, not a claim of launch readiness. It distinguishes working UI, draft/read-only workflows, missing business logic, and work that depends on owner decisions. Do not enable money movement or alter production data while completing the remaining work.

## Existing application surfaces

| Area | Current implementation | Remaining work |
|---|---|---|
| Public marketplace | Responsive React/Vite shell, live auction listing query with deterministic 100-row server pages and Load More, full-text search over loaded records, dynamic category filter, price/ending sort, 9-item client pagination, listing detail modal; Products tab reads active product catalogue in deterministic 100-row server pages with Load More, loaded-record search and explicit load-error/retry messaging; Admin product drafts, publish/hide RPC source and product-media upload are present | Public informational pages, search across not-yet-loaded pages, Production RPC/Storage migration reconciliation |
| Authentication | Supabase email/password signup/signin, phone/name metadata, sponsor lookup, password update, global signout, password reset/recovery, self-only profile editing; registration now provisions an inactive Main ID and profile, and only an Admin-approved package activation changes inactive status to active (migration prepared, not applied) | Apply and review the lifecycle migration only after package economics/legal approval; email verification/resend UX, session expiry/error handling, account lifecycle and privacy consent |
| Member dashboard | Profile self-service editing with client-side validation matching server constraints and exception-safe save state, read-only identity and sponsor summary, Main/Duplicate ID listing, package activation history, wallets, team genealogy, bids, commissions, withdrawals, security, winner/delivery history; activity panels now use deterministic Load More pagination (50 activation rows and 100 bid/Fixed Bid/commission/winner rows per page); complete personal CSV export fetches all activity pages and linked delivery records | Reconcile missing member identity/profile RPCs with Production; team genealogy pagination, richer profile settings, accessible/mobile navigation and consistent loading/error/empty states |
| Packages | Active package catalogue and payment-reference submission RPC | Receipt upload/storage and policies, member activation history UX, retry/idempotency UX review, refund/cancellation workflow and owner-approved activation rules |
| Wallet | Bid/Income balances, paginated read-only ledger and complete Main-ID wallet statement CSV export; Admin complete wallet-ledger export; no client-side balance writes | Owner-defined financial model, secure server-side ledger flows after approval, reconciliation/adjustment controls and audit detail |
| Referrals / MLM | Main-ID genealogy dashboard and summary RPC; admin sponsor correction and plan draft editor | Automatic commission calculation/posting engine, eligibility snapshots, reversal/refund handling, plan activation/version selection, complete team pagination and duplicate attribution rules |
| Duplicate IDs | Admin create pending ID with mandatory Under / Placement ID, preserve Sponsor separately, placement parent saved on the Duplicate ID, Admin queue displays Under ID and owner Main ID; member-owned ID RPC displays Sponsor and Under IDs separately | Placement-tree lineage snapshots for each qualifying package activation, automated placement-based commission attribution and reconciliation for every Admin-configured plan level (no fixed five-level limit), owner-defined limits and placement rules, concurrency-safe placement, lifecycle history; no commission or wallet posting implemented by this placement change |
| Auctions | Admin product/auction draft creation; public live/scheduled listing; bid RPC with wallet-first locking | Product media upload, complete editing/publishing/scheduling/cancel/close flow, anti-sniping/tie/extension rules, bid history; member auction activity now shows bid status counts and related auction start/end schedule and winner selection/settlement |
| Fixed Bid | Campaign read-only listing restricted to scheduled/live/ended statuses; deterministic 50-row pagination with Load More; admin campaign draft creation/editing | Owner-defined entry price/charge, entry submission, caps, tie/winner algorithm, cancellation/refunds, settlement and member history with entry-status summary and campaign status/date details |
| Winning items | Member/admin read-only payment registers; delivery tracking save RPC/UI | Winner selection, Income Wallet payment/settlement, payment failure/refund handling, courier update lifecycle, notifications and member support |
| Withdrawals | Member request submission RPC and history; Admin read-only request queue | Owner-defined min/max/fees, approve/reject/review workflow, payout provider/integration, payout reconciliation, failure/refund handling and audit coverage |
| Admin members/sponsors | Member directory with Admin-checked 100-row RPC pagination and Load More, client-side search across loaded Main IDs, CSV export, read-only detail panel (status, sponsor, registration date, placement and linked Duplicate IDs), sponsor changes/default sponsor, structure report | Server-side search wiring, full-history filtered export, editable member profile/status actions, safe account lifecycle |
| Admin packages/payments | Package draft editor; pending activation review UI/RPC | Receipt inspection, complete activation history, reject reasons, refunds, safe publication/retirement and financial reconciliation |
| Admin reports | Complete paginated CSV exports for wallet ledger, withdrawals, winning payments, delivery tracking and audit logs; audit export applies active search/date filters; other reports use full-list RPC results where available | Verify server-side limits for members/packages/activation/team/commission reports; add date-range filters and printable/PDF reporting |
| Support | Member support ticket submission/history and Admin queue with status/response updates, owner/Admin RLS, audit logging and 100-row pagination | Email/SMS dispatch, attachment uploads, SLA/assignment workflow and additional abuse/rate controls |
| Notifications | Member in-app inbox with unread state/mark-read and Admin targeted notification creation; 100-row pagination; support ticket status/response changes create owner notifications; templates remain inactive drafts | Provider integration, dispatch queue/retries, delivery logs, preferences/consent and opt-out; no email/SMS/push delivery configured |
| Admin access | Server-side role checks and read-only admin account list | Secure first-admin provisioning procedure and auditable role lifecycle (no client-side role assignment) |
| Settings/system health | Admin feature settings and health display; feature-group headings, labels and descriptions are now consistently English | Finish documented feature-to-backend enforcement mapping, eliminate unsafe switch combinations and document operator procedures |
| Security/operations | 21/21 Production public tables report RLS enabled; authenticated direct table grants on key financial tables are SELECT-only; Admin RPCs use trusted app_metadata role checks; source-only owner approval interlock covers wallet credits, commissions, bids, Fixed Bid entries, withdrawals, package approval and winner settlement | Apply/reconcile the source-only interlock through owner-approved rollout; complete full function/grant/policy/Storage review, abuse/rate limiting, leaked-password protection, monitoring, backup/restore, privacy/legal and incident procedures |

## Confirmed high-priority incomplete items

1. **Financial/business rules are not complete.** Referral eligibility and posting timing, duplicate-ID placement, fixed-bid entry/winner rules, auction close/tie/extension rules, winning payment, withdrawal limits and payout process require explicit owner-approved definitions. Do not invent them.
2. **Several modules are intentionally drafts or read-only.** Admin auction/product, Fixed Bid and package editors create drafts; member Fixed Bid, admin withdrawals and winner payment registers are read-only; notification templates do not send messages; admin roles are read-only.
3. **No payment gateway or payout provider is integrated.** Payment reference submission is not a payment gateway. Withdrawal requests are not actual payouts.
4. **Product image handling is incomplete.** Admin product editor currently accepts an image path/URL string; no complete upload/storage workflow is present.
5. **Reporting is partial.** Wallet ledger, member activity, withdrawals, winning payments, delivery tracking and audit logs now have complete paginated CSV exports; member/team/package/commission reports still need server-side limits and historical export verification.
6. **Member experience is incomplete.** Support and in-app notifications now exist, but provider delivery, preferences/consent, richer profile settings, complete team pagination and full accessible/mobile UX remain outstanding.
7. **Production database and repository migration history are not reconciled.** Existing production objects must be compared carefully; never replay baseline migrations or blindly mark migrations as applied.

## Safety constraints retained

- Do not delete, overwrite or seed real production member/financial records.
- Do not use real members as test accounts or create real wallet credits, commissions or payouts.
- Keep the Growth Package and referral commissions inactive pending economic/legal review. The current draft has ₹3,000 revenue, ₹3,500 Bid Wallet credit and up to ₹1,000 referral obligations (₹1,500 deficit before costs). The owner-approval database interlock is committed in source only and has NOT been applied to Production. Until the owner-approved migration is applied, the Production Admin approval RPC remains a possible package-credit path; the Admin UI lock is not a substitute for the live database guard.
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


## Public product catalogue (2026-11-15)

- Added a dedicated Products navigation tab. It reads only active product records and presents a responsive catalogue card grid with image fallback, category, title and description. This is a read-only public/member experience; it does not create or modify products.
- Added `20261116010000_public_active_product_catalogue.sql` to permit anonymous and authenticated SELECT of active products only. Draft/inactive products remain hidden. The migration is committed to `completion-work` and has NOT been applied to Production.
- No financial features were enabled and no Production data was changed. Tests remain deferred as requested.


## Admin product management and media (2026-11-15)

- Added an Admin product register with draft/active status, edit, publish and hide controls. Hiding a product preserves the database record and existing auction references; it removes the product from the public active catalogue.
- Added secure Admin RPCs for listing, saving/updating drafts and publishing/unpublishing products. Each mutation writes an audit-log entry and verifies the trusted `app_metadata.role=admin` claim server-side.
- Added the public `product-media` Storage bucket with a 5 MB limit and JPG/PNG/WebP MIME allow-list. Public read is limited to that bucket; upload/update/delete require the trusted Admin role. Admin UI uploads images and stores the public URL with the product draft.
- Migration: `20261116020000_admin_product_management_and_media.sql`. It is source-only on `completion-work`; it has NOT been applied to Production. Existing Storage bucket/policy state has not been inspected in Production, so rollout must reconcile policies before applying.
- No tests, deployment, financial writes or Production database changes were performed.


## Production-schema alignment — product catalogue (2026-11-15)

- A read-only inspection of the connected BiddWorld-Production database confirmed that `products` uses `name`, `image_path`, and `status` (draft/published), not the legacy baseline fields `title`, `image_url`, and `is_active`.
- Updated the public Products query and card model to read only `status='published'` and use the live product columns.
- Updated Admin product publication labels/actions to use the live `published` status. Product publishing remains a controlled Admin action; hiding returns the record to draft.
- Updated Fixed Bid public listing to use the live campaign statuses `scheduled`, `live`, and `ended`.
- Corrected the two pending product migrations to match the reconciled live schema and `audit_logs.details`. These are source-only changes and have NOT been applied to Production.
- Production data, schema, migration history, settings, and Storage were not changed. No tests were run, per the deferred verification sequence.


## Admin-configurable referral plan depth (2026-11-15)

- The Admin editor already supports Add Level / Remove Last Level, but the currently connected Production RPC `admin_save_referral_plan_draft` still rejects anything other than exactly five rules.
- Added source-only forward migration `20261116030000_admin_configurable_referral_plan_depth.sql` to accept one or more distinct positive level numbers without a fixed five-level or arbitrary 100-level cap.
- The RPC still requires trusted Admin access and an inactive package, creates a new inactive plan version, validates every rule, records an audit entry, and never activates commissions or credits wallets.
- Updated the Admin section description to match its configurable-depth behavior.
- This migration has NOT been applied to Production. The existing Production function remains five-level-only until a reviewed migration is explicitly applied.


## Package approval safety lock (2026-11-15)

- The live Production settings snapshot still has package activation, Bid Wallet and Income Wallet feature flags enabled, and the `financial_model_approved` key was not present.
- The source-only database financial guard migration is not applied to Production. To prevent routine Admin UI use from issuing a real package credit before owner approval, the Admin approval action is now hard-locked in the frontend; rejection remains available.
- This client-side lock is an interim safeguard only. A trusted Admin could still call the exposed review RPC directly until the reviewed database guard is applied. Production must remain untouched per owner instruction; treat installation/reconciliation of the database guard as a hard launch blocker.


## Duplicate ID placement workflow alignment — 2026-11-16

- Reconciled the Admin UI with the branch migration `20261115230000_duplicate_under_id_placement_attribution.sql`: Duplicate ID creation requires both an active owner Main ID and a different active Under / Placement ID, and sends the migration's two-argument RPC signature.
- The placement selector is sourced from the Admin member-structure result and filters to active IDs. The database migration enforces ownership separation and stores the placement parent; IDs remain Pending for review. Approval remains disabled until the returned placement parent is present.
- Read-only Production inspection previously found the currently deployed RPC still has the older one-argument signature. The branch's forward migration is not applied to Production by design; this UI workflow becomes available in Production only after owner-approved migration rollout and reconciliation. No Production data or schema changed; no tests run.


## Production reconciliation audit — 2026-11-16

- Added `docs/PRODUCTION_RECONCILIATION_AUDIT_2026-11-16.md` from a read-only comparison of the frontend RPC inventory, live Production function catalogue, migration history, selected RLS policies and feature settings.
- Confirmed missing live RPCs for member identity, member ID listing, member profile updates and product publish/hide; confirmed the Duplicate ID one-argument/two-argument signature mismatch; recorded the referral plan depth migration gap.
- Recorded that the financial approval guard is not deployed and that Production still reports package activation, Bid Wallet and Income Wallet feature switches enabled while bidding, withdrawals, commissions and other execution switches are disabled. No Production settings were changed.
- This is a reconciliation/audit deliverable, not a completed feature module or security certification. Tests remain deferred; Production remains untouched.


## Fixed Bid draft editing batch (2026-11-16)

- Admin can reopen and update an existing Fixed Bid campaign only while its status is `draft`, using the existing Admin-only `admin_save_fixed_bid_campaign_draft` RPC contract.
- Campaign product, title and description are restored into the editor; saving updates the same draft rather than creating a duplicate. Cancel clears edit state.
- Non-draft campaigns remain read-only. Entry pricing, participant limits, scheduling, winner selection, wallet debits, settlement and payouts remain unavailable pending owner-defined rules and approval.
- No Production SQL, settings, records, wallet balances or financial state were changed. Tests were not run in this implementation phase.


## Auction draft editing batch (2026-11-16)

- Added Admin editing for existing auction records only while their status is `draft`; published/live/closed records remain read-only in this editor.
- The editor restores product, title, description, image, category, starting price, increment and schedule values, and saves through the existing `admin_save_auction_draft` RPC using the existing auction ID.
- Validates title length, numeric price/increment and chronological start/end values before calling the RPC. Cancelling clears the edit state.
- Read-only Production inspection confirmed the existing RPC checks trusted Admin JWT role, draft product status, valid price/increment, draft-only update, and writes an audit record. No Production changes were made.
- Auction bidding, publication, winner selection, settlement and all financial activity remain disabled. Tests were not run.


## Auction Admin RPC source reconciliation (2026-11-16)

- Added source migration `20261116040000_admin_auction_draft_management.sql` for the Admin-only `admin_list_auctions()` and `admin_save_auction_draft(...)` RPCs already observed in the live Production catalogue.
- RPCs enforce the trusted `app_metadata.role=admin` claim, accept only draft products, validate title/price/increment/date ranges, restrict edits to existing draft auctions, and write audit records. Execution is granted only to authenticated users; each function performs its own Admin check.
- Migration is committed as source only. It has NOT been applied to Production. The migration follows the reconciled live schema (`products.name/status`, auction `updated_at`); baseline schema drift remains a rollout prerequisite.
- No bidding, publication, winner selection, wallet movement, settlement or payouts were enabled. No tests were run.


## Recovery checkpoint (2026-11-16)

- Verified `completion-work` exists and its current HEAD at recovery was `b9cb37c7dd20306a810fa352d98997fc8ac7ff28`. This supersedes the older commit hash included in the user prompt.
- Repository metadata reports linked GitHub push/admin permissions. The default branch is `main`; all project work remains on `completion-work`.
- Verified Production project is `ACTIVE_HEALTHY` on PostgreSQL 17.11 in `ap-south-1`.
- Read-only Supabase migration ledger reports 30 applied migrations; latest is `20261115163218_admin_audit_log_pagination`.
- Current combined commit status reports four Vercel contexts failed with build-rate-limit destinations. This does not prove the source build itself fails. GitHub Actions result was not independently verified in this pass.
- No local build, typecheck, Vitest, browser E2E or security test was run during recovery.
- Added `docs/PROJECT_RECOVERY_AUDIT_2026-11-16.md` with source inventory, production snapshot, known drift, blockers and next execution sequence.
- No Production SQL, migration, settings, Storage, member data, financial data, domain or hosting changes were performed.
- Recovery snapshot is not a completion or production-readiness claim.


## Member Support module (2026-11-16)

- Added `src/components/Support.tsx` for member ticket submission/history and Admin queue response/status management.
- Added `20261116040000_member_support_tickets.sql` with RLS, least-privilege column grants, server-enforced ownership/admin checks, timestamps and audit logging.
- Added signed-in Support navigation without changing existing member/Admin routes. The module is non-financial.
- Remaining: run build/typecheck/unit/integration tests; inspect actual Production table grants and policies during the final reconciliation; add email/SMS/push dispatch only after a free, approved provider and consent design exist. Migration is not applied to Production.


## Support security correction and CI scope (2026-11-16)

- Corrected the support audit trigger to write `audit_logs.metadata`, matching the existing schema (the initial draft referenced a non-existent `details` column).
- Added static migration contract tests covering owner/admin RLS, restricted member insert and Admin update grants, audit schema compatibility and input bounds.
- Expanded the existing CI push trigger to include `completion-work`; the workflow has not yet reported a run for this branch, so no test/build success is claimed.


## In-app Notifications module (2026-11-16)

- Added signed-in member inbox with unread count, refresh and mark-as-read.
- Added Admin-only targeted notification creation with UUID recipient validation, bounded title/message and category allow-list.
- Added additive `20261116050000_member_notifications.sql` with RLS, owner-only reads/read receipts and Admin-only inserts. No email, SMS or push delivery is configured.
- Added static migration security-contract tests. Migration remains unapplied to Production. Build/test run is still pending.


## Verification update — 2026-11-16

- GitHub Actions CI run `43751441554` on `completion-work` commit `c9b77e971cffb7ab43f947f822b472e4a1a27c02` completed successfully: dependency installation, dependency security report, unit tests, TypeScript type-check and Vite production build all passed.
- This verifies the repository snapshot only. It does not apply or validate pending Supabase migrations, prove live Production RPC/RLS compatibility, or certify payment/withdrawal workflows.
- The run includes the null-safe withdrawal-history rendering fix and the notification/support source changes. Production remains untouched.


## Admin product/media security contract — 2026-11-16

- Added static migration-contract coverage for the `product-media` bucket MIME/size limits, public-read versus trusted-Admin write policies, privileged RPC claim checks, draft-only product creation/editing and anonymous EXECUTE revocation.
- This test coverage does not prove Storage behavior or live Production compatibility. The migration remains source-only; Storage bucket/policy state and the `audit_logs` column contract still require reconciliation before rollout.
- Product image selection is still a path/URL field in the Admin UI; an end-to-end file picker, upload, object cleanup and upload-error UX remain outstanding.


## Support-to-notifications integration and current CI — 2026-11-16

- Added `20261116060000_support_ticket_notifications.sql`: trusted Admin status/response changes create a bounded in-app notification for the ticket owner. The trigger uses an empty search path, validates the Admin `app_metadata.role` claim and revokes direct client EXECUTE privileges.
- Added `tests/support-ticket-notifications.test.ts` covering Admin claim validation, owner recipient, status/response change detection, message length and function ACL.
- Corrected the test's SQL closing-parenthesis whitespace assertion. GitHub Actions run `43752553469` for commit `af4ae55f71e62905644fba19f70c5f4ee6a7c911` passed all configured unit tests, TypeScript type-check and Vite production build.
- Product media upload is already present in `Admin.tsx`: JPG/PNG/WebP, 5 MB maximum, Storage upload and public URL assignment. Remaining work is orphan/replaced-object cleanup and live Storage-policy validation; static migration tests do not prove live Storage behavior.
- All related migrations remain unapplied to Production. No Production schema, data, settings, wallet balances or financial operations were changed.


## Delivery tracking feature gate — 2026-11-16

- Added `delivery_tracking_enabled` to the Admin UI's backend-pending feature set because the current branch has frontend RPC call sites but no version-controlled migration defining `admin_save_delivery_tracking` or `admin_list_delivery_tracking`.
- Added a static regression test to ensure this gate remains in place until a reviewed migration contract exists. This is a safety hold, not a claim that delivery tracking backend is complete.
- No Production changes or delivery record changes were made.


## Delivery tracking backend source recovery — 2026-11-16

- Read-only Production catalog queries recovered the existing delivery_tracking table, owner-only SELECT policy, Admin list/save RPCs, paid-payment checks, pagination/input bounds, audit_logs.details usage and delivery feature-gate trigger.
- Added source-only migration 20261116070000_delivery_tracking_backend.sql. It includes explicit RLS/column grants, trusted Admin RPC checks, a transaction advisory lock and a unique payment index to prevent duplicate tracking rows under concurrent creation.
- Removed the obsolete UI pending-backend lock. The database delivery_tracking_enabled feature switch remains the write gate and has not been enabled.
- Corrected support-ticket audit logging to use Production's audit_logs.details column. Renamed the support migration to 20261116041000_member_support_tickets.sql to avoid a duplicate migration version with the auction draft migration.
- No Production migration, setting, delivery row or financial data was changed. Static tests cover source contracts; live execution remains pending.


## Support and notification inbox pagination — 2026-11-16

- Member Support and Admin Support Queue now load records in bounded batches of 100, with deterministic secondary ID ordering and a Load More control.
- Member Notifications and Admin Notifications now use the same 100-record pagination pattern; the member unread count explicitly describes the currently displayed records.
- Added a Vitest static contract test for bounded first-page and subsequent-page queries and the visible pagination controls.
- These are source-only UI changes. No Production schema, data, Storage, feature settings or financial state was changed.
- CI has not yet been verified for these commits. Vercel status contexts currently report build-rate-limit failures; these are provider limits and do not establish whether the TypeScript/Vite build passes.


## Complete Member Activity Report — 2026-11-16

- Replaced the latest-100-only CSV report with a complete personal activity export.
- Export re-verifies the signed-in user and Main ID, then retrieves package activations, auction bids, Fixed Bid entries, referral commissions and winning payments in deterministic 500-row pages.
- Delivery tracking is fetched in bounded batches based only on the current Main ID's winning-payment IDs. Wallet balances, member IDs and the member's existing withdrawal history are included.
- Added export-busy state, success record count and clear error feedback. CSV uses the shared formula-safe serializer.
- Added static Vitest coverage for page bounds, deterministic ordering, personal identity scope and included data sources.
- Source-only change on `completion-work`. No Production schema/data/settings or financial activity was changed. Verification for this new commit is pending.


## Member report type-check correction — 2026-11-16

- The first CI run for the complete report export exposed TypeScript narrowing and Supabase query-builder generic incompatibilities in the page helper. The export now captures a narrowed client reference before async callbacks and uses the query builder's thenable response without imposing an incompatible structural generic.
- This is a compile-time correction only; no database or financial behavior changed. The corrected branch commit is awaiting CI verification.


## Admin historical CSV exports — 2026-11-16

- Admin withdrawal requests, winning-item payments, delivery tracking and audit logs now export every secured RPC page (100 rows per request), rather than exporting only the currently visible first page.
- Audit export applies the active Admin search and date filters to the complete retrieved history. Export busy/success/error feedback is displayed in the Reports section.
- Existing Admin wallet-ledger export already retrieves every RPC page. Other reports continue to use their full-list RPCs and are explicitly described as such until their server-side result limits are audited.
- Added static regression tests for pagination and all four complete CSV exports. Source-only; no Production data, schema, settings or financial actions changed.


## Financial interlock expansion — 2026-11-16

- Extended the source-only database guard to block credited referral commissions, auction bid inserts and Fixed Bid entry inserts in addition to all wallet ledger inserts, package approvals, withdrawal requests/processing and winner-payment settlement.
- Replaced the Admin feature-setting RPC in the migration so financial/MLM switches cannot be enabled until the trusted `financial_model_approved` setting is explicitly true. Disabling remains allowed; the approval key is not exposed through the Admin toggle.
- Added a matching Admin UI guard to refuse enabling financial feature switches before owner approval.
- Expanded static security-contract tests to cover the new trigger surfaces and feature-toggle guard.
- This migration is source-only and NOT applied to Production. Live Production still lacks this interlock; no Production schema, data, settings or financial records were changed.


## Member Dashboard history pagination — 2026-11-16

- Member package activations now load 50 per page; auction bids, Fixed Bid entries, referral commissions and winning payments load 100 per page.
- Added deterministic secondary ID ordering, per-history Load More controls and busy/error handling. Newly loaded winning payments also fetch linked delivery records.
- Existing wallet transaction history and complete personal CSV export remain independently paginated; no financial write paths were added.
- Added static regression tests for bounded first pages, stable ordering and all continuation controls. Source-only; Production unchanged.

## Verified bulk completion checkpoint — 2026-11-16

- Current audited source HEAD: aaffdcdb4dad8dc08bef885d2b310adf5123d529 on completion-work.
- GitHub Actions run 43755981322 completed successfully on this exact HEAD: 17/17 Vitest files passed, TypeScript project build passed, and Vite 6.4.6 production bundle built successfully.
- Completed source batches now represented on the branch: Support and Notifications inbox pagination; complete member activity CSV export across all pages; Member Dashboard history Load More pagination; Admin full-history CSV exports for wallet ledger, withdrawals, winning payments, delivery tracking and audit logs; source-only financial approval interlock for package approvals, wallet ledger, referral commissions, auction bids, Fixed Bid entries, withdrawals and winner settlement.
- Latest batch commit aaffdcdb4dad8dc08bef885d2b310adf5123d529 records the module register and read-only Production security findings.
- The source financial interlock has NOT been applied to Production. Production still lacks financial_model_approved and has package_activations_enabled, bid_wallet_enabled and income_wallet_enabled set true. The owner must not approve package credits or execute financial actions until the reviewed interlock is applied through an explicitly approved rollout.
- Production remains unchanged: 21/21 public tables RLS-enabled, 30 applied migrations, latest 20261115163218_admin_audit_log_pagination. No Production SQL, DDL/DML, settings, Storage, wallet balances, commissions, payouts, domain or hosting changes were made.
- Vercel deployment status contexts still report build-rate-limit failures; GitHub Actions build success does not establish a Vercel deployment. No deployment or paid upgrade was attempted.
- This is a verified source build/test checkpoint, not a Production-readiness certificate. Final module completion, complete RPC/RLS/Storage audit, owner-defined business rules, integration/browser testing, legal/compliance review and deployment preparation remain outstanding.

## Catalogue pagination verification — 2026-11-16

- Source commit `aa681d821b1051d65d8e5c6b19bebcd3e941fdc2` on `completion-work` passed GitHub Actions run `43756332602`: 19/19 Vitest files passed, TypeScript project build passed, and Vite 6.4.6 production bundle built successfully.
- The same batch includes Fixed Bid catalogue pagination in commit `e95c37d0dc6848ca5f07fa1f8f75ee75e24e54d7`; its CI run `43756267630` passed.
- Public auction listings now use deterministic 100-row server pages with Load More. Fixed Bid public catalogue uses deterministic 50-row pages with Load More. Existing member/admin financial locks are unchanged.
- Admin member directory remains limited by the live `admin_list_members_sponsors()` RPC to its first 500 Main IDs. A secure paginated/search RPC and matching UI remain outstanding; the Production RPC was inspected read-only and no Production change was made.
- CI validates repository source only. It does not apply pending migrations or certify live Production RPC/RLS/Storage behavior.

## Admin directory and catalogue batch — verified 2026-11-16

- Source commit `4b8e89f7e80f824cc5892126562603029f5f1d2e` on `completion-work` passed GitHub Actions run `43756709964`: 20/20 Vitest files passed, TypeScript project build passed, and Vite 6.4.6 production bundle built successfully.
- Public auctions: bounded deterministic 100-row pages with Load More.
- Fixed Bid catalogue: bounded deterministic 50-row pages with Load More; CI run `43756267630` passed 19/19 test files and build.
- Admin Main ID directory: new source-only Admin-checked paginated RPC with 100-row pages, stable ordering and optional bounded search parameter; UI first page and Load More implemented. Current UI search remains client-side over loaded rows, and complete filtered export remains outstanding.
- New migration `20261116090000_admin_members_sponsors_pagination.sql` is source-only and has NOT been applied to Production. No Production data/schema/settings/Storage or financial operations were changed.
- This CI run verifies source code only, not the new migration against live Production. Existing Production RPC remains limited to 500 records until a reviewed rollout of the new RPC.

## Admin member directory server-side search batch — 2026-11-16

- Commit `53bc09805e88e0ffc37108431593682a43b4326f` passed GitHub Actions run `43757646055`.
- CI verified 20/20 Vitest files, TypeScript project build and Vite 6.4.6 production bundle.
- Admin Main ID directory now sends the search term to the Admin-checked paginated RPC, searches all Main IDs server-side, loads subsequent matching pages with the same query, and exports all matching pages to CSV.
- This is still source-only integration. The new RPC migration `20261116090000_admin_members_sponsors_pagination.sql` is NOT applied to Production; live Production still has the legacy 500-row RPC. Do not use the updated UI against Production until a reviewed migration reconciliation is approved and deployed.
- No Production database, data, settings, financial records, or migrations were changed.


## Member genealogy pagination batch (2026-11-16)

- Added bounded, authenticated server-side sponsor genealogy pagination, cross-page search, level filtering and Load More to the member Referrals workspace.
- Added source-only migration `20261116100000_member_genealogy_pagination.sql` and regression tests.
- Initial CI: 21/21 test files and 83/83 tests passed; TypeScript build exposed nullable Supabase client narrowing in an async callback. Corrected in the follow-up fix commit; verify the new CI run before treating the batch as green.
- Production migration not applied; no Production records or financial settings changed.


## Member sponsor genealogy pagination — verified 2026-11-16

- Final source commit `c3217f8180941cfc6c2d1c0d56841ec2edaee60b` passed GitHub Actions run `43759348588`.
- CI: 21/21 Vitest files passed; TypeScript build and Vite production bundle passed; npm audit reported 0 vulnerabilities.
- Member Referrals now supports full-downline server-side search, level filtering and 50-row paginated Load More using new authenticated RPC migration `20261116100000_member_genealogy_pagination.sql`.
- The SQL migration is source-only and NOT applied to Production. No Production data, schema, settings or financial records changed.


## Member package activation safety lock — 2026-11-16

- Removed the member-facing UTR/payment-reference form and activation RPC call from the package catalogue.
- Package catalogue entries, if present, are informational only; displayed wallet benefits are explicitly marked as proposed and not issued.
- Free member registration remains available. Paid activation requests remain locked until explicit owner financial/legal approval and independent verification of the database interlock.
- Added regression tests for the fail-closed UI, absence of payment submission controls/RPC calls and clear informational labels.
- This UI guard does not replace the database trigger/RPC interlock. The financial-approval and lockdown migrations remain source-only and Production migration reconciliation is still required.


## Admin Duplicate ID directory pagination — 2026-11-16

- Added source-only Admin-checked `admin_list_duplicate_ids_page(text,integer,integer)` with 50-row pages, bounded offsets, deterministic ordering, total count and continuation flag.
- Search spans Duplicate ID, owner Main ID, Under ID, owner/placement display names, phone and status.
- Admin Duplicate ID management now searches the full result set and loads subsequent pages while retaining the applied search.
- Regression tests cover Admin authorization, bounded pagination, search fields, stable ordering, RPC grants and UI continuation.
- Migration is not applied to Production; duplicate ID creation/activation remains disabled by the financial approval lock. No Production data or settings changed.


## Admin Duplicate ID pagination CI correction — 2026-11-16

- First CI run `43785205823` caught a mismatch in the new test's authorization regex (the SQL authorization clause itself was present); 22/23 test files and 91/92 tests passed before the assertion stopped the build.
- Corrected the assertion to match the exact trusted Admin claim and made the UI surface a clear directory-load error when the source-only RPC has not been installed.
- Corrected an obsolete Admin member-directory note that still described the former 500-row limitation.
- Re-run CI is required before treating this batch as verified.


## Admin Duplicate ID pagination — verified 2026-11-16

- Final source commit `9e42ee4af7b3b49958f18e55a7505c218ad3feb0` passed GitHub Actions run `43785364112`.
- CI: 23/23 Vitest files and 92/92 tests passed; TypeScript project build and Vite production bundle passed; dependency audit reported 0 vulnerabilities.
- Admin Duplicate ID directory now has Admin-checked server-side search across Duplicate ID, Main ID, Under ID, names, phone and status, with bounded 50-row pages, total count and Load More.
- First CI run `43785205823` failed one test assertion because the test regex did not match the valid SQL claim expression; corrected in the follow-up commit. The SQL authorization condition itself was present in both versions.
- The new migration `20261116110000_admin_duplicate_id_pagination.sql` remains source-only and is NOT applied to Production. Duplicate ID activation remains blocked by the financial approval interlock.
- Production read-only Security Advisor snapshot (2026-11-16): 43 authenticated-callable SECURITY DEFINER routines (the individual routines must be reviewed for Admin/caller checks), one anon-callable `lookup_sponsor(text)` SECURITY DEFINER routine used by sponsor validation, and one RLS-enabled table without direct policies (`notification_templates`). Performance findings: one unindexed FK on `notification_templates.created_by` and 17 unused indexes (do not remove without workload review).
- Production migration history remains at 30 applied migrations, latest `20261115163218_admin_audit_log_pagination`. No Production SQL, schema, data, settings, Storage or financial records were changed.


## Product media upload lifecycle improvement — 2026-11-16

- Admin product image uploads now use collision-resistant UUID object names and retain the path of the currently staged, not-yet-attached upload.
- Replacing a staged image removes the previous temporary object; Admin can explicitly discard an unattached upload. Switching to an existing product or entering a manual image URL also detaches and attempts to remove the temporary object.
- Successfully saving the product draft marks the staged object as attached, so it is not deleted. Existing product images and auction references are never automatically removed.
- Storage removal failures are surfaced for manual Admin cleanup. This is source-only; no Storage objects, Production policies, schema or data were changed. Final tests remain deferred until implementation completion.


## Admin notification template draft hardening — 2026-11-16

- Added explicit input validation for template name, channel, message body and email subject before calling the Admin RPC.
- Added exception-safe save handling so network/RPC failures display an error and always release the busy state.
- Added Cancel Edit/reset behavior and clearer editing feedback; templates continue to save only as inactive drafts and no notification is sent.
- Provider integration, recipient targeting, delivery tracking, unsubscribe/consent handling and end-to-end notification testing remain pending. No Production data, policies, RPCs or settings were changed.


## Public product catalogue pagination — 2026-11-16

- The public Products tab now loads active published products in deterministic 100-row server pages, ordered by product name and ID, with a Load More control and loaded-count feedback.
- Product query failures and continuation-page failures now show clear retry guidance instead of silently presenting an empty catalogue. Search continues to filter all product pages loaded in the current session.
- The query remains read-only and restricted to `status='published'`; no Admin draft or unpublished product is exposed. No financial behavior or Production database state changed.
- Source-only UI update on `completion-work`; CI/build verification is pending. This does not reconcile or apply the pending product catalogue migration to Production.


## Bulk development batch — public catalogue and member profile hardening — 2026-11-16

- Public Products catalogue now loads active published products in deterministic 100-row server pages, with Load More, loaded-count feedback and explicit first-page/continuation error states. Search filters all pages loaded in the current session; searching across unloaded pages remains a future server-search enhancement.
- Member profile self-service now validates display-name length and phone format before calling the existing self-only RPC, validates the response shape, surfaces errors and always releases the saving state. Server-side update remains restricted to the caller's own display name and phone; member IDs, sponsor, status and financial fields are not editable through this workflow.
- Added source-contract tests for product pagination and member profile safeguards. Tests have been authored but have not yet been executed in this batch.
- Code commits: `cc9e6366` (product catalogue), `6e42728f` (member profile hardening). Test commits: `b2391637`, `4110e9e7`, `a5fbd57a`, `8009b4af`. No Production database, Storage, settings or financial records were changed.


## Installable PWA foundation batch (2026-11-16)

- Added a Web App Manifest with standalone display, app scope/start URL, theme/background colours and scalable 192/512 SVG app icons.
- Added production-only service-worker registration using Vite BASE_URL, so GitHub Pages /biddworld/ and future root-domain hosting use the correct scope without cross-origin API caching.
- Added a versioned same-origin app-shell cache, network-first navigation fallback and same-origin static-asset cache; Supabase/API requests are not intercepted or cached.
- Added automated source-contract tests for the manifest, registration, offline fallback and cache boundaries.
- This is the installability/offline foundation, not a claim that Android installation, browser compatibility or offline authenticated workflows have been device-tested. Those remain in final QA.
- No Supabase migrations or Production changes were made.


## Member inbox and Support workflow usability batch (2026-11-16)

- Member notification inbox now provides an unread-only view over loaded rows and a bulk mark-as-read action. Bulk updates are limited to unread records and rely on the existing owner-scoped RLS policy; Admin notification authoring does not expose this member action.
- Support workspace now filters loaded tickets by status and case-insensitive subject/message/response text for both member and Admin views. The UI explicitly labels filters as applying to loaded records; existing 100-row pagination and database RLS remain in place.
- Added source-contract regression tests for both changes. CI is required to verify tests, TypeScript and production build.
- No migrations, Production schema/data/settings, wallet balances or financial workflows were changed.


## Fixed Bid catalogue and CI regression correction (2026-11-16)

- Added client-side search and status filters (Scheduled, Live, Ended) over the Fixed Bid campaigns already loaded by the existing 50-row paginated query. Search covers campaign title/description and product name/category. The UI labels the scope as loaded campaigns and preserves pagination.
- Corrected the notification inbox heading wording to retain the existing pagination test's explicit 'unread shown' contract while still clarifying that the count is for the current page.
- CI run `43789281452` exposed one existing source-contract assertion expecting the phrase `unread shown`; 27 test files passed and 1 test file failed (108/109 tests passed). This batch corrects that compatibility issue and adds Fixed Bid filter regression coverage. New CI verification is pending.
- No financial actions, migrations, Production data/schema/settings or wallet state changed. Fixed Bid remains read-only; no entries, bids or payments are enabled.


## Member wallet statement date filters (2026-11-16)

- Added inclusive UTC start/end date filters to the member Wallet Transaction History, alongside existing wallet-type and credit/debit filters.
- The same combined filter is applied to the complete Main-ID-scoped CSV export, not just the currently loaded 100-row screen. Invalid reversed date ranges are blocked and clearly reported; date filters can be cleared without reloading wallet records.
- Added regression tests for date boundaries, complete export parity and retention of Main ID scope/pagination.
- No wallet balances, ledger rows, financial RPCs, Supabase migrations, Production data/schema/settings or financial enablement were changed.


## Admin complete wallet ledger export (2026-11-16)

- Added a dedicated complete Admin wallet-transaction CSV export using the existing authenticated `admin_list_wallet_transactions` RPC in 100-row pages until the final page.
- Export includes transaction/member IDs, wallet type, direction, amount, balance-after, reference metadata, description and timestamp. It is read-only and does not alter balances or ledger records.
- Clarified the Reports screen about which exports are complete paginated RPC exports and which remain limited to currently returned source-RPC records (package activations, referral plans, auctions and Fixed Bid campaigns).
- Added regression tests for the RPC pagination contract, ledger fields and report-scope wording.
- No migrations, Production schema/data/settings, wallet balances or financial workflows were changed.


## Admin wallet ledger Reports entry-point correction (2026-11-16)

- Connected the Reports screen to the existing complete paginated wallet-ledger export action rather than maintaining a duplicate implementation. This avoids duplicate code and keeps one source of truth for its loading/error state and CSV generation.
- No new database calls or financial behavior were introduced; export remains read-only.


## Admin wallet ledger search and date filters (2026-11-16)

- Added client-side search over the currently loaded Admin wallet ledger (Main ID, wallet, transaction type/direction, reference and description) and inclusive UTC From/To date filters.
- Added a clear-filters action, matching-row count, and reversed-range warning. The UI explicitly states filters cover loaded rows only.
- The complete CSV export continues fetching all secured RPC pages independently of these screen filters, so the filters cannot silently narrow the archival export.
- Added source-contract regression tests. No wallet records, balances, RPCs, schema or Production settings changed.


## Admin pending package activation review filters (2026-11-16)

- Added search on the currently loaded pending activation requests by request number, Main ID, member name, package and payment reference.
- Added inclusive UTC submission-date filters, clear action, matching count and reversed-range warning.
- Filtering is display-only: it does not change payment status, reject/approve behavior, financial locks or the existing CSV export scope (which remains all currently loaded pending requests).
- Added regression tests. No package activation, wallet credit, payment status, Supabase schema or Production data was changed.


## Admin Auction and Fixed Bid report filters (2026-11-16)

- Added loaded-record search and status filters to the Admin Auction and Fixed Bid CSV report sections.
- Auction search covers ID, product, title, category and status. Fixed Bid search covers campaign ID, product, title, description and status.
- CSV exports now use the matching filtered rows and show matching versus loaded counts. UI text explicitly states these source RPC results are not guaranteed complete-history exports.
- Referral plan export remains clearly labelled as plan drafts, not a commission payout history. No Supabase schema/RPC, Production data, bidding, settlement or wallet behavior changed.


## Admin Winning Payment and Delivery report filters (2026-11-16)

- Added search, status and inclusive date-range controls for Winning Payments and Delivery Tracking report exports.
- Filters run after the exporter retrieves every 100-row page from the existing secured Admin RPC, so they apply to the complete fetched dataset rather than only the first on-screen page.
- Winning-payment date range uses `created_at`; delivery date range uses `updated_at` with `shipped_at` fallback. Export filenames and controls identify filtered complete exports.
- No payment, delivery, wallet, auction, Fixed Bid, Supabase schema/RPC or Production data was changed. This is reporting only.


## Admin Package Activation report filters (2026-11-16)

- Connected the existing pending-activation search and inclusive submitted-date filters to the CSV export; added a matching/total count and disabled export for reversed date ranges.
- The existing `admin_list_pending_activations()` RPC returns the complete pending-review queue (no page limit in its migration). The report is explicitly scoped to pending requests and is not represented as an approved/rejected historical activation archive.
- No approval/rejection action, wallet credit, payment, Supabase schema/RPC or Production data changed.


## CI regression correction (2026-11-16)

- Updated the existing complete-report export contract test to expect the filtered-complete filenames now produced by the Winning Payments and Delivery report filters. This resolves a stale filename assertion; no application behavior changed in this correction.


## Admin Withdrawal report filters (2026-11-16)

- Added search, status and inclusive request-date filters to the withdrawal CSV export.
- Filters are applied after the existing export helper retrieves every 100-row page from `admin_list_withdrawal_requests`; date range uses `requested_at`. Reversed ranges disable export.
- Export remains read-only. No withdrawal approval, payout, wallet balance, financial setting, Supabase schema/RPC or Production data changed.


## Pending activation regression test alignment (2026-11-16)

- Updated the existing pending activation filter regression test to assert the current filtered-export label/count. This corrects a stale UI assertion after connecting the existing filters to CSV export.


### Withdrawal report test alignment (2026-11-16)

- Updated the complete-export regression assertion for the new filtered withdrawal CSV filename. Export still fetches all secured RPC pages before applying the selected filters.


## Browser Supabase credential security check (2026-11-16)

- Added a regression test confirming the browser client uses only the public publishable/legacy anon key variables, retains session refresh/persistence, and contains no service-role or Supabase secret key.
- `.env.example` explicitly warns against placing service-role/secret keys in `VITE_` variables. The configured browser key is a public publishable key; database authorization must continue to rely on RLS and server-side RPC checks.


## Fresh Production drift and security verification — 2026-11-16 (read-only)

A further direct read-only inspection was completed against the connected `BiddWorld-Production` project. No SQL writes, migrations, settings changes, Storage operations, or row changes were performed.

### Confirmed migration drift

- Production migration ledger currently contains **30 applied migrations**; latest is `20261115163218_admin_audit_log_pagination`.
- The branch contains forward migrations dated `20261116` that are not present in the Production ledger. The financial approval guard and expanded financial activity lockdown remain source-only.
- Production still exposes the one-argument `admin_create_duplicate_member_id(p_main_member_code text)`; the branch workflow expects the two-argument placement-aware signature. Do not use the branch Duplicate ID placement workflow against Production until its migration is owner-approved and reconciled.
- Production `place_bid` and `submit_package_activation` are SECURITY DEFINER wrappers that delegate to private SECURITY DEFINER implementations. The private implementations inspected derive the member from `auth.uid()`; bidding is additionally disabled by the current feature setting. This does not remove the need to install and verify the expanded source-only financial interlock before any financial enablement.

### Security review findings

- Catalog inventory confirms public Admin SECURITY DEFINER RPCs are executable by `authenticated` but not `anon`; the inspected Admin RPC bodies contain authenticated-user and `app_metadata.role = admin` checks. This is an inventory-level check, not a line-by-line certification of every function.
- `lookup_sponsor(text)` remains intentionally callable by `anon` and `authenticated`, returns exact-match active Main ID code and display name, and has no rate limiting in its current definition. Signup requires this lookup, so do not revoke it without replacing the signup flow. Rate limiting, enumeration controls and privacy review remain launch blockers.
- Supabase Security Advisor currently reports leaked-password protection disabled. Enable it through the Auth security settings after owner review; it was not changed during this audit.
- Security Advisor reports multiple authenticated-callable SECURITY DEFINER functions. The execute grant alone is not proof of a vulnerability; every function body must be checked for authentication, ownership or trusted Admin authorization, fixed search_path and data minimization.

### Financial interlock — do not enable

- The Production settings snapshot still has `package_activations_enabled=true`, `bid_wallet_enabled=true`, and `income_wallet_enabled=true`; the `financial_model_approved` setting is absent.
- Production has not received `20261116000000_financial_approval_guard.sql` or `20261116080000_financial_activity_lockdown.sql`. The source guard is therefore not active in Production.
- Treat package approval, wallet ledger writes, commission credits, bid debits, Fixed Bid entries, withdrawals and winner settlement as prohibited until a complete forward-only migration is reconciled, independently tested and explicitly approved by the owner. Keep financial features disabled; do not infer safety from client-side locks.

### Required next actions

1. Reconcile every source migration against actual Production object definitions, not only migration version names; prepare a forward-only plan and dry-run in a safe non-production environment.
2. Review every exposed SECURITY DEFINER RPC body, especially the Admin RPCs, member withdrawal request, sponsor lookup and bid/package wrappers.
3. Add rate-limit/abuse protection for public sponsor lookup without breaking signup.
4. Owner to review and enable leaked-password protection in Auth settings.
5. Do not apply migrations or alter financial settings without explicit owner approval.


## Critical Admin RPC authorization drift correction (2026-11-16)

- A fresh read-only Production catalog inspection found the live definitions of `admin_get_member_structure()` and `admin_get_mlm_overview()` did not contain the Admin-role guard present in the current source migrations. Both RPCs were executable by authenticated callers, so this represented a member-to-admin report data exposure risk.
- Added forward-only migration `20261116130000_restore_admin_report_rpc_authorization.sql` to restore `auth.uid()` plus trusted `auth.jwt()->'app_metadata'->>'role' = 'admin'` checks, fixed empty search_path, and revoke PUBLIC/anon execution while granting authenticated invocation (the function body enforces Admin role).
- Added regression tests for both function bodies and ACL statements.
- Migration is committed to GitHub only and is **NOT applied to Production**. Owner approval and non-production verification are required before deployment. No Production data/settings/schema were changed during this batch.


## Withdrawal RPC identity hardening (2026-11-16)

- Read-only Production function review found `member_create_withdrawal_request` checked authentication, the withdrawal feature switch and Income Wallet balance, but did not independently verify that the profile's Main ID belongs to the caller and is currently active.
- Added a source-only forward migration that validates the profile Main ID against `member_ids.owner_user_id`, `id_type='main'` and `status='active'` before creating a withdrawal request. Existing Income Wallet-only deduction/request behavior, balance row lock, open-request check, disabled-by-default feature switch and authenticated-only grant are preserved.
- Added regression tests. This is defense in depth; it does not enable withdrawals and does not replace the financial approval interlock.
- NOT applied to Production. No live database data, schema, settings or financial records were changed.

### Admin RPC review clarification

The latest exact Production definitions of `admin_get_member_structure()` and `admin_get_mlm_overview()` both contain `auth.uid()` and trusted `app_metadata.role='admin'` checks. The prior batch's concern that these two live functions lacked those checks was incorrect. Keep their proposed redefinition migration unapplied pending full reconciliation; it is redundant against the current observed definitions.


## Signup inactive-until-verified Production drift (2026-11-16)

- Read-only inspection of the live `auth.users` trigger found `private.handle_new_auth_user()` currently creates both `profiles.status='active'` and `member_ids.status='active'`.
- The development branch's intended lifecycle is inactive until a verified/approved package activation. The corresponding source migration is not applied in Production, so this is a real source/Production drift and member eligibility risk.
- Added `20261116150000_enforce_inactive_signup_until_verified.sql`, preserving Production's current `registration_enabled` and `sponsor_referrals_enabled` feature-switch behavior, sponsor validation/default sponsor logic, profile and wallet provisioning, while setting both new profile and Main ID to inactive.
- Added regression tests for inactive creation and preserved gates. The migration is source-only; NOT applied to Production. No existing account statuses were mass-updated and no Production rows/settings/schema were changed.
- Deployment remains blocked on full migration reconciliation, non-production testing, and explicit owner approval of the financial/legal model. Do not activate package, referral, wallet, bid, or withdrawal operations.


## Public sponsor lookup privacy hardening (2026-11-16)

- Replaced the public lookup response containing member_code and display_name with a boolean exact-match result only. The signup trigger remains the authoritative independent sponsor validation/linking path.
- Signup UI no longer displays another member's name from a public anonymous lookup. It validates a minimally complete alphanumeric code before lookup and debounces requests by 450 ms to avoid a request on every keystroke.
- Added regression coverage for data minimization, grants, independent signup validation, debounce and incomplete-code suppression.
- This reduces PII disclosure and accidental request volume, but is NOT IP-based rate limiting and does NOT eliminate valid/invalid code enumeration. A trusted Edge Function/API gateway with server-observed IP throttling and abuse controls remains a launch blocker. No Edge Function is currently present in the repository.
- Source-only migration; Production still has its prior table-returning function. Do not apply before complete migration reconciliation and explicit owner approval. No Production changes made.


## Registration-to-package request lifecycle verification (2026-11-16)

- Confirmed the branch's `20261115220000_inactive_until_verified_package_activation.sql` migration already replaces the package-request RPC so an authenticated owner can submit a pending request with an inactive Main ID. It still requires a caller-owned Main ID, creates only pending activation rows, and does not credit wallets or activate the account.
- The prior concern is therefore a **Production migration-drift / rollout-order issue**, not a missing source implementation. Production currently has not applied the 20261115/16 source migrations and its live RPC still requires an active Main ID.
- Added a regression test asserting inactive Main IDs can submit pending package requests without wallet credit, and that the branch migration retains the pending-only lifecycle.
- Before deployment, reconcile and test the entire ordered migration chain together; do not apply the signup trigger migration in isolation. No Production changes made.


## Batch 20 CI correction (2026-11-16)

- Workflow `43792820737` executed 154 tests: 153 passed and one new assertion failed because its regular expression accidentally matched a literal backslash instead of optional whitespace. The application and SQL guard assertions passed; npm audit reported zero vulnerabilities.
- Corrected the test expression to a whitespace-tolerant regex. No production code or database change was needed for this test-only correction. Re-run CI to confirm.

- Follow-up workflow `43793006069` exposed a second overly broad negative assertion: it matched the trigger's legitimate read of the approval setting rather than only checking that the Admin feature-switch function cannot write that setting. Narrowed the assertion to the function body and the exact INSERT pattern. Re-run CI pending.

- The Batch 21 rerun revealed the negative regex was still double-escaped in the generated test file. Replaced it with direct string assertions scoped to the Admin feature-setting function body to avoid regex-escaping ambiguity.

- Batch 24: removed blanket historical profile/Main-ID status reconciliation from `20261115220000_inactive_until_verified_package_activation.sql`. It now provisions new accounts as inactive and activates only on verified package approval; existing account statuses are not bulk rewritten. Added regression tests for this data-safety guarantee.

- CI correction for Batch 24: initial regression assertion matched the legitimate row-level profile activation inside the verified-package trigger. Narrowed the assertion to reject only historical bulk CASE/EXISTS status reconciliation; it now permits activation of the specific member tied to an approved package.

- Follow-up CI test correction: the data-safety regression now rejects only the former historical bulk CASE/EXISTS status updates. It intentionally permits the trigger's row-specific activation updates after the matching package row is approved and active.

- Batch 24 CI verification: latest corrected commit `e6d308437d89d3158bbca30433525baa0ee0812b` passed GitHub Actions run `43794384681`. The workflow reports 44 test files and 162 tests passed; the job also completed the production build and dependency audit with 0 reported vulnerabilities. An earlier test assertion incorrectly rejected the legitimate row-specific activation trigger; it was narrowed to reject only the removed historical bulk CASE/EXISTS status updates.

- Additional financial approval-key access audit: Production `app_settings` grants are read-only for authenticated users; only service_role can write. Ordinary Admin feature RPC allowlist excludes `financial_model_approved`. Matching source guard keeps that owner approval key out of the Admin feature RPC. Production still lacks the source guard migrations; no Production changes made.

- Latest financial approval-key access regression verification: commit `e027992d8b928fc70db97fb0a8e51ef75ca18215`, GitHub Actions run `43795161226` passed. CI reports 44 test files / 163 tests passed; type-check/build completed successfully. The new test verifies the trusted approval key is absent from the ordinary Admin feature-setting allowlist (while allowing the guard to read it).

- Read-only Production grant audit: authenticated role has SELECT only (no direct write grants) on wallet accounts/ledger, package activations, withdrawals, referral commissions, bids, Fixed Bids and winner payments; anon has no grants. Source-only ledger BEFORE INSERT guard is expected to abort and roll back balance mutations performed earlier in the same RPC transaction, but this must be proven in a disposable non-Production integration environment.

- [x] Batch 28: read-only credential-pattern scan of all 18 browser source files; no service-role/secret credential patterns found. `.env.example` documents publishable-key-only browser configuration.
- [ ] Scan deployed bundles, Git history and CI secret usage; source scan alone is not a full secret-exposure audit.


## 2026-11-16 — Bulk security hardening batch

- Added a repository-wide SQL migration test covering public SECURITY DEFINER search_path pinning and EXECUTE revocation.
- Latest verified preceding CI: wallet ledger append-only batch and credential scanner correction passed; Follow-up commit `14308d223c53605854078fb1b5167f1f2b64d476` passed CI run `43798298345`: 45 test files / 167 tests passed, TypeScript type-check and Vite build succeeded, npm audit reported 0 vulnerabilities.
- Production Supabase remains unchanged. Development completion estimate is not a launch-readiness certification.


- CI initially caught escaped template-literal delimiters in the new SECURITY DEFINER contract test; corrected in the follow-up commit. Follow-up CI is now green; the test is included in 45 passing files / 167 passing tests.


- Refreshed migration reconciliation on 2026-11-16: 42 source SQL files vs 30 Production migration rows; only 4 exact timestamp-prefix matches. Full inventory and no-same-version Production entries are recorded in `docs/MIGRATION_RECONCILIATION_MATRIX_2026-11-16.md`. This is a blocker, not authorization to apply migrations.


## Source safety batch — financial feature fail-closed defaults (2026-11-16)

- Updated 20261116080000_financial_activity_lockdown.sql so rollout explicitly forces package activations, Bid Wallet, Income Wallet, referral commissions, withdrawals, bidding, Fixed Bid and winning-payment switches to false, overriding permissive legacy defaults.
- The ordinary Admin feature RPC still cannot enable financial features unless the trusted financial_model_approved setting is already true. The migration deliberately does not overwrite that approval key; an explicit owner approval must remain durable and cannot be created by an ordinary Admin toggle.
- Added regression assertions for every fail-closed feature default and for preserving the owner-approval setting.
- Latest source commits: a19cf18 (initial batch) and 9728058 (preserve explicit owner approval). Latest CI for 9728058 is running; no pass is claimed yet.
- This is source-only. No Production Supabase settings, schema, rows, wallets or financial transactions were changed. The Production project still requires a separate reviewed forward-only migration rollout after migration reconciliation and owner approval.
