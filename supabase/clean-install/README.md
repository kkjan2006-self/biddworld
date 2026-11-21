## Staff permission regression contract alignment (source-only, 2026-11-21)

Updated two source-only regression suites to match the current four-scope Staff permission allowlist, including Support review, while preserving the three-scope default for newly granted Staff. Tests not executed. No migration or manifest entry required.

## Support Admin audit deduplication (source-only, 2026-11-21)

The restricted-Staff Support RPC now writes an audit event only for `admin_staff`. Admin updates remain covered once by the existing row trigger, avoiding duplicate Admin audit rows while preserving Staff reviewer-role audit context. Source-only regression assertion added; not executed. No new migration or manifest entry.

## Wallet history Matrix reference integrity (source-only, 2026-11-21)

The shared wallet transaction validator now rejects blank reference types and requires canonical UUID references for Matrix commission ledger rows before source attribution is requested. Both paginated history and full CSV export use this validation. Source-only assertions added; not executed. No SQL migration or manifest entry required.

## Admin winning-payment and delivery page integrity (source-only, 2026-11-21)

The Admin winning-payment and delivery reports validate complete row contracts on initial and continuation requests. Cross-page duplicate/overlap responses fail closed instead of being silently filtered; delivery pagination additionally enforces its SQL-defined descending updated_at/tracking_id order. Source-only regression assertions added; not executed. No SQL migration or manifest entry required.

## Admin winning-payment and delivery page integrity (source-only, 2026-11-21)

The Admin winning-payment and delivery reports now validate complete row contracts and strict descending composite page order on initial and continuation requests. Cross-page duplicate/overlap responses fail closed instead of being silently filtered. Source-only regression assertions added; not executed. No SQL migration or manifest entry required.

## Duplicate ID directory response precision (source-only, 2026-11-21)

The Admin Duplicate ID parser now validates duplicate-row and linked Main ID UUIDs and accepts `total_count` only as a non-negative safe JavaScript integer. This prevents malformed identifiers, numeric-string coercion and bigint precision loss from entering the directory or its page metadata. Source-only regression assertions added; not executed. No SQL migration, manifest entry or database operation was required.

## Restricted Staff permission preservation on re-grant (source-only, 2026-11-21)

A repeated Primary Admin Staff grant previously replaced the existing app-metadata permissions with the default payment/auction set. This could silently remove the separately assigned `support_ticket_review` permission. Added `20261121010000_preserve_existing_staff_permissions_on_regrant.sql`: an existing restricted Staff account retains its current allowlisted permissions on re-grant; a new account receives the default three review permissions. The audit event records previous and resulting permission sets. Updated the Staff client to validate any non-empty supported permission set and added source-only regression coverage. Not executed or applied. Inventory: **156 forward + 16 excluded = 172 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Sponsor Referral reversal replay identity parity repair (source-only, 2026-11-21)

A follow-up source audit found that the credited-and-reversed idempotent replay branch in `20261120260000_referral_commission_reversal_replay_identity.sql` still omitted `commission_id`, even though the pending-only replay and Admin client contract required it. Corrected the second replay response and strengthened source-only coverage to require both successful replay paths to return the exact selected commission UUID. Existing migration #154 was corrected in place; no new manifest entry, migration replay or database write. Inventory remains **155 forward + 16 excluded = 171 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Admin notification recipient canonical Main ID (source-only, 2026-11-20)

The baseline permits multiple historical Main ID rows per owner, while `profiles.main_member_id` identifies the canonical account Main ID. The Admin recipient lookup previously returned every Main ID joined to the same profile, creating duplicate recipient options. The lookup now joins only the profile-linked Main ID and confirms ownership/type; the client rejects duplicate user UUIDs and Main ID codes. Added `20261120270000_canonical_admin_notification_recipient_lookup.sql` and source-only coverage in `tests/admin-notification-recipient-canonical-main.test.ts`; not executed. Inventory: **155 forward + 16 excluded = 171 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Sponsor Referral reversal replay identity parity (source-only, 2026-11-20)

The Admin Referral Commission reversal client now requires the returned commission UUID on both fresh and idempotent replay responses. The original RPC omitted commission_id only when a previously reversed pending commission had no wallet-credit ledger row; a forward-only replacement now includes the selected commission UUID on that replay path. Source-only regression coverage: tests/admin-commission-mutation-result-integrity.test.ts; not executed. Inventory: **154 forward + 16 excluded = 170 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Withdrawal cancellation member notification (source-only, 2026-11-20)

The canonical withdrawal status set includes `cancelled`. The member/Admin UIs now display that terminal state, but the workflow-status trigger previously returned without notifying the member when a withdrawal changed to `cancelled`. Added `20261120250000_notify_member_on_withdrawal_cancellation.sql` to reuse the existing private notification trigger and in-app inbox; no new notification channel or direct client write is introduced. Source-only regression coverage: `tests/member-workflow-status-notifications.test.ts`; not executed. Inventory: **153 forward + 16 excluded = 169 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Withdrawal lifecycle status contract reconciliation (source-only, 2026-11-20)

The canonical baseline allows the withdrawal statuses `pending`, `approved`, `rejected`, `paid` and `cancelled`. Member and Admin frontend parsers previously omitted `cancelled`, which could cause a valid row to invalidate an entire history/queue response. Both parsers now accept it; the Admin CSV filter and member history summary expose the terminal state. No SQL migration or manifest change was required. Source-only assertions updated; not executed.

## Clean-install manifest regression source repair (source-only, 2026-11-20)

Repaired `tests/clean-install-migration-manifest-integrity.test.ts`: literal backslash-n sequences embedded in the migration version-prefix uniqueness assertion block are now actual source line breaks. This restores valid test-source structure without changing assertions, manifests, baseline or migration inventory. Test remains unexecuted. Inventory remains **152 forward + 16 excluded = 168 timestamped paths**, plus 3 legacy/unversioned SQL files.

## Staff Support notification delivery (source-only, 2026-11-20)

Migration `20261120230000_staff_support_ticket_notifications.sql` updates the existing Support-ticket notification trigger to accept Admin changes and Staff changes carrying the explicit `support_ticket_review` app-metadata permission. This closes the event-delivery gap introduced when the Support review RPC was extended to restricted Staff: member ticket status/reply notifications now follow the same feature switch and existing in-app inbox. Source-only regression coverage: `tests/staff-support-ticket-notifications.test.ts`; not executed. Inventory: **152 forward + 16 excluded = 168 timestamped paths**, plus 3 legacy/unversioned SQL files.

# BiddWorld clean-install reconstruction (candidate)

Schema-only baseline candidate reconstructed from read-only Production PostgreSQL catalogue evidence captured on 2026-11-18.

## Safety and status
- Metadata source: Production `hbqatszyzqobgtauyuzy` (ap-south-1, PostgreSQL 17.11).
- No application rows, member records, wallet balances, payment records, credentials or secrets were exported.
- No Production or TEST writes were performed.
- `production_schema_baseline_candidate.sql` is **not an approved executable migration**. Never execute it against Production.
- Final replay and all integration tests are deferred until development completion; isolated TEST is the only permitted replay target.
- Supabase-managed schemas are prerequisites and are not recreated.

## Captured object inventory
- 21 public tables and 175 column definitions.
- 110 constraints and 28 non-constraint indexes.
- 21 RLS enable statements and 20 exact public RLS policies.
- 47 public/private function definitions, including captured search_path clauses.
- 11 application triggers, including the app-owned trigger on `auth.users`.
- Table, sequence and function grants; function/sequence default PUBLIC grants are revoked before explicit grants.

## Forward migration manifest
The baseline represents the current Production schema at capture time. Do not replay historical migrations at/before `20261115163218` on top of it. The source migration `20261115180000_admin_audit_log_pagination.sql` is excluded because its effect is already represented in the captured state.

Ordered forward candidates are listed in `forward-migrations.txt` (**156 unique entries at the latest inspected completion-work manifest checkpoint**). The 16 timestamped source files whose effects are already captured in the baseline are explicitly listed in `excluded-historical-migrations.txt`; do not replay those on top of the baseline. Together the two manifests contain **171 listed timestamped migration paths** (155 forward + 16 excluded). The manifest totals are **156 forward + 16 excluded = 172 timestamped SQL migration paths**. The current source-tree accounting is 156 forward entries + 16 excluded timestamped entries + 3 legacy/unversioned SQL files = 175 SQL files, with no duplicate, stale or missing timestamped manifest entries. The three legacy files remain intentionally outside the clean-install path. This is file-inventory accounting only; it does not prove dependency safety, SQL compilation or successful replay. Legacy/unversioned SQL files remain disqualified from clean installation. This is a review manifest, not proof of dependency safety or successful replay.

## Remaining work before canonical status
1. Review all captured function definitions and ACLs against current source and the recovered historical SQL archive. Public function EXECUTE counts align with the Production inventory (43 authenticated, anon only public.lookup_sponsor(text)); read-only Production evidence confirms service_role EXECUTE on all 43 public functions. The candidate intentionally narrows audit_logs_id_seq to service_role USAGE only; effective permissions still require final TEST replay. See docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md.
2. Source review now confirms 43 public SECURITY DEFINER/search_path declarations, all 36 Admin auth predicates, four private function boundaries and 11 trigger dependencies are coherent in the candidate; see `docs/CLEAN_INSTALL_BASELINE_SECURITY_DEFINER_TRIGGER_REVIEW_2026-11-18.md`. Platform prerequisites (`auth.users` and Supabase `extensions` schema) must exist before replay. The candidate's least-privilege sequence grant is documented; exact effective grants require final TEST replay.
3. Review every forward migration dependency and any repeated object replacement.
4. Storage bucket/policy migrations, Admin pending-queue receipt-path integration, legacy receipt-read policy tightening, and Main/Duplicate placement-tree traversal are included in the forward set; final TEST replay and access verification remain pending.
5. At the final testing phase, replay only on TEST and compare schema, functions, RLS, grants and Storage; then run synthetic-data integration tests. CI is intentionally not triggered by `completion-work` pushes; the final verification workflow runs on `main` pushes / PRs to `main` and uses `npm ci`.
6. Never apply this candidate to Production.

## 2026-11-20 — Active profile requirement for Income Wallet Add Money

- Added `20261120180000_require_active_profile_for_wallet_funding.sql`: the member submission RPC now requires both the authenticated profile and its owned Main ID to be active, and locks both rows during the eligibility check. This aligns Add Money with the active-profile rule used by other member financial actions and prevents submitting through a suspended profile.
- Added source-only regression coverage in `tests/member-wallet-funding-active-profile.test.ts`; not executed. Inventory: 146 forward + 16 excluded = 162 timestamped paths, plus 3 legacy SQL files.

This candidate reconstructs schema, not Production data. Historical SQL evidence remains archived under `supabase/audit/production-ledger/`.

## Current static reconciliation checkpoint

See [`docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md`](../../docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md) for the current focused migration dependency, lockfile/advisory, CI sequencing and PWA source review.

See [`docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`](../../docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md) for the historical 90-file inventory (superseded by the latest manifest inventory of 156 listed paths: 140 forward + 16 excluded; exact directory accounting remains pending), baseline object counts, migration sequencing observations, Storage policy final-state dependency, and the current CI result. Function ACL findings are recorded in [`docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md`](../../docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md). All findings are source-level only; no TEST or Production replay has occurred. The member Main-ID lifecycle serialization review is recorded in [`docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md`](../../docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md).


## Recent Winners profile-join repair (source-only, 2026-11-20)

The canonical baseline defines `public.member_ids.owner_user_id`; it does not define `member_ids.user_id`. Migration `20261120120000_fix_recent_auction_winner_profile_join.sql` replaces the Recent Winners RPC from migration `20261120110000_auction_item_awards_and_homepage_winners.sql` to join `profiles.id = member_ids.owner_user_id`. The forward manifest includes this correction. No migration was applied and no test was run.

## Canonical clean-install path clarification (source-only)

The legacy `supabase/migrations/0001_biddworld.sql` schema is not the clean-install starting point and must not be combined with the current forward chain. The intended candidate path under review is the schema-only `production_schema_baseline_candidate.sql`, followed by the ordered entries in `forward-migrations.txt`. Static comparison confirms that the candidate defines the canonical columns used by the first forward migrations, including `profiles.phone`, `profiles.main_member_id`, `member_ids.owner_user_id/id_type/status`, `wallet_accounts.member_id`, `referrals.source_member_id`, and `package_activations.activation_number/payment_status/activation_status`. This resolves the specific old-legacy-shape mismatch for this candidate path, but does not prove every dependency or SQL body compiles. Candidate approval and TEST replay remain pending.


The support-ticket and member-notification frontend write paths were reconciled against table grants and RLS. Direct support-ticket INSERT/UPDATE and direct notification INSERT were unnecessary because the UI uses audited, idempotent RPCs. Forward candidate #67 removes table-level support INSERT/UPDATE and notification INSERT grants. Follow-up candidate #68 explicitly removes the residual support-ticket column-level INSERT/UPDATE grants left by the original migration. Owner/Admin SELECT and owner-scoped notification read-state UPDATE remain; audited idempotent RPCs are the intended support write paths. See `docs/SUPPORT_TICKET_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`. See [`docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md`](../../docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md).


## Notification column privilege follow-up (#69)

The original member-notification migration separately granted column-level INSERT on (user_id, title, message, category). Candidate #67 revoked table-level INSERT only; the Admin-only RLS insert policy still allowed an Admin to bypass the audited/idempotent delivery RPC if the column grant survived. Candidate #69 explicitly revokes both table-level and column-level INSERT from authenticated. Owner-scoped UPDATE(read_at) remains intentionally available for members marking notifications as read. See [the notification column privilege follow-up](../../docs/MEMBER_NOTIFICATION_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md). The ordered forward manifest now contains 79 candidates + 16 excluded timestamped migrations + 3 legacy SQL files = 98 SQL files. Source-only; no replay or database verification has occurred.


## Fixed Bid public rules projection (#70)

`20261119000000_fixed_bid_public_rules_projection.sql` replaces the restricted public catalogue RPC projection to include `max_entries_total` and `refund_non_winners`, alongside the existing entry amount, winner payment, per-member limit, winner count and schedule. These are the published campaign rules consumed by the Member Fixed Bid catalogue. The RPC remains a bounded, stable, title-search/status-filtered projection over published products and scheduled/live/ended campaigns; it does not grant direct anonymous table reads. It retains explicit EXECUTE grants only for `anon` and `authenticated`. This is source review only; PostgreSQL replay and runtime access verification remain pending.


## Placement Tree root ownership guard (#71)

`20261119010000_enforce_member_placement_tree_root_ownership.sql` replaces `get_my_placement_tree()` so the authenticated profile's `main_member_id` must resolve to a Main ID whose `owner_user_id` is the same authenticated user. The recursive Main/Duplicate traversal, depth cap, cycle guard, output shape and authenticated/service_role grants are preserved. This closes a source-level fail-open gap where the previous function trusted the profile pointer without verifying the referenced Main ID's ownership. Source review only; no migration replay or runtime authorization verification has occurred.


## Admin notification history recipient projection (#72)

`20261119020000_admin_notification_history_recipient_labels.sql` adds the Admin-only `admin_list_member_notifications_page(integer,integer,text)` RPC. It returns bounded, stable 100-row pages with the recipient Main ID and display name joined server-side, while retaining the notification UUID only as an internal row field. The category filter is validated against the four supported categories plus `all`; offsets are bounded to 1,000,000. The RPC uses an empty `search_path`, verifies the Admin app_metadata claim, revokes PUBLIC/anon execution and grants authenticated execution. `src/components/Notifications.tsx` now uses this RPC for Admin history while member inbox reads remain owner-filtered direct selects and member mark-read actions remain unchanged. Source review only; no replay or runtime verification.


## Support-ticket audit event deduplication (#73)

`20261119030000_deduplicate_support_ticket_audit_events.sql` makes the existing row trigger the single audit writer for Admin support-ticket updates. The trigger audit payload retains the actor, ticket ID, member user ID, old/new status and response-change indicator. The Admin update RPC no longer inserts a second audit row, while retaining its Admin-claim check, row lock, status/content validation, result shape and explicit authenticated-only EXECUTE grant. A static source-contract test was added; it remains unexecuted until the final testing phase. This source-only correction has not been replayed or runtime-verified.


## 2026-11-18 — Admin report keyset pagination

- Added cursor-specific Admin-only RPCs for auction bids and Fixed Bid entries. Both use stable descending `(created_at,id)` ordering and validate paired cursor values and page bounds.
- Updated the two report components to use the cursor RPCs for both interactive pagination and complete CSV export. The prior offset RPCs remain available for compatibility with any legacy caller.
- Added source-contract tests for both UI/RPC contracts. Tests have not been executed.
- Forward migration inventory: 85 candidates + 16 excluded timestamped migrations + 3 legacy SQL files = 104 SQL files (101 timestamped). No migration replay, tests/build/QA or database writes were performed.


## 2026-11-19 — Main Wallet funding workflow (#76)

- Added the member Add Money flow: verified KRFSI UPI QR (krindia@bpunity), amount, UTR/payment reference and private receipt upload (JPG/PNG/PDF, max 5 MB).
- Added a private wallet-funding-receipts Storage bucket with member-owned upload paths and Admin-only receipt reads.
- Added wallet_fund_requests with unique normalized UTR, pending/approved/rejected states, member-scoped history, Admin pending queue and an Admin review RPC.
- Approval locks the request and Main Wallet row, credits the internal income wallet account atomically, writes one immutable wallet_transactions credit with a deterministic idempotency key, and records an audit event. Rejection makes no wallet credit.
- Member-facing labels now call the former Income Wallet the Main Wallet; internal wallet type remains income to preserve existing ledger and settlement contracts. Bid Wallet remains unchanged.
- Admin review currently uses the repository's existing authenticated Admin role. A distinct Admin Staff role is not present in the current authorization model and has not been invented or granted.
- Added forward migration candidate #76. Source-only; migration not applied. Tests not run. No build, QA, DB replay/write, Production access or deployment.


- Inventory update after Main Wallet funding migration #76: 76 forward + 16 excluded timestamped + 3 legacy SQL files = 95 SQL files (92 timestamped). This is source inventory only; no replay was performed.


## 2026-11-19 — Shared payment reference protection (#77)

- Added a private trigger guard for package activation and Main Wallet top-up inserts.
- Both paths normalize the UTR/reference, acquire the same transaction-scoped advisory lock, and reject a reference already used by the other payment workflow. Existing per-table unique protection remains in place.
- Added source-contract coverage. No tests were executed and no database migration was applied.
- Updated forward candidate inventory: 77 forward + 16 excluded timestamped + 3 legacy SQL files = 96 total (93 timestamped).


## 2026-11-19 — Registration email verification setting (#78)

- Added the Admin Platform Settings switch Email Verification, default ON. Admin setting changes are audit logged and included in the Admin feature-settings response.
- Added an anonymous/authenticated read-only RPC so the registration screen can read the policy without exposing other app settings. Registration messaging and email redirect behavior now follow the stored setting.
- Supabase Auth's project-level Email Confirm option is provider configuration and cannot be securely changed by a browser-side app setting. The Admin description explicitly requires that provider option to match; when the app switch is OFF but the provider still requires confirmation, the registration flow explains the mismatch instead of claiming verification was disabled.
- Added a source-contract test (not run). Forward migration candidate #78 added. Inventory: 78 forward + 16 excluded timestamped + 3 legacy SQL files = 97 total (94 timestamped).
- Admin financial actions now defer to the connected database's safeguards instead of a hardcoded client-side lock. Database interlocks remain intact; Production is not unlocked. No tests/build/QA or DB replay/write performed.


- Package Activation payment screen now reuses the KRFSI UPI payment QR presentation and shows Payee KRFSI / UPI ID krindia@bpunity before UTR and receipt submission. The same QR is used by Main Wallet Add Money. This is source integration only; the actual QR asset and UPI payment flow still require final isolated Test validation before any Live release.


## 2026-11-19 — Restricted payment-review Admin Staff (#79)

- Added a restricted `admin_staff` role, granted/revoked only by the designated Primary Admin for an existing account. The role receives exactly two permissions: `package_activation_review` and `wallet_funding_review`; changes are audited and require sign-out/sign-in to refresh JWT claims.
- Added a dedicated staff portal containing only Package Activation payment review and Main Wallet Add Money review. It does not render the full Admin dashboard, wallet adjustment, settings, reports, member management or role management.
- Updated the package activation and Main Wallet funding queue/review RPCs to accept Admin or the matching explicit staff permission. Approval still uses the existing atomic server-side wallet/package transactions and writes the reviewer ID into the audit/verification records.
- Updated private receipt Storage read policies to allow staff only for the workflow they are assigned to. Member-owned receipt upload/read behavior is retained.
- Added migration candidate #79 and source-contract test `tests/restricted-payment-review-staff.test.ts` (not run). Inventory: 79 forward + 16 excluded timestamped + 3 legacy SQL files = 98 SQL files (95 timestamped).
- No tests/build/CI/QA, migration replay, DB writes, Production access or deployment. Production remains read-only; TEST remains untouched.


## 2026-11-19 — Notification inbox keyset pagination (#80)

- Member and Admin inboxes now load bounded 100-row pages using a stable descending `(created_at,id)` cursor and one extra row to determine whether another page exists. The Admin inbox uses a dedicated Admin-only cursor RPC; member inbox queries remain scoped to the authenticated member and preserve unread/category filters.
- The previous Admin offset RPC remains available for compatibility. Added source-contract test `tests/notification-inbox-keyset-pagination.test.ts` (not run).
- Added forward migration #80. Inventory: 80 forward + 16 excluded timestamped + 3 legacy SQL files = 99 total (96 timestamped).
- No tests/build/CI/QA, migration replay, DB writes, Production access or deployment.


## 2026-11-19 — Member auction submissions and moderation (#81–#82)

- Added an authenticated member Place an Auction form, image uploads (1–8 JPG/PNG/WebP files, 5 MB each), title, description, category, starting price, bid increment, start/end schedule and optional key/value details. Server submission requires an active Main ID and active profile.
- All submissions are private and Pending Admin Approval; they do not enter the public catalogue. Admin or restricted Admin Staff with `auction_submission_review` can inspect images, edit listing details, approve/publish or reject. Approval creates the published product and scheduled/live auction in one database transaction; review actions are audited. Members can view their own submission statuses.
- Added migrations #81–#82; existing restricted staff are granted the additional auction review permission while retaining only the fixed review scope. Added member and staff UI plus source-contract test (not run).
- Inventory: 82 forward + 16 excluded timestamped + 3 legacy SQL files = 101 total (98 timestamped).
- Media is stored in a private bucket. Public delivery of approved images still needs a dedicated publish/copy or signed-media delivery step before live rollout; do not treat the image pipeline as production-ready yet.
- No tests/build/CI/QA, SQL replay, DB writes or deployment.


## 2026-11-19 — Approved auction image delivery (#83)

- Member-submitted images stay in the private `auction-submission-media` bucket while pending. On Admin/authorized Staff approval, the review UI copies images to the public `product-media` bucket and passes the published object paths to the approval RPC. The RPC then publishes the associated product and auction; public catalogue cards and detail views resolve the stored paths to public URLs.
- The new migration grants upload to Admin or Staff with `auction_submission_review`; public read is enabled for published product media. Added source-contract test `tests/approved-auction-public-media-delivery.test.ts` (not run).
- Inventory: 83 forward + 16 excluded timestamped + 3 legacy SQL files = 102 total (99 timestamped).
- Media copying and database approval are separate client operations; failed approval after upload can leave unreferenced public media objects for later cleanup. No tests/build/QA, SQL replay, DB writes or deployment.


## 2026-11-19 — Expected-price auction lifecycle (#84)

- Member listing now requires a Starting Price and Expected Price; Expected Price must be at least Starting Price. A fixed end time is not requested. Bidding remains open until current bid reaches or exceeds Expected Price; at that moment the database sets the deadline to 48 hours later. The public catalogue shows the target and either the waiting state or live countdown.
- The bid RPC accepts `ends_at IS NULL` and still rejects bids after the deadline. A `pg_cron` job starts scheduled listings and marks them ended at the 48-hour deadline. Admin/Staff moderation edits the two prices; no end-time input remains.
- Added source-contract test `tests/expected-price-auction-lifecycle.test.ts` (not run). Inventory: 84 forward + 16 excluded timestamped + 3 legacy SQL files = 103 total (100 timestamped).
- No tests/build/QA, SQL replay, database writes or deployment were performed. Cron scheduling is defined in the migration and has not been applied or verified in a database.


## 2026-11-19 — Individual restricted Staff permissions (#85)

- Added `20261119160000_individual_payment_staff_permissions.sql`: Primary Admin can independently assign Package Activation Payment Review, Main Wallet Add Money Review, and Member Auction Listing Review to each existing restricted Staff account. Permission updates are allowlisted and audited; at least one permission must remain. Revoke Staff Access removes the role.
- Added per-user permission controls and source-contract test (not run). Staff must sign out and back in to refresh app_metadata claims.
- Inventory: 85 forward + 16 excluded timestamped + 3 legacy SQL files = 104 total (101 timestamped). No tests/build/QA, migration replay, DB writes or deployment.


## 2026-11-19 branch-head reconciliation

The `completion-work` branch was rechecked at HEAD `42e8855a8af1e36d7d247a4e26a85970b41f4b43`. The forward manifest already includes the wallet-funding, cross-workflow payment-reference, email-verification, restricted Staff, notification pagination, auction moderation/media, Expected Price lifecycle, and individual Staff permission migrations. The manifest reconciles to 85 forward + 16 excluded timestamped migrations = 101 timestamped files. No clean-install replay, build, tests, QA, or database writes were performed. The canonical baseline and migration dependencies remain subject to final source review and isolated TEST replay.


## Latest branch-head manifest reconciliation — 2026-11-19

The verified `completion-work` source inventory contains 103 timestamped migrations and three legacy/unversioned SQL files. The forward manifest now contains 87 candidates and the excluded manifest contains 16 historical entries, accounting for every timestamped file exactly once. The Admin Expected Price lifecycle migration was assigned the unique version `20261119160100` to resolve a duplicate version prefix; the Admin open-ended auction status migration `20261119170000` was added to the forward set. The repository manifest-integrity test source covers exact file accounting and order, but remains unexecuted. This is source-only reconciliation: no database replay or writes have occurred.


## Registration email verification default (#93)

The forward migration `20261119230000_registration_email_verification_off_by_default.sql` sets the BiddWorld application setting `email_verification_required` to false on both clean installs and upgrades, and changes the public policy RPC's missing-row fallback to false. The Admin override remains available. Supabase Auth's project-level Confirm Email option is separate and must also be OFF in the isolated TEST/Preview environment for immediate login. This migration is source-only and has not been applied.

## Duplicate ID feature switch enforcement (#94)

- Added `20261119270000_block_duplicate_creation_when_disabled.sql`. The database now rejects every new Duplicate ID row (including Pending rows and direct insert paths) while `duplicate_ids_enabled` is OFF. Turning it ON again restores new creation.
- The Admin switch can be turned OFF/ON independently of unrelated feature locks. Existing Duplicate IDs, status management, balances, reports, transactions and history are not deleted or changed by the creation switch.
- Added `tests/duplicate-id-feature-switch.test.ts` source-contract coverage. No tests/build/QA or migration replay were run; no Supabase database was changed.
- Inventory: 88 forward + 16 excluded timestamped migrations = 104 timestamped migration files, plus 3 legacy SQL files. The forward manifest includes the new migration.

## Matrix plan configuration foundation (#95)

- Added package-specific, versioned Matrix plan storage with independent Matrix Width (2–100) and Matrix Depth (1–50). Predefined widths such as 1:3 through 1:7 are supported, and custom widths such as 1:8 or 1:10 can be stored without a schema change.
- Added per-level enable/disable, Fixed Amount / Percentage reward type, reward value and eligibility JSON configuration, plus Admin save/list/activate RPCs and audit records.
- Matrix configuration is separate from Sponsor Referral plan tables. This migration does not create placements, calculate commissions, or credit wallets; those workflows remain separate follow-up development.
- Added source-contract test `tests/matrix-plan-configuration.test.ts` (not run). No tests/build/QA or database replay/writes were performed.
- Inventory: 89 forward + 16 excluded timestamped migrations = 105 timestamped migration files, plus 3 legacy SQL files.
## 2026-11-19 — Matrix plan configuration foundation

- Added `20261119280000_matrix_plan_configuration.sql` with package-specific versioned Matrix plans. Matrix Width (2–100) and Matrix Depth (1–50) are separate values; this accommodates the predefined 1:3–1:7 widths and custom widths such as 1:8/1:10.
- Added independent per-level enabled state, Fixed Amount / Percentage reward configuration, eligibility JSON, Admin save/list/activate RPCs and audit records. Sponsor Referral plan tables remain separate.
- This is configuration groundwork only. Matrix placement, next-gap auto-placement, Under-ID-based Matrix commission calculation, Main Wallet credit attribution and the Admin editor UI are still pending. No wallet credits or placements were created.
- Added source-contract test `tests/matrix-plan-configuration.test.ts`; not run. Added migration to clean-install forward manifest.
- Inventory: 98 forward + 16 excluded timestamped migrations = 114 timestamped migrations, plus 3 legacy SQL files.
- No tests/build/type-check/browser QA, SQL replay, Supabase writes or deployment. Production and TEST remain untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending full source reconciliation and final verification.


## Admin auction Expected Price moderation RPC (#136)

`20261119680000_admin_auction_submission_expected_price_review.sql` restores the Admin/authorized-Staff moderation RPC removed when the fixed-end-time signature was retired. Its argument contract now matches `AdminAuctionSubmissionReview.tsx`, validates the required Expected Price, verifies the complete public image gallery belongs to the submitter and exists in `product-media`, creates the published product and scheduled/live auction with `ends_at = NULL`, and records the review outcome. The pending submission constraint requires an Expected Price at least as high as Starting Price. This is source-only; no database migration was applied or replayed.


## Duplicate pending auction submission guard (#137)

`20261119690000_prevent_duplicate_pending_auction_submissions.sql` adds an owner-scoped pending-title index and a `BEFORE INSERT OR UPDATE` trigger. It serializes writes per submitter with a transaction advisory lock and rejects a second pending auction submission with the same normalized title, including direct RPC or resubmission paths. This source migration has not been applied to TEST or Production.

## 2026-11-20 — Fixed Bid card and details experience

- Reworked Fixed Bid cards to show a single-line campaign title and product subtitle, a Product Details link, entry amount, percentage progress bar and prominent BID NOW action. Full details open in a responsive dialog with the complete published product attributes and all approved gallery images.
- Extended the restricted public catalogue RPC projection to return the approved product image gallery and product details, plus a percentage-only campaign capacity indicator. The response does not expose raw entry or participant counts. Existing secure member entry RPC and feature controls remain unchanged.
- Added source migration `20261120100000_public_fixed_bid_card_details_and_progress.sql` to the clean-install forward manifest. Source-only: no migration was applied and no tests/build/browser QA were run.
- Updated clean-install inventory: **138 forward + 16 excluded = 154 timestamped SQL migrations**.

## 2026-11-20 — Auction item awards and homepage Winners

- Corrected Auction finalization: the highest eligible bidder is recorded as the winner and awarded the listed item. Auction finalization no longer creates a separate `winning_item_payments` record or returns a winner-payment obligation. Fixed Bid campaign winner-payment flows remain unchanged.
- Added a restricted public read RPC for recent finalized Auction winners, exposing only auction title, listing image, display name, winning bid amount and finalization date. Homepage shows responsive Recent Winners cards only when real winner records exist; no sample winners are invented.
- Auction winner-payment notifications are excluded; Fixed Bid winner-payment notifications remain active. Historical Auction payment records, if any, are not deleted or modified by this source migration.
- Added static source-contract assertions and registered migration `20261120110000_auction_item_awards_and_homepage_winners.sql`.
- Commit: `20fc530cea4e171bc3502ad23d49b63c7e6d3bb4`. No SQL was applied and no tests/build/browser QA were run.
- Clean-install inventory: **139 forward + 16 excluded = 155 timestamped SQL migrations**.

## 2026-11-20 — Admin wallet adjustment idempotent replay response

- Added `20261120130000_wallet_adjustment_idempotent_response_integrity.sql` to the forward manifest. Replayed Admin wallet adjustments now return the complete original result, including the original ledger balance-after snapshot, instead of an incomplete response that could be misread as a zero balance.
- Admin client validates the response against the original request before clearing its idempotency key. Source-only; no migration replay or runtime tests were performed.
- Updated inventory: **141 forward + 16 excluded = 157 timestamped SQL migration paths**, plus 3 legacy/unversioned SQL files outside the clean-install chain.

## 2026-11-20 — Fixed Bid-only winner payment

- Added `20261120140000_restrict_winner_payment_to_fixed_bid.sql` to the forward manifest. New winner-payment requests are rejected for Auction item awards; Fixed Bid winner payment remains a separate workflow. Existing paid ledger records remain untouched and replay-compatible.
- Updated inventory: **145 forward + 16 excluded = 159 timestamped SQL migration paths**, plus 3 legacy/unversioned SQL files outside the clean-install chain.


## 2026-11-20 — Matrix auto-post with restricted Staff approvals

- Added `20261120160000_matrix_staff_activation_auto_post.sql` so the package-activation trigger uses a private, non-publicly executable posting routine when Matrix auto-post is enabled. Restricted Staff approval no longer calls the Admin-only public posting RPC, preventing the package approval transaction from failing solely due to the reviewer's Staff role.
- The manual `admin_post_matrix_commissions` RPC remains Admin-only; the private routine retains the activation lock, Income Wallet ledger idempotency, balance updates and audit attribution to the approving actor.
- Added source-only regression coverage in `tests/matrix-staff-activation-auto-post.test.ts`; not executed. Inventory: 145 forward + 16 excluded = 161 timestamped paths, plus 3 legacy SQL files.


## 2026-11-20 — Global payment reference uniqueness

- Added `20261120170000_global_payment_reference_uniqueness.sql`. Package Activation and Income Wallet Add Money now serialize inserts/updates by the same normalized UTR using a transaction-scoped advisory lock and each workflow's trigger checks the opposite workflow before accepting the reference. This closes the race left by separate cross-table preflight checks; existing same-table unique constraints remain in place.
- Added source-only coverage in `tests/global-payment-reference-uniqueness.test.ts`; not executed. Inventory: 145 forward + 16 excluded = 161 timestamped paths, plus 3 legacy SQL files.


## Admin Main-ID lifecycle / financial-action serialization (source-only, 2026-11-20)

Migration `20261120200000_serialize_admin_main_member_lifecycle.sql` makes the Admin Main-ID status RPC acquire the same per-Main-ID transaction advisory lock used by member Fixed Bid, withdrawal and winner-payment actions. This serializes suspension/closure with member financial eligibility checks while preserving the graph-wide lock, lifecycle rules, linked Duplicate-ID propagation, audit event and authenticated-only RPC grant. Source-only regression coverage is in `tests/admin-main-member-financial-lifecycle-serialization.test.ts`; not executed. Inventory: **149 forward + 16 excluded = 165 timestamped paths**, plus 3 legacy/unversioned SQL files.


## Admin withdrawal review lifecycle serialization (source-only, 2026-11-20)

Migration `20261120210000_serialize_admin_withdrawal_review_lifecycle.sql` makes the Admin approve, reject/release and mark-paid RPC acquire the shared per-Main-ID transaction advisory lock after locking/identifying the request and before any profile/Main-ID eligibility check or wallet ledger mutation. This serializes Admin withdrawal processing with member withdrawal/Fixed Bid/winner-payment actions and Admin Main-ID lifecycle changes, while preserving the existing reservation, compensating release, payout confirmation and audit contracts. Source-only regression coverage is in `tests/admin-withdrawal-review-lifecycle-serialization.test.ts`; not executed. Inventory: **149 forward + 16 excluded = 165 timestamped paths**, plus 3 legacy/unversioned SQL files.
