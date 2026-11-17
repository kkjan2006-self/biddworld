## Duplicate ID lifecycle RPC deployment feedback — 2026-11-17

- Duplicate ID creation and status transitions now use the shared missing/stale RPC classifier and show action-specific deployment guidance.
- Ordinary errors continue to show their underlying message; duplicate status no-op behavior remains unchanged.
- Regression tests updated for both Duplicate ID lifecycle guidance and the existing two-argument placement-attribution RPC contract.
- CI run `43997847013` passed on commit `461382876f09e2b78e89f7bf453f3dfd1f667d9c`: all tests, TypeScript type-check, and production build passed.
- No Main ID lifecycle or cascade behavior was added; Production Supabase remains unchanged.

## Admin Member Management RPC deployment feedback — 2026-11-17

- Admin member profile editing, sponsor changes, and paginated Main ID directory search now distinguish missing/stale RPC deployments from ordinary errors and show an actionable administrator-facing message.
- Existing error behavior remains for unrelated permission, validation, and network failures.
- Updated regression assertions for the member directory pagination request lifecycle after the error copy change.
- CI run `43997409594` passed on commit `64bd2e825eece0fc7f7c00c20bab31bd307a158f`: all tests, TypeScript type-check, and production build passed.
- This batch changes frontend diagnostics only. No account status, Main/Duplicate ID lifecycle, sponsor records, commissions, wallet records, or Production database objects were changed.

## Member account identity and ID-list RPC feedback — 2026-11-17

- Member Account now distinguishes missing/stale deployment of `member_get_my_identity`, `member_list_my_ids` and `member_list_my_withdrawals` from ordinary history-query failures.
- Existing generic account-history errors remain for table/query failures and non-contract errors; no wallet, activation, bid or commission data is changed.
- Regression coverage added to the member dashboard initial-load tests.
- CI run `43997033647` passed on source commit `7d31323cd46a84df80767b7644ce2c6e9c17bbc8`: tests, TypeScript type-check and production build all passed.
- Production Supabase remains unchanged; no RPC migration was applied.

## Member-facing RPC deployment guidance CI verification — 2026-11-17

- GitHub Actions run `43996743591` passed on commit `e8ecb18ba6e3dcbdfae4b6742472e603bf1c5e56` (`completion-work`).
- Dependency installation, dependency security report, tests, TypeScript type-check and production build all completed successfully.
- The source-only UX improvements are verified; unavailable database functions remain unavailable until a separately tested migration rollout.
- Production Supabase was not modified.

## Member-facing RPC deployment guidance — 2026-11-17

- Added a shared user-facing message formatter on top of the existing RPC-contract mismatch classifier.
- The member team dashboard now distinguishes a missing/stale `get_my_mlm_dashboard_page` deployment from ordinary authorization, validation, and network errors on initial load and pagination.
- Member profile editing now explains when `member_update_my_profile` is unavailable because its database RPC migration has not been installed.
- Added regression coverage for the actionable deployment guidance and for not misclassifying ordinary permission errors.
- This is frontend resilience only. It does not install the missing Production RPCs or alter member records, wallet data, Auth, Storage, or Production schema.

## Frontend RPC mismatch feedback CI verification — 2026-11-17

- GitHub Actions run `43996275259` passed on commit `89791ba8b4cfbad1f9a1ec81349ebedea467a044` (`completion-work`).
- Dependency installation, dependency security report, test suite, TypeScript type-check and production build all completed successfully.
- This validates the source-level RPC mismatch classification and UI feedback regression tests; it does not install or execute the pending Production RPC migrations.
- Production Supabase schema, member records, Auth accounts, Storage, settings and financial records remain unchanged.

## Frontend RPC deployment-mismatch handling — 2026-11-17

- Added shared `src/lib/rpc-errors.ts` detection for PostgREST `PGRST202`, PostgreSQL `42883`, and equivalent missing/stale function-schema messages.
- Signup sponsor lookup now distinguishes an unavailable/stale RPC from an invalid Sponsor ID and presents the existing unavailable state rather than incorrectly marking the ID invalid.
- Auction bidding and Admin Duplicate ID creation now show a clear backend-migration-pending message when the deployed RPC signature is missing or stale. Other authorization, validation and network errors retain their existing handling.
- Added regression tests for RPC error classification and Duplicate ID mismatch feedback.
- Reconciliation result: the Sponsor lookup helper already accepts both Production's legacy table response and the source boolean response, and deliberately ignores returned display names. The two-argument Duplicate ID creation and idempotent two-argument `place_bid` contracts cannot safely fall back to the old Production signatures; keep those operations blocked until the ordered migration chain is tested and deployed.
- No Production migrations, member data, wallet data, Auth accounts or settings were changed.

## Duplicate ID no-op feedback and refresh behavior — 2026-11-17

- Admin now consumes the status RPC's `changed` result. When the selected Duplicate ID already has the requested status, the UI reports that no change was needed and does not trigger an unnecessary full refresh.
- Real status transitions retain the success message and refresh the directory. Added regression assertions for both paths.
- This is frontend behavior layered on the source-only no-op migration. Production remains untouched.

## Duplicate ID status no-op safety — 2026-11-17

- Added source-only forward migration `20261117130000_admin_duplicate_status_noop_guard.sql` for `admin_set_duplicate_id_status`.
- The RPC now returns `changed: false` without updating the member ID or creating an audit row when the requested status already matches. Real status transitions retain the existing row lock, Admin authorization, audit event and closed-ID no-reactivation rule.
- Added regression tests for no-op behavior and preservation of lifecycle protections.
- Migration is not applied to Production. Main ID/profile/linked Duplicate ID cascade rules remain intentionally unimplemented until specified.
- CI for the preceding commit `e6aeca626172fdbdb7317fc51e56aa69da00f121` passed (run `43995699435`). CI for this new batch is triggered by the latest commits and must complete before claiming validation.
- No Production data, schema, Auth accounts or settings were changed.

## Admin profile RPC no-op protection and latest CI verification — 2026-11-17

- Latest CI run `43995371854` passed on `ea9f67949d6f9153df0885975390a2483df9d668`; tests, TypeScript type-check and production build all completed successfully.
- Hardened `admin_update_member_profile` so the server compares locked values and returns `changed: false` for unchanged submissions without updating `updated_at` or creating an audit row. Real changes continue to generate one field-flag-only audit event.
- Added a regression test for server-side no-op handling. Migration remains source-only and has not been applied to Production.
- No Production schema, settings, Auth accounts, member records or financial records were changed.

## Admin member profile editing verification and UX hardening — 2026-11-17

- Latest CI for the profile-editor implementation passed on commit `586a749db0de67e9129d61a1a5e4acc9a9845c1d` (GitHub Actions run `43994891990`).
- Read-only Production schema inspection confirmed the profile fields, Main ID ownership fields and `audit_logs` columns used by the source-only profile-edit migration.
- Added a Reset changes action and disabled no-op saves in the Admin profile editor; regression tests cover both behaviors.
- The profile-edit migration remains unapplied. Production schema and data were not changed. A disposable Supabase test project is still required for live migration/RPC execution before rollout.

## Admin Member Profile Editing CI correction — 2026-11-17

- First CI run for the profile-editor batch exposed two expected source-contract updates: the Admin View details handler now initializes the edit form, and the frontend RPC inventory must include `admin_update_member_profile`.
- Updated `tests/admin-member-detail-search-selection.test.ts` to assert the expanded View details handler.
- Updated `docs/FRONTEND_RPC_INVENTORY.json` to include the new RPC call site and source snapshot.
- Updated `docs/FRONTEND_PRODUCTION_RPC_MATRIX_2026-11-17.md`: source inventory is now 45 names and the new profile RPC is explicitly recorded as missing from Production until a test-environment rollout.
- The initial CI failure was in tests only; TypeScript/build were skipped by workflow dependency. A fresh latest-HEAD CI run is required.
- No Production database or data was changed.

## Admin Member Profile Editing — 2026-11-17

- Added an Admin-only edit form to the existing Main ID detail panel for profile name and phone.
- Added source-only forward migration 20261117120000_admin_update_member_profile.sql; server-side Admin JWT authorization, Main ID resolution, profile-row lock, input validation and audit logging are enforced in the RPC.
- Frontend calls the RPC and updates the current directory row without resetting applied search or pagination.
- Added tests/admin-member-profile-editing.test.ts and docs/ADMIN_MEMBER_PROFILE_EDITING_2026-11-17.md.
- Profile editing excludes Auth credentials, role, sponsor, wallet and account/ID status. Lifecycle cascade rules remain unresolved and are not invented.
- Migration is not applied to Production. No Production data, schema, settings or Auth accounts were changed. CI is required on the final commit.

## Fresh continuation audit — 2026-11-17

- Re-verified `completion-work` HEAD: `74a08fc7b42e0a707ad98ccae679195f54cbc8f4`.
- Latest GitHub Actions run for that exact HEAD: `43993043162`, conclusion `success`.
- Re-read the complete 1,228-line project completion register and recursively inspected the 223-path source tree.
- Read-only Production inspection: 30 migration-ledger rows versus 42 source SQL migration files; 21/21 public tables have RLS enabled; Production Storage has zero buckets.
- Reconciled the 44 literal frontend RPC names against the Production public function catalogue: eight RPC names are missing; three additional present-name contracts have known signature/return-shape mismatches. Full matrix: `docs/FRONTEND_PRODUCTION_RPC_MATRIX_2026-11-17.md`.
- Admin Member Directory currently has bounded server-side search, pagination, CSV export, sponsor correction and read-only member detail. Profile editing and Main ID account lifecycle actions are not implemented.
- Production status constraints permit pending/active/suspended/closed for both profiles and member IDs. The Main ID/profile/linked Duplicate ID cascade and login/session behavior are not specified; do not invent these rules.
- No source implementation or Production changes were made during this audit. The next safe Member Management batch can add Admin profile editing with audit logging, while lifecycle transitions remain gated on the owner-defined cascade behavior.
- Production remains untouched. No deployment was initiated.

## Admin wallet ledger export safety — 2026-11-17

- Wallet ledger CSV export now uses the shared bounded pagination helper, including repeated-page detection and the 100,000-row export cap. Download creation occurs only after all pages pass validation.
- Existing read-only RPC and CSV field set are preserved; export progress/error feedback is shared with Admin report exports.
- Added `tests/admin-wallet-ledger-export-safety.test.ts` and `docs/ADMIN_WALLET_LEDGER_EXPORT_SAFETY_2026-11-17.md`.
- Static source-contract coverage only; no live wallet RPC or Production data was accessed or changed.

## Admin member detail search consistency — 2026-11-17

- Both Admin member-directory search controls now clear the selected member-detail panel immediately when the query changes, avoiding stale detail display across different result sets.
- Explicit View details selection remains available for the currently displayed member records.
- Added `tests/admin-member-detail-search-selection.test.ts` and `docs/ADMIN_MEMBER_DETAIL_SEARCH_SELECTION_2026-11-17.md`.
- Static source-contract test only. No live Supabase RPC, Production data, member status, account lifecycle, or database schema was changed.

# BiddWorld project completion register

Last source inspection: 2026-11-16  
Repository: `kkjan2006-self/biddworld`  
Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`)

This register is an implementation inventory, not a claim of launch readiness. It distinguishes working UI, draft/read-only workflows, missing business logic, and work that depends on owner decisions. Do not enable money movement or alter production data while completing the remaining work.

## Existing application surfaces

| Area | Current implementation | Remaining work |
|---|---|---|
| Public marketplace | Responsive React/Vite shell, live auction listing query with deterministic 100-row server pages and Load More, full-text search over loaded records, dynamic category filter, price/ending sort, 9-item client pagination, listing detail modal; Products tab reads active product catalogue in deterministic 100-row server pages with Load More, loaded-record search and explicit load-error/retry messaging; Admin product drafts, publish/hide RPC source and product-media upload are present | Public About, How It Works, FAQ, Contact, Privacy-information and Terms-draft pages with footer navigation; search across not-yet-loaded pages, final owner/legal policy approval, Production RPC/Storage migration reconciliation |
| Authentication | Supabase email/password signup/signin, phone/name metadata, sponsor lookup, password update, global signout, password reset/recovery, self-only profile editing; registration now provisions an inactive Main ID and profile, and only an Admin-approved package activation changes inactive status to active (migration prepared, not applied) | Apply and review the lifecycle migration only after package economics/legal approval; email confirmation/resend flow added to signup; authenticated email-change request with Supabase verification added to Account Security; session expiry/error handling, account lifecycle and privacy consent |
| Member dashboard | Profile self-service editing with client-side validation matching server constraints and exception-safe save state, read-only identity and sponsor summary, Main/Duplicate ID listing, package activation history, wallets, team genealogy, bids, commissions, withdrawals, security, winner/delivery history; activity panels now use deterministic Load More pagination (50 activation rows and 100 bid/Fixed Bid/commission/winner rows per page); complete personal CSV export fetches all activity pages and linked delivery records | Reconcile missing member identity/profile RPCs with Production; team genealogy pagination, richer profile settings, accessible/mobile navigation and consistent loading/error/empty states |
| Packages | Active package catalogue and payment-reference submission RPC | Receipt upload/storage and policies, member activation history UX, retry/idempotency UX review, refund/cancellation workflow and owner-approved activation rules |
| Wallet | Bid/Income balances, paginated read-only ledger and complete Main-ID wallet statement CSV export; Admin complete wallet-ledger export; no client-side balance writes | Owner-defined financial model, secure server-side ledger flows after approval, reconciliation/adjustment controls and audit detail |
| Referrals / MLM | Main-ID genealogy dashboard and summary RPC; admin sponsor correction and plan draft editor | Automatic commission calculation/posting engine, eligibility snapshots, reversal/refund handling, plan activation/version selection, complete team pagination and duplicate attribution rules |
| Duplicate IDs | Admin create pending ID with mandatory Under / Placement ID, preserve Sponsor separately, placement parent saved on the Duplicate ID, Admin queue displays Under ID and owner Main ID; member-owned ID RPC displays Sponsor and Under IDs separately; Admin creation now serializes graph mutations with a transaction-scoped advisory lock before row locks | Placement-tree lineage snapshots for each qualifying package activation, automated placement-based commission attribution and reconciliation for every Admin-configured plan level (no fixed five-level limit), owner-defined limits and placement rules, live PostgreSQL concurrency verification and lifecycle history; no commission or wallet posting implemented by this placement change |
| Auctions | Admin product/auction draft creation; public live/scheduled listing; bid RPC with wallet-first locking | Product media upload, complete editing/publishing/scheduling/cancel/close flow, anti-sniping/tie/extension rules, bid history; member auction activity now shows bid status counts and related auction start/end schedule and winner selection/settlement |
| Fixed Bid | Campaign read-only listing restricted to scheduled/live/ended statuses; deterministic 50-row pagination with Load More; admin campaign draft creation/editing | Owner-defined entry price/charge, entry submission, caps, tie/winner algorithm, cancellation/refunds, settlement and member history with entry-status summary and campaign status/date details |
| Winning items | Member/admin read-only payment registers; delivery tracking save RPC/UI | Winner selection, Income Wallet payment/settlement, payment failure/refund handling, courier update lifecycle, notifications and member support |
| Withdrawals | Member request submission RPC and history; Admin read-only request queue | Owner-defined min/max/fees, approve/reject/review workflow, payout provider/integration, payout reconciliation, failure/refund handling and audit coverage |
| Admin members/sponsors | Member directory with Admin-checked 100-row RPC pagination and Load More, server-side search, CSV export, detail panel (status, sponsor, registration date, placement and linked Duplicate IDs), Admin profile name/mobile editing via an audited source-only RPC, sponsor changes/default sponsor, structure report | Verify profile-edit RPC on a disposable Supabase project; account status actions and safe Main ID/profile/linked Duplicate ID lifecycle remain pending owner-defined behavior |
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


## Public information pages batch — 2026-11-16

Added public How It Works, Privacy information and Terms draft views and footer navigation to all public information pages. Privacy and Terms are explicitly marked as incomplete drafts; they are not legal policies and must not be represented as approved or launch-ready. No database or Production changes were made.


## Authentication completion batch — 2026-11-16

Signup now distinguishes email-confirmation-required responses from immediate sessions and offers a resend-confirmation action using Supabase Auth. User-facing confirmation status is announced accessibly. This does not change Production Auth settings or bypass email confirmation. Session-expiry and consent lifecycle work remain open.


## Member account security batch — 2026-11-16

Account Security now displays the authenticated email address and lets the member request an email change through Supabase Auth. The UI does not directly overwrite profile email fields; the new address is subject to Supabase's configured verification flow. Password update and global sign-out remain available. Production Auth settings were not changed.


## Admin member directory search batch — 2026-11-16

Member Directory now submits search terms to `admin_list_members_sponsors_page` from the server, resets pagination when a new search is applied, and carries the applied query into Load More. A Clear action restores the unfiltered first page. This avoids implying that browser-side filtering of only the currently loaded 100 records searches the entire directory.


## Member wallet statement usability batch — 2026-11-16

Wallet History now supports transaction-type selection and description/reference search alongside existing wallet, direction and UTC date filters. It reports the number of matching loaded records and provides one action to clear all filters. The UI explicitly distinguishes loaded-record filtering from the full Main-ID CSV export, which continues retrieving all records before applying the selected filters. No wallet mutation or financial RPC was added.


## Member communications and Fixed Bid discovery batch — 2026-11-16

Notifications now provide loaded-record title/message/category search and category filtering, with a single clear-filter action and matching-result count; unread filtering remains explicit and scoped to loaded inbox records. Support now states how many loaded requests match its search/status filters and provides a clear-filter action. Fixed Bid campaign discovery now reports matching loaded campaigns and provides a clear-filter action. These changes are presentation/read-only improvements; no new database columns, RPC assumptions, financial actions or Production changes were introduced.


## Environment isolation and signup verification configuration — 2026-11-16

- Removed the browser client's implicit fallback to the live Production Supabase URL and publishable key. An unconfigured preview now stays disconnected instead of silently reading/writing Production.
- Added explicit `preview`, `test` and `live` build modes. Test mode refuses the known Production project reference; Live mode accepts only the approved Production project reference.
- Documented that email-confirmation enable/disable is controlled by Supabase Auth project settings, not a client-side switch. Disable it only in a separate disposable TEST project; require it enabled in LIVE.
- A separate test Supabase project is not currently confirmed as available. No test records were inserted, no hosted Auth settings were changed, and Production was not modified. Test execution remains blocked until the isolated project is provisioned.


## Explicit environment visibility — 2026-11-16

- The application header area now displays a persistent environment banner: Preview, Test or Live. Test mode warns against real member/payment information; Live mode warns that real member data may be present.
- Supabase configuration failures now display the specific configuration/safety error from the environment guard instead of only a generic Preview notice.
- This is a client-side environment indicator, not an authorization boundary. Database RLS, trusted server-side role checks and financial interlocks remain mandatory. No Supabase project settings or Production data were changed.


## Notification loading reliability — 2026-11-16

- Member/Admin notification inbox initial loading and Load More now use exception-safe busy-state cleanup and preserve actionable errors if a request rejects unexpectedly, rather than leaving the inbox stuck in a loading state.
- No database, Supabase Auth settings, Production records or financial workflows were changed. Tests remain deferred.


## Support workflow resilience — 2026-11-16

- Support inbox initial load and pagination now clean up busy state even when requests throw unexpectedly and retain a useful error for retry.
- Member ticket submission and Admin response/status updates now use exception-safe cleanup, so the form does not remain stuck after network/runtime failures.
- These changes preserve existing RLS/RPC authorization and do not add email/SMS dispatch, attachment storage, or new status permissions. No Production data/settings or financial flows were changed.


## Member workspace resilience and environment guidance — 2026-11-16

- MLM dashboard now uses one debounced, cancellation-safe request path for initial loads, refresh, search and depth filters; stale responses cannot replace newer filter results.
- MLM genealogy pagination now handles thrown request failures and always releases its loading state when the active request completes.
- Account and package empty-configuration messages now direct operators to the selected Preview/separate Test environment rather than encouraging a Production connection for testing.
- Paid package activation remains fail-closed. No database settings, schema, member data or financial records were changed. No tests were run in this development-only batch.


## Notification workflow reliability — 2026-11-16

- Notification inbox load, pagination, Admin send, individual read and mark-all-read now handle rejected requests with actionable errors and guaranteed busy-state cleanup.
- Existing RLS and database operations are unchanged. No Production database changes or financial actions were performed. Tests remain deferred.


## Wallet history and placement tree resilience — 2026-11-16

- Wallet transaction history handles rejected profile/ledger requests and always clears initial/pagination loading indicators; stale requests remain cancellation-safe.
- Placement tree loading now reports actionable errors and always clears its loading state, including when the RPC rejects.
- Read-only behavior and existing database permissions are unchanged. No Production data/schema/settings or financial actions were changed. Tests remain deferred.


## Admin catalogue, auction and Fixed Bid workflow resilience — 2026-11-16

- Delivery tracking save, Fixed Bid draft save, product draft save/publication, and auction draft save now handle rejected RPC requests with visible errors and `finally`-based busy-state cleanup.
- Successful save behavior and draft-only safeguards are retained; no auction or Fixed Bid campaign was activated and no financial transaction was performed.
- No Production schema, settings, or data were changed. Tests remain deferred.


## Admin member-finance configuration workflows — 2026-11-16

- Duplicate ID creation and status changes, referral-plan draft saves, package draft saves, and package-payment review now handle rejected RPC requests with clear errors and guaranteed busy-state cleanup.
- Added non-negative numeric validation for referral reward drafts and package price/proposed credit inputs.
- Package approval remains locked by the existing owner financial/legal interlock; no wallet credits, commissions, or package activations were issued.
- No Production schema, settings, or data were changed. Tests remain deferred.


## Admin sponsor and product-media workflow resilience — 2026-11-16

- Default sponsor and member sponsor updates now catch rejected RPC calls, show actionable errors, and always release the shared busy state. Successful member sponsor changes still refresh the Admin data; existing commission records are explicitly unchanged.
- Product image upload and temporary-image cleanup now handle Storage/network exceptions and always release the upload busy state. A staged image path is retained when cleanup fails, and replacing a staged image reports cleanup failures without discarding the newly uploaded image.
- Existing draft-only product behavior and Storage bucket/policy requirements are unchanged. This is source-only; no Production Storage or database settings/data were changed. Tests remain deferred as requested.


## Member and marketplace async loading resilience — 2026-11-16

- `src/components/Account.tsx`: the initial member-account loader now handles rejected Auth/profile/RPC/parallel history/Delivery requests, provides safe retry-oriented messages, fails closed when withdrawal availability cannot be confirmed, and always clears the initial loading state through `finally`. Partial history query errors remain visible instead of being silently treated as a fully successful load.
- `src/App.tsx`: initial Auth lookup now catches rejected requests and avoids a stale initial lookup overwriting a newer Auth state event; subscription cleanup prevents updates after unmount. Public product and auction initial-load effects now catch rejected promises, preserve stale-request cleanup, reset pagination flags on failure, and recover wallet display state safely.
- Commits: `669ed550f9aa8465096a6f01d67c680310887795` (Account) and `c723d335313be7258a8c523bc252278e8fca322e` (App).
- Source-only changes on `completion-work`. No Production SQL, settings, Storage, member records, wallet balances, commissions, payments, or payouts were changed. No manual test campaign was started in this development phase; compilation and regression verification remain pending for the dedicated verification phase.


## Member search consistency and CI correction — 2026-11-16

- Admin member directory now records the applied server-side search term when the debounced first page loads. Load More and the complete CSV export reuse that exact applied term, so editing the search input cannot silently mix records from different queries.
- Updated the pagination regression assertion to check the applied search contract. Updated the member report source assertion to follow the scoped Supabase client used by the exception-safe loader/export.
- CI initially exposed two stale test assumptions and the applied-search mismatch. Follow-up correction is committed; latest source commit `1ee9b7257386c2edba784a4df3e14f6bc63ec37b` passed GitHub Actions run `43843577708`: **49 test files / 187 tests passed**, TypeScript type-check passed, Vite production build passed, and npm audit reported **0 vulnerabilities**.
- No Production database, Auth, Storage, settings, member records, wallets, commissions, payments or payouts were changed. This CI result verifies repository tests/build only; it is not Production integration or launch certification.


## Fixed Bid catalogue request lifecycle — 2026-11-16

- Added a synchronous in-flight guard so rapid taps cannot start overlapping Fixed Bid catalogue page requests before React updates the disabled button state.
- Added request identity and mounted-component guards so stale responses and responses after unmount do not update the UI.
- Loading and pagination busy indicators are released in `finally`, including rejected requests; existing read-only catalogue behavior, page size, filters and server ordering are preserved.
- Added regression assertions for overlap prevention, stale/unmounted response guards, and busy-state cleanup.
- Source commits: `3c2e287b40a355c1d9827b71d3eff5d366c4fb3d`; test commit: `d9e2f390b0946d4718cf3463ab15e158f2890d9e`.
- This is a source-level resilience change only. No RPC, schema, Production data/settings, wallet or financial behavior was changed. CI verification for this batch is pending.


## Package catalogue request lifecycle — 2026-11-16

- Package catalogue reads now use request identity and mounted-component guards. A newer retry supersedes an older response, and responses completing after unmount cannot update component state.
- Network/query failures clear stale catalogue rows, show a retry-oriented error, and release the loading indicator only for the active request.
- Added regression assertions for stale/unmounted request protection, loading cleanup and the existing package activation lock.
- Source commit: `def68a7e30f33783b96832161df90425a7df0226`; regression test commit: `98936ac0bd2822a72968c7f8918980a58b9dab58`.
- No package activation, payment, wallet credit, commission, RPC, schema, Production data or settings were changed. CI for this batch is pending.


## Admin report pagination recovery — 2026-11-16

- Admin audit-log, wallet-ledger and withdrawal-request Load More operations now catch rejected RPC/network promises, preserve an actionable error message, and always release their busy indicators in `finally`.
- Successful page append, bounded 100-row paging and existing read-only behavior are unchanged.
- Added regression tests for all three rejection/cleanup paths.
- Code commit: `fa9aa339c0f4343acfa1dfe76ff339d9eabec549`; test commit: `0e7115c140a89d43b3ea105988204f864a0a2416`.
- The previous Package catalogue code, test and register CI runs all completed successfully: runs `43845691811`, `43845747538`, and `43845771972`. This new Admin batch CI is pending.
- No SQL/RPC, schema, Production data/settings, wallet balances, commissions, payments, withdrawals or financial activation controls were changed.


## Public catalogue and member wallet lifecycle batch — 2026-11-16

- Public auction and product catalogue page requests now use request identities and synchronous in-flight locks. Duplicate Load More taps cannot issue overlapping requests; a query refresh or newer first-page request invalidates an older continuation response so stale rows cannot be appended to the wrong catalogue state.
- Wallet History now prevents an initial Auth lookup from overwriting a newer Auth state event, catches rejected session lookups, prevents duplicate pagination requests before React updates the disabled state, and releases the in-flight lock after success or failure.
- Added regression tests for auction/product stale-response and duplicate-request guards, Wallet History auth ordering, pagination cleanup and read-only Main-ID scoping.
- Source commits: `0dd38d2cb94b4ddf7a4dad98d454c4142e391c5d`, `ae28969cb60b6e201e1620d00b82cff0221f06ea`, `5be245866f412cf0f119065c7ee1ddca7ce9735d`; regression test commits: `5b6fb59192fb5ad5087a8802f51c1a59de592d64`, `b51d65e7087e7c8a728f97cacebcffbd773fff69`, `ad27de46fa44d36467290a3cce3cbd72aa2f38df`.
- This is source/test-only. No RPC, schema, Production Supabase data/settings, wallet balances, commissions, payments, bids, withdrawals or financial controls were changed. CI verification is pending.


- CI follow-up correction: the first run exposed an outdated navigation test assertion after pagination was moved into a guarded handler, plus a missing handler insertion caught by the new lifecycle test. The guarded handler is now explicitly present, and the no-session path also releases the pagination lock. The corrected test and build run is pending; earlier failed CI runs are retained as failure history, not represented as passing.


## Member workspace async lifecycle batch — 2026-11-16

- Notifications inbox: refresh requests now invalidate older page requests; Load More uses a synchronous in-flight guard; stale responses cannot append to refreshed data; unmount invalidates pending requests.
- Support queue: same refresh/page request sequencing and synchronous pagination lock, with stale-response protection and unmount invalidation.
- Referral dashboard: Auth event ordering is protected against a late initial session lookup; team pagination uses a synchronous lock and stale request identity so an older page cannot append after filters or refresh change.
- Added `tests/member-workspace-request-lifecycle.test.ts` for Notifications, Support and Referral request lifecycle guarantees.
- Source commits: `96bdb6492334a649e48283f654897e87066b46f5`, `bfa608235c64c9ec02eb9e2436e87c4ce8c149a4`, `9502da15745dac0f13d32d369babb6c8a8cf594d`, `7267465bcfe88c99008304fb5d2252635830e8b7`, `d05fde82ade20f20826565e2384b81028357de44`; test commit: `101cd5017fc0e565f980972d23bf9af160c199f3`.
- No business rules, financial configuration, RPC definitions, database schema, Production Supabase data/settings, wallet balances, commissions, payments, bids or withdrawals were changed. CI verification pending.

- Additional UI resilience in this batch: Placement Tree now presents an explicit Retry action when its secured tree RPC fails; regression coverage was added. Commit: `bb5ddf8ea1e63f073236a523b49ffe03d9a62d50`; test update: `dc966d577c682f0fe004c3af671eb0704f402602`.


## Public catalogue recovery and RPC inventory refresh — 2026-11-16

- Added accessible Retry actions to the public Auctions and Products first-page error states; retry resets the visible page and refreshes both catalogue requests without changing any backend or financial behavior.
- Updated the frontend RPC manifest from all ten React surfaces: 44 literal RPC call/surface entries at source snapshot `39320b8814fe7e33a50513772336803a73b2b5cb`. Existing completeness tests compare the manifest against the current source.
- Production RPC gaps remain blocked by the read-only snapshot documented in `FRONTEND_PRODUCTION_RPC_AND_ADVISOR_REVIEW_2026-11-16.md`; refreshing the source manifest does not certify Production availability.
- Public catalogue source commit: `a86cde57920ed7eff62cf633d822f7035696059f`; test commits: `ce49f27e1d39afdf2be284728ff3e2e271e45adc`, `39320b8814fe7e33a50513772336803a73b2b5cb`; RPC inventory commit: `e651ec63eaaf8764be7c83bb4bfbb33a9dc7fb85`.
- No Production database, migration ledger, Auth, Storage, financial settings, wallet or member data was changed.


## Admin workspace resilience — 2026-11-16

- Admin initial workspace loading now catches rejected RPC/query promises, displays an actionable load error and always clears the loading state while mounted.
- Admin Auth initialization now ignores a late `getSession()` result after an Auth state event and safely handles a rejected session lookup, avoiding an unhandled rejection or stale role overwrite.
- Added regression coverage in `tests/admin-initial-workspace-resilience.test.ts` for rejected initial requests, loading cleanup, unmount safety and Auth event ordering.
- These are frontend resilience changes only. Admin role authorization remains enforced server-side; no Production database or financial behavior was changed.

- The Admin overview now exposes a keyboard-accessible Retry action directly in the alert when its initial workspace load fails; this complements the existing header refresh action.


## Fixed Bid requirements audit — 2026-11-16

- Re-audited `completion-work` at source HEAD `a81e1f08362f26bf64cf8c1760528d83dffb87f6`.
- Captured the owner's confirmed Fixed Bid rules, current schema/UI gaps, backend safety requirements and delivery gates in `docs/FIXED_BID_IMPLEMENTATION_CONTRACT.md`.
- Confirmed the baseline `fixed_bids` uniqueness constraint conflicts with unlimited entries; the campaign schema currently has no explicit time-vs-entry-target close mode; member catalogue is read-only and has no target progress display.
- Confirmed the financial activity lock still blocks Fixed Bid entry inserts and the feature flag is fail-closed. These safeguards were not changed.
- Confirmed the checked auction draft migration does not define the Fixed Bid Admin RPCs currently called by the UI. Their source definitions and actual Production signatures need reconciliation before implementation.
- Special Winner eligibility remains an owner decision (entrant-only vs any registered member), so that single rule is intentionally not guessed.
- Documentation only. No application code, schema, migrations, Production Supabase data/settings, financial ledger, entries, refunds, winners or feature flags were changed. No tests or CI are claimed as run by this documentation update.


## Fixed Bid catalogue status correction — 2026-11-16

- Corrected the member Fixed Bid catalogue to query the actual `auction_status` enum value `active` rather than the nonexistent `live` value. The UI continues to display the friendly label “LIVE”.
- Updated the status filter to use `active` internally and updated the regression test accordingly.
- This is a read-only catalogue correction; no entry, payment, winner, refund, feature-flag, schema or Production data workflow was enabled.
- Changes are source-only on `completion-work`; CI status must be checked separately before calling the change verified.


## Production schema reconciliation correction — 2026-11-16

- Read-only inspection of the actual `BiddWorld-Production` project (`hbqatszyzqobgtauyuzy`) showed that the live `fixed_bid_campaigns.status` is text constrained to values including `scheduled`, `live`, `paused`, `ended` and `cancelled`. The old repository baseline `0001_biddworld.sql` instead declares a different `auction_status` enum with `active` and no `live`.
- The interim catalogue change that queried `active` was therefore incorrect for the connected Production schema and has been reverted. The member catalogue and regression test again use `live`.
- Production's actual `fixed_bids` table has `member_id`, `bid_amount`, `status` and a unique `idempotency_key`; no per-member-per-campaign uniqueness constraint appeared in the table metadata. The baseline repository schema is not authoritative for this project state.
- The Production `fixed_bid_campaigns` table uses a `configuration jsonb` column and does not expose the legacy baseline's `entry_amount`, `starts_at` or `ends_at` columns. Existing Admin draft RPCs were confirmed by read-only `pg_proc` inspection.
- No Production data, schema, migrations, RPCs, feature flags or financial settings were modified. All inspection queries were SELECT-only.


## Fixed Bid Production audit — 2026-11-16

- Confirmed the live Production schema and Admin RPCs using read-only metadata/catalogue queries. The live campaign table uses `configuration jsonb` and text statuses (including `live`); the old baseline migration is not the live schema contract.
- Confirmed the live entry table has no per-member-per-campaign unique constraint, but only a unique idempotency key; Production RLS has no INSERT policy for `fixed_bids`.
- Confirmed no Fixed Bid entry/draw/special-winner/refund RPCs exist in the Production function catalogue. Admin draft RPCs exist but only save/list draft campaign metadata.
- Confirmed `fixed_bid_enabled=false` and `winning_payment_enabled=false`. Wallet feature settings are currently true; the source-only financial activity lockdown migration is not in the current Production migration ledger and must not be assumed active.
- Confirmed migration drift: Production ledger lists 30 migrations and includes `20261115151930_admin_fixed_bid_campaign_draft_management`, while the source tree has 43 migration files and lacks that exact migration file. No migration was applied.
- Restored the member catalogue status query to `live` to match Production. This correction is in source only; the latest CI result will be checked separately.
- All Production inspection was read-only. No production schema, rows, RPCs, flags, wallets, entries or financial records were changed.


## Production/source migration reconciliation — 2026-11-16

- Compared the live Production migration ledger (30 entries) with the current `completion-work` source tree (43 SQL files: 40 timestamped and 3 unversioned legacy/baseline files).
- Classification: 4 exact version+name matches; 9 same-slug migrations with different timestamps; 17 Production ledger entries with no same-slug source file; 27 timestamped source migrations not represented in Production by version or slug; 3 unversioned baseline files.
- Added `docs/PRODUCTION_SOURCE_MIGRATION_RECONCILIATION_2026-11-16.md` with the exact comparison lists and a safe forward-only reconciliation sequence. Filename similarity is not treated as SQL equivalence.
- No migrations were applied and no Production schema, settings, Auth, Storage, member, financial or other data were changed. The Production database remains read-only for this audit. The source financial interlock is not active in Production unless separately reconciled and applied through an approved rollout.


## Production financial interlock risk — 2026-11-16

- A further read-only Production audit found `package_activations_enabled=true` and `bid_wallet_enabled=true`, with no `financial_model_approved` setting row.
- The live Admin package-review SECURITY DEFINER RPC can approve a pending package activation, credit the Bid Wallet ledger and activate the Main ID. The existing Production feature-gate triggers consult the two settings above, which were both true at audit time. The requested owner financial approval guard is source-only and absent from the Production migration ledger.
- **Do not use Admin package approval in Production** until the financial interlock has been reconciled and installed under an explicitly approved rollout. No settings were switched off and no package, member or wallet records were changed because Production changes have not been authorized.
- Additional catalogue snapshot: all 21 public tables have RLS enabled (none FORCE RLS); `notification_templates` has zero direct policies; `fixed_bids` has owner-only SELECT and no INSERT policy; ten feature-gate triggers were found. See the migration reconciliation report for the complete point-in-time details.


## 2026-11-16 — Financial RPC read-only audit and CI repair

- Reviewed live Production definitions for package approval, feature toggles, wallet reporting and withdrawal request/list RPCs; no Production writes were performed.
- Confirmed live package approval can credit Bid Wallet and activate a package without the source-only trusted owner-approval guard.
- Confirmed live feature-setting RPC has no trusted owner-approval check and can enable package activation/Bid Wallet/Income Wallet.
- Confirmed live withdrawal request checks current Income Wallet balance under row lock and prevents a second open request, but does not reserve/debit funds, enforce a configured minimum, or independently verify active Main-ID status.
- No Admin withdrawal settlement mutation RPC was found in the inspected public RPC catalogue; the Admin RPC found is list-only.
- Source/UI financial approval lock remains in place. Do not approve package activations, post credits, enable financial settings, or process withdrawals in Production.
- New evidence report: `docs/PRODUCTION_FINANCIAL_RPC_REVIEW_2026-11-16.md`.
- CI regression test briefly failed because the new assertions did not load `Admin.tsx`; fixed in commit `f2bce4c5b9e8608a91a3d13d8064d1aa86bc3dbe`. CI run `43854387609` passed on that commit.
- No Production migration, setting, member, wallet, payment or financial data was changed.


## 2026-11-16 — Auction bidding and referral RPC review

- Rechecked latest CI: run `43854574837` passed on commit `ddfeb5052ea5bfc1851217fbf3d2319d3d687ca8`.
- Read-only Production review of `private.place_bid`: active Main ID ownership, auction row lock/time checks, Bid Wallet-first then Income Wallet deduction, balance checks, ledger debits and auction update occur in one transaction.
- Critical retry issue: `place_bid` generates a new random idempotency key internally on every call; a client retry after timeout can create and charge a second bid. Stable client request idempotency is required before enabling bidding.
- Package activation submission has unique case-insensitive payment-reference indexes and unique member activation numbering. Submission is pending-only; Admin approval remains financially unsafe without the trusted owner-approval database guard.
- Referral plan draft/list functions and a unique commission row key exist; no commission calculation-and-credit RPC was found in the inspected function catalogue. Full private routine/grant/background-job audit remains outstanding.
- Live feature triggers gate bid, package activation, referral commission and wallet transaction inserts/updates. Do not enable financial features based on those gates alone.
- Evidence report: `docs/PRODUCTION_BIDDING_REFERRAL_RPC_REVIEW_2026-11-16.md`.
- All inspection was read-only; no Production state was changed.


## 2026-11-16 — Privileged RPC and member-data review

- CI run `43854827419` passed on commit `e6c33bd9d11974d97d4b8d977b321ee1f0faf5a1`.
- Selected Admin SECURITY DEFINER RPCs checked Admin role in their function bodies; Duplicate ID creation checks its feature flag and starts new IDs as pending.
- Critical: live `admin_set_feature_setting` still permits enabling package activation and wallet-related switches without a trusted owner-level financial approval interlock. Live package approval similarly credits Bid Wallet without checking such approval. Keep financial features locked; UI guard alone is insufficient.
- Sponsor reassignment checks for cycles but does not serialize concurrent graph edits; add transaction-level graph mutation locking and concurrency tests.
- Public `lookup_sponsor` is executable by anon and returns exact active Main ID code/display name. Review enumeration/privacy controls.
- Member dashboard and placement tree are rooted through the caller's own profile Main ID; data minimization review remains required.
- Evidence: `docs/PRODUCTION_PRIVILEGED_RPC_MEMBER_DATA_REVIEW_2026-11-16.md`.
- Read-only Production inspection only; no live state changed.


## 2026-11-16 — Production RLS, grants, SECURITY DEFINER and scheduler review

- Production catalogue review found 47 SECURITY DEFINER functions across public/private schemas; 43 callable by authenticated and one callable by anon (`lookup_sponsor(text)`). A full line-by-line review of all authenticated-callable functions remains required.
- All 20 ordinary public tables inspected have RLS enabled. Authenticated direct table grants are SELECT-only; no direct authenticated write grants were found. Member data policies are owner-scoped; catalogue policies are status-scoped; audit logs are role-scoped.
- No FORCE RLS is enabled. Privileged postgres-owned SECURITY DEFINER functions may bypass RLS, making their internal checks essential.
- `auth.users` has one BiddWorld provisioning trigger invoking the private postgres-owned handler.
- No pg_cron/pg_net/pgmq/pg_timetable extension or `cron.job` relation was found. No DB scheduler is evidenced for time-based auction/fixed-bid closing.
- Evidence: `docs/PRODUCTION_RLS_GRANTS_SCHEDULER_REVIEW_2026-11-16.md`.
- All checks were read-only; Production state unchanged.


## 2026-11-16 — Auth provisioning, Storage and default privilege review

- Latest previous CI runs `43858774382` and `43858745904` completed successfully.
- Live Auth signup trigger creates profile and Main ID as active, initializes zero-balance Bid/Income Wallets and links a validated sponsor when sponsor referrals are enabled. Source migration `20261116150000_enforce_inactive_signup_until_verified.sql` changes new profiles/Main IDs to inactive, but remains unapplied to Production.
- Source-only migration `20261116160000_minimize_public_sponsor_lookup.sql` returns a boolean instead of member code/name, but still needs rate limiting at API/edge layer.
- Source-only migration `20261116190000_bid_request_idempotency.sql` addresses repeated bid requests with stable client keys; TEST migration/API/concurrency verification remains required.
- Production Storage has no configured buckets and no Storage RLS policies were found. Receipt uploads/product media are not ready for launch.
- Production default ACLs for public schema objects are broad for anon/authenticated (future tables CRUD, functions EXECUTE, sequences usage/select/update). Existing explicit grants/RLS do not eliminate the future migration hazard. Every migration needs explicit least-privilege grants and RLS assertions.
- Evidence: `docs/PRODUCTION_AUTH_STORAGE_DEFAULT_PRIVILEGES_REVIEW_2026-11-16.md`.
- All Production checks were read-only; no live state changed.


## 2026-11-16 — Bid idempotency Production compatibility review

- CI runs `43859286459` and `43859186877` completed successfully on the previous documentation commits.
- Read-only comparison confirms the source bid-idempotency migration's referenced columns and status values match the inspected Production catalogue.
- Production already has unique indexes on `bids.idempotency_key` and `wallet_transactions.idempotency_key`; the source migration uses one stable bid key and separate wallet suffix keys.
- Live Production still exposes the old `place_bid(uuid)` private/public RPC pair that generates a fresh server-side UUID per call. The source two-argument idempotent RPC is not live.
- Browser code retains the same request key after a network error and clears it only after a successful RPC response.
- Existing Vitest checks are source-text contract tests, not PostgreSQL integration/concurrency tests. No disposable TEST project was used in this audit; do not claim full idempotency behavior tested.
- Required TEST cases and rollout blockers: `docs/BID_IDEMPOTENCY_PRODUCTION_COMPATIBILITY_REVIEW_2026-11-16.md`.
- Production remained read-only; bidding remains disabled and no bids or wallet entries were created.


## 2026-11-16 — Inactive member / package lock messaging alignment

- Reviewed the member dashboard inactive-state banner against the package catalogue's explicit lock and the Admin payment-verification screen's database financial lock.
- Found contradictory guidance: the member dashboard told inactive members to submit payment for an available package even though the package module explicitly says paid activation is closed and instructs members not to submit payments.
- Updated `src/components/Account.tsx` to state that package activation is locked, members must not pay, and inactive status remains until an approved activation process is formally opened and Admin verifies it.
- Added `tests/inactive-account-package-lock-copy.test.ts` to assert the member and package messaging stay consistent.
- This is a copy/safety improvement only; it does not change activation logic, settings, database state, wallets, or payments.
- Latest code/test commits: `0cf3e68d7aa3d0265fae1d480b1a08c74f7811c3` and `5aa9178a44bd89c57c9fced334dd6a6460eab939`.
- CI for both commits was still running at register preparation time; verify before claiming pass.


## 2026-11-16 — Admin Duplicate ID / sponsor controls audit

- Verified latest previous CI run `43860555307` passed.
- Read-only Production inspection found the live `admin_create_duplicate_member_id(text)` signature still takes one argument, while Admin UI calls the two-argument `(p_main_member_code,p_under_member_code)` contract. Branch migration `20261115230000_duplicate_under_id_placement_attribution.sql` provides the newer placement-aware function but is not live in the audited Production catalogue.
- Added a contract test to keep the Admin call, migration signature and placement fields aligned.
- Live duplicate status RPC is Admin-only, row-locks the target, audits changes, and prevents reopening closed IDs; it does not validate placement-parent eligibility when activating an ID. Lifecycle rule review remains open.
- Live sponsor cycle check prevents sequential cycles but has no graph-wide serialization lock around read/check/write; concurrent sponsor changes can potentially create a cycle. Requires a shared transaction advisory lock across every referral graph mutation and TEST concurrency coverage.
- No broad Main ID status mutation control was identified in the reviewed Admin UI/RPC set; do not invent one before defining account, package, wallet and appeal consequences.
- Full findings and rollout tests: `docs/ADMIN_DUPLICATE_ID_SPONSOR_CONTROLS_REVIEW_2026-11-16.md`.
- No Production writes, feature toggles, member status changes or Duplicate IDs were performed.


## 2026-11-16 — Registration / Main ID activation lifecycle audit

- Confirmed the registration modal offers free registration, treats Sponsor Referral ID as optional, and states that the account remains INACTIVE until Admin verification.
- Read-only Production inspection confirms `registration_enabled=true`, `sponsor_referrals_enabled=true`, `duplicate_ids_enabled=false`; the default sponsor points to an active Main ID.
- Critical deployment mismatch remains: live `private.handle_new_auth_user()` still creates new profiles and Main IDs with `active` status. Branch migration `20261116150000_enforce_inactive_signup_until_verified.sql` changes new records to `inactive` and preserves registration/sponsor feature-switch enforcement, but is not deployed to Production.
- Production package activation and Bid Wallet switches were still `true` in the read-only snapshot despite the source/UI financial lock. This reinforces that source UI guards do not replace live database interlocks.
- Added `tests/registration-inactive-ui-contract.test.ts` and `docs/REGISTRATION_ACTIVATION_LIFECYCLE_REVIEW_2026-11-16.md`.
- No Production writes, registrations, status changes, financial transactions, settings changes or migrations were performed.


## 2026-11-16 — Package submission direct-RPC guard

- Follow-up review found that the branch's package submission RPC accepted an inactive Main ID (intended) but did not itself check `package_activations_enabled` or `financial_model_approved`. A direct authenticated RPC call could therefore create a pending payment request despite the UI lock.
- Added source-only migration `20261116200000_lock_package_activation_submission.sql`: fail closed unless both settings are true; request remains pending-only and never activates or credits a wallet. Private implementation remains inaccessible directly to authenticated/anon/public; the existing authenticated public wrapper remains the entry point.
- Added `tests/package-activation-submission-lock.test.ts`, including the active Main ID withdrawal guard assertion from the existing source-only withdrawal migration.
- Details: `docs/REGISTRATION_ACTIVATION_SECURITY_FOLLOWUP_2026-11-16.md`.
- Production remains read-only; no payment, setting, migration or member state was changed.


## 2026-11-16 — Production package approval transaction reconciliation

- Re-read live Production definitions for `admin_review_package_activation`, `admin_set_feature_setting`, `submit_package_activation`, and `private.enforce_feature_gate` using SELECT-only queries.
- Confirmed the live Admin approval RPC locks the activation, Main ID and Bid Wallet; updates the balance; inserts a deterministic activation-scoped ledger credit; updates activation to approved/active; and writes an audit record within one PostgreSQL function transaction.
- Confirmed existing live `private.enforce_feature_gate()` triggers check feature switches only, not `financial_model_approved`. No live `private.require_financial_model_approval()` or wallet-ledger append-only trigger was found on the inspected tables.
- Live feature snapshot: package activations, Bid Wallet and Income Wallet flags are true; bidding, fixed bid, referral commissions, withdrawals and winning payment flags are false. No `financial_model_approved` setting row was returned.
- Added `docs/PRODUCTION_PACKAGE_APPROVAL_TRANSACTION_REVIEW_2026-11-16.md` and `tests/package-approval-atomic-guard.test.ts`.
- Production remains strictly read-only. Do not approve package requests or toggle financial flags. Full migration rehearsal and explicit owner approval remain prerequisites.


## 2026-11-16 — Supabase migration-chain readiness audit

- Reviewed all 44 SQL migration files, CI workflow and package/auth/financial migration sequence.
- Confirmed CI currently runs npm tests and frontend build only; it does not replay SQL migrations or run a Supabase/Postgres integration stack.
- Repository has no `supabase/config.toml`; no TEST project endpoint/config is established in the branch.
- Found legacy baseline schema in `0001_biddworld.sql`, later migrations use a newer schema shape, `0002_place_bid_rpc.sql` is an older bid implementation, and `001_initial_schema.sql` is empty. The full chain must be replayed from a clean TEST database before rollout.
- Added `docs/SUPABASE_MIGRATION_CHAIN_READINESS_REVIEW_2026-11-16.md` with clean-room validation plan. No TEST or Production database writes were performed.

## Live recovery and authentication audit checkpoint — 2026-11-16 18:58 IST

### Repository and CI
- Live `completion-work` HEAD re-confirmed as `daec136252d5b9db5f35de2e963b4c684a98bd1f`; the previously supplied checkpoint is still current.
- GitHub Actions run `43874908720` completed successfully: 60/60 Vitest files, 228/228 tests, TypeScript project build and Vite production bundle passed; npm audit reported 0 vulnerabilities.
- The build emitted a >500 kB main-chunk advisory and Node 20 action deprecation warnings. These are cleanup items, not failed tests.
- GitHub commit status also contains four failed Vercel deployment contexts with the explicit reason `Deployment rate limited — retry in 24 hours`. This is separate from the successful GitHub Actions CI; no deployment or paid upgrade was attempted.
- The register is stored at `docs/PROJECT_COMPLETION_REGISTER.md` (not repository root).

### Fresh read-only Production verification
- Connected project metadata confirms `BiddWorld-Production`, ref `hbqatszyzqobgtauyuzy`, region `ap-south-1`, PostgreSQL `17.11.0.019`, status `ACTIVE_HEALTHY`.
- Fresh migration ledger query returned 30 rows, latest `20261115163218_admin_audit_log_pagination`. The branch migrations dated 2026-11-16 remain unrecorded in the Production ledger.
- Fresh catalogue query: 21/21 ordinary public tables have RLS enabled; this is not a full policy/function security certification. Production Storage buckets: 0.
- Fresh feature setting snapshot: registration and sponsor referrals true; package activations, Bid Wallet and Income Wallet true; bidding, Fixed Bid, duplicate IDs, referral commissions, withdrawals and winning payments false. No `financial_model_approved` setting row exists.
- Fresh `auth.users` trigger definition still creates both `profiles.status` and Main `member_ids.status` as `active`. This conflicts with the intended inactive-until-admin-verified lifecycle.
- Fresh Production routine signatures still include `place_bid(uuid)` and `admin_create_duplicate_member_id(text)`; branch source expects the newer idempotent bid key and placement-aware duplicate-ID signature. Production package approval routine remains `admin_review_package_activation(uuid,boolean)`.
- No Production SQL write, migration, setting update, signup, test member, wallet or financial operation was executed.

### Authentication and member activation — source audit
- Existing UI source implements email/password signup and login, email confirmation handling, resend confirmation, password reset, PASSWORD_RECOVERY handling, password update, session restoration via `onAuthStateChange` plus `getUser()`, and sign-out.
- Signup collects name, phone and optional sponsor metadata. UI copy says accounts remain inactive until Admin verification.
- Existing tests cover inactive profile/Main-ID migration contracts, signup UI contract and dashboard dual-status warning. Latest CI passed these static/source tests.
- Source migration `20261116150000_enforce_inactive_signup_until_verified.sql` creates new profiles and Main IDs inactive while retaining registration/sponsor feature-switch validation. It is not applied to Production.
- Source migration `20261116200000_lock_package_activation_submission.sql` adds database-side checks for both `package_activations_enabled` and `financial_model_approved` before a pending activation request is created. It is not applied to Production.
- Account UI displays a dual-status inactive warning; this is not an authorization boundary. Financial safety must be enforced by the live database RPCs/triggers.
- Supabase Auth email-confirmation configuration, redirect allow-list, password policy and provider delivery settings were not exposed by the read-only project metadata/catalogue queries; do not infer their live values.

### Critical rollout blockers and next work
1. Do not approve package activations or enable financial actions: Production currently has package activation and wallet switches ON but no owner financial approval row or live approval interlock. This is an immediate operational risk; do not use the Production package-review action.
2. Do not apply the inactive-signup or package-lock migrations until the complete historical migration/object reconciliation and disposable TEST rehearsal are complete. Do not bulk-change existing member statuses.
3. A disposable Supabase TEST project is not currently evidenced as connected. Therefore signup/login/email confirmation/password reset/session E2E must remain NOT VERIFIED; do not test with real Production accounts.
4. Next source audit: inspect the complete signup/confirmation/recovery/session route behavior and member/admin role guards, map each auth RPC to the current Production signature and grants, then design tests for a disposable TEST project.
5. Complete the Production routine/grant/policy/trigger/Storage reconciliation before preparing a forward-only rollout plan. No Production changes without explicit owner approval.

This checkpoint updates evidence only. It does not increase the implementation completion percentage or certify authentication, integration, Production safety or launch readiness.

## Live recovery checkpoint — 2026-11-17

### Branch and CI verification
- Live `completion-work` branch was re-read before editing. Starting HEAD: `117896cf886b00950b178b8d2b4cb9bd3b119fcc` (`Implement lazy loading for tab modules`).
- The supplied latest commit was exact. Its GitHub Actions CI run `43921846842` completed successfully.
- Verified run output: 60/60 Vitest files and 228/228 tests passed; `tsc -b && vite build` completed; npm audit reported 0 vulnerabilities. Build output confirms separate Account (44.28 kB), Admin (101.66 kB), and shared initial bundle (313.75 kB) chunks. Warnings include Node.js 20 action deprecation and transitive `punycode` / `url.parse()` deprecations.
- Five commits were added after the prior recovery checkpoint: continuation protocol, `.gitignore`, generated TypeScript build-info file, lockfile, and lazy-loaded tab modules. No application feature was removed in this sequence.
- The repository contains `BiddWorld-Complete.zip`; its freshness/content has not been verified and it must not be represented as the latest deliverable.

### Source and PWA inspection
- The branch contains React 18, TypeScript 5.7, Vite 6.4, Supabase JS 2.57 and Vitest 4.1, with exact dependency versions recorded in `package-lock.json`.
- The nine secondary workspaces (Packages, Referrals, WalletHistory, FixedBid, Admin, Support, Notifications, Account and DashboardPreview) are dynamically imported and rendered through an accessible Suspense fallback.
- PWA source includes a relative-scope standalone manifest, SVG app icon, production-only service worker registration using Vite BASE_URL, and same-origin GET-only static/app-shell caching. Supabase/cross-origin/API traffic and non-GET requests are excluded from service-worker caching. Offline behavior is shell-only; no authenticated or financial data is persisted.
- Existing PWA tests are source-contract tests. Android Chrome install prompt, standalone launch, offline fallback and update lifecycle have not been physically verified on a device.
- Repository hygiene finding: `tsconfig.tsbuildinfo` is a generated TypeScript cache file tracked in the repository and was not ignored. The current checkpoint removes this generated artifact and adds the ignore rule; no source feature is affected. A regression test is added for lazy workspace imports and Suspense fallbacks.

### Fresh read-only Production verification
- Supabase metadata: `BiddWorld-Production`, ref `hbqatszyzqobgtauyuzy`, region `ap-south-1`, PostgreSQL `17.11.0.019`, `ACTIVE_HEALTHY`.
- Migration ledger remains at 30 applied entries; latest is `20261115163218_admin_audit_log_pagination`. The 2026-11-16 source migrations are not represented in this ledger and the existing reconciliation matrix remains a blocker to rollout.
- Fresh catalogue snapshot: 21/21 public tables have RLS enabled (0 FORCE RLS), 20 public policies, 43 public routines, 10 public triggers, and 0 Storage buckets. RLS enabled does not prove policy or privileged-function correctness.
- Live Auth trigger `private.handle_new_auth_user()` still inserts `profiles.status='active'` and Main `member_ids.status='active'`. This is a confirmed Production/source lifecycle mismatch.
- Current settings snapshot: registration, package activation, Bid Wallet and Income Wallet true; bidding, Fixed Bid, duplicate IDs, referral commissions, withdrawals and winning payments false. No `financial_model_approved` row was found.
- Auth email-confirmation provider settings, redirect allow-list, password policy and email delivery were not exposed by these read-only calls; they remain unknown and are not claimed verified.
- No Production DDL/DML, migration, setting change, signup, test member, wallet, payment or financial operation was performed.

### Current implementation and verification boundaries
- Existing register describes a substantial UI/source baseline, but several backend modules remain draft/read-only or depend on unimplemented workflows and owner decisions. Do not equate page presence with completed functionality.
- CI validates static source tests and the frontend build only. It does not replay the Supabase migration chain, test live RPC integration, or certify production grants/RLS.
- A separate disposable TEST Supabase project is not currently evidenced as connected; end-to-end Auth and financial transaction testing remain NOT VERIFIED.
- Next priority: finish exact auth route/role-guard and frontend-to-live-RPC contract mapping; then reconstruct all 17 unmatched historical Production migrations, compare live definitions and build a clean-room disposable TEST migration rehearsal. No Production changes without explicit authorization.
- This checkpoint is evidence and repository hygiene only; it does not increase the implementation completion estimate or claim launch readiness.

### CI confirmation and Supabase advisor snapshot — 2026-11-17
- Checkpoint commit `a9637a62aca53d910c5291140abb5da60f417f8c` was verified as the live `completion-work` HEAD.
- GitHub Actions run `43931163798` completed successfully on that exact commit: 61/61 Vitest files and 230/230 tests passed; TypeScript project check and Vite production build passed; npm audit reported 0 vulnerabilities.
- New test `tests/lazy-workspace-loading.test.ts` protects all nine dynamic workspace imports and their accessible Suspense fallback. `.gitignore` now ignores `*.tsbuildinfo`; generated tracked `tsconfig.tsbuildinfo` was removed. These changes do not remove application functionality.
- Fresh Supabase advisors (read-only) returned:
  - Security: one RLS-enabled table without direct policies (`notification_templates`); one anonymous-callable SECURITY DEFINER function (`public.lookup_sponsor(text)`); 43 authenticated-callable SECURITY DEFINER function findings; and leaked-password protection disabled.
  - Performance: one unindexed foreign key on `notification_templates.created_by`, plus 17 indexes currently reported unused.
  - Health: no findings.
- Treat the 43 authenticated SECURITY DEFINER findings as a review queue, not an instruction to revoke all execution: trusted Admin RPCs intentionally expose authenticated wrappers but must each enforce trusted `app_metadata.role` checks, fixed search_path, bounded inputs and appropriate data scope. The anonymous `lookup_sponsor(text)` finding is a genuine privacy hardening target; source migration `20261116160000_minimize_public_sponsor_lookup.sql` is not deployed to Production.
- Do not automatically add the missing `notification_templates` policy: zero direct policies may be the intended deny-by-default posture because the Admin path is through guarded RPCs. Confirm expected access before changing.
- Do not drop the 17 unused indexes based on a single snapshot; low traffic and short observation history can make useful indexes appear unused. Validate query plans and workload before any index change.
- No Production settings, Auth configuration, schema, policies, grants, Storage, member data or financial records were changed. Leaked-password protection remains a dashboard configuration item that requires a separately approved Production settings change.


## Frontend-to-Production RPC contract audit — 2026-11-17
- Read-only source-to-live comparison performed at branch snapshot `825057437428160e87810ac7976607b40545991b` against `BiddWorld-Production`.
- Identified eight current UI RPC names absent from the Production public function catalogue, plus incompatible contracts for `admin_create_duplicate_member_id`, `place_bid`, and `lookup_sponsor`. Exact details and the intended source migration paths are in `docs/PRODUCTION_FRONTEND_RPC_CONTRACT_AUDIT_2026-11-17.md`.
- Confirmed that Production `lookup_sponsor(text)` returns a table containing member code and display name, while current branch expects a boolean. Added a strict frontend compatibility helper that accepts either boolean true or a legacy row whose member code exactly matches the requested code; the legacy display name is ignored. Added regression tests.
- Production currently has no Storage buckets, while Admin product media upload expects `product-media`; this flow remains unverified/unavailable until a separate TEST setup is validated.
- No Production DDL/DML, migration, setting, Auth, Storage, member, wallet, payment or financial operation was performed. This checkpoint is not a Production integration certification.


## Supabase migration history reconciliation — 2026-11-17
- Compared the 44 branch SQL files (41 timestamped plus 3 legacy/unversioned files) against the 30 Production migration-ledger rows using read-only queries.
- Only four migration rows match by exact version and name. Nine recognizable migration names have different version timestamps; remaining entries cannot be paired by ledger metadata alone. This is not a safely replayable one-to-one migration history.
- Confirmed an important mixed state: Production has `bids.idempotency_key` with a unique index, but still exposes only the old one-argument `place_bid(uuid)` RPC. Placement columns exist while the duplicate-ID creation RPC remains one-argument. The report records this evidence and next reconciliation steps: `docs/SUPABASE_MIGRATION_HISTORY_RECONCILIATION_2026-11-17.md`.
- Do not apply the branch migration tail directly to Production or edit ledger entries to conceal drift. Reconstruct exact applied SQL and replay a curated chain in a separate disposable TEST project first.
- No Production writes, migration, ledger edit, Auth setting, Storage, member, wallet, payment, bid or withdrawal operations were performed. `main` remains untouched.

- Extended the migration reconciliation audit with live RPC body comparisons: Production withdrawal creation lacks the branch's active-Main-ID ownership guard; member withdrawal history returns the complete payout-details JSON rather than the branch's method-only response; Admin duplicate-ID listing is legacy/non-paginated and lacks placement fields. The placement-tree RPC name and response shape do match the current component at source-inspection level only. See the expanded reconciliation report.

## Production RLS / grants / triggers audit — 2026-11-17
- Read-only inspection confirms 21/21 ordinary public tables have RLS enabled; 20 direct policies exist and all are SELECT-only; no direct anon table privileges or authenticated direct writes were found in the inspected ACL snapshot. `notification_templates` has no direct policy and no authenticated/anon table privileges, consistent with deny-by-default.
- All 43 public functions are SECURITY DEFINER and have explicit search_path settings. 42 are not anon-callable; `lookup_sponsor(text)` is the only anon-callable SECURITY DEFINER exception and currently returns member code plus display name. Prioritize its privacy-minimizing source migration after TEST replay.
- Inspected Admin RPC bodies explicitly check authenticated user and JWT app_metadata Admin role. Do not mass-revoke authenticated execution without per-routine review.
- Ten public triggers route through `private.enforce_feature_gate()`. Legacy `place_bid(uuid)` uses a non-empty search_path and remains a hardening/review item.
- Full evidence and interpretation: `docs/PRODUCTION_RLS_FUNCTION_GRANTS_TRIGGER_AUDIT_2026-11-17.md`. No Production changes or function executions were performed.

## Production RPC security and contract matrix — 2026-11-17
- Inspected 43 public function overloads. All 36 Admin overloads (34 names) contain auth UID and JWT app_metadata role guard markers; none is anon-callable. All 43 public functions have explicit search_path settings.
- `lookup_sponsor(text)` is the only anon-callable SECURITY DEFINER function and returns member code + display name; source boolean-only contract remains undeployed.
- Live `place_bid(uuid)` delegates to an auth-gated private routine but generates a fresh UUID each invocation; the UI expects the source two-argument idempotent contract.
- Live package submission requires an active Main ID, conflicting with intended inactive-until-verified onboarding; live withdrawal request lacks the branch active-Main-ID ownership check; withdrawal history still returns full payout JSON.
- `admin_set_member_sponsor` has a recursive cycle check but no serialization lock, so concurrent graph edits remain a race risk. Source migration contains the same non-serialized check.
- Full matrix and priorities: `docs/PRODUCTION_RPC_SECURITY_CONTRACT_MATRIX_2026-11-17.md`. No live RPCs were executed and Production was not changed.


## Member inbox and support owner-scope hardening — 2026-11-17

- Member Notifications now explicitly scopes initial and continuation reads to the authenticated user's own `user_id`; Admin mode retains its separate queue path.
- Member Support now explicitly scopes initial and continuation reads to the authenticated user's own `user_id`; Admin mode retains its separate queue path.
- Database RLS remains the authoritative security boundary; explicit client filters are defense in depth and reduce unnecessary rows returned to member clients.
- Added `tests/member-support-inbox-owner-scope.test.ts` for both read paths and Admin separation.
- Details: `docs/MEMBER_SUPPORT_INBOX_OWNER_SCOPE_2026-11-17.md`. CI must pass on the latest branch commit. No Production schema, data, settings or financial records were changed.


## Authentication request resilience — 2026-11-17

- Registration and sign-in now recover from thrown network failures and always clear the shared busy state.
- Password reset, confirmation resend and password recovery now have exception-safe loading states and clear network-error messages.
- Email is trimmed before sign-in/registration submission; sponsor validation and inactive-until-verified registration messaging are retained.
- Added `tests/auth-network-failure-recovery.test.ts`; it is a static source-contract test, not a live Supabase Auth simulation.
- Details: `docs/AUTH_NETWORK_FAILURE_RECOVERY_2026-11-17.md`. CI must pass on the final branch commit. No Supabase accounts, settings, schema or Production data were changed.


## Member dashboard automatic initial loading — 2026-11-17

- Fixed a missing mount-time invocation in `Account.tsx`: member data now loads automatically when the dashboard opens instead of waiting for a manual Refresh click.
- Kept the manual Refresh action and existing authenticated profile / Main-ID-scoped history reads.
- Added `tests/member-dashboard-initial-load.test.ts`; CI verification is required on the final commit.
- Details: `docs/MEMBER_DASHBOARD_AUTOMATIC_INITIAL_LOAD_2026-11-17.md`. No Production data or Supabase settings were changed.


## Member account action network recovery — 2026-11-17

- Withdrawal submission, email change, password change and global sign-out now catch thrown network failures and release their loading states in `finally` blocks.
- Existing validation and Supabase-returned error handling are retained.
- Added `tests/member-account-action-network-recovery.test.ts`; latest-commit CI is required for final verification.
- Details: `docs/MEMBER_ACCOUNT_ACTION_NETWORK_RECOVERY_2026-11-17.md`. No Production data or Auth settings were changed.


## Member account refresh concurrency — 2026-11-17

- Account refreshes now use request generations and mounted-state guards; stale responses cannot overwrite newer data or clear the current loading state.
- Guards cover authentication, profile, identity, settings, history and delivery reads; unmount invalidates outstanding work.
- Added `tests/member-account-refresh-concurrency.test.ts` and updated the initial-load regression test for the guarded loading-state cleanup.
- Details: `docs/MEMBER_ACCOUNT_REFRESH_CONCURRENCY_2026-11-17.md`. CI is required on the latest branch commit; no Production data was changed.


## Admin member directory search race protection — 2026-11-17

- Added request-generation ownership across debounced search, explicit Search and Clear; stale results/errors/loading cleanup cannot override a newer request.
- Initial Admin workspace loading no longer overwrites a member search started after it began.
- Added `tests/admin-member-directory-search-race.test.ts`; latest-commit CI is the verification gate.
- Details: `docs/ADMIN_MEMBER_DIRECTORY_SEARCH_RACE_2026-11-17.md`. No Production data was changed.


## Admin Duplicate ID directory request ordering — 2026-11-17

- Added request-generation ownership to prevent stale workspace loads and Load More responses from replacing the current Duplicate ID search results.
- Captured the active search and page offset before pagination; stale errors and loading cleanup are ignored.
- Added `tests/admin-duplicate-directory-request-order.test.ts`; latest-commit CI is the verification gate.
- Details: `docs/ADMIN_DUPLICATE_DIRECTORY_REQUEST_ORDER_2026-11-17.md`. No Production data was changed.


## Admin Duplicate ID placement serialization — 2026-11-17

- Added `20261117110000_serialize_admin_duplicate_id_placement.sql`: Admin Duplicate ID creation acquires a transaction-scoped advisory lock before reading settings and locking the active Main / Under ID rows, avoiding cross-request row-lock inversion for overlapping placement operations.
- Preserved the active-ID checks, cross-owner placement restriction, Pending status, Under ID attribution, audit log, empty search_path and authenticated-only RPC grant.
- Added `tests/admin-duplicate-placement-serialization.test.ts` and implementation note `docs/ADMIN_DUPLICATE_ID_PLACEMENT_SERIALIZATION_2026-11-17.md`.
- Static contract test only; no live concurrent PostgreSQL test has been run. Migration remains source-only and has not been applied to Production. No Production data or settings were changed.


## Admin Member Directory pagination request ordering — 2026-11-17

- Debounced member search now invalidates outstanding pagination requests immediately when the search effect changes.
- Load More captures the active search generation, applied query and page offset; stale results, errors and loading cleanup cannot override a newer search.
- Added `tests/admin-member-directory-pagination-order.test.ts` and `docs/ADMIN_MEMBER_DIRECTORY_PAGINATION_ORDER_2026-11-17.md`.
- Static source-contract coverage only; no live Supabase RPC was exercised and no Production data was changed.


## Admin paginated report export safety — 2026-11-17

- Shared Admin CSV export pagination now detects an identical repeated server page and aborts with a clear error instead of looping indefinitely or producing duplicate rows.
- Exports are capped at 100,000 rows; larger reports return a filter-narrowing message. The file is generated only after all fetched pages pass the safety checks.
- Added `tests/admin-paginated-report-export-safety.test.ts` and `docs/ADMIN_PAGINATED_REPORT_EXPORT_SAFETY_2026-11-17.md`.
- Static source-contract tests only; no live RPC or Production data was queried or changed.
