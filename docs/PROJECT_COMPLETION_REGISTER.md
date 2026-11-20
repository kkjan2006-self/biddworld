## 2026-11-20 — Paginated withdrawal history payout privacy

- Found that the newer `member_list_my_withdrawals_page` RPC returned `w.payout_details` unchanged, while the older `member_list_my_withdrawals` endpoint had already been restricted to the payout method label. Since the Member Account UI uses the paginated RPC, the newer path could disclose the member's UPI ID or bank account number to the client unnecessarily.
- Added `20261120190000_minimize_paginated_withdrawal_payout_data.sql`. The paginated response now returns only `{method: ...}` or `{}` while preserving the result shape, keyset pagination, row ordering, page bounds and authenticated-only execution grant.
- Added `tests/member-withdrawal-paginated-payout-privacy.test.ts`; source-only and not executed. Inventory: 147 forward + 16 excluded = 163 timestamped paths, plus 3 legacy SQL files.
- Commits: migration `7a2c825269ce357771c54c783cfe359b092c3c79`; source test `35e60f47460788ecc893bb130763169dc01d8a9b`.

---

## 2026-11-20 — Income Wallet Add Money active-profile eligibility

- Found that the Add Money submission RPC checked the Main ID status but did not check the authenticated profile status, unlike other member financial actions. A profile marked inactive/suspended while its Main ID remained active could still submit a funding request.
- Added `20261120180000_require_active_profile_for_wallet_funding.sql`. The RPC now requires the profile to belong to the authenticated user, requires both profile and Main ID to be active, and locks both rows while validating eligibility. Existing receipt ownership, Income Wallet feature gate, UTR checks, insert/audit contract and authenticated-only grants are preserved.
- Added `tests/member-wallet-funding-active-profile.test.ts`; source-only and not executed. Inventory: 146 forward + 16 excluded = 162 timestamped paths, plus 3 legacy SQL files.
- Commits: migration `51276bb1081d85126370ae1d678db13291f6a28c`; source test `6ff40a5141900892912f469b4cd0c2429a6ac354`.

---

## 2026-11-20 — Global payment reference uniqueness across payment workflows

- Found a race between Package Activation and Income Wallet Add Money: each workflow checked the other table before insert, but concurrent transactions could both pass those independent checks and submit the same UTR.
- Added `20261120170000_global_payment_reference_uniqueness.sql`. Both tables now invoke the same SECURITY DEFINER trigger routine, acquire a transaction-scoped advisory lock using the normalized UTR, and check the opposite workflow after acquiring the lock. Existing same-table unique constraints remain unchanged. Inserts and payment-reference updates are covered.
- Added source-only regression coverage in `tests/global-payment-reference-uniqueness.test.ts`; not executed.
- Registered migration in the clean-install forward manifest. Inventory: **145 forward + 16 excluded = 161 timestamped migration paths**, plus 3 legacy/unversioned SQL files.
- Commits: migration `03d088b9e8a4c177cd8a2cfcd07cce4aa27f8d33`; source contract `ec1176d94ac84582653689f59a45c2f8153ec6c8`; manifest `bbabbdb22ea0f255bd3b258896f168eaa8066965`; clean-install inventory `ae3f3915ac1654c5e750536ae443a4ba7a9ccf67`.
- Source-only development. No tests/build/type-check, migration replay, database access or deployment were performed.

---

## 2026-11-20 — Matrix auto-post and restricted Staff activation compatibility

- Found a cross-module failure path: when Matrix auto-post was enabled, the package-activation trigger called the public Admin-only Matrix posting RPC. A Staff member with the valid `package_activation_review` permission could therefore have their otherwise valid package approval rolled back by the Admin-only check.
- Added `20261120160000_matrix_staff_activation_auto_post.sql`. The trigger now uses a private internal posting routine; the public manual posting RPC remains Admin-only and the private routine is not executable by authenticated clients. Wallet locking, ledger idempotency, balance updates and audit attribution to the approving actor are preserved.
- Added `tests/matrix-staff-activation-auto-post.test.ts` source-only contract coverage. Not executed.
- Registered the migration in the clean-install forward manifest. Inventory: **144 forward + 16 excluded = 160 timestamped migration paths**, plus 3 legacy/unversioned SQL files.
- Commits: migration `6f1138f45f63b6529f7ac70d6d65cf35b3b77689`; source contract `5769c235ccdeaa64f2d0dad4fe3adba2ddec8836`; manifest `49bd906f952ffaa07f2429d5435a999985770ea1`; clean-install inventory `ed63440879dbb84e0a21681689318295d731e829`.
- Source-only development. No tests/build/type-check, migration replay, database reads/writes or deployment were performed.

---

## 2026-11-20 — Member Product/Auction media ownership and cleanup concurrency

- Member Product and Auction submission history now validates every returned image path against the same authenticated-user-folder and safe filename contract enforced by the forward SQL RPCs; submission IDs are validated as UUIDs before signed URLs are requested.
- Persisted cleanup queues are filtered against the authenticated user's exact folder and SQL-compatible filename rules, preventing malformed or cross-account paths from reaching Storage removal.
- Manual cleanup retries are single-flight and share the submission busy state, preventing duplicate cleanup and overlapping uploads/submissions.
- Added source-only assertions in `tests/member-product-submission-editing.test.ts` and `tests/member-auction-submission-editing.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Upload failure orphan tracking across receipt and listing workflows

- Package Activation and Income Wallet receipt paths are now recorded before the Storage upload call; a failed/ambiguous upload is treated as a pre-RPC orphan candidate and removed or persisted for retry. Cleanup still does not run after an ambiguous activation RPC outcome.
- Member Product/Auction and Admin Product/Auction moderation now record each generated object path before attempting upload, so partial/ambiguous upload failures can be included in the existing cleanup path/queue.
- Added source-only assertions for pre-upload path tracking in the Member and Admin submission/receipt tests; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Admin Product moderation Storage recovery

- Failed deletion of temporary public `product-media` objects after a definite Product moderation RPC rejection or pre-RPC failure is now persisted in an Admin-account-scoped queue, validated against generated UUID image paths and capped at 100 entries.
- The Product Review screen exposes a Retry image cleanup action and retains the queue across page reloads; ambiguous moderation outcomes continue to preserve uploaded images to avoid breaking a possibly published product.
- Added source-only assertions in `tests/admin-product-submission-image-cleanup.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Wallet history, Admin templates and member submission contracts

- Wallet History now treats the wallet-account FK embed as its to-one object shape, validates bounded transaction rows and Matrix source records, and resolves complete Matrix attribution in 200-ID chunks to respect the SQL RPC cap during full CSV export.
- Admin notification template saves now validate the returned template UUID, inactive state and exact existing template identity before resetting the editor.
- Member Product and Auction create/edit submission RPCs now validate the returned UUID and require edits to return the original submission ID before clearing forms. Ambiguous/malformed outcomes retain uploaded media and instruct the member to refresh history.
- Added/extended source-only assertions in `tests/wallet-matrix-commission-source.test.ts`, `tests/admin-notification-template-response-integrity.test.ts`, `tests/member-auction-submission-editing.test.ts` and `tests/member-product-submission-editing.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Member submission moderation response contracts

- Admin Product moderation now validates `success`, action-specific status, the returned Product UUID and exact published image count before reporting success or clearing workflow state.
- Admin Auction moderation now validates action-specific status, returned Auction/Product UUIDs, exact Expected Price and the SQL 48-hour deadline contract (including the already-reached-at-start case) before clearing edits or reporting publication.
- Corrected the auction review regression assertion to match the actual 5-character minimum title contract.
- Added source-only assertions in `tests/admin-product-submission-image-cleanup.test.ts` and `tests/admin-auction-submission-review-safety.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Matrix commission report pagination contract

- Matrix commission report pages now reject responses over the requested 100-row bound, require numeric summary/amount fields and require a boolean, consistent `has_more` flag on every returned row.
- A short page cannot claim additional records; malformed pagination metadata fails closed instead of silently truncating or duplicating the report.
- Added source-only assertions in `tests/admin-matrix-commissions-source-integrity.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Support export response integrity

- Full Support CSV export now validates that every fetched page is an array of at most 500 complete ticket records before adding any row to the export. Malformed server responses stop the export rather than being cast into trusted records.
- Added source-only regression assertions in `tests/support-ticket-keyset-pagination.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Income Wallet funding receipt recovery

- Failed deletion of a private Add Money receipt after a definite RPC rejection is now persisted in a bounded, account-scoped retry queue; only UUID-owned `wallet-funding` paths are eligible. The queue retries when the member account returns and offers a manual Retry action.
- Wallet funding submission now validates the returned request UUID and pending status before clearing the form; ambiguous outcomes preserve the receipt.
- Added `tests/wallet-funding-receipt-cleanup-recovery.test.ts` source-only assertions; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Member package activation response contract

- Member package activation submission now validates the exact returned activation UUID, positive activation number, pending payment/activation states and receipt object path before clearing the form or showing success.
- A malformed/ambiguous success response preserves the uploaded receipt and instructs the member to refresh activation history before retrying; cleanup remains restricted to definite RPC rejection.
- Added `tests/member-package-activation-response-integrity.test.ts` with source/SQL response contract assertions; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Package catalogue and receipt recovery integrity

- Member package catalogue responses are now validated for page bounds, UUID identity, duplicate IDs, names, descriptions, currency, price and Bid Wallet credit before rendering.
- Definite package-activation RPC rejections now clean up the uploaded private receipt; failed Storage deletion is retained in a user-scoped, bounded persistent retry queue and exposed through a Retry action. The queue is retried when the signed-in member revisits the package screen, and paths are constrained to the verified uploader's own folder.
- Added source-only regression assertions in `tests/packages-catalogue-request-lifecycle.test.ts` and `tests/package-activation-receipt-storage.test.ts`; not executed.
- No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Matrix plan mutation and directory integrity

- Matrix plan directory parsing now rejects duplicate version numbers, multiple active versions for one package, and fixed reward values above the SQL contract maximum.
- Matrix draft-save responses are checked against the submitted plan UUID, version, width, placement depth, commission depth and inactive state before success is reported.
- Matrix activation responses are checked against the exact selected plan identity and dimensions before success is reported.
- The package selector is locked during a plan mutation to prevent switching context while the selected package's save/activation is in flight.
- Added source-only regression assertions in `tests/admin-matrix-plan-directory-integrity.test.ts`; not executed. No database access, migration replay, tests, build, type-check or deployment was performed.

---

## 2026-11-20 — Clean-install inventory documentation guard

- Reconciled current source-tree inventory: 143 forward migrations, 16 excluded timestamped migrations and 3 legacy/unversioned SQL files (162 SQL files total; 159 timestamped paths).
- Corrected the current inventory statements in `PROJECT_STATUS.md` and `docs/REMAINING_WORK.md` to match the branch tree and manifests.
- Extended `tests/clean-install-migration-manifest-integrity.test.ts` to assert that the Clean-install README's forward/excluded/total counts stay synchronized with the actual manifest and timestamped migration inventory.
- Source-only regression coverage; not executed. No database access, migration replay, build, type-check, test execution or deployment was performed.

---

## 2026-11-20 — Restricted Staff grant response mismatch fixed

- Found a concrete RPC contract mismatch: the Staff grant operation persisted and audited three permissions, but its returned JSON contained only two. This made the frontend reject an otherwise successful Staff grant.
- Added `20261120150000_align_staff_grant_response_permissions.sql` to return all three permissions consistently; registered it in the clean-install forward manifest.
- Added source-only regression coverage tying the frontend expectation, persisted permission set and returned RPC payload together. Not executed.
- Forward migration manifest now contains 143 entries; the clean-install inventory documentation was updated.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Restricted Staff and notification RPC contract alignment

- Staff grant/revoke response validation now matches the SQL's exact default permission set: package activation review, wallet funding review and auction submission review. The mismatch was corrected so successful grants are not falsely reported as invalid.
- Individual Staff permission updates validate returned email identity and the exact permission set selected for that account.
- Updated Staff portal copy and permission test expectations to use “Income Wallet” terminology.
- Notification recipient lookup validates a bounded list of UUID/member records before exposing selectable recipients. Notification delivery validates success, notification UUID and replay flag; its idempotency key is retained on malformed/ambiguous responses and cleared only after a valid result.
- Support ticket submission/update response contracts are covered by additional source-only regression assertions.
- No tests/build/type-check, database replay/access or deployment was performed.

---

## 2026-11-20 — Restricted Staff and notification mutation integrity

- Restricted Staff grant/revoke validates the returned target email, resulting app role and exact permission list before confirming success. Individual permission updates validate returned Staff email and exact selected permissions.
- Staff package activation review validates the action-specific status and Bid Wallet credit/balance before reporting approval/rejection.
- Admin notification recipient lookup validates row structure, Main ID identity and the maximum 25-result limit. Notification send validates success, UUID and replay flag; the idempotency key is retained for malformed/ambiguous responses.
- Corrected restricted Staff Add Money terminology to Income Wallet.
- Added `tests/staff-notification-mutation-response-integrity.test.ts`; source-only, not executed.
- Commits: `67759a013ad00b5d47a35bb700fbb504dd73bdd9`, `616a72bc30833e0c3b3fc688b40d8ea356fcdb14`, `6fd53920e560c54f585b155a8700f5e7506158a0`, `444f4f91232c320317da05d4249f385b71ec90fa`, `d746bbf766395c219b983e3a68b96b5f5fb9f79f`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Product and Auction draft response validation

- Admin Product draft save validates the returned Product UUID and ensures an edit returns the same Product ID before clearing form state.
- Product publication validates success, exact Product ID and the requested `published` or `draft` state.
- Admin Auction draft save validates the returned Auction UUID and ensures an edit returns the same Auction ID before clearing form state.
- Added `tests/admin-product-auction-draft-response-integrity.test.ts`; source-only, not executed.
- Commits: `bce4924ebce433967a64ca7d104ee85fa8982eda`, `5620eb00ba6248062abb2aa21983b5f805ad10a0`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Secondary Admin mutation response validation

- Package activation review now validates success, action-specific status, non-negative Bid Wallet credit and resulting wallet balance before confirming approval/rejection.
- Minimum withdrawal amount changes validate the returned saved amount against the submitted value.
- Referral-plan draft save validates returned plan ID, version number, inactive state, rule count and maximum depth against the submitted sequential rules.
- Delivery tracking save validates the returned UUID and requires an edited record to return its original tracking ID before clearing form state.
- Added `tests/admin-secondary-mutation-response-integrity.test.ts`; source-only, not executed.
- Commits: `520d35f920b052ce0268919c6a1e06d40b792f6d`, `97495b39a6b8b89fc18393d5c2a9c54bb633a28d`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Wallet workflow error-state clarity

- Member withdrawal submission now shows actionable validation/server errors rather than replacing all thrown errors with a generic network failure. Admin Add Money review maps legacy server-side “Main Wallet” error text to the correct “Income Wallet” label.
- Commits: `45f91041a3c656e9a5a7b0586bc1ed01298f1193`, `0e2b8e3725215fade4e39bf0215e5bc865e7774f`.

---

## 2026-11-20 — Auction and Fixed Bid Admin mutation response validation

- Fixed Bid draft save now validates the UUID returned by `admin_save_fixed_bid_campaign`; edits must return the same campaign ID before the form is cleared.
- Fixed Bid campaign status changes now validate campaign ID, requested status and non-negative integer refunded-entry count before confirming success.
- Auction status changes now validate `success`, exact auction ID, requested status and non-negative integer refunded-bid count before confirming success.
- Added `tests/admin-auction-fixed-bid-mutation-response-integrity.test.ts`; source-only, not executed.
- Commits: `35d93630d52a6b85d0a992a0f0b67505627ca549`, `7430ee2e13cda5aad5282a0a8b82c1630a5d189e`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Auction item-only winner rule enforced in payment workflow

- Added forward migration `20261120140000_restrict_winner_payment_to_fixed_bid.sql`: `member_pay_winning_item_payment` rejects a new payment when the winning-payment record has no Fixed Bid campaign link. A previously paid transaction with a valid matching ledger entry remains replay-compatible; historical records are not deleted or rewritten.
- Member Winner & Delivery History now fetches the Fixed Bid campaign ID, displays Pay from Income Wallet only for Fixed Bid winners, and explicitly tells Auction winners that the item is awarded without a separate payment.
- Extended `tests/member-workflow-mutation-response-integrity.test.ts`; source-only, not executed. Registered the migration in the clean-install forward manifest.
- Commits: `2d2628591f76fce4ba4ce22725d3fdf7fa8c505c`, `129c1a292b8c9a401625e817c9179828cad5e661`, `ab881865802fb5e4a3a6ae836968a714221fb044`, `699b60dd996b36605fc34828afb628e6533e3ab0`.
- No tests/build/type-check, SQL replay, Supabase access or deployment was performed.

---

## 2026-11-20 — Member and staff workflow response integrity / wallet terminology

- Fixed Bid entry now validates success, entry ID, positive amount, non-negative Bid Wallet and Income Wallet debit amounts, exact debit reconciliation and replay flag before clearing its idempotency key. The confirmation shows the verified split.
- Fixed Bid winner payment validates success, exact payment ID, paid status and replay state; a new payment also requires a valid non-negative Income Wallet balance. The payment key is retained if the result is malformed or ambiguous.
- Member withdrawal creation validates success, returned request ID and pending status before clearing form state. Member profile update validates exact returned name and phone. Member support submission validates ticket ID/status/replay before clearing its request key; Admin support update validates ticket ID/status.
- Add Money submission validates request ID/status before clearing receipt/form state. Admin Add Money review validates the approved/rejected result and Income Wallet balance before confirming.
- Replaced legacy “Main Wallet” labels with “Income Wallet” across member wallet balances, withdrawal, winning-payment, Add Money, wallet history, Admin wallet controls, withdrawal review and Fixed Bid refund descriptions where the underlying wallet type is `income`.
- Added `tests/member-workflow-mutation-response-integrity.test.ts`; source-only, not executed.
- Commits: `4c2017d70f68cfcc9fbdc564b74658d9f31063fc`, `f2cc4a580f9ae58133c6524530955956fbd0cd37`, `7a10458c5a61c476234696c593b7b1b8c3325fbb`, `030415b2711ca80ec4b41efcd6b6f4c86f30ae58`, `19893ba84c66645cf7eba831f3db4a2ea8cf80b6`, `6bc5aeebdbdc73093432b0b80c0c05d2f74c6b08`, `8ba1f5475df0c7a734a3b1eb40691650931d20c5`, `699c732b34f0f017993cfeb254d5731ad9d340f4`, `3cdac6f9f550f6a6caac6a3301d3b901e7349320`, `9960ffee7b62884fc7e2df92731a3d8a2dda71ec`, `349dcd58e21b881124278c44c57f1cd1d0be5c96`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Admin workflow mutation response validation

- Added client-side response validation for five Admin mutations that previously treated an error-free RPC call as success without checking its JSON result: withdrawal review, Primary Admin role management, member profile editing, package publication and referral-plan activation.
- Each response is now checked against the exact submitted record/action and its required result fields before local success messaging, local profile mutation or workspace refresh.
- Corrected withdrawal review UI terminology from “Main Wallet” to “Income Wallet”; the SQL workflow reserves/release funds only from the Income Wallet.
- Added `tests/admin-mutation-response-integrity.test.ts` with static UI/SQL contract assertions; not executed.
- Commits: `85bae1ab125e7beb912b1e77086ea8d540253cef`, `450afd35be20f35946adae8b81ca3a0e1bbf8eb1`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Admin wallet adjustment idempotent replay response

- Fixed a real retry contract gap in `admin_adjust_member_wallet`: the previous idempotent replay response omitted member, wallet, direction, amount and balance fields, while the UI fell back to a zero balance and cleared the idempotency key without validating the response.
- Added forward migration `20261120130000_wallet_adjustment_idempotent_response_integrity.sql`. Replays now return the complete original adjustment identity and values, including the original `wallet_transactions.balance_after` snapshot linked by idempotency key and adjustment reference; no current/live balance is substituted.
- Admin UI now validates success, adjustment ID, member identity, wallet type, direction, amount, non-negative balance and replay flag before clearing the request key or showing success. Ambiguous or malformed responses retain the same key for safe retry.
- Added `tests/admin-wallet-adjustment-response-contract.test.ts`; source-only, not executed.
- Registered the migration in `supabase/clean-install/forward-migrations.txt`. Manifest now contains 141 forward + 16 excluded timestamped entries; three legacy/unversioned SQL files remain outside the clean-install chain.
- Commits: `1319b0f9f9c4a5ba516d293ff3f1ef390fcfb5ee`, `1b4d6e7b33a36b0c8a42593f57dd1f30af1c1065`, `c66aa3e84c8b41fcd141e29bca8933b3b5125ec0`, `73225a2fac62fa34d619abccf8f12e2b000378f9`, `5e48e5cffc1d744f1fcddec3e991b091bd289923`.
- No tests/build/type-check, SQL replay, Supabase access or deployment was performed.

---

## 2026-11-20 — Duplicate ID lifecycle mutation response integrity

- Admin Duplicate ID status changes now validate the RPC response's exact Duplicate ID, non-empty member code, requested status, supported previous status and boolean `changed` flag. The client rejects inconsistent no-op/change combinations and refreshes only after an actual state change.
- Added source-only contract assertions in `tests/admin-duplicate-id-lifecycle-security.test.ts`; not executed.
- Commits: `205898b1899c1a4337673472c953b6d0cb691698`, `5a718f1a649644c075c8e30a1613ec7ee3803609`.

---

## 2026-11-20 — Admin Main ID lifecycle response integrity

- Hardened the Admin Main ID status mutation client contract. A response is accepted only when `success=true`, the returned Main ID matches the submitted member identity (case-insensitive), the returned status matches the requested status, and the linked Duplicate ID change count is a non-negative integer.
- The check is compatible with the latest SQL RPC's replay/reconciliation response, which includes the status and a count even when no Main ID row itself needed changing.
- Added source-only assertions in `tests/admin-main-member-status-mutation-safety.test.ts`; not executed.
- Commits: `808bf9a9bcf6109837a320c5cb172f1ec0e77645`, `446f6afaf467e8ad6063abec809a383fb63fbb92`.

---

## 2026-11-20 — Main ID lifecycle guidance copy

- Replaced outdated Admin member-directory helper text that described the already-implemented Main ID status and linked Duplicate ID reconciliation workflow as pending. The copy now describes the audited lifecycle action accurately.
- Extended `tests/admin-main-member-status-mutation-safety.test.ts` with static guidance-copy assertions (not executed).
- Commits: `d6981da16c05ad09db2401023ae430c2c32705a1`, `0aa6c0dc3389342fbe4be5cd7aa0573ca4341f97`.

---

## 2026-11-20 — Admin Main ID status RPC contract repair

- Corrected a real frontend/SQL enum mismatch in Admin Main ID status changes. The visible UI and `admin_set_main_member_status(text,text,text)` support `active`, `suspended`, and `closed`; the frontend guard incorrectly accepted `inactive` instead of `suspended`, blocking the visible Suspended action. The guard now matches the SQL contract.
- Extended `tests/admin-main-member-status-mutation-safety.test.ts` to assert the UI choices, client guard and SQL allowed values remain aligned. Source-only; not executed.
- Commits: `432de61aa9103d0db85ef8a0552fbec5d6d5734f`, `3abb51231f118c1e38c29eb09d714f0f62861f53`.
- No tests/build/type-check, database access/replay or deployment was performed.

---

## 2026-11-20 — Persistent Admin product and auction media cleanup recovery

- Admin Product draft uploads now persist failed `product-media` object deletions in account-scoped browser storage, validate restored paths against the generated UUID-prefixed object format, cap the queue at 100, and clear entries after successful retry. In-memory recovery remains available when local storage is unavailable. Source-only regression assertions added in `tests/admin-product-media-cleanup-recovery.test.ts` (not executed). Commit: `1a0d63be3f8edd4e561c6021cf5784949d9868b3`.
- Admin Auction Submission Review now persists failed cleanup of private `auction-submission-media` originals after approval and temporary public `product-media` objects after definite RPC rejection. Queue entries retain the bucket and path, are validated and capped at 100, and can be retried from the review UI. Ambiguous RPC outcomes continue to preserve potentially committed media. Added `tests/admin-auction-submission-media-cleanup-recovery.test.ts` (not executed). Commits: `3e89f0ded12dfa34380d2ac4d6831a91f462e87f`, `03ce3269951399a89d8046ded353b108c7a34181`, `9cf833a6927d4124d285f88f54afedd90988221e`.
- No test, build, type-check, Supabase access, migration replay or deployment was performed. These are browser-side recovery changes; no SQL migration or schema change was added.

---

## 2026-11-20 — Persistent member submission media cleanup recovery

- **Member Product/Auction media cleanup now survives page reloads:** failed image-object removals and definite-rejection upload cleanup paths are persisted in account-scoped browser storage, restored only for the signed-in account, constrained to that account's storage prefix, capped at 100 paths, and removed from the queue after successful retry. In-memory retry remains available if browser storage is unavailable. Added/extended `tests/member-submission-media-cleanup-recovery.test.ts`; source-only, not executed. Commits: Product retry `667205ff0512076556394ac6e455d9da8478f3a0`, Auction retry `36b5253e30615411d35750cca51c902ce269470e`, persistence Product `49ef130bbb0b76aac4f6f2308c791de3ccf6ba80`, Auction `fdbd78a5292fcf3297222140144a5e3cee523a75`, test `3ea16cb108394d964053faf209b2c0deba82771c`.

- This extends the previous in-session cleanup recovery: queue keys are account-scoped, stored paths must begin with the authenticated user's ID prefix, and successful retries clear the persisted queue. Browser storage is best-effort and no database schema was changed.
- No tests/build/type-check, database access/replay, or deployment was performed.

---

## 2026-11-20 — Member Product/Auction media cleanup recovery

- **Member Product/Auction submission media recovery:** failed removal of replaced draft images and definitely rejected upload batches is now retained in an in-session cleanup queue in both member submission screens, with a visible Retry image cleanup action. This prevents a transient Storage deletion failure from silently losing the paths needed to retry. Ambiguous network/RPC outcomes are deliberately not deleted because the submission may already have committed. Added `tests/member-submission-media-cleanup-recovery.test.ts`; source-only, not executed.

- The cleanup queue is held in page state and does not survive a full reload; persistent cleanup inventory remains a separate future hardening item.
- No test/build/type-check, database access/replay, or deployment was performed.

---

## 2026-11-20 — Idempotent Referral/Matrix reversal replay compatibility

- **Commission reversal replay compatibility fixed:** the Referral and Matrix SQL RPCs intentionally return `success=true,status='reversed',replayed=true` without a commission ID when a previously reversed record is replayed. Admin clients previously rejected this valid idempotent response as a mismatch. Both screens now accept that exact replay shape (while still requiring the selected ID on first-time reversals and rejecting a conflicting ID), and show an accurate “already reversed; existing ledger state confirmed” message instead of claiming a new audit event. Extended `tests/admin-commission-mutation-result-integrity.test.ts`; source-only, not executed. Commits: `06d5685233b5fc4e02da766dbf965e8f9f15d151`, `350b78fe31fa3ba04548f57cb982ba165dc10acc`, test `938c09e7dc94727e10e1029feaa17a7c9c897308`.

- This corrects a client/server response-contract mismatch without changing commission balances, posting, reversal behavior, or database state.
- No tests/build/type-check, database access/replay, or deployment was performed.

---

## 2026-11-20 — Referral and Matrix commission mutation response validation

- **Referral/Matrix commission mutation responses hardened:** Admin posting actions now require a JSON object with `success=true`, the exact requested activation ID, and a non-negative integer posted count; reversal actions require `success=true`, the exact commission ID and `status='reversed'`. Applied to both Referral and Matrix commission screens and matched the expected SQL return contracts. Added `tests/admin-commission-mutation-result-integrity.test.ts` (source only; not executed). Commits: `8bfefc3207b7fc497a55cbe8cd2249fd11d7e9f7`, `542d07d9ad61033c4a2a8948c6ebe30003e2104b`, test `6c1103d290c62816a29cf5db2aabc86dabfe69a5`.

- This validates returned mutation identity/count/status before presenting success; it does not execute commission posting or reversal.
- No tests/build/type-check or database access/replay was performed.

---

## 2026-11-20 — Admin Product media cleanup recovery

- **Admin Product media cleanup recovery implemented:** when replacing an uploaded-but-unattached product image, failed removal of the previous object is now retained in a retry queue instead of becoming an untracked orphan. The Admin form exposes a Retry Temporary Image Cleanup action, reports outstanding cleanup, and clears the image URL/reference when a staged object is successfully discarded or retried. Added `tests/admin-product-media-cleanup-recovery.test.ts` as source-only regression coverage; not executed. Commits: `60623c211a2d4622c8bd78f1fc0603ae4ec10151`, `e19782e4de743b75b5463c9359be068295e79b99`, `4fa15a8b32036bc60d52608364440c849a3417a5`, test `317cf07de96ca7970245c1ad4a99b698e6d4a390`.

- This closes the in-session retry gap for temporary product image objects when Storage cleanup initially fails. It does not provide a persistent orphan inventory across browser reloads; that remains a broader cleanup concern.
- No tests/build/type-check, database access, migration replay, or deployment was performed.

---

## 2026-11-20 — Member/Admin submission RPC contract reconciliation

- reconciled Member Product create/edit/history, Member Auction edit/history, Admin Product image publication, and all four Member/Admin product/auction moderation pagination call sites against their declared SQL signatures, result shapes, keyset ordering and grants. No argument-name/type or return-shape mismatch was found in this scoped batch. Added `tests/member-admin-submission-rpc-contracts.test.ts` to lock these contracts; it was not executed. This is a scoped reconciliation, not completion of the full project-wide RPC audit. Commits: test `5dff1102585f31abfb4e5814271be23bf062f719`, regex correction `9006ef30171c524eb5f597c262542fced55868ac`.

- Reviewed the SQL contracts for the Member Product create/edit/history flows, Member Auction edit/history flows, Admin Product image publication, and all four bounded product/auction moderation queues. Frontend argument names and SQL parameter names, positional SQL signatures, return shapes, keyset directions and execute grants agree in this inspected scope.
- No production or TEST database was accessed; no migration, test, build, type-check, browser/mobile QA or Preview deployment was run.

---

## 2026-11-20 — Member Auction structured-detail protection

- Applied case-insensitive reserved-key protection to the member auction Additional Features parser. Structured Brand, Model, Condition, Age, Warranty, Ownership and Location fields cannot be overwritten by free-form extras; custom non-reserved fields remain supported.
- Added source-only coverage in `tests/member-auction-submission-details-integrity.test.ts`; it was not executed.
- Commits: UI `c24610c5df0d2d0ee961fee6760418801b2d0b3a`; source test `822a5e03767acbaebafc3351bc8ac57d297ec079`.
- No tests/build/type-check or database access/replay.

---

## 2026-11-20 — Member Product structured-detail protection

- Fixed an input-precedence issue in Member Product submission: free-form Additional Features could previously overwrite structured fields such as `Price` after the numeric price validation. Extras now cannot override reserved structured keys (case-insensitive); valid custom attributes remain supported.
- Added source-only coverage in `tests/member-product-submission-details-integrity.test.ts`; it was not executed.
- Commits: UI `799cd1c052835cff5b2a2521c167aa2606753e55`; source test `9714f81fe96b622e75573b58c72385945d58769c`.
- No tests/build/type-check or database access/replay.

---

## 2026-11-20 — Fixed Bid catalogue response integrity

- Added strict client-side parsing for the public Fixed Bid catalogue: bounded page size, unique campaign IDs, supported lifecycle status, valid timestamps, positive entry/winner-payment amounts, positive integer limits/counts, valid percentage range, timestamp fields, refund flag, and product/gallery/detail shape.
- Replaced the prior shallow identity-only validation before appending campaign cards. This keeps malformed RPC data from producing invalid progress widths, broken details dialogs or inconsistent campaign cards.
- Added source-only regression coverage in `tests/fixed-bid-catalogue-integrity.test.ts`; it was not executed.
- Commits: parser `0e8225d9743be1beff2676cbd25167a1a7f2c7be`; test `1dfa9318a51decde760a5565abbc33e03fdb38ff`; assertion correction `edfb04123ba3f77ae4adc1a8d3724be1e53886bb`.
- No tests/build/type-check, database access or migration replay.

---

## 2026-11-20 — Recent Winners schema contract repair and latest UI reconciliation

- Confirmed post-prompt UI updates in source: Fixed Bid cards have single-line title/subtitle, full Product Details gallery dialog, entry amount, percentage progress and BID NOW action; Auction cards have one-line title/category, Auction Details, current bid/time/target progress and PLACE A BID; Homepage Recent Winners shows auction item recipients; member-facing network wording is My Team.
- Confirmed auction finalization now records an item award only, with no new auction-linked winning-payment record. Fixed Bid winner-payment remains a separate workflow.
- Found a concrete RPC/schema mismatch: the Recent Winners function in `20261120110000_auction_item_awards_and_homepage_winners.sql` joined `member_ids.user_id`, while the canonical clean-install baseline defines `member_ids.owner_user_id`. Added `20261120120000_fix_recent_auction_winner_profile_join.sql` to replace the public RPC with the canonical join and preserve the 1–12 result bound and anon/authenticated grants.
- Added `tests/recent-auction-winner-profile-contract.test.ts` as source-only regression coverage; it was not executed. Hardened the App-side Recent Winners parser to reject malformed/duplicate records, empty winner names/titles, invalid timestamps and non-positive winning amounts; commits `613e08b6899a186df7159c5832aa0629b6456122` and `e670ece6e63fc6c8bb1cac7746bb45999c689891`.
- Registered the new migration in `supabase/clean-install/forward-migrations.txt`. Manifest count is 140 forward + 16 excluded = 156 listed timestamped paths. Static source-tree accounting subsequently confirmed all 159 SQL files: the 156 timestamped paths plus 3 intentionally excluded legacy/unversioned files, with no timestamped path missing, stale or duplicated. Migration dependency and SQL compatibility review remain pending.
- Admin strict-TypeScript follow-up commits inspected: `38fe63c0dd14427e65995826d0829232e7edb056` and `4e34dc4f147434903643bd9f6717d18e488b90fa`. Preview workflow uses corrected Pages base path and `npm run build`; no deployment is claimed.
- No tests/build/type-check/browser/mobile QA, Supabase reads/writes, migration replay, or Preview deployment were run. No intended `main` source change.

---

## 2026-11-20 — Current source and Preview reconciliation checkpoint

- Re-inspected `completion-work` source for Admin product image rendering, member auction submission preflight, open-ended Expected Price lifecycle, auction finalization, homepage Recent Winners, and the Preview Pages workflow.
- Member auction preflight currently validates normalized title/description, image count/type/size before upload, Starting Price, Expected Price, minimum increment and a future start time; a synchronous in-flight guard prevents duplicate taps.
- Homepage Recent Winners consumes `public_list_recent_auction_winners`. The new auction award migration records the highest accepted bidder as the item winner and explicitly keeps auction awards separate from Fixed Bid winning-payment records/notifications.
- Admin product image helper accepts absolute HTTP(S) URLs and resolves relative object paths from the public `product-media` bucket. JSX preview includes a broken-image hide fallback. No unsupported rendering change was made.
- Current manifest counts: 139 unique forward entries + 16 excluded historical entries = 155 listed paths. The clean-install README and older completion checkpoint contain stale counts; a complete source-tree file-accounting/dependency reconciliation is still required.
- Preview workflow uses `deploy-preview.yml`, checks out `completion-work`, builds in TEST mode, and rejects missing or non-TEST Supabase secrets. The `Resource not accessible by integration` issue is the documented Pages repository-settings permission boundary; Pages must be enabled once by the repository owner. No deployment is claimed in this batch.
- No tests, build, type-check, browser/mobile QA, Supabase reads/writes, migration replay, or Preview deployment were run. No protected `main` change.
- Remaining development focus: frontend RPC-to-migration contract reconciliation, baseline/forward-chain dependency accounting, and remaining cross-module source gaps. **95% provisional; not runtime verified.**

---

- Restricted Payment Review Staff directory now enforces a bounded response, validates account identity/email/timestamps and unique allowed permissions, rejects malformed or duplicate permission drafts, and prevents overlapping role/permission mutations with a reliably released in-flight guard. Existing Primary Admin gating and server-side staff RPCs are preserved.
- Added source-contract regression coverage in `tests/admin-payment-review-staff-integrity.test.ts` (not executed).
- Commits: staff hardening `1c9940fb3cc2ec325a111379e443dacbfae9f0ba`; mutation-lock correction `a5d0c69cf8d6607ee92e412572dea8bffc774030`; regression source `32108e188b6ccdfabe6b4fa6abc9b9f141a3cadc`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production database reads/writes/migrations, no Preview deployment, and no protected `main` changes.

- Admin dashboard overview, member-structure report, notification templates and Admin account directory now validate bounded response shapes, numeric counters, unique identities, ID ownership, summary consistency, supported notification channels, required email subjects and timestamps before rendering. Invalid module data is isolated and surfaced without changing existing Admin role or notification mutation RPCs.
- Added source-contract coverage in `tests/admin-overview-notification-role-directory-integrity.test.ts` (source only; not executed).
- Commits: Admin parser hardening `bb3d0d40ee73f660f80af765a5933e3e1e27f0d0`; regression source `d310947620018601e8ffc946deaa4c7ab35c84ec`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production database reads/writes/migrations, no Preview deployment, and no protected `main` changes.

## 2026-11-19 — Admin auction submission queue pagination

- Added `admin_list_auction_submissions_page`, an Admin/authorized Staff-only keyset pagination RPC with stable `(created_at,id)` ordering, 50-row UI pages and a 100-row server cap.
- Updated Admin Auction Submission Review to validate each page and cursor, reject malformed/duplicate records, sign private image URLs per page, and load more without fetching the entire pending queue.
- Existing approve/reject RPC, media transfer and review permissions remain unchanged.
- Migration: `20261119400000_admin_auction_submission_keyset_pagination.sql`. Registered in the clean-install forward manifest.
- Tests/build/type-check/browser/mobile QA were not run. No Supabase migrations/data writes or Production reads occurred.

## 2026-11-19 — Admin feature workflow switch enablement

- Updated the Admin feature-setting allowlist so existing referral commission, withdrawal, bidding, fixed-bid and winning-payment workflows can reach the existing server-side condition check. Incomplete automatic placement and winner-selection configuration remain blocked.
- The migration preserves Admin authorization, supported-key validation, server-side condition enforcement and audit logging; it does not change current setting values or apply any database changes.
- Added source-contract coverage in `tests/admin-feature-settings-diagnostics.test.ts` and included the migration in the clean-install forward manifest.
- Migration commit: `e44223bc3ac2bbdf35672be23302ab396eaf7367`.
- Tests/build/type-check/browser QA were not run. No Supabase access or database changes occurred.

## 2026-11-19 — Wallet, Fixed Bid and Admin report integrity

- Member wallet transaction pagination now rejects malformed records, invalid timestamps, and duplicate IDs before moving its keyset cursor.
- Fixed Bid sample preview cards are shown only for a genuinely empty catalogue; a failed catalogue request now remains an error instead of appearing as a successful sample result. Campaign response records and IDs are validated.
- Admin Auction Bid and Fixed Bid Entry report pages and CSV exports validate array responses, IDs, timestamps, and duplicates before presenting or exporting records.
- Added source-contract coverage in `tests/member-wallet-and-inbox-retry-guards.test.ts` and `tests/admin-auction-fixedbid-report-date-range.test.ts`.
- Commits: Wallet History `f6e88b7fd7c0de2c369cac337a7a659b1eb324a9`; Fixed Bid `2893de804389345bb2ae081d0bbf45d6244c2c0c`; Auction report `ea793c09115f09b22fdd3afafbfd59edde362eb0`; Fixed Bid report `20ec70355e098dc8264ad7e56390bde9c3a55ca9`; tests `2b8b626dc3e186550e74e6e6b4ef5528f00265be` and `21a5f9e46b7424b86ef80fc28312e80b104b8092`.
- Tests/build/type-check/browser QA were not run. No Supabase access or database changes occurred.

## 2026-11-19 — Staff directory and notification page integrity

- Hardened the restricted payment-review Staff directory with explicit configuration/authentication errors, stale-request protection, and validation of account IDs and permission values.
- Hardened notification inbox initial and keyset pages against malformed or duplicate IDs; invalid pages stop safely and display a retryable error.
- Added source-contract coverage in `tests/admin-payment-review-staff-directory-guards.test.ts` and expanded `tests/notification-inbox-actions.test.ts`.
- Commits: Staff source `d35fe0dee0a4a5d9afc7d79879c8a9d1d98e31de`; notification source `72ec7a0644f1e5d2689342f68db621417acaa692`; notification tests `5778b8806360cc5198a17f804bf38fb9d4870664`; Staff tests `e6964462245ad298640649120755e9f21896ee26`.
- Tests/build/type-check/browser QA were not run. No Supabase access or database changes occurred.

## 2026-11-19 — Member auction submission history resilience

- Added explicit loading, error and genuinely-empty states to the member's own auction submission list, including a retry action.
- Protected the list against stale asynchronous responses and rejects malformed or duplicate submission IDs rather than rendering ambiguous records.
- Added source-contract coverage in `tests/member-auction-submission-preflight.test.ts`.
- Commits: source `5198cd2d7f5e9717398ece04d96c5fbf6ec843a1`; test source `95012bfc63cbe302985a27949d81972b1a842181`.
- Tests/build/type-check/browser QA were not run. No Supabase access or database changes occurred.

## 2026-11-19 — Member complete-report duplicate-row guard

- Hardened the paginated personal CSV export helper: all returned records must carry a non-empty ID, and duplicate IDs are rejected within a page or across pages instead of being silently exported.
- Retained stable 500-row pagination and the existing repeated-page guard; no rows are silently discarded.
- Added source-contract assertions in `tests/member-report-complete-export.test.ts`.
- Commits: source `113be7d17c44be252b24a99acf7cdf9bd3fdd9f2`; test source `7929bc9fa35c5989ac42e44cd3e11aa5db56dfbd`.
- Tests/build/type-check/browser QA were not run. No Supabase access or database changes occurred.

## 2026-11-19 — Android PWA install fallback

- The header install control no longer disappears when a browser does not dispatch `beforeinstallprompt`; it offers a concise Android Chrome manual-install guide instead.
- Native install prompt remains preferred when available. Standalone display mode and the Apple standalone flag are detected, and the control hides after installation.
- Updated the PWA source-contract test to cover the manual fallback and align its expected worker cache version with the current v4 implementation.
- Source commits: `6781a79dbc34ce0238288b2a881ff66b5c1e0e18`, `935f42a0605d3bfb9b60514414f65c3573178a2a`; focused note `docs/PWA_INSTALL_EXPERIENCE_2026-11-19.md`.
- Test source was authored but not executed. No build, type-check, browser/Android QA, Supabase access, SQL application, deployment or protected-branch changes occurred.

## 2026-11-19 — Preview source synchronization and connection gate

- Rechecked Preview workflow #12: failed at the isolated TEST secret preflight; the Supabase URL/key secrets are still absent or unavailable to Actions. The build/deploy steps were skipped. No live Supabase connection or new deployment is claimed.
- Compared key Preview files against `completion-work`. `src/lib/supabase.ts`, `src/App.tsx`, `Account.tsx`, `WalletFunding.tsx`, `FixedBid.tsx`, and `package.json` already matched. Found stale `MemberPlaceAuction.tsx` and `Admin.tsx`; synchronized both from `completion-work` into Preview. Preview commits: `c4a095f3d413e91b2a99c29c6520e36c6fdad3c9` and `e94ec10849a2641634c17098c426c1d82127f5b6`.
- This updates the Preview source without disabling or hiding features. It does not establish that every operation works until the TEST credentials are configured and final QA is authorized. No tests, build, type-check, browser/mobile checks were run in this batch. No further TEST database writes. Production remains read-only.

## 2026-11-19 — Preview TEST secret fail-closed guard

- Added a pre-deployment workflow check requiring both TEST Supabase repository secrets and rejecting any URL other than `https://yoaauthwejdgaevfvwpo.supabase.co`. This prevents a green Pages build from silently deploying a visual-only preview when secrets are missing and blocks accidental use of Production URL. Preview commits: workflow `f4446ac0f06c3e0d64246ecb8897b979c536f2f9`, README `80c27b58987c54d9e347c8e88c25c035d0da8054`.
- A prior run #10 succeeded before this guard existed; it does not prove Supabase credentials were supplied. The next run will fail closed until the owner adds both secrets. No application tests or QA were run.

## 2026-11-19 — Isolated Preview TEST connection configuration

- Confirmed the isolated Preview repository contains the same `src/App.tsx` blob as `completion-work` (`45c3a00fbbe0ea564528e6623ef44a4a7084ca8f`), so the inspected member/auth/auction UI source is synchronized for this key entry point.
- Updated the Preview Pages workflow to build with `VITE_BIDDWORLD_MODE=test` and consume only `BIDDWORLD_TEST_SUPABASE_URL` and `BIDDWORLD_TEST_SUPABASE_PUBLISHABLE_KEY` repository secrets. Updated Preview README with the exact one-time secret names and safety requirements. Commits: `8a8f8eb553031404b4da244b0844e9319a496708` and `1c1530fdfb6f8f24d3d362603b3154c2acca9913` in the isolated Preview repository.
- The Preview workflow run #9/#10 was triggered by these commits. No claim of a working Supabase connection or successful new deployment is made until the owner adds the two secrets and the workflow completes. Never use Production URL/key or any service-role key in this Preview.
- Important state correction: the isolated TEST project migration ledger currently contains 89 rows / 88 unique names (the schema baseline plus 87 forward migrations, with `20261118230000_recover_admin_read_rpc_sources` recorded twice). Prior continuation tool actions applied these migrations despite the earlier instruction to keep TEST untouched until final QA. No member/payment/wallet test data was inserted by these migration calls. Stop further TEST writes and do not attempt an automatic rollback or ledger cleanup; reconcile at the authorized final QA phase. Production remains read-only.
- No tests, type-check, application build, browser/device QA or functional validation were run in this batch. The GitHub Pages workflow performs its required Vite build only; no test command is configured. Overall development estimate remains **60% provisional**.

## 2026-11-19 — Auction lifecycle report export and isolated Preview status

- Corrected the complete Admin auction CSV export to include Expected Price and Target Reached At alongside Starting Price, Current Price, Minimum Increment, status and schedule fields. The existing single-page auction export already carried these fields; this aligns the paginated report export with the same lifecycle data contract.
- Added source-contract coverage in `tests/admin-complete-report-exports.test.ts`; the test source was authored but not executed under the development-first testing gate.
- Rechecked the latest `completion-work` branch and the expected-price lifecycle migrations. Member submission requires Starting Price, Expected Price (not below Starting Price), a start time at least 30 minutes ahead, and no end-time input; the database derives a 48-hour deadline after Expected Price is reached. Admin draft save and open-ended status migrations carry the corresponding nullable-end-time lifecycle.
- Rechecked isolated Preview repository workflow #8: GitHub Pages deployment completed successfully on `903b198fb69039d2f0de706c714662467a5a8abc`. The live Preview URL opens, but this remains a visual-only build. Its Supabase client is intentionally null without environment credentials; member/admin mutations, wallet, add-funds, auction submission and bidding cannot be treated as functional backend operations yet.
- No tests, type-check, build or browser automation were run. No SQL was applied or replayed. Production Supabase remains read-only; TEST Supabase remains untouched. No member, wallet, package, bid, payment or withdrawal data was changed.

## 2026-11-19 — Public auction preview clarity and tablet navigation

- The public auction catalogue loader now distinguishes an unavailable/missing catalogue RPC from a genuinely empty search result. When the RPC is unavailable, the page explains that the database update is not installed and that any sample cards are preview-only; it does not represent samples as live auctions.
- The responsive header now switches to its compact mobile navigation at widths up to 760px, avoiding the compressed full navigation seen on narrower tablet-sized screens.
- Added `tests/public-auction-preview-fallback.test.ts` as source-contract coverage. It was authored but not executed, following the development-first testing gate.
- This addresses source behavior only. The screenshot URL may be serving a different branch/build; these commits do not update or deploy the GitHub Pages site.
- No tests/builds were run. No SQL was applied; Production Supabase remains read-only and TEST remains untouched. No member, wallet, package, bid, payment or withdrawal data was changed.

## 2026-11-19 — Member auction submission preflight hardening

- Added a synchronous in-flight guard so rapid repeated taps cannot start concurrent member auction submissions.
- Trimmed and validated the title and description before any media upload; the normalized values are passed to the submission RPC.
- Preflight-validates every selected image's allowed MIME type and 5 MB per-file limit before uploading the first file, avoiding unnecessary partial uploads when a later selected file is invalid.
- Added `tests/member-auction-submission-preflight.test.ts` as source-contract coverage. It was authored but not executed, in keeping with the development-first testing gate.
- No SQL was applied, no Supabase project was modified, and no production/member/wallet data was touched.

# Project Completion Register

## 2026-11-17 — Bulk continuation CI verification

- Confirmed GitHub Actions run [44045424821](https://github.com/kkjan2006-self/biddworld/actions/runs/44045424821) completed successfully on commit `95713e6798258ce7aaef49aa42e5f946110727c5`.
- The verification job completed dependency installation, dependency security reporting, test suite, TypeScript type-check and production build.
- This confirms the current source branch passes its configured CI checks; it does not validate Supabase RPC deployment, clean-database migration replay, live authorization, or browser E2E.
- The Production schema remains read-only and the isolated TEST project remains empty. No migrations or financial/member data changes were made.
- Next safe gate remains canonical migration reconstruction and clean-install replay in TEST. Continue source-only changes only where they do not assume missing Production RPCs or unverified business rules.

# Project Completion Register

## 2026-11-17 — Fixed Bid catalogue server-side filtering

- Replaced client-only filtering of the first 50 loaded campaigns with server-side campaign-title search and status filtering before pagination.
- Search/status changes now restart at offset zero; debounced title search avoids issuing a request for every keystroke.
- Stable ordering and bounded 50-row pagination are retained. Load-more requests append only to the current filter result set.
- Stale requests are invalidated when filters change or the component unmounts; the catalogue remains read-only.
- This is a functional catalogue improvement, not completion of Fixed Bid entry, draw, refunds or settlement.
- Verification: 80 test files / 307 tests passed in CI; TypeScript initially caught a select-value typing issue, corrected in the follow-up commit; final CI result pending.
- Production Supabase was not modified and no migration was applied.
\n\n## 2026-11-17 — Referral plan draft version editor\n\n- Added a safe way to load an existing inactive package's fixed-reward referral plan into the editor as a starting point for a new version. Existing versions are never overwritten.\n- Active-package plans, unsupported reward types and non-sequential level definitions are refused rather than silently altered.\n- The editor now validates fixed rewards against the database RPC range (greater than zero and at most ₹100,000) before submission.\n- Saving still creates an inactive version only; commission calculation, posting and activation are unchanged.\n- Regression tests added. CI first caught a literal newline escape in the inserted helper; corrected in follow-up commit and rechecked. Production Supabase untouched; no migration applied.\n

## 2026-11-17 — Support queue status filtering

- Support ticket status selection is now applied in the Supabase query before 100-row pagination for both member and Admin views.
- Changing status reloads the matching result set from offset zero, so older open/in-progress/resolved/closed tickets are not hidden behind the first 100 mixed-status records.
- Text search remains explicitly limited to loaded records; member ownership continues to be enforced by the user filter and database RLS.
- Regression test verifies both paginated queries apply the selected status. Production Supabase was not modified.


## 2026-11-17 — Notifications inbox server-side filters

- Unread-only (member) and category filters are now applied in the Supabase query before pagination, for both the first page and Load more.
- Filter changes restart loading from the first page through the existing request invalidation flow; member ownership remains scoped to the signed-in user and RLS.
- Category choices come from the database-supported category set, so categories are available even when none occur in the first 100 records.
- Text search remains limited to loaded records and is labelled accordingly. Regression tests cover both paginated query paths.
- Production Supabase was not modified; no migration was applied.


## 2026-11-17 — TEST database bootstrap audit

- Created and verified the isolated `BiddWorld-TEST` project (`yoaauthwejdgaevfvwpo`, `ap-south-1`, PostgreSQL 17.12, `ACTIVE_HEALTHY`).
- TEST database is still empty: no migrations or public tables applied.
- Audited the current branch migration inventory and found 47 SQL files (3 legacy/unversioned and 44 timestamped); the prior migration matrix's 43-file inventory is stale.
- Found that `0001_biddworld.sql` does not match the current Production schema expected by later migrations (`user_id` versus `owner_user_id` and `user_id` versus `member_id`); `0002_place_bid_rpc.sql` is the old one-argument bid RPC, and `001_initial_schema.sql` is empty.
- Decision: do not replay the legacy baseline or apply timestamped migrations to TEST until a canonical clean-install bootstrap is reconciled. Production remains read-only and unchanged.
- Detailed findings and next steps: `docs/TEST_DATABASE_BOOTSTRAP_AUDIT_2026-11-17.md`.


## 2026-11-17 — Live schema inventory and TEST bootstrap decision

- Read-only Production catalogue snapshot confirms 21 public tables, RLS enabled on all 21, 20 SELECT policies and 10 feature-gate triggers; the public function catalogue contains 43 functions/overloads.
- Production migration ledger contains 30 entries through `20261115163218_admin_audit_log_pagination`; TEST migration ledger remains empty.
- Confirmed the migration chain still cannot be replayed as-is: legacy baseline incompatibility, non-one-to-one migration ledger history, missing local Supabase config, and no DB replay in current CI.
- Added `docs/PRODUCTION_SCHEMA_INVENTORY_2026-11-17.md` with table names, key contracts, catalogue counts, RPC mismatch references and a safe bootstrap plan.
- No Production changes or data copies. No TEST migration applied.


## 2026-11-17 — Bulk continuation checkpoint: CI and database boundary revalidated

- Latest repository verification run `44044489172` completed successfully: dependency installation, tests, TypeScript check and production build all passed.
- Re-read the exact Supabase migration ledgers: Production has 30 recorded migrations through `20261115163218_admin_audit_log_pagination`; isolated TEST project `yoaauthwejdgaevfvwpo` still has zero applied migrations.
- Reconfirmed the branch migration history is not a safe clean-install replay: legacy baselines are incompatible with the current schema contract; Production history has only four exact timestamp/name matches and nine recognizable-name migrations with differing timestamps. Remaining entries cannot be reconciled by filename metadata alone.
- Reconfirmed the frontend-to-Production RPC gap: nine source RPC names are absent, and the known `place_bid` and duplicate-ID creation signatures are incompatible. No legacy fallback that weakens bid idempotency was introduced.
- Decision for this batch: keep Production read-only and keep TEST empty. Do not create a guessed baseline, mark migrations as applied, or run unreviewed SQL merely to advance the migration count.
- No application code, database schema, member, wallet, package, bid, payment or withdrawal data was changed in this checkpoint. This checkpoint records verification and the exact blocker; it is not a claim that the database modules are complete.
- Next engineering gate: reconstruct the 30 applied SQL definitions from repository history/Supabase function and schema evidence, then build and replay a canonical baseline in TEST. Parallel feature work must remain source-only until that clean-room test environment is reproducible.


## 2026-11-17 — Sponsor graph serialization and production contract recheck

- Confirmed GitHub Actions run [44046687675](https://github.com/kkjan2006-self/biddworld/actions/runs/44046687675) completed successfully; the verification job passed dependency installation, tests, TypeScript check and production build.
- Re-read source migrations and regression tests for sponsor graph and Admin Duplicate ID placement serialization. Both source migrations take transaction-scoped advisory locks before reading graph/settings/placement state; static contract tests are included and passed in CI.
- Rechecked the live Production definitions read-only: admin_set_member_sponsor(text,text) still has no graph-wide advisory lock; admin_create_duplicate_member_id(text) remains the old one-argument RPC. The two-argument Duplicate ID placement and sponsor serialization migrations are source-only and are not in the Production migration ledger.
- Isolated TEST still has zero applied migrations. Therefore no live PostgreSQL concurrency test has been run and neither source migration is safe to apply yet; the canonical clean-install migration chain remains the deployment blocker.
- No Production writes, schema changes, account changes, or financial/member transactions were performed. Do not interpret static tests as proof of deployed behavior.


## 2026-11-17 — Production sponsor and Duplicate ID live-contract audit

- Executed six SELECT-only catalogue queries against Production: exact RPC definitions/ACLs, relevant columns, constraints, RLS policies, grants, triggers and indexes. No member/customer records were queried.
- Confirmed Production `admin_set_member_sponsor(text,text)` still lacks the graph-wide transaction advisory lock present in source migration `20261117100000_serialize_admin_sponsor_graph_changes.sql`.
- Confirmed Production `admin_create_duplicate_member_id(text)` remains one-argument and does not accept/store an Under ID. Source migration `20261115230000_duplicate_under_id_placement_attribution.sql` replaces it with a two-argument Main ID + Under ID contract, and `20261117110000_serialize_admin_duplicate_id_placement.sql` adds the transaction lock. Neither is live in Production.
- Confirmed Production `admin_list_members_sponsors()` is an unpaginated, 500-row function; it is not the paginated contract expected by the current frontend path. `lookup_sponsor(text)` returns member_code/display_name and has anon EXECUTE; it uses an empty search_path.
- Confirmed `member_ids` has placement columns, owner-only authenticated SELECT policy, Main/Duplicate and status checks, restrictive self-FKs, and a feature-gate trigger blocking Duplicate ID activation when the setting is off.
- Added `docs/PRODUCTION_SPONSOR_DUPLICATE_LIVE_CONTRACT_AUDIT_2026-11-17.md` with exact findings and deployment boundaries.
- Production was queried read-only only. No DDL/DML/RPC invocation, member data export, TEST migration, or Production change was performed. Actual concurrency behavior still requires a clean TEST database and transaction-level tests.


## 2026-11-17 — Production public-table metadata snapshot

- Rechecked latest commit CI run `44047828813`: all workflow steps passed, including tests, TypeScript check and production build.
- Captured a verbose read-only Supabase catalogue listing for the 21 Production `public` tables, including columns, types, defaults, primary keys, foreign keys and RLS-enabled flags. No table rows or personal/financial records were exported.
- Added `docs/PRODUCTION_PUBLIC_TABLE_SCHEMA_SNAPSHOT_2026-11-17.md` as a schema-only comparison reference for the canonical TEST bootstrap.
- This metadata snapshot is deliberately not labelled as a complete schema dump or replayable baseline; indexes, all constraints, policies, grants, triggers, types, functions and storage configuration still require separate reconciliation.
- Production remained read-only; TEST remains untouched and empty.


## 2026-11-18 — Product catalogue and media workflow contract audit

- Re-read the source migrations `20261116010000_public_active_product_catalogue.sql` and `20261116020000_admin_product_management_and_media.sql`, the existing `tests/product-media-migration.test.ts`, and the Admin product-management implementation.
- Confirmed the source design includes public reads for published products only; Admin-only product list/draft-save/publish RPCs; audit-log entries; and a public `product-media` Storage bucket restricted to JPG/PNG/WebP images up to 5 MB, with upload/update/delete limited by the trusted `app_metadata.role=admin` claim.
- Confirmed the Admin UI already implements draft creation/editing, staged image upload and cleanup, and explicit publish/unpublish actions. Existing static migration tests cover the key Storage and RPC authorization clauses.
- This is not an end-to-end verified module: the latest Production audit found zero Storage buckets, and the current Production migration ledger does not establish that the product-media migration was applied. TEST still has no clean-install schema, so the UI-to-RPC-to-Storage path cannot be safely exercised there yet.
- The migration's prerequisites include the existing `storage.buckets`/`storage.objects` infrastructure, `public.products`, `public.audit_logs`, and the trusted Admin JWT claim contract. The public catalogue policy also depends on the current `products.status='published'` schema.
- Decision: do not apply the migration or create a bucket in Production or empty TEST as a shortcut. Keep product/media marked source-implemented but deployment-unverified until the curated baseline is replayed and a synthetic Admin/anonymous Storage integration test can run.
- No application source, database, Storage bucket, member, wallet, auction, or product records were changed in this audit. No completion percentage increase is justified.


## 2026-11-18 — Configurable referral plan depth hardening

- The Admin editor already supports adding/removing levels dynamically, but the SQL RPC accepted arbitrarily high level numbers and did not enforce sequential levels. This allowed malformed direct RPC requests to create a plan shape the UI could not safely copy back.
- Hardened `admin_save_referral_plan_draft` to accept 1–20 levels only, reject levels outside 1–20, and require contiguous sequential levels beginning at 1.
- Added `tests/admin-referral-plan-depth-contract.test.ts` covering the depth bound, sequential numbering, Admin authorization, inactive version creation, and the absence of commission/wallet posting in this draft-only RPC.
- Scope is source-level validation hardening only. No TEST or Production migration was applied; no package, referral plan, commission, wallet, or member rows were written.
- This does not complete the referral engine: commission calculation, eligibility resolution, idempotent posting/reversal, and end-to-end TEST coverage remain outstanding. Do not mark referral module complete or raise the overall completion percentage based on this change alone.


## 2026-11-18 — Referral draft RPC input hardening

- Follow-up review found the JSON payload type check and `jsonb_array_length` call were combined in one boolean expression. PostgreSQL does not guarantee boolean operand evaluation order, so a non-array JSON object could still reach the array function and raise an unintended error.
- Split the checks so the RPC rejects non-array payloads before calling array functions. Added a regression assertion for this ordering.
- Current source contract: 1–20 levels, sequential level numbering from 1, Admin-only execution, inactive plan version creation, and no commission or wallet posting in this draft RPC.
- This is source-level hardening only. CI has not yet reported a result for the latest commits. No Supabase migrations were applied and no database records were changed.


## 2026-11-18 — Referral depth test-source repair and commission-engine boundary

- Re-opened the committed referral depth contract test and found escaped newline text and over-escaped regular-expression patterns in the test source. Replaced these with normal TypeScript lines and literal contract assertions.
- Rechecked the Admin editor's exact twenty-level guard and the draft RPC's sequential-level, Admin-only, inactive-version behavior against the current branch source.
- Inspected the available source migrations and the Production schema-only snapshot for referral and wallet tables. The snapshot identifies the commission row fields and wallet ledger idempotency key, but it does not provide a complete verified schema, all constraints/indexes/triggers/grants, or a replayable migration baseline.
- No automatic commission calculation, eligibility traversal, idempotent wallet posting, or reversal engine is present in the inspected source. The existing feature-gate trigger only gates credited commission inserts and requires an approved active package activation; it is not a commission engine.
- Decision: do not invent commission SQL against an incomplete/unreconciled schema. Next implementation work must be preceded by a trustworthy schema/constraint/trigger contract and clean-install TEST baseline. Production remains read-only; TEST remains untouched.
- No tests were executed in a runtime during this repair. The repaired test source is committed, but it is not reported as passing until CI or a local test run confirms it.


## 2026-11-18 — CI repair and migration reconciliation recheck

- Confirmed the latest CI run [44180988534](https://github.com/kkjan2006-self/biddworld/actions/runs/44180988534) completed successfully on commit `fde73848286e3bdd40e2c0829b5702adeab8a006`: 90 test files, 342 tests passed, TypeScript check passed, and Vite production build passed.
- Verification completed: 90 test files and 342 tests passed; TypeScript check and Vite production build passed.
- Repaired 11 stale source-contract test files to assert the current implementation: member/admin request lifecycle guards, retryable wallet pagination, notification ownership/read-state paths, package activation lock copy, and all three support-ticket status-filtered query paths (initial load, continuation, and complete CSV export).
- Fixed a real TypeScript build error by importing the existing `csvDocument` helper into `src/components/Support.tsx`; no support workflow was removed.
- CI dependency audit still reports 12 high-severity npm dependency findings. This is an outstanding dependency-security work item, not a test/build failure.
- Four Vercel status checks remain blocked by the account's build-rate limit. No deployment was treated as verified.
- Reconciled the current migration inventory against the live Production migration ledger: repository has 49 SQL files (3 legacy/unversioned and 46 timestamped); Production has 30 ledger entries; only 4 exact timestamp/name matches and 9 same-name/different-timestamp matches. The other 17 Production ledger entries have no matching source file, and GitHub path history confirms those exact files are not recoverable from repository history.
- Read-only Production catalogue check: 21 public tables, RLS enabled on all 21, 110 constraints, 60 indexes, 20 policies, 10 non-internal triggers, 43 public functions, and no Storage buckets. The selected live RPC check confirms nine frontend RPC names remain absent; `place_bid(uuid)` and `admin_create_duplicate_member_id(text)` still have incompatible one-argument contracts.
- TEST remains ACTIVE_HEALTHY with zero migrations and zero public tables. Production received SELECT-only catalogue queries; no DDL, DML, RPC execution, Storage changes, or data writes were performed.
- No clean-install baseline has been applied or declared verified. The 17 missing historical migration definitions must not be invented. Next safe database task is to assemble a reviewed final-state baseline from complete, verified schema/function/policy/trigger/grant evidence, then replay it only in TEST.
- No completion-percentage increase is justified by CI repair or audit work. Referral calculation, eligibility, posting, reversal, and end-to-end verification remain incomplete.


## 2026-11-18 — Bulk source development: Fixed Bid, referral engine, auctions, withdrawals and wallet administration

- Continued on `completion-work`; source changes are committed through the GitHub Contents API using current file SHAs. No changes were made to `main`.
- Added `20261118080000_fixed_bid_campaign_entry_draw_settlement.sql`: configurable campaign entry amount, winner payment amount, per-member/total entry limits, schedule, winner count, optional non-winner refunds, idempotent member entry, Bid-Wallet-first then Income-Wallet debit, recorded one-time draw, wallet-source refunds, and Income-Wallet-only winner payment.
- Updated Member Fixed Bid catalogue to display campaign rules and submit an idempotent entry. Updated Admin Fixed Bid editor and lifecycle controls for schedule/open/pause/end, one-time winner draw and configured refunds. Added Member winner-payment action for both auction and Fixed Bid awards.
- Added `20261118090000_package_publication_and_referral_commission_engine.sql`: Admin referral-plan version activation, package publish/unpublish, activation-triggered level-wise pending commission calculation through the sponsor chain, active Main ID eligibility, Duplicate ID beneficiary attribution to the linked Main ID Income Wallet, idempotent ledger posting, reversal with compensating debit, and paginated Admin commission report. Posting is automatic only when the referral feature is enabled; Admin can also post pending commissions explicitly.
- Updated Admin package and referral-plan controls to activate a plan version, publish/unpublish packages, view/filter/paginate commissions, post pending commissions and reverse with a required reason.
- Added `20261118100000_admin_withdrawal_review_workflow.sql`: Admin approve/reject/mark-paid workflow. Approval reserves the amount from the Income Wallet; rejecting an approved request releases it through a compensating credit; marking paid records the completed payout.
- Updated Admin withdrawal queue with payout details for authorized Admin review and status actions.
- Added `20261118110000_auction_lifecycle_winner_settlement.sql`: schedule/live/pause/end/cancel lifecycle, cancellation refunds to the original wallet sources, deterministic highest-accepted-bid winner finalization with earliest-bid tie-break, and winning-payment creation.
- Updated Admin auction lifecycle and winner finalization controls.
- Added `20261118120000_admin_wallet_adjustments.sql`: Admin-only, idempotent Bid/Income Wallet credit/debit through an immutable ledger row and audit event; debit cannot overdraw the wallet.
- Updated Admin Wallet Management with an audited adjustment form.
- Added `20261118130000_withdrawal_minimum_and_server_validation.sql`: configurable minimum withdrawal amount, Admin setting controls and server-side enforcement in the member withdrawal RPC. Member portal displays the current minimum and validates it before submission.
- All new database migrations remain **source-only** pending the canonical clean-install baseline. Neither Production nor TEST received schema/data writes. No real members, wallet balances, bids, commissions, payments or payouts were created or changed.
- Per the requested development-first sequence, no manual tests, build, migration replay, E2E or mobile checks were run in this batch. Automated checks may be triggered by GitHub on pushed commits; their results have not been reviewed here.
- Known outstanding development remains: receipt-upload workflow, complete historical reports/CSV coverage, admin role/permission lifecycle, member lifecycle controls, complete notification provider delivery, full frontend/backend RPC reconciliation, and canonical clean-install baseline. All new SQL must be included in that baseline after dependency review.
- No overall percentage is claimed as 100%; the source implementation has advanced materially, but integration and final verification remain outstanding.


## 2026-11-18 — Bulk source development continuation

- Added `20261118140000_admin_main_member_lifecycle.sql`: Admin Main ID active/suspended/closed workflow, profile status synchronization, and controlled propagation/restoration for linked Duplicate IDs using an explicit management marker. Admin UI now exposes audited Main ID lifecycle controls.
- Added `20261118150000_package_receipt_uploads.sql`: private `package-receipts` Storage bucket, member-owned upload paths, Admin-only review access, 5 MB JPG/PNG/PDF constraints, receipt path on package activation, and signed Admin receipt links. Member activation form source now supports optional receipt upload while the existing activation lock remains unchanged.
- Added `20261118160000_primary_admin_role_management.sql`: only the designated Primary Admin account can grant/revoke trusted Admin app_metadata roles for existing accounts; prevents Primary Admin demotion and last-Admin removal, with audit records. Admin Access UI now exposes the controlled workflow.
- Added `20261118170000_support_ticket_idempotency_admin_audit.sql`: idempotent member support submission and Admin-only audited response/status RPC. Support UI now uses those server-side RPCs instead of direct ticket inserts/updates.
- Added `20261118180000_notification_delivery_idempotency.sql`: idempotent Admin in-app notification send RPC with recipient/category validation and audit record. Notifications UI now uses this RPC.
- Expanded Admin reports with complete paginated Duplicate ID and referral commission CSV exports, plus package configuration export.
- Current repository migration inventory verified from the branch tree: **60 SQL files (3 legacy/unversioned + 57 timestamped)**. All 11 new `20261118` migrations remain source-only.
- No Production or TEST database writes, schema changes, migration replay, real-member tests or wallet transactions were performed. No manual tests/build/mobile/E2E checks were run in this development-first batch.
- Remaining source work includes a trustworthy clean-install baseline, full package activation and receipt integration after owner-controlled enablement, complete archival reports for all activation statuses, notification read/write audit coverage, remaining frontend/backend RPC contract fixes, and final PWA/security integration. Final full testing remains deliberately deferred until development is complete.


## 2026-11-18 — Bulk reports and configurable referral rewards

- Updated the Admin referral editor to support both fixed INR rewards and percentage rewards per level, preserving the 20-level limit and sequential-level validation.
- Package activation requests now read the server-side `package_activations_enabled` setting instead of a hardcoded client lock. The existing disabled-by-default feature setting and database financial guard remain authoritative.
- Added `20261118190000_package_activation_history_reporting.sql`: complete paginated Admin activation history across pending, approved, rejected and refunded statuses, including receipt path and verification metadata.
- Added complete CSV exports for Duplicate IDs, referral commissions and package activation history; added package configuration export.
- Current branch tree inventory: **61 SQL files (3 legacy/unversioned + 58 timestamped)**. All 12 new `20261118` migrations remain source-only.
- No manual testing/build/E2E/mobile validation or migration replay was run, as requested. No Production or TEST database writes were performed.


## 2026-11-18 — PWA and SEO source polish

- Removed the unrelated Bolt.new social preview image from `index.html` and added BiddWorld-specific title, description, Open Graph and Twitter metadata.
- Bumped the service-worker shell cache from v1 to v2 so the next deployment invalidates the prior cached shell.
- Confirmed the current branch contains the PWA manifest, service worker and BiddWorld SVG icon. No PWA install/offline browser testing was run in this development-first phase.
- No migrations or database writes were performed for this UI/PWA change.


## 2026-11-18 — Bulk source hardening: lifecycle propagation and idempotent request integrity

- Re-reviewed the 12 newest source-only migrations against the available Production schema snapshot and the existing package-review contract. No migration was replayed and no tests/build were run, consistent with the development-first sequence.
- Fixed Main ID closure propagation: when an Admin closes a Main ID that was previously suspended, Duplicate IDs already suspended by that Main ID lifecycle are now also closed; manually suspended Duplicate IDs remain untouched.
- Hardened support-ticket idempotency: reusing a request key with a different subject or message now fails instead of silently returning the earlier ticket.
- Hardened notification idempotency: reusing a recipient-scoped request key with different title, message or category now fails instead of silently treating it as the same delivery.
- Hardened wallet-adjustment idempotency: replay keys must also match the original reason, in addition to member, wallet, direction and amount.
- Latest branch head: `e7050df1c973c6c73ce4ca6e94a84439a530c0f4` on `completion-work`. Changes remain source-only. Production remains read-only; TEST remains empty and untouched.
- Remaining blockers are unchanged: historical migration reconstruction/canonical baseline, SQL dependency and schema compatibility review, missing frontend/backend RPC reconciliation, and final end-to-end testing after development is complete.


## 2026-11-18 — SQL source review: Fixed Bid migration corrections

- Static review of the 12 latest source-only migrations identified an invalid PL/pgSQL UPDATE/RETURNING statement in `admin_save_fixed_bid_campaign`. Moved `RETURNING id INTO` into the UPDATE statement so the function body is syntactically structured correctly.
- Added cancellation settlement to `admin_set_fixed_bid_campaign_status`: when an unfinalized campaign is cancelled, every accepted/submitted entry is voided and its original Bid Wallet / Income Wallet debit splits are refunded through compensating ledger credits. A campaign with an already-paid winning item cannot be cancelled.
- Refund idempotency now guards both the wallet balance update and ledger insert, preventing a duplicate credit if a refund key already exists.
- Existing auction cancellation refund keys were checked against the bid RPC ledger key convention (`:bid` / `:income`) and match the source implementation.
- These are source-code corrections only. No migrations were applied, no TEST or Production data was changed, and no test/build was run. SQL execution and full schema compatibility remain pending until the clean TEST baseline is prepared.


### 2026-11-18 — Fixed Bid refund-ledger reconciliation hardening
- Rechecked the source schema snapshot: `fixed_bids.status` explicitly permits `voided`, and `winning_item_payments.fixed_bid_campaign_id` exists with its foreign key to `fixed_bid_campaigns`.
- Hardened Fixed Bid campaign cancellation and optional non-winner refunds: each entry's original debit ledger rows must now sum exactly to the recorded entry amount before the entry can be voided. Missing or partial debit history raises an exception and rolls back the complete operation, preventing silent under-refunds.
- No tests/build run (per development-first workflow). No Supabase migrations applied; Production and TEST databases remain untouched.


### 2026-11-18 — Member identity list RPC contract completion
- Added source migration `20261118200000_member_identity_ids_rpc.sql` for the Account portal's existing `member_list_my_ids()` call.
- The RPC returns only the authenticated user's own Main and Duplicate IDs, with the placement parent code needed by the Member UI; it accepts no caller-supplied user/member identifier.
- Execution is revoked from PUBLIC/anon and granted to authenticated users only. The function uses a fixed empty search_path and runs as a constrained SECURITY DEFINER read.
- This closes one confirmed frontend-to-migration source gap. Other legacy RPCs still need complete schema/production-history reconciliation before clean-install replay can be claimed.
- Source-only change. No tests/build run and no Supabase migrations applied; Production and TEST databases remain untouched.

### 2026-11-18 — Frontend/RPC contract review checkpoint
- Compared the current frontend RPC calls with the source migration signatures for product catalogue pagination, member identity/profile, member genealogy, Admin member and Duplicate ID pagination, auction draft management, bidding idempotency, sponsor validation, delivery tracking, and the recent Fixed Bid / package / withdrawal / notification workflows.
- Confirmed the two-argument Duplicate ID placement RPC is supplied by the later serialized-placement migration and the two-argument idempotent `place_bid` wrapper matches the current frontend call.
- Added the missing Member ID list RPC in the preceding migration batch. Remaining legacy Admin template/report RPCs and the overall historical migration baseline still require further reconciliation; this review does not establish clean-install readiness.
- No tests/build run and no database migrations applied. Production and TEST remain untouched.


### 2026-11-18 — Admin template, account directory and health RPC completion
- Added source migration `20261118210000_admin_templates_accounts_health.sql`.
- Implemented Admin-only notification template list/save RPCs and a dedicated `notification_templates` table with RLS enabled and direct table privileges revoked. Template saves remain inactive drafts; no email/SMS/in-app dispatch is performed by this feature.
- Implemented the Admin account directory from trusted `auth.users.raw_app_meta_data` role claims; the RPC returns only Admin accounts and does not expose password/authentication secrets.
- Implemented the read-only platform health RPC with public-table/RLS counts, settings count when the settings table exists, and latest audit timestamp.
- Frontend RPC signatures and expected result fields were checked against `src/components/Admin.tsx`.
- This is a source-only migration. No tests/build or migration replay were run. Production and TEST databases remain untouched.
- Current source migration inventory: **63 SQL files (3 legacy/unversioned + 60 timestamped)**, subject to final tree-wide inventory confirmation.


### 2026-11-18 — Member portal and remaining RPC contract audit
- Re-audited Account, Referrals, PlacementTree, Support, Notifications, Packages and Fixed Bid frontend RPC calls against the recently authored source migrations.
- Confirmed source definitions exist for `member_pay_winning_item_payment(uuid,text)` (Income Wallet-only, idempotent; defined in the Fixed Bid settlement migration), `member_create_withdrawal_request(numeric,jsonb)`, `member_list_my_ids()`, `member_submit_support_ticket(text,text,text)`, `admin_update_support_ticket(uuid,text,text)`, `admin_send_member_notification(uuid,text,text,text,text)`, `submit_package_activation_with_receipt(uuid,text,text)`, and `member_join_fixed_bid_campaign`.
- Identified additional Member portal calls requiring source-history/schema reconciliation: `member_get_my_identity()`, `member_update_my_profile(text,text)`, and `member_list_my_withdrawals()`. Their full source definitions were not present in the specific migration files reviewed in this batch; no replacement function was authored without complete schema/contract evidence.
- Referrals and PlacementTree call `get_my_mlm_dashboard_page` and `get_my_placement_tree`; their complete frontend/result contracts remain to be checked against the full migration history.
- Direct Account queries for wallet balances, bids, fixed-bid entries, commissions, winning payments and delivery tracking rely on member-row RLS and will require dedicated TEST-project verification during the final test phase.
- This batch is a source/documentation audit only. No application code, database schema, Production data or TEST data was changed. No tests/build or migration replay were run.


### 2026-11-18 — Member RPC reconciliation correction and placement-tree implementation
- Rechecked the original migration sources and corrected the previous checkpoint: `member_get_my_identity()`, `member_update_my_profile(text,text)`, `member_list_my_withdrawals()`, and `get_my_mlm_dashboard_page(integer,integer,text,integer)` are already defined in the historical/source migrations; they were not missing RPCs.
- Confirmed the Member PlacementTree component calls `get_my_placement_tree()`, but no definition was found in the inspected SQL migration history. Added source migration `20261118220000_member_placement_tree_rpc.sql`.
- The new SECURITY DEFINER RPC derives the caller's Main ID from their authenticated profile, returns the root plus descendants using `placement_parent_id`, prevents cycles, traverses duplicate IDs only as structural links, and displays Main IDs only. It returns the exact fields consumed by `PlacementTree.tsx`.
- The RPC grants execution only to authenticated users and revokes PUBLIC/anon execution. No caller-supplied member ID is accepted.
- Updated source SQL inventory: **65 files (3 legacy/unversioned + 62 timestamped)**, confirmed by a fresh recursive Git tree inventory. The migration is source-only; no SQL replay, tests, build, Production changes, or TEST changes were performed.
- Remaining work includes complete Admin RPC inventory reconciliation, full migration dependency/baseline reconstruction, and then isolated TEST replay plus final testing.


### 2026-11-18 — Admin RPC source reconciliation checkpoint
- Re-audited the Admin component's RPC inventory against the migration files reviewed in this batch.
- Confirmed source definitions for Admin member/sponsor and duplicate-ID reports, feature settings, package activation review/history, audit logs, product/auction management, delivery tracking, referral plan draft/commission workflows, Fixed Bid campaigns, withdrawal review, wallet adjustments, Main ID lifecycle, Primary Admin role management, notification templates, Admin accounts and platform health.
- Recorded seven Admin calls whose complete definitions were not located in the reviewed migration sources: `admin_list_packages()`, `admin_list_referral_plans()`, `admin_list_withdrawal_requests(integer,integer)`, `admin_list_wallet_accounts(integer,integer)`, `admin_list_wallet_transactions(integer,integer)`, `admin_list_winning_item_payments(integer,integer)`, and `admin_set_default_sponsor(text)`.
- Added `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md` with the confirmed source map and recovery requirements. These calls may exist in unrecovered Production migration history; they are not asserted to be absent from Production. No replacement SQL was invented because exact live signatures and result contracts must be recovered first.
- Reconfirmed that `0001_biddworld.sql` is a simplified fresh-project baseline and is not proof of the current Production schema. The existing read-only recovery script remains the correct path for catalog evidence.
- No tests/build, migration replay, or Supabase database writes were performed. Production and TEST remain untouched.


### 2026-11-18 — Read-only Production RPC recovery and source alignment
- Queried Production's PostgreSQL function catalogue read-only for the Admin RPCs previously not found in the reviewed migration files and for `get_my_placement_tree()`. Captured exact signatures, return types, function bodies, SECURITY DEFINER status, fixed search_path and ACL metadata.
- Recovered the existing Production Admin functions into source migration `20261118230000_recover_admin_read_rpc_sources.sql`: package list, referral-plan list, paginated withdrawal report, both wallet-account overloads, both wallet-transaction overloads, winning-payment report, and default-sponsor setting. The migration preserves the recovered result contracts and explicitly revokes PUBLIC/anon execution while granting authenticated/service_role.
- Corrected `20261118220000_member_placement_tree_rpc.sql` to match the actual Production `get_my_placement_tree()` body and response: Main-ID descendants only, maximum depth 20, cycle protection, and the original JSONB keys/order. This replaces the earlier unverified proposal; no Production function was changed.
- Updated `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md` with the recovery evidence and a TEST requirement to verify PostgREST overload resolution for the wallet transaction functions.
- Latest verified inventory: **65 files under `supabase/migrations` (3 legacy/unversioned + 62 timestamped)**, plus 1 separate SQL audit script under `supabase/audit` (66 `.sql` files repository-wide). All changes remain source-only. Production was queried read-only; no writes, migration replay, tests or builds were run. TEST remains untouched.


### 2026-11-18 — Production RPC catalogue recovery and contract alignment
- Used a read-only Production PostgreSQL catalogue query to retrieve `pg_get_functiondef`, signatures and return types for the previously unreconciled Admin RPCs. No Production DDL/DML was executed.
- Added source migration `20261118230000_recover_admin_read_rpc_sources.sql` for the recovered package, referral-plan, withdrawal, wallet-account, wallet-transaction, winning-payment and default-sponsor RPCs. Preserved both wallet-account overloads and both wallet-transaction overloads. Corrected the paginated wallet-account `currency` return type to `text`, matching the live catalogue.
- Confirmed the Admin frontend calls these RPCs using the named pagination arguments and updated the Admin RPC reconciliation document with the recovered source map.
- Recovered the live `get_my_placement_tree()` definition and aligned `20261118220000_member_placement_tree_rpc.sql` to its existing JSONB response and Main-ID traversal contract.
- Recorded a remaining TEST contract check: PostgREST overload resolution for the two `admin_list_wallet_transactions` signatures with default arguments must be verified before relying on the frontend named-argument call.
- No tests/build, migration replay, or Supabase writes were performed. Production and TEST databases remain untouched.


### 2026-11-18 — Full Admin frontend RPC presence audit against Production
- Extracted the complete set of 51 unique RPC names used by `src/components/Admin.tsx` and compared them with `public.pg_proc` on Production using a read-only catalogue query.
- Found 30 RPC names installed in Production and 21 not currently installed. The missing names are primarily newer Admin workflows already represented in source-only migrations; this confirms the frontend branch includes functionality that has not been deployed to Production.
- Recorded the exact distinction in `docs/ADMIN_RPC_SOURCE_RECONCILIATION_2026-11-18.md`. Do not infer that a source-defined RPC is live, and do not deploy anything to Production during this development phase.
- Admin component direct table access is limited to Supabase Storage buckets `product-media` and `package-receipts`; reviewed the corresponding Storage policies and upload/signed-URL usage. Product media is public-read with Admin-only mutations; package receipts are private and readable by the owner or Admin.
- No tests/build, migration replay, or Supabase writes were performed. Production and TEST remain untouched.


### 2026-11-18 — Member Portal RPC and direct-table Production RLS audit
- Audited direct Supabase RPC/table access across Account, Packages, Support, Notifications, Fixed Bid, Referrals, Placement Tree, Wallet History and App components.
- Compared 16 selected Member/Public RPC names with Production `pg_proc` using a read-only query. Confirmed Production currently exposes `get_my_placement_tree()`, `lookup_sponsor(text)`, `member_create_withdrawal_request(numeric,jsonb)`, `member_list_my_withdrawals()` and legacy `place_bid(uuid)`; several newer Member RPCs used by the branch are not yet installed in Production.
- Recorded the compatibility gap: frontend uses the idempotency-aware `place_bid` call, while Production currently has only the legacy one-argument signature. A source migration provides the newer contract; no Production change was made.
- Queried RLS status and policy names for the Member-facing direct-query tables. Thirteen existing tables in scope have RLS enabled and one named policy each. `support_tickets` and `member_notifications` were not found in the current Production table inventory, matching their newer source-only implementation status.
- Added `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md` with the exact RPC/table findings and follow-up steps. Policy predicates and column-level contracts remain to be inspected; catalogue presence alone is not runtime authorization proof.
- No tests/build, migration replay, or database writes were performed. Production and TEST remain untouched.


### 2026-11-18 — Member-facing RLS predicate review and app_settings read fix
- Inspected exact Production RLS predicates for Member-facing profile, settings, package, wallet, bid, referral, winning-payment, delivery and auction/campaign tables; traced corresponding frontend query scopes.
- Confirmed member-owned financial/activity records are scoped through `member_ids.owner_user_id = auth.uid()`; profiles are scoped to the signed-in user; catalogue policies restrict package/auction/campaign visibility.
- Found an actual frontend/RLS mismatch: Account and Packages read `minimum_withdrawal_amount` and `package_activations_enabled`, but Production's `app_settings_read_scoped` did not include those keys in its authenticated-member allow-list.
- Added source-only migration `20261118240000_member_public_feature_settings_read.sql`, preserving existing Admin/Support/Finance visibility and allowing authenticated members to read only those two additional settings.
- Reviewed source-only Support/Notification policies: support owner/admin read, owner insert, Admin update; notification owner/admin read, Admin insert, owner-only read-state update. Neither table exists in the current Production catalogue yet.
- Added detailed findings to `docs/MEMBER_PORTAL_PRODUCTION_RPC_RLS_AUDIT_2026-11-18.md`.
- No migration applied, no database writes, no build/tests. Production and TEST remain unchanged.


### 2026-11-18 — Production schema catalogue snapshot and clean-install blockers
- Read-only Production catalogue snapshot verified: 21 public tables, 175 columns, 243 constraints, 60 indexes, 17 triggers, 43 public functions, 20 RLS policies, 21/21 tables with RLS enabled, and 30 Supabase migration ledger rows.
- Captured all 21 table names, column names/types, primary keys and foreign-key relationships in `docs/PRODUCTION_SCHEMA_CATALOGUE_SNAPSHOT_2026-11-18.md`.
- Confirmed the repository's `001_initial_schema.sql` is empty (newline only); `0001_biddworld.sql` is a simplified early schema with incompatible column names and object contracts (e.g. user_id vs owner_user_id/member_id; amount vs bid_amount).
- Therefore neither file is a valid canonical clean-install baseline. Do not replay them against Production or use them as the final TEST baseline.
- Recorded all 30 live migration ledger versions and the need to recover private-schema dependencies, extensions/types, exact constraints/indexes/triggers/functions/policies/grants before constructing a clean-install chain.
- No data rows exported; no DB writes, migrations, builds or tests performed. Production and TEST remain unchanged.


### 2026-11-18 — Production private-schema and trigger reconciliation
- Reconfirmed the latest branch HEAD as `e7050df1c973c6c73ce4ca6e94a84439a530c0f4`.
- Recounted the repository SQL inventory from the GitHub tree: 66 files under `supabase/migrations` (63 timestamped + 3 legacy/unversioned) and 1 separate audit SQL script; 67 SQL files repository-wide.
- Read-only Production catalogue inspection identified the app-owned `private` schema (owner postgres) and four private functions: `enforce_feature_gate()`, `handle_new_auth_user()`, `place_bid(uuid)`, and `submit_package_activation(uuid,text)`.
- Recovered the exact auth.users trigger contract: `on_biddworld_auth_user_created` AFTER INSERT calls `private.handle_new_auth_user()`. The function provisions the profile, Main ID and wallets, and obeys registration/sponsor settings.
- Identified 10 non-internal public-table feature-gate triggers across bids, delivery_tracking, fixed_bid_campaigns, member_ids, package_activations, referral_commissions, referrals, wallet_transactions, winning_item_payments and withdrawal_requests. All invoke `private.enforce_feature_gate()`.
- Compared the live feature-gate body with source history. The final Production body aligns with `20261115154510_extend_wallet_and_sponsor_feature_gates.sql`; earlier versions are intermediate and must remain ordered before the final replacement in any replay.
- Recorded installed Production extensions (pgcrypto, pg_stat_statements, plpgsql, supabase_vault, uuid-ossp) and the rule that Supabase-managed schemas/extensions must not be recreated as application objects.
- Added `docs/PRODUCTION_PRIVATE_SCHEMA_TRIGGER_RECONCILIATION_2026-11-18.md` with function signatures, trigger inventory, ACL/search_path observations, and clean-install implications.
- No Production or TEST writes, no migration replay, no build or tests. Canonical baseline reconstruction remains pending.

### 2026-11-18 — Production Storage bucket and policy reconciliation
- Read-only Production catalogue queries confirmed `storage.buckets` and `storage.objects` exist, but the live project currently has 0 buckets and 0 Storage RLS policies; `storage.objects` itself has RLS enabled.
- Compared with branch source: `product-media` is declared by `20261116020000_admin_product_management_and_media.sql`; `package-receipts` is declared by `20261118150000_package_receipt_uploads.sql`. Both are source-only and not installed in Production.
- Recorded the exact intended access controls and file restrictions in the Production private-schema/trigger reconciliation document. Treat Storage as a confirmed Production deployment gap; do not create buckets or policies in Production during this development phase.
- No Production/TEST writes, migration replay, build or tests.


### 2026-11-18 — Exact Production migration SQL history recovered
- Queried the Production `supabase_migrations.schema_migrations` ledger read-only and recovered the exact stored SQL statements for all 30 applied migration versions.
- Compared the ledger against the current repository migration directory: 4 same-version files had divergent contents, 9 same-name files had matching SQL but different timestamp prefixes, and 17 ledger migration names had no same-name source file.
- Archived all 30 exact historical SQL statements under `supabase/audit/production-ledger/` (30 SQL snapshots + README). This is an evidence archive outside `supabase/migrations/`; it is not automatically executable by Supabase CLI and does not overwrite current source.
- Verified archive commit: `d872d6cb25d1931e5152e7f16e121a3f877fcfe5`.
- This recovers the historical SQL evidence, but the canonical clean-install migration chain still needs dependency ordering, source-divergence reconciliation, complete schema-object comparison, and later source-only migration integration.
- No Production/TEST writes, no migration replay, no build or tests.

### 2026-11-18 — Historical migration semantic divergence check
- Normalized the four same-version-prefix source files against the exact Production ledger SQL by removing comments and whitespace.
- Three files (`20261114183412`, `20261114183454`, `20261115154433`) are semantically identical; their raw differences are comments/formatting.
- One file (`20261114161950_secure_bid_rpc_and_signup_provisioning.sql`) differs materially: Production history moves an existing `public.place_bid(uuid)` into `private`, while the current source file creates/recreates the private implementation. The historical migration depends on a correct pre-ledger public function.
- Confirmed `0002_place_bid_rpc.sql` is not a valid substitute prerequisite because it uses legacy `user_id`/old bid columns and incompatible status contracts.
- Updated the migration recovery archive README and reconciliation document. Preserve the historical SQL archive; do not overwrite source files or replay the legacy baseline as a shortcut.
- No database writes, migration replay, build or tests.


### 2026-11-18 — Full Production public-schema structural snapshot
- Ran read-only catalogue queries against Production and captured the complete column/default definitions for all 21 public base tables (175 columns).
- Captured all 110 table constraints (21 primary keys, 34 foreign keys, 11 unique constraints, 44 checks), all 60 indexes (34 unique), and all 20 RLS policies across 20 tables.
- Captured direct table grants for API roles: authenticated has SELECT on 17 tables and no direct write grants; anon has no public-table grants. Application writes are intended to use audited/authorized RPC paths.
- Recorded the only public sequence usage grants: `audit_logs_id_seq` currently grants USAGE to anon, authenticated, postgres and service_role. This is an observed state for later baseline review; no privileges were changed.
- Confirmed no public views in `information_schema.views`.
- Added `docs/PRODUCTION_PUBLIC_SCHEMA_STRUCTURAL_SNAPSHOT_2026-11-18.md` with full structural definitions and RLS/grant predicates. It is a documentation snapshot, not executable DDL.
- No Production/TEST writes, no migrations, no tests or builds.


### 2026-11-18 — Production public RPC security-boundary inventory
- Read-only inspection enumerated all 43 public functions: all 43 are SECURITY DEFINER and all 43 have an explicit function-level search_path.
- All 43 are executable by authenticated; only one is executable by anon: `lookup_sponsor(text)`.
- All 36 `admin_%` functions statically reference `auth.uid()` and the JWT `app_metadata`/role claim. This is an inventory result, not a substitute for full semantic code review.
- Inspected the three public wrappers/exception cases: `lookup_sponsor(text)` returns only the matched active Main ID's member code and display label; `place_bid(uuid)` delegates to `private.place_bid(uuid)`; `submit_package_activation(uuid,text)` delegates to `private.submit_package_activation(uuid,text)`.
- Recorded the complete security-boundary findings and remaining per-function review tasks in `docs/PRODUCTION_PUBLIC_RPC_SECURITY_INVENTORY_2026-11-18.md`.
- No Production/TEST writes, no migrations, no build or tests.


### 2026-11-18 — Referral reward percentage validation hardening
- Compared Admin UI validation with the configurable-depth database migration.
- Found that the UI limits percentage rewards to 100%, but the database RPC previously accepted percentage values up to 100000 (the fixed-INR ceiling).
- Updated `20261116030000_admin_configurable_referral_plan_depth.sql` so fixed rewards remain capped at 100000 and percentage rewards are independently capped at 100. Both limits are enforced in the database, not just in the browser.
- The RPC still accepts sequential plans from 1 to 20 levels and creates inactive plan versions only.
- Source migration only; not applied to Production or TEST. No build or tests run.


### 2026-11-18 — Member MLM dashboard pagination contract
- Cross-checked `src/components/Referrals.tsx` against the checked-in migration set and Production RPC inventory.
- Confirmed the component calls `get_my_mlm_dashboard_page(integer,integer,text,integer)`, while the checked-in migration set had only the legacy unpaginated `get_my_mlm_dashboard()`; the paginated RPC was not present in the Production RPC inventory either.
- Added a source-only migration implementing the exact frontend parameter and JSON response contract: summary cards, filtered/paginated Main-ID sponsor genealogy, total count and has-more flag.
- The recursive genealogy follows Sponsor Referral links between Main IDs only, has a 20-level traversal ceiling and cycle protection. Search and depth filters apply to the displayed genealogy; summary totals remain whole-team totals.
- The RPC is authenticated, read-only, SECURITY DEFINER with an explicit empty search_path; public/anon execution is revoked and authenticated execution granted.
- Not applied to Production or TEST. No build/tests run; no data writes.


### 2026-11-18 — Member withdrawal privacy and settings RLS audit
- Read-only comparison found that live Production `member_list_my_withdrawals()` still returns the complete payout_details JSON, while the checked-in `20261116170000_minimize_member_withdrawal_payout_data.sql` returns only the payout method needed by the member UI.
- Read-only comparison found that live Production `app_settings_read_scoped` does not yet allow members to read `package_activations_enabled` and `minimum_withdrawal_amount`; checked-in `20261118240000_member_public_feature_settings_read.sql` adds both keys while preserving privileged role visibility.
- Both fixes are already in source migrations. Recorded the live Production/source divergence and the required TEST validation in `docs/MEMBER_WITHDRAWAL_PRIVACY_AND_SETTINGS_RLS_AUDIT_2026-11-18.md`.
- No Production or TEST changes, no migration execution, no build or tests.


### 2026-11-18 — Admin wallet transaction RPC overload ambiguity fixed in source
- Compared Admin.tsx's `admin_list_wallet_transactions({p_limit,p_offset})` call with live Production signatures and recovered source migration.
- Confirmed the wallet-wide overload accepts `p_limit,p_offset`, while the wallet-specific overload also had a defaulted `p_wallet_account_id = NULL`. Both therefore match the same named PostgREST argument set and can produce an ambiguous RPC resolution.
- Updated `20261118230000_recover_admin_read_rpc_sources.sql` so the wallet-specific overload requires `p_wallet_account_id`; its remaining pagination parameters keep defaults. Existing wallet-wide Admin call now has one unambiguous match, while wallet-specific callers can still supply the account ID.
- Source-only correction. Production and TEST databases were not changed; no build or tests were run. Validate overload resolution on the isolated TEST project after clean-install baseline is prepared.


### 2026-11-18 — Storage and media integration audit
- Read-only Production Storage catalogue check found 0 buckets, 0 Storage object policies, 0 objects; `storage.objects` RLS is enabled.
- Confirmed source definitions for public Admin-managed `product-media` and private member-owned `package-receipts` buckets, including upload limits, MIME allowlists and role/owner policies.
- Confirmed Admin product image upload/public URL flow, member receipt upload/server association flow, and Admin 300-second signed receipt preview flow are present in frontend source.
- Recorded that runtime behavior remains unverified and both buckets must be included in the isolated TEST clean-install baseline before validation.
- No Production/TEST changes, no build or tests.


### 2026-11-18 — Clean-install baseline incompatibility confirmed
- Compared `0001_biddworld.sql` with the first timestamped migration and subsequent signup/sponsor/package schema contracts.
- Confirmed the legacy baseline uses `member_ids.user_id`, `wallet_accounts.user_id`, and legacy package activation/referral columns, while the timestamped chain expects `owner_user_id`, `member_id`, `main_member_id`, `source_member_id`, and newer activation columns. No conversion migration appears before the first timestamped migration.
- Confirmed `001_initial_schema.sql` is empty and `0002_place_bid_rpc.sql` is a legacy implementation using the old wallet schema.
- Read-only isolated TEST catalogue check: no public tables, public functions, migration-history table or Storage buckets; no migrations applied.
- Documented that the current folder is not yet a validated clean-install sequence and recorded remediation paths. No schema was changed; no Production/TEST writes, no builds or tests.


## 2026-11-18 — CI assertion alignment with current feature contracts

- Inspected the latest `completion-work` head and GitHub Actions run #893 logs. The two current failures were stale source assertions: the package test expected a removed hard-coded lock constant, and the withdrawal test expected a read-only queue that had since been replaced by a server-authorized Admin review workflow.
- Updated the package regression test to verify fail-closed database feature-setting behavior, conditional activation form rendering, receipt upload/RPC wiring, proposed-only wallet credit display, and continued free registration.
- Updated withdrawal regression coverage to verify the database feature interlock, trusted-Admin RPC usage, row locking, Income Wallet reservation, idempotent release, audit logging, and member payout-data minimization.
- Changes are committed to `completion-work`; GitHub Actions verification for the new head is pending. No TEST or Production database writes were made. No completion percentage increase is claimed from test-only changes.


## 2026-11-18 — CI regression contract reconciliation verified

- Latest branch CI run [#898](https://github.com/kkjan2006-self/biddworld/actions/runs/44234569835) passed on commit `936d05864e93b1d452a89bac9c224852510e4eb6`.
- GitHub Actions reported **90/90 test files and 343/343 tests passed**. TypeScript project build/type-check and Vite 6.4.6 production build also completed successfully.
- Corrected stale assertions to match current member selection, pending activation export, 20-level editor guard, referral draft validation, Fixed Bid server-side participation/idempotency, account refresh lifecycle and database-driven package activation gate.
- Rebuilt the frontend RPC call-site inventory from the ten React surfaces: 67 unique literal RPC-and-surface entries. This is a source inventory only, not proof that all RPCs are deployed in Production.
- No Supabase writes or migrations were run. Production remains read-only and TEST remains empty. This CI pass verifies repository source only; clean-install replay and live integration remain unverified.


## 2026-11-18 — Production RPC/schema contract diff captured

- Added `docs/PRODUCTION_FRONTEND_RPC_LIVE_DIFF_2026-11-18.md` from fresh read-only Production catalogue queries and the refreshed 67-name frontend RPC inventory.
- Current comparison: 35 frontend RPC names exist in Production; 32 are absent. Confirmed live drift includes one-argument bidding and Duplicate ID functions, five-level live referral draft validation versus the source 1–20-level editor, a stale feature-setting implementation, and no configured Storage buckets.
- Revalidated 21/21 public tables have RLS, 110 constraints, 60 indexes, 20 SELECT-only policies, 10 non-internal application triggers, and 43 SECURITY DEFINER public functions with explicit settings. TEST remains empty.
- This is an evidence/reconciliation checkpoint, not a completed clean-install baseline. Production and TEST remain unmodified; no completion percentage increase is claimed.


### 2026-11-18 — Notification template creator attribution fix
- Source review found the Admin template table requires `created_by`, but the template-create RPC omitted that column, causing new template inserts to fail on a clean database.
- Updated `admin_save_notification_template` to record the authenticated Admin as `created_by` on insert; updates continue to preserve the original creator.
- This is a source migration correction only. Per the agreed development-first workflow, tests/builds are deferred to the final consolidated testing phase. No Supabase database was modified.
- No overall completion percentage increase is claimed for this isolated correction.


### 2026-11-18 — Production schema baseline candidate assembled
- Captured the current Production schema through read-only catalogue queries and added a separate candidate baseline under `supabase/clean-install/`; it is not in the Supabase CLI migration directory.
- Candidate inventory: 21 public tables, 110 constraints, 28 non-constraint indexes, 20 RLS policies, 47 public/private function definitions, 11 application triggers, and captured table/sequence/function grants.
- Added an ordered manifest of 48 source-only forward migration candidates after the Production snapshot. Historical migrations already represented by the snapshot are excluded; the duplicate audit-log pagination source is also excluded.
- Added explicit function/sequence ACL revocation before replaying observed grants, preventing PostgreSQL's default PUBLIC function EXECUTE privilege from weakening the captured access model.
- This is a schema-only candidate, not a verified canonical migration chain. No migration was executed and no Production or TEST writes occurred. Final replay, comparison and all tests remain deferred until the consolidated testing phase.
- Overall completion percentage remains unchanged; baseline replay and end-to-end integration are not yet verified.


### 2026-11-18 — Referral commission ledger idempotency integrity
- Hardened commission posting so a pre-existing credit idempotency key is accepted only when the ledger row matches the exact Income Wallet, credited Main ID, transaction type, direction, amount and commission reference.
- Hardened reversal so the original credit ledger row must reconcile before reversal, and an existing reversal key must match the exact debit transaction before it is treated as a replay.
- This prevents an unrelated wallet transaction with a colliding idempotency key from being mistaken for a posted commission or completed reversal.
- Source migration only. No database migration, financial transaction, build or test was run; final consolidated testing remains deferred as requested.
- Overall completion percentage is not increased for this isolated integrity hardening.


### 2026-11-18 — Withdrawal reservation/release ledger reconciliation
- Hardened Admin rejection of an approved withdrawal: the original Income Wallet reservation debit must exist and match the exact wallet, Main ID, amount and withdrawal reference before funds can be released.
- Existing release idempotency keys are now validated against the exact expected credit transaction instead of being treated as success based on key presence alone.
- Admin payout confirmation now also requires a matching reservation ledger entry, preventing an approved status without a corresponding reserved amount from being marked paid.
- Source migration only. No database migration, payout, build or test was run; all tests remain deferred to the final consolidated phase.
- Overall completion percentage is not increased for this isolated integrity hardening.


### 2026-11-18 — Winner-payment replay ledger verification
- Tightened both Fixed Bid-specific and shared Auction/Fixed Bid winner-payment retry paths.
- A repeated payment key now counts as a successful replay only when the existing ledger row matches the winner's Income Wallet, Main ID, debit direction, exact amount, transaction type and winning-payment reference.
- A colliding key from an unrelated wallet transaction now fails closed instead of returning a false paid/replayed response.
- Source migration only. No payment, database migration, build or test was executed; consolidated testing remains deferred.
- Overall completion percentage is not increased for this isolated integrity hardening.

### 2026-11-18 — Withdrawal payout details server-side validation
- Added a forward-only migration that validates payout details independently of the member UI: exact supported methods (UPI / Bank Transfer), matching credential field, account-holder length, UPI syntax, bank account length and rejection of unexpected JSON keys.
- The database stores a normalized method-specific payout object and audit logs record only the payout method and amount, never the UPI ID, account number or account-holder name.
- Preserved the existing active Main ID ownership check, Income Wallet balance lock, minimum-withdrawal setting, withdrawals feature gate and authenticated-only RPC grant.
- Added a focused static contract test. As requested, tests and builds remain deferred until the consolidated final testing phase.
- Source-only change. No Supabase migration or payout was executed; Production and TEST remain unchanged. No overall completion percentage increase is claimed for this isolated security hardening.

### 2026-11-18 — Auction and Fixed Bid cancellation refund ledger integrity
- Hardened Fixed Bid cancellation to verify every original debit belongs to the entry's Main ID and one of that member's wallets, uses the expected transaction/reference contract, and reconciles to the recorded entry amount.
- Existing Fixed Bid refund idempotency keys are now accepted only when the ledger row matches the exact wallet, Main ID, transaction type, direction, amount and entry reference.
- Hardened Auction cancellation with equivalent source-debit ownership/type/reference checks, bid-amount reconciliation, and exact validation of any existing refund key before treating it as a replay.
- Added a focused source-contract test for both cancellation workflows. Tests/builds remain deferred to the final consolidated phase as requested.
- Source-only changes to the not-yet-replayed migration chain. No database migrations or wallet transactions were executed; Production and TEST remain unchanged. No overall completion percentage increase is claimed for this isolated integrity work.

### 2026-11-18 — Member identity RPC migration compatibility
- Corrected the member identity migration chain: the earlier `member_list_my_ids()` definition returned eight columns, while the newer definition returns seven. PostgreSQL does not permit this table-return row type change through `CREATE OR REPLACE FUNCTION`.
- The forward migration now drops only the exact zero-argument RPC signature before recreating the seven-column contract consumed by the Account portal, then reapplies authenticated-only execution grants.
- This prevents a deterministic clean-install / forward-replay migration failure. Source-only correction; no Production or TEST database was changed. Tests/builds remain deferred to the final consolidated testing phase.
- No overall completion percentage increase is claimed for this migration compatibility correction.

### 2026-11-18 — Registration and Account status messaging alignment
- Aligned signup confirmation text with the existing auth-user trigger, which creates the member profile, Main ID and initial wallet rows at registration. The UI no longer incorrectly claims every new account remains inactive pending Admin verification.
- Email-confirmation-required users are instructed to confirm their email before signing in; users receiving an immediate session are told their free member account and Main ID have been created.
- Replaced the Account portal's unrelated review wording with a direct support/admin instruction for genuinely inactive accounts.
- Added a focused static contract test. Source-only change; no registrations, database writes, builds or tests were run. Production and TEST remain unchanged.
- No overall completion percentage increase is claimed for this UI consistency correction.

### 2026-11-18 — Duplicate ID placement approval hardening
- Removed the obsolete one-argument `admin_create_duplicate_member_id(text)` overload, which could create a pending Duplicate ID without an Under ID. The current two-argument placement RPC remains the sole creation contract.
- Duplicate ID activation now requires an active owner Main ID, a non-null active placement parent, and a different parent owner. The existing closed-ID no-reactivation rule remains, and status changes are audited.
- Unified the transaction-scoped advisory lock for Duplicate ID creation, Duplicate ID status changes, and Main ID lifecycle changes to serialize overlapping graph mutations.
- Main ID reactivation now only auto-reactivates linked Duplicate IDs whose placement parent is still active and belongs to another member.
- Added a focused source-contract test. Development-only migration; no database changes or tests/builds were executed. Production and TEST remain unchanged.
- No overall completion percentage increase is claimed for this security hardening batch.
## 2026-11-18 — Admin form validation lock recovery

- Fixed three Admin save handlers that acquired their in-flight mutation lock before validating input: notification template save, member profile save, and sponsor reassignment.
- Invalid or incomplete input now returns before the lock is acquired, so the Admin can correct the fields and submit again without refreshing the page.
- Valid submissions retain the existing in-flight guard, server RPC, success/error feedback and finally-based lock release.
- Added a source-contract regression test for validation-before-lock ordering and the existing finally cleanup.
- Source-only change. No tests/build were run in this development phase; all testing remains deferred to the final testing stage. Production and TEST Supabase projects were not accessed or modified. No completion-percentage increase is claimed.

## 2026-11-18 — Latest branch CI regression repair

- Re-fetched `completion-work` and confirmed the exact head before changes: `c87a2baa3eddf159fd8f1c8c882fb0be31db1542`.
- Inspected GitHub Actions run #915: 89/96 test files passed (355/362 tests); seven failures were traced to stale source assertions after legitimate workflow/lock/message changes, plus malformed duplicated fragments in the payout-validation migration.
- Updated the Duplicate ID serialization contract to assert the shared `biddworld.member_id_graph_mutation` transaction lock used by Duplicate ID approval and Main ID lifecycle operations.
- Updated registration/account tests to match the actual free-registration confirmation and current account-activation lock notice without asserting an inactive status that the Auth provisioning flow does not promise.
- Updated withdrawal safety assertions to verify the current select-and-validate idempotent release path rather than the removed `IF NOT EXISTS` insert pattern.
- Rebuilt the payout-detail validation migration as one complete function definition, correcting the UPI and bank-account regular expressions and removing orphaned duplicated PL/pgSQL fragments. This is source-only; no migration was applied to TEST or Production.
- GitHub Actions verification for this repair is pending. No completion percentage increase is claimed until the integrated application/database workflows are implemented and validated.

### 2026-11-18 — CI assertion follow-up
- The first repair run (#916) confirmed the seven original failures were reduced to two stale test files; the remaining assertions were overly whitespace-sensitive and one phone-pattern assertion retained an obsolete escaping form.
- Updated those checks to validate the actual phone-length contract and payout validation semantics independent of SQL formatting.
- The repaired payout migration remains source-only. Awaiting the next integrated CI run; no database changes and no completion percentage increase.

### 2026-11-18 — CI payout validation assertion follow-up
- CI run #918 passed 95/96 test files (the only remaining failure was an over-specific assertion that omitted the deliberate JSON null-type guard's `coalesce(..., 'null')` wrapper).
- Updated the assertion to verify the complete fail-closed type check. The payout validation migration itself now has one complete function definition and both format patterns include their end anchors.
- Awaiting CI run #919 for the final test/type-check/build result. No database migration was executed.

## 2026-11-18 — CI verification restored and withdrawal profile guard strengthened

- GitHub Actions run [#919](https://github.com/kkjan2006-self/biddworld/actions/runs/44241327288) passed on commit `ea2082e4fecd747621d2726f37cfb9f0d1285d05`: 96/96 test files and 362/362 tests passed; TypeScript project build/type-check and Vite production build passed.
- Follow-up source review found that the member withdrawal RPC and Admin approval workflow checked the active Main ID but did not independently require the linked member profile to be active, although the Member UI already checks both.
- Updated the member request RPC to require an active profile and Main ID, and Admin approval to lock/check the linked profile and Main ID together before reserving Income Wallet funds.
- Added regression assertions for both server-side checks. Source-only; no TEST or Production database writes or migration replay.
- The next CI run is pending. No completion percentage increase is claimed.

### 2026-11-18 — Withdrawal profile authorization CI follow-up
- CI run #920 stopped during test-file parsing because the payout validation contract test file contained SQL source instead of TypeScript test content.
- Restored the test file and retained the SQL migration in its intended path. The profile-status authorization checks in the member request and Admin approval RPCs remain in the source migration files.
- A fresh CI run is required before considering this follow-up verified. No database changes or migrations were applied.

## 2026-11-18 — Fixed Bid and Referral engine hardening

- Added source-level integrity checks to Fixed Bid entry replay: the existing entry must still be open and its Bid/Income Wallet debit ledger must reconcile to the recorded entry amount and owner.
- Fixed Bid participation and winner-payment RPCs now require the caller's active member profile and owned active Main ID. Draw eligibility now excludes inactive profiles/IDs.
- Fixed Bid draws now return the recorded draw result on retry, validate source debit ownership/type/wallet/reference before refunds, and verify existing refund ledger rows before treating them as completed.
- Unified the Fixed Bid-specific winner-payment ledger transaction type with the shared winning-payment contract.
- Referral commission reversal replay now verifies the original credit and reversal ledger rows; pending-only reversals remain replayable without a wallet debit.
- Added focused static contract tests for the Fixed Bid and referral calculation/posting/reversal source paths. Runtime database verification remains deferred until the TEST clean-install baseline is reviewed and development is complete.
- No TEST or Production writes or migration replay. CI for this batch is pending.

## 2026-11-18 — Clean-install migration partition audit

- CI run #922 passed after Fixed Bid and Referral source hardening: 98/98 test files and 372/372 tests passed; TypeScript check and Vite production build passed.
- Reconciled the current migration directory against the clean-install forward manifest: 66 timestamped migration files are partitioned into 50 ordered forward candidates and 16 historical/source files already represented by the Production baseline.
- Added an explicit excluded-historical manifest and a regression test requiring every timestamped migration to appear exactly once in either the forward or excluded list. The two missing Production ledger source files remain preserved only in the exact historical archive under `supabase/audit/production-ledger/`.
- The 1,929-line Production schema baseline remains a candidate only. No TEST migration replay or Production write was performed; canonical clean-install status is not claimed.

### 2026-11-18 — Clean-install partition CI verification and catalogue scope correction
- GitHub Actions run #923 passed: 99/99 test files and 375/375 tests; TypeScript and Vite production build passed.
- Added a machine-checked partition of the 66 timestamped source migrations: 50 forward candidates plus 16 explicitly excluded historical files, with every file accounted for exactly once.
- Updated the Production catalogue documentation to distinguish 243 constraints across all inspected catalogue schemas from the 110 constraints on the 21 public application tables; clarified the 17 all-schema triggers versus 11 application-owned triggers.
- Updated migration recovery documentation to reflect the exact 30 historical Production migration SQL bodies now archived under `supabase/audit/production-ledger/`. The two unrecoverable executable paths remain archival-only and are not copied into the executable migration directory.
- Clean-install baseline remains a candidate only. No TEST migration replay or Production write was performed.

### 2026-11-18 — Public auction RPC CI follow-up
- CI run #925 validated the new public-auction RPC source coverage, but two test assertions failed: the explicit frontend RPC inventory did not yet include the newly added RPC, and the SECURITY DEFINER test regex was over-escaped.
- Added `public_list_active_auctions_page` to the frontend RPC inventory and refreshed its source snapshot commit. Updated the branch RPC contract test to reference the final Member ID list RPC and new public auction RPC.
- Corrected the regex assertion. The source migration and App integration are unchanged. Awaiting a fresh CI run.

## 2026-11-18 — Public Auction RPC and source inventory verification

- GitHub Actions run #926 passed on source commit `6c272b5b9a462e7943dc97be6e0f34a030bbed77`: 100/100 test files and 413/413 tests passed; TypeScript and Vite production build passed.
- Added the public paginated auction catalogue RPC and replaced the anonymous direct-table query in the website. The function exposes only public listing fields for published products with live/scheduled time windows and grants RPC execution to anon/authenticated, without table SELECT grants.
- Refreshed the frontend RPC inventory to 68 unique literal RPC names. The Production diff now records 35 live names and 33 source-only names, with source migration coverage checks for all 33.
- Updated the clean-install forward chain to 51 timestamped migrations; the explicit excluded historical list remains 16, partitioning all 67 timestamped migration files exactly once.
- No Production or TEST SQL writes or migrations were performed. The public auction RPC is source-only pending clean-install replay and final deployment.

### 2026-11-18 — Public Fixed Bid catalogue CI follow-up
- CI run #929 confirmed the new public Fixed Bid RPC source tests and the 69-name frontend RPC inventory coverage, but the pre-existing Fixed Bid pagination test still asserted the removed direct-table query.
- Rewrote those assertions to verify the RPC-based search/status/page contract while retaining the request lifecycle and idempotent entry checks.
- The source RPC and migration manifest changes are unchanged. A fresh CI run is pending.

### 2026-11-18 — Fixed Bid pagination test syntax correction
- CI run #931 stopped before TypeScript/build because the updated Fixed Bid pagination test had an incorrectly escaped single-quoted assertion.
- Corrected the assertion to use a double-quoted TypeScript string. The source UI and migration are unchanged.
- The public package catalogue RPC batch has also been committed; its CI result is pending.

### 2026-11-18 — Fixed Bid pagination regex correction
- CI run #932 confirmed 418/418 individual tests passed, but the Fixed Bid pagination suite failed while constructing an over-escaped regular expression.
- Replaced the regex with direct source-string assertions for client-side insert/update/upsert calls. The Fixed Bid UI and database migration remain unchanged.
- A fresh CI run is pending.

### 2026-11-18 — Fixed Bid public catalogue time-filter hardening
- CI run #933 passed: 102/102 test files and 423/423 tests; TypeScript check and Vite production build passed.
- Hardened the Fixed Bid public catalogue time-window predicate with an explicit SQL CASE so ended campaigns do not evaluate timestamp casts for their configuration. Scheduled/live campaign timestamp validation remains strict.
- Added a contract assertion for the branch-specific time-window behavior. A fresh CI run is pending.

## 2026-11-18 — Production dependency audit gate

- CI run #934 passed: 102/102 test files and 423/423 tests; TypeScript check and Vite production build passed.
- The full dependency audit reported 12 high-severity and 0 critical findings, concentrated in the development/build toolchain dependency graph (including picomatch, chokidar, Tailwind, Vite and Vitest). Major-version changes are not being forced blindly.
- Added a separate `npm audit --omit=dev --audit-level=high` CI gate and a retained production-only audit report. This distinguishes deployable runtime dependencies from dev tooling and blocks high/critical production dependency findings.
- The all-dependency high findings remain an open security-remediation item before launch; no production package upgrades have been applied yet.

## 2026-11-18 — Public catalogue coverage and dependency security gate

- GitHub Actions run #934 passed: 102/102 test files and 423/423 tests; TypeScript and Vite production build passed.
- Added secure public catalogue RPCs for Fixed Bid campaigns and active packages. The public Fixed Bid UI no longer directly selects campaign rows; it receives only published-product data and member-facing campaign configuration. The Packages UI now lists active packages through a limited public RPC and reads the activation feature flag only for authenticated sessions.
- Frontend inventory is now 70 unique literal RPC names: 35 present in Production and 35 source-only. Source coverage tests verify every source-only RPC has a corresponding forward migration and UI call.
- Clean-install partition now contains 53 ordered forward candidates and 16 excluded historical source files, accounting for all 69 timestamped migration files exactly once (72 SQL files in `supabase/migrations`, including three legacy files).
- GitHub Actions run #935 passed the production dependency audit gate: `npm audit --omit=dev` reported 0 vulnerabilities (0 high/critical). The full dependency audit still reports 12 high, 0 critical findings in development/build tooling; this remains an open remediation item before launch. No major dependency upgrades were forced.
- No TEST migration replay or Production writes were performed. All three new public catalogue RPCs remain source-only.

## 2026-11-18 — PWA install icon assets

- GitHub Actions run #938 passed: 102/102 test files and 423/423 tests; TypeScript check and Vite production build passed.
- Added real 192×192 and 512×512 PNG install icons derived from the existing BiddWorld SVG brand mark. The 512 icon is declared `any maskable`; the Apple touch icon now points to the 192 PNG.
- Added both PNGs to the service-worker shell cache and strengthened PWA tests to verify actual PNG signatures and dimensions.
- Bumped the service-worker cache to v3 in a follow-up commit so previous shell assets are retired on activation. CI for that cache-version change is pending.
- Android installation and offline behavior still require real-device verification during final QA; source tests/build do not prove device installation.

### 2026-11-18 — PWA cache lifecycle and Pages build verification
- CI run #939 passed: 102/102 test files and 423/423 tests; TypeScript and Vite production build passed.
- Bumped the service-worker shell cache to v3 so the prior v2 cache is removed on activation after the PNG icon update.
- Added an explicit PWA test for the GitHub Pages `/biddworld/` base-path contract and a second CI build using `GITHUB_PAGES=true`. This validates the Pages subpath build without deploying or configuring hosting.
- CI for the Pages subpath build is pending; real Android installation/offline verification remains part of final QA.

### 2026-11-18 — Auction Bid report inventory follow-up
- CI run #942 validated the new Admin auction bid report source coverage, but the explicit frontend RPC inventory surface allow-list did not yet include the new `AdminAuctionBidReport.tsx` component.
- Added the component to the known UI surface list and refreshed the inventory snapshot commit. The SQL RPC, Admin integration and pagination/CSV implementation are unchanged.
- A fresh CI run is pending.

### 2026-11-18 — Fixed Bid entry reporting source integration
- Added an Admin-only, paginated Fixed Bid entry report with campaign/member search, status/date filters, continuation and complete CSV export.
- Added the `admin_list_fixed_bid_entries_page` SECURITY DEFINER RPC with trusted Admin-role authorization and a restricted result projection that omits idempotency keys.
- Added the new migration to the forward manifest and source RPC coverage. The inventory allow-list is being updated for the new UI surface; CI is pending.
- No TEST or Production database writes were performed.

### 2026-11-18 — Complete auction/Fixed Bid export assertion update
- CI run #946 confirmed the new paginated Admin auction and Fixed Bid export source contracts, but the existing filter test still expected the previous “current loaded rows” export button labels.
- Updated the assertions to the new complete-history CSV labels. The filters, RPCs and migration are unchanged.
- CI for the refreshed assertions is pending.

### 2026-11-18 — Referral commission report level filtering
- Added a 1–20 level filter to the Admin commission register, alongside the existing status filter.
- Complete CSV export now passes the selected status and level filters to the paginated Admin RPC, while the on-screen list retains its load-more behavior.
- Added source-contract coverage for the level/status filter and complete export. CI is pending.

## 2026-11-18 — Complete Admin bid and catalogue report coverage

- Added Admin-only paginated Auction Bid History and Fixed Bid Entries reports, each with server-side search, status/date filters, load-more pagination and complete CSV export. Internal idempotency keys are excluded from both RPC projections.
- Replaced the current-loaded-row-only Auction and Fixed Bid campaign CSV exports with complete server-paginated exports using new Admin-only RPCs. Existing management-list RPCs remain unchanged.
- Added level 1–20 filtering to the referral commission register; complete CSV export now applies the selected status and level filters.
- Frontend RPC inventory: 74 unique calls; 35 names exist in the read-only Production catalogue and 39 remain source-only. The source coverage test maps all 39 source-only contracts to forward migrations and UI call sites.
- Migration partition: 75 SQL files total (72 timestamped + 3 legacy); 56 ordered forward candidates and 16 excluded historical files account for all 72 timestamped files exactly once.
- GitHub Actions run #948 passed: 102/102 test files, 431/431 tests, TypeScript, normal production build and GitHub Pages subpath build. Production dependency audit: 0 vulnerabilities; full development/build dependency audit still reports 12 high, 0 critical.
- No Production or TEST writes were performed. The new reporting RPCs remain source-only pending the clean-install replay and integration phase.

### 2026-11-18 — Android PWA install control
- Added a conditional `Install App` button to the public header. It uses the browser's `beforeinstallprompt` event, appears only when the browser considers the app installable, and clears on prompt completion or `appinstalled`.
- Added source-contract coverage for install prompt and installed-event handling. No install prompt is fabricated when the browser does not offer one.
- Real-device installation and offline navigation remain pending final Android QA.

### 2026-11-18 — PWA install header wiring correction
- CI run #950 caught that the install-button component and test were added, but the final App source commit did not include the header render.
- Wired the component import and render into the public header. The browser event handler component and PWA manifest/service worker are unchanged.
- CI rerun is pending.

### 2026-11-18 — PWA import correction
- CI run #951 passed all tests but TypeScript failed on a duplicate `PWAInstallButton` import in `src/App.tsx`.
- Removed the duplicate import; the header render and install prompt component remain intact. CI rerun is pending.


## 2026-11-18 — Latest branch CI and read-only database revalidation

- Confirmed the exact `completion-work` branch HEAD: `398398927d97154cf94417234449c7c60a73b069` (`fix: remove duplicate PWA install component import`). This is the branch HEAD; repository-wide commit search results are not used as a substitute for branch metadata.
- Inspected GitHub Actions run [#951](https://github.com/kkjan2006-self/biddworld/actions/runs/44248768197): all 102 test files / 432 tests passed; TypeScript then failed because `src/App.tsx` imported `PWAInstallButton` twice. Removed the duplicate import in the next commit.
- Verified GitHub Actions run [#952](https://github.com/kkjan2006-self/biddworld/actions/runs/44248923875) on the current HEAD: 102/102 test files and 432/432 tests passed; TypeScript project build, Vite production build and GitHub Pages subpath build all passed.
- Rechecked the package activation and support-filter contracts on the current branch. The package activation UI fails closed unless the database setting is explicitly true; the support queue applies status filters in initial load, load-more and full CSV export paths. The current support test expects all three paths. The older reported two-assertion CI failure is not present on this HEAD.
- Read-only Production catalogue revalidation: 21 public tables / 175 columns; RLS enabled on all 21; 110 constraints; 60 indexes; 20 public policies; 47 public/private application functions; 10 public-table triggers plus the Auth-user trigger (11 application triggers total). Storage currently has 0 buckets.
- Read-only TEST revalidation: project is `ACTIVE_HEALTHY`, PostgreSQL 17.12; 0 public tables, 0 migrations, 0 application functions, 0 public policies, 0 public indexes, 0 public-table triggers and 0 Storage buckets. No migrations or data were written.
- The clean-install baseline remains a candidate only: 56 ordered forward migrations and 16 explicitly excluded historical timestamped migrations are listed; three legacy/unversioned SQL files still require explicit treatment. The candidate must be reviewed and replayed only on TEST after development completion. It is not approved for Production.
- Production Storage is not configured yet, although source migrations define the intended media/receipt buckets. This remains a TEST replay and final integration-verification item.
- This entry records verification and blockers only. No feature completion percentage increase is claimed; no Production or TEST writes were performed.


### 2026-11-18 — Clean-install candidate structural and migration-partition cross-check
- Compared the schema-only baseline candidate's static object inventory with fresh read-only Production catalogue results: 21 tables, 21 RLS enablements, 20 policies, 47 functions, 11 application triggers and 28 explicit non-constraint indexes are represented; live Production reports 21 tables / 175 columns, 110 constraints, 60 total indexes, 20 policies, 47 public/private functions and 10 public-table triggers plus the Auth trigger. No object-count discrepancy was found in this structural pass.
- Recomputed the source migration partition against the current branch directory: 75 SQL files total (72 timestamped and 3 legacy/unversioned); 56 ordered forward candidates plus 16 explicitly excluded historical migrations account for all 72 timestamped files exactly once. No missing entries, duplicates or overlaps were found.
- Confirmed `pgcrypto` version 1.3 is already installed in the `extensions` schema in both Production and TEST, matching the baseline's extension prerequisite. No extension changes were made.
- Reviewed the two source Storage migrations: `product-media` is public-read with Admin-only mutation; `package-receipts` is private with member-owned upload/read and Admin review. Neither Production nor TEST currently has a Storage bucket, so these policies and upload paths remain unverified until TEST replay.
- Remaining baseline review gates: exact function-definition/ACL parity, trigger function/order and identity-sequence ownership, and dependency/semantic review of all 56 forward migrations. Candidate remains non-executable pending TEST replay; Production stays read-only.
- No database writes, migrations, test data, member actions or wallet activity. No completion-percentage increase is claimed.


### 2026-11-18 — Notification template persistence contract repair
- Current branch review found that `admin_save_notification_template` inserted `created_by`, but the new `notification_templates` table definition omitted that column. This would fail on first template creation after clean-install replay.
- Added nullable `created_by uuid references auth.users(id) on delete set null` to the table definition. The save RPC continues to force all saved templates to inactive drafts; no email/SMS dispatch is introduced.
- Source change committed as `960681dcafc84e5c86db1b6f7b02a4c8ee304f97`. No database was modified and no tests were run manually, per the requested final testing phase.
- Remaining work continues with full module integration and schema/function/ACL reconciliation. This isolated repair does not justify a completion percentage increase.


### 2026-11-18 — Fixed Bid winner draw security hardening
- Reviewed the existing Fixed Bid entry/draw/settlement SQL and found winner ranking used PostgreSQL `hashtextextended` with a random UUID seed. This is a non-cryptographic hash, so replaced the future-draw ranking with a seeded SHA-256 digest using the already-installed `pgcrypto` extension in the `extensions` schema.
- Added forward migration `20261118340000_secure_fixed_bid_random_draw.sql`; existing recorded draw rows remain immutable. New migration is appended to the ordered clean-install forward manifest (57 candidates now) and the README count was updated.
- Added a source-contract assertion to the existing Fixed Bid integrity test for the SHA-256 ranking and absence of the old hash scoring. Tests intentionally not run, per the request to execute the full test suite only after development completion.
- No Production or TEST database changes; no real member, wallet or campaign activity. The source migration remains pending final TEST replay and integration verification.


### 2026-11-18 — Member profile and withdrawal input validation repair
- Source inspection of the member Account portal found several regular-expression literals with doubled backslashes. As written, the mobile-number pattern expected a backslash rather than an optional plus sign, and the withdrawal amount / bank-account patterns did not match ordinary digits. Corrected the literals to use the intended digit and plus-sign classes.
- Added a regression contract to `tests/member-withdrawal-payout-privacy.test.ts` covering the mobile, amount and bank-account patterns. Tests were not run; all testing remains deferred to the final phase as requested.
- No database changes or financial actions were performed. The fix affects client-side input validation only; server-side payout validation remains authoritative.


### 2026-11-18 — Private package receipt Storage integration
- Found an end-to-end gap: Member and Admin portals both use the `package-receipts` bucket, while the reviewed Production and TEST catalogues had no Storage buckets and no forward migration created this bucket.
- Added `20261118350000_private_package_receipt_storage.sql`: private 5 MB bucket, JPEG/PNG/PDF allowlist, authenticated member upload restricted to their own `auth.uid()` folder, and SELECT access restricted to the Admin `app_metadata.role` claim. No public access, member read, update or delete policy is added.
- Added a source-contract test and included the migration in the clean-install forward manifest (58 candidates). Updated clean-install documentation.
- Tests not run per the requested final-only testing phase. No Production or TEST database writes; the migration still requires isolated TEST replay and Storage API verification at final testing.


### 2026-11-18 — Admin pending activation receipt-path integration
- Source review found that the Admin pending-activation RPC omitted `receipt_path`, even though the Admin UI's receipt viewer requires it to create a private signed URL. The receipt preview was therefore unreachable from the pending queue for uploaded receipts.
- Added `20261118360000_admin_pending_activation_receipt_path.sql` to return the receipt object path while retaining Admin-only authorization and authenticated-only EXECUTE grants. Results now use stable newest-first ordering.
- Added a regression source-contract test and included the migration in the clean-install forward manifest (59 candidates). Updated clean-install documentation.
- Tests not run, as requested; no Production or TEST database writes. The migration and private Storage access still require final isolated TEST replay and integration verification.


### 2026-11-18 — Package receipt read-policy tightening
- Review of the original receipt migration found a legacy `package_receipts_select_own_or_admin` Storage policy that still allowed a member to read their own receipt, even after the later migration introduced an Admin-only SELECT policy. The older policy was not removed by the later migration, so both policies would be OR-combined by PostgreSQL RLS.
- Added `20261118370000_restrict_package_receipt_reads_to_admin.sql` to drop the permissive legacy SELECT policy and duplicate legacy INSERT policy, then retain one owner-folder-only member upload rule and one Admin-role-only read rule.
- Added a regression source-contract test and included the migration in the clean-install forward manifest (60 candidates). Updated clean-install documentation.
- Tests not run per the requested final-only testing phase. No Production or TEST database writes; policy behavior still requires isolated TEST replay and Storage API verification at final testing.


### 2026-11-18 — Member placement tree includes Duplicate IDs
- Source review found `get_my_placement_tree()` traversed only child rows with `id_type='main'`, omitting Duplicate IDs even though Duplicate IDs participate in placement and can be selected as Under IDs for subsequent placements.
- Added `20261118380000_include_duplicate_ids_in_member_placement_tree.sql`: cycle-safe, depth-bounded traversal now includes Main and Duplicate nodes, and each returned node identifies its ID type and owning Main ID. The authenticated member's own Main ID remains the only root.
- Added regression source-contract test; included migration in clean-install forward manifest (61 candidates) and updated README.
- Tests not run per requested final-only testing phase. No Production or TEST database writes; runtime RPC validation remains part of final isolated TEST replay.


### 2026-11-18 — Filterable complete package activation history export
- Extended the Admin Reports package activation section beyond the pending-only queue export. Administrators can now export the complete activation history with payment-status (pending / approved / rejected / refunded), text search and inclusive submission-date filters.
- The status filter is passed to the Admin-only paginated RPC; search/date filters are applied across all fetched pages before CSV generation. The existing pending-only report remains separate and clearly labelled.
- Added regression assertions for the complete-history filter contract. Tests intentionally not run until the final testing phase. No Production or TEST database changes.
- Source commits: `ea86ea7f0f2b591d7a908e9c820fcf86cec2bbbc` (Admin UI) and `8f958924453442a194350d5974cf28afba494c65` (regression coverage).


### 2026-11-18 — Clean-install manifest and dependency reconciliation (current branch checkpoint)
- Reconciled the GitHub `supabase/migrations` directory against both clean-install manifests. The current directory has 80 SQL files: 77 timestamped plus 3 legacy/unversioned files. All 77 timestamped files are partitioned exactly once into 61 ordered forward candidates and 16 excluded historical files. No missing, stale, duplicate or overlapping manifest entries were found.
- Confirmed the existing `tests/clean-install-migration-manifest-integrity.test.ts` enforces exact partition, existence, order and candidate-only guard assertions. The test was inspected, not run.
- Reconciled the baseline candidate's static object counts: 21 public tables, 175 columns per the catalogue snapshot, 110 public constraints, 28 explicit non-constraint indexes (60 total including constraint-backed indexes), 21 RLS enablements, 20 policies, 47 functions (43 public + 4 private), and 11 app-owned triggers.
- Inspected all 61 forward migration files at source level for DDL and object references. Recorded important replacements and prerequisites, including support-ticket notification ordering, repeated financial-guard function replacements, signup-function replacement, MLM dashboard replacement, identity RPC return-type drop/recreate, placement-tree replacement, and Storage bucket/policy sequence.
- Identified an important final-state dependency: the package receipt owner-read policy introduced in `20261118150000` is not fully removed by `20261118350000`; the final `20261118370000` migration drops the permissive owner-read policy and leaves Admin-only receipt SELECT plus owner-folder upload. The complete ordered sequence through `20261118370000` is required.
- Added `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md` and corrected the current inventory in the clean-install README and Production audit documents. Earlier 48/56 forward and 72 timestamped counts are superseded by the current 61/16/77 inventory.
- Latest GitHub Actions run #989 on commit `dd72209c1da51d7953da14245d6520431f03469c` failed at the test step: 105/106 files and 443/444 tests passed. The only failure is a stale source-string assertion in `tests/admin-package-activation-report-filters.test.ts`; type-check/build and Pages build were skipped. This automatic CI result is recorded for the consolidated final testing/repair phase; no manual tests were run.
- No Production or TEST database writes, migrations, Storage changes, member actions, wallet transactions or payouts occurred. No overall completion percentage is claimed.


### 2026-11-18 — Baseline function ACL/search-path static pass and repeated CI result
- Scanned the baseline candidate's function and grant statements: 47 SECURITY DEFINER function definitions, 47 function-level search_path settings, 88 explicit EXECUTE grants across 42 function names, and schema-wide function revocations before grants. Three private helper functions have no direct client EXECUTE grant; `private.place_bid(uuid)` is service_role-only. All 11 app-owned triggers are defined after the functions they invoke.
- Confirmed 38 table grant statements align with authenticated SELECT on 17 public tables and service_role access to all 21 public tables. These are source-level ACL observations, not runtime verification.
- Latest completed CI at this checkpoint is run #996 on `f7274c13053ad593c3fa303560d0e4f06f51c42a`; it repeats the single stale assertion failure in `tests/admin-package-activation-report-filters.test.ts` (105/106 files, 443/444 tests). Build/type-check and Pages build were skipped. The failure remains deferred to the consolidated final test/repair phase.
- No Production or TEST writes, no migration replay, no manual test execution, and no wallet or member activity.


### 2026-11-18 — Auction bid active-profile eligibility alignment
- Reconciled the public auction bid call in `src/App.tsx` with the final `public.place_bid(uuid,text)` wrapper and cancellation refund ledger contract. Named RPC arguments, request-key reuse, `:bid`/`:income` suffixes, `auction_bid` transaction type and `auction` reference metadata align.
- Found that auction bid eligibility required an active Main ID but did not also require its owning `profiles` row to be active, unlike the Fixed Bid entry workflow. Added `20261118410000_require_active_profile_for_auction_bids.sql` to require active profile status and the canonical `profiles.main_member_id` ownership link while preserving the existing debit/idempotency implementation and RPC grants.
- Added the migration to the ordered forward manifest and updated the clean-install README count to 63. Current SQL inventory: 82 files (79 timestamped + 3 legacy), partitioned as 63 forward + 16 excluded timestamped.
- Source inspection only. Tests/build, TEST replay and browser checks remain deferred; Production `hbqatszyzqobgtauyuzy` and TEST `yoaauthwejdgaevfvwpo` were not modified.


### 2026-11-18 — Active winner eligibility and payment replay integrity
- Reconciled Admin auction status/finalize calls with SQL signatures, Admin authorization and consumed JSON result fields; reconciled Member Account winner-payment call with the shared RPC named arguments and stable retry-key behavior.
- Found that auction finalization selected the highest accepted bid without checking current Main ID/Profile activity. A suspended member could be selected but then be blocked by the payment RPC. Added `20261118420000_active_winner_eligibility_and_payment_replay_guard.sql`: only active Main IDs with their canonical active owning profiles are eligible at finalization. It acquires the same member-graph advisory lock as the Admin Main-ID lifecycle function before locking the auction, preserving the winner eligibility snapshot against concurrent lifecycle changes. Highest-bid / earliest-created / UUID tie-break ordering remains unchanged.
- Hardened both shared and legacy Fixed Bid winner-payment idempotent replay branches: an existing matching ledger row now returns replay success only if the winning payment row is already marked paid and has `paid_at`; inconsistent ledger/payment state fails closed. Income-Wallet-only debit, ledger metadata, public signatures and authenticated grants remain intact.
- Added migration to clean-install forward manifest (64 candidates) and updated README. Inventory: 83 SQL files (80 timestamped + 3 legacy), 64 forward + 16 excluded timestamped migrations.
- Source review only; tests/build and TEST replay remain deferred. Production `hbqatszyzqobgtauyuzy` and TEST `yoaauthwejdgaevfvwpo` were not modified.


### 2026-11-18 — Auction refund and delivery tracking source reconciliation
- Rechecked Auction cancellation against source bid debits and refund idempotency keys: accepted bid rows and wallet accounts are locked; member, wallet type, transaction metadata, auction reference and debit suffixes are validated; summed source debits must equal the recorded bid amount; mismatches roll back the transaction.
- Rechecked Fixed Bid draw refunds: SHA-256 seeded ranking remains deterministic for the recorded draw; only exact winning entry IDs are excluded from refunds; each losing entry's wallet debit is reconciled and conflicting refund ledger rows fail closed.
- Reconciled Delivery Tracking table/RLS and Member/Admin callers: members receive owner-scoped read-only access; Admin RPCs enforce role; new tracking requires a paid winning-item payment and uses a payment advisory lock; updates lock the tracking row and recheck paid status; Member Account loads tracking alongside paginated winning-payment history.
- Found that Delivery Tracking validates the status vocabulary but does not define allowed transitions. Admin can reopen a delivered record or move returned records to shipped; changing away from delivered clears delivered_at. The repository does not specify an authoritative transition graph or correction/return rules, so no speculative guard was added. This remains a documented policy requirement before lifecycle hardening.
- Corrected clean-install README inventory text: 80 timestamped SQL files (64 forward + 16 excluded) plus 3 legacy files = 83 total. README had stale 78 / 81 counts.
- Added `docs/AUCTION_REFUND_DELIVERY_TRACKING_SOURCE_REVIEW_2026-11-18.md`. Source review only; no tests/builds, TEST replay or database writes. Production and TEST remain untouched.
- Documentation commits: `025ec6050f5846347d682025e2cd443feaabf5f7` (clean-install README) and `74337c27b1646887f13340d4495147189f223e4e` (source review).


### 2026-11-18 — Serialize Auction Bid eligibility with Main-ID lifecycle

- Found a source-level race between `private.place_bid` and Admin Main-ID suspend/close: the bid RPC read active Main ID/Profile state without synchronizing with the Admin status mutation.
- Added `20261118430000_serialize_auction_bid_member_eligibility.sql`. Both paths now acquire the same per-Main-ID advisory transaction lock; the bid path rechecks Main ID and Profile active state after acquiring it, before idempotency, auction or wallet processing.
- Retained the existing public RPC signature/grant and bid wallet debit/idempotency behavior. The Admin lifecycle function body is carried forward with the added lock; no product status rules were changed.
- Added the migration as forward candidate 65. Current SQL inventory: 81 timestamped (65 forward + 16 excluded) + 3 legacy = 84 total.
- Source-only change. No tests/builds, CI, TEST replay, Production access or database writes. Consolidated testing remains deferred. Overall estimate remains 55%.
- Source commit: `5f15127ec192bd04c0fcd0908e0bb441674daaa8`.


### 2026-11-18 — Clean-install baseline function ACL reconciliation

- Compared the candidate baseline's 47 function definitions (43 public, 4 private) and explicit EXECUTE grants with the Production public RPC security inventory.
- Candidate grants authenticated EXECUTE on all 43 public signatures and anon EXECUTE only on public.lookup_sponsor(text), matching the recorded Production counts. Both wallet-account and wallet-transaction overloads are granted by exact signature.
- Candidate explicitly grants service_role EXECUTE on all 43 public functions and private.place_bid(uuid). The referenced Production inventory does not record service_role privilege state; exact parity remains unverified.
- Candidate grants anon/authenticated USAGE on audit_logs_id_seq although the identity-sequence privilege rationale is not recorded. This is flagged for exact ACL/identity behavior verification; no speculative grant change made.
- Added docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md and linked it from the clean-install README.
- Source-only review. No tests/build, database replay, Production or TEST access/writes. Overall estimate remains 55%.


### 2026-11-18 — Clean-install baseline SECURITY DEFINER and trigger dependency review

- Inspected all 43 public function declarations: all are SECURITY DEFINER and carry explicit function-level search_path settings.
- All 36 Admin functions contain auth.uid() and exact JWT app_metadata.role = admin authorization checks with a rejection path. The SQL `admin_list_members_sponsors()` applies the predicate in its WHERE clause and returns no rows to unauthorized callers.
- Member-scoped RPCs use auth.uid(); public bid and package-activation wrappers delegate to the private implementations. The four private functions and their client-execution boundary were recorded.
- Confirmed the candidate creates one auth.users signup trigger and ten public feature-gate triggers after the corresponding private function and application table definitions. Supabase-managed schemas/tables remain platform prerequisites, not app-created schema objects.
- No evidenced authorization or trigger-order source defect found; no speculative SQL patch made. service_role and audit_logs identity-sequence ACL parity remain unresolved pending exact evidence.
- Added docs/CLEAN_INSTALL_BASELINE_SECURITY_DEFINER_TRIGGER_REVIEW_2026-11-18.md and linked it from the clean-install README.
- Source-only review. No tests/build/CI, database replay, Production or TEST changes. Overall estimate remains 55%.


### 2026-11-18 — Forward migration dependency, CI sequencing and dependency security review

- Source-reviewed high-impact portions of the ordered 65-forward-migration chain: Auth/signup, member graph, package/referral, financial guards, Fixed Bid/auction settlement, withdrawals, wallet, receipt Storage, notification and report/catalogue dependencies. No evidenced ordering defect found in inspected groups; full SQL compile/replay remains pending.
- Confirmed package-lock v3 contains 228 package entries and exact key versions Vite 6.4.6, Vitest 4.1.12, @vitest/mocker 4.1.12 and @supabase/supabase-js 2.57.4. Current Vite and Vitest mocker advisories list the locked versions as patched floors; no speculative upgrade made.
- Updated CI workflow: push-triggered verification no longer runs on completion-work, while main pushes and PRs to main retain verification. Changed install step to npm ci for lockfile-based reproducibility. Workflow was not executed.
- Reviewed PWA production-only service worker registration, BASE_URL scope, relative manifest URLs/icons, and service-worker cache rules that exclude cross-origin Supabase/API traffic. Actual Android install/offline verification remains pending.
- Added docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md. No tests/build/CI, npm install/audit, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Member Main-ID lifecycle concurrency: Fixed Bid, withdrawals and winner payments

- Found four member RPCs that checked active Main-ID/Profile status without sharing the per-Main-ID advisory lock introduced for Admin lifecycle changes and auction bids: `member_join_fixed_bid_campaign`, `member_create_withdrawal_request`, `member_pay_winning_item_payment`, and `member_pay_fixed_bid_winning_payment`.
- Added `supabase/migrations/20261118440000_serialize_member_financial_eligibility.sql` (forward candidate #66). Each function acquires the shared lifecycle transaction lock and rechecks the same user's Main ID ownership/type and active Profile/Main-ID status before processing.
- Preserved function signatures, idempotency keys, campaign/payment behavior, wallet debit rules, strict payout validation and authenticated EXECUTE grants.
- Package activation already locks the Main-ID row `FOR UPDATE`; auction winner selection already takes the member-graph mutation lock. Those paths were not changed.
- Updated clean-install forward manifest and README to 66 forward + 16 excluded timestamped migrations, plus 3 legacy SQL files (85 total). Added `docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md`.
- Source-only. No tests/build/CI, SQL execution, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Frontend support and notification direct-write/RLS reconciliation

- Confirmed Support UI reads tickets directly under owner-or-Admin RLS, but member submission and Admin status/response changes use audited idempotent RPCs. Unused direct table INSERT/UPDATE grants could bypass RPC idempotency and audit behavior.
- Confirmed Notifications UI reads directly, marks read via owner-scoped UPDATE(read_at), and Admin sends only through the audited idempotent RPC. Direct authenticated INSERT was unnecessary.
- Added `supabase/migrations/20261118450000_restrict_direct_support_notification_writes.sql` (forward candidate #67): revoke authenticated direct INSERT/UPDATE on support_tickets and direct INSERT on member_notifications; preserve SELECT and owner-only read-state UPDATE.
- Added `docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md`; updated manifest/clean-install README to 67 forward + 16 excluded timestamped + 3 legacy SQL files (86 total).
- Source-only. No tests/build/CI, SQL execution, migration replay or database writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Frontend member/Admin direct-read and RLS review

- Reviewed App catalogue/wallet summary, Account, Packages, WalletHistory, Referrals, PlacementTree, FixedBid, Notifications, Support, Admin dashboard and selected report components against the clean-install baseline RLS and relevant forward policies.
- Confirmed own-profile SELECT, member-owned wallet account/transaction SELECT through member_ids.owner_user_id, allowlisted app_settings read for the package activation switch, and owner/Admin notification/support read boundaries.
- Confirmed inspected Admin data and mutation call sites use Admin RPCs; member identity/graph/withdrawal and Fixed Bid actions use member-scoped RPCs. No additional evidenced direct-read ownership or Admin direct-table-write defect found in this focused slice.
- Noted WalletHistory CSV export retrieves all RLS-visible transactions in 500-row batches and filters client-side; this is an efficiency enhancement, not an authorization defect.
- Added `docs/FRONTEND_MEMBER_ADMIN_DIRECT_READ_RLS_REVIEW_2026-11-18.md`. Source-only; no tests/build/CI, SQL execution, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Baseline ACL evidence and least-privilege correction

- Verified current GitHub refs: `completion-work` was `bd857fefef45943f14446b5c828f9d46e6c14bdb`; protected `main` was `415364b71534c7fc31d6c0928dd8395e10cbd94f`. The branch comparison shows `main` has one documentation-only commit not present on `completion-work`; `main` was not modified.
- Ran read-only Production catalogue queries only. Confirmed `service_role` has EXECUTE on all 43/43 public functions, matching the clean-install candidate's explicit public function grants; `private.place_bid(uuid)` remains an explicit service_role-only private grant.
- Confirmed Production `audit_logs_id_seq` grants SELECT, UPDATE and USAGE to anon, authenticated and service_role, while `audit_logs` table access is limited to service_role and postgres. Tightened the schema-only candidate to grant only USAGE on this sequence to service_role and no sequence privileges to anon/authenticated. This is an intentional least-privilege improvement, not exact live ACL parity. Production and TEST were not changed.
- Updated the ACL and SECURITY DEFINER/trigger audit documents to record the evidence and remaining limits. No tests, builds, CI, SQL replay or database writes were run. Overall estimate remains 55%.


### 2026-11-18 — Support-ticket residual column privilege correction

- Inspected the original support-ticket grants and discovered that migration #67 revoked only table-level INSERT/UPDATE, while the original migration had separately granted INSERT(user_id, subject, message) and UPDATE(status, admin_response). PostgreSQL column ACLs are independent; those column-level privileges can survive table-level REVOKE.
- Added `20261118460000_revoke_support_ticket_column_writes.sql` as forward candidate #68. It revokes both table-level and exact column-level INSERT/UPDATE from authenticated while preserving SELECT and the intended audited/idempotent RPC write paths.
- Added `docs/SUPPORT_TICKET_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`; updated manifest to 68 forward + 16 excluded timestamped + 3 legacy SQL files (87 total), clean-install README, status and static inventory checkpoint.
- Source-only. No tests/build/CI, SQL execution, migration replay or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


### 2026-11-18 — Member-notification residual column privilege correction

- Rechecked the original `member_notifications` grant and candidate #67. The original migration granted authenticated column-level INSERT(user_id, title, message, category); #67 revoked only table-level INSERT. Column ACLs are independent, and the Admin-only INSERT RLS policy meant an Admin direct-write path could remain, bypassing notification RPC idempotency and audit logging.
- Added `supabase/migrations/20261118470000_revoke_member_notification_column_insert.sql` as forward candidate #69. It revokes table-level and exact column-level INSERT from authenticated, while preserving owner-scoped UPDATE(read_at) for the member inbox.
- Added `docs/MEMBER_NOTIFICATION_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`; updated the ordered manifest and clean-install README to 69 forward + 16 excluded timestamped + 3 legacy SQL files (88 total).
- Source-only. No tests/build/CI, SQL execution, migration replay or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


### 2026-11-18 — Complete forward migration column write-ACL scan

- Scanned explicit GRANT/REVOKE statements in all 69 ordered forward migration candidates.
- The only independent column-scoped write grants found were support-ticket INSERT/UPDATE (corrected in #68) and member-notification INSERT (corrected in #69). The notification UPDATE(read_at) grant is intentionally preserved for the member read-state UI.
- No other explicit column-scoped INSERT/UPDATE grants were found in the forward migration set. This is not yet a complete ACL parity proof: baseline grants, default privileges, effective role privileges, policies and PostgreSQL replay still require review.
- Updated `docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md` and `PROJECT_STATUS.md`. Static source review only; no tests/build/CI or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


### 2026-11-18 — Fixed Bid published rules projection and clean-install manifest correction

- Compared the Member Fixed Bid catalogue's consumed configuration fields with the final public RPC definition. The UI displays `max_entries_total` and `refund_non_winners`, but migration `20261118290000_public_fixed_bid_catalogue_page.sql` did not include those keys in its restricted JSON projection.
- Reviewed follow-up migration `20261119000000_fixed_bid_public_rules_projection.sql`: it replaces the same bounded paginated RPC contract and adds both missing published rule fields while retaining the allowlisted projection, published-product filter, status/date rules, bounded title search/page size/offset, stable ordering, empty search_path and explicit anon/authenticated EXECUTE grants. No direct table read grant is added.
- Found the migration was absent from `supabase/clean-install/forward-migrations.txt`; the manifest test would detect the unaccounted timestamped SQL file. Added it as forward candidate #70 and corrected the clean-install README/static reconciliation counts to 70 forward + 16 excluded + 3 legacy = 89 SQL files (86 timestamped).
- Added a source-contract assertion to `tests/fixed-bid-catalogue-pagination.test.ts` for all eight public rule keys and the RPC access/bounds contract. This test source was not executed.
- Latest source branch HEAD before this checkpoint: `ec70002007d2b52719af7709f68dcff700f9eabc` (`fix: align placement tree UI with duplicate ID hierarchy`). That commit also updates the Placement Tree to identify Main versus Duplicate IDs and show the owning Main ID for duplicates.
- Source-only development. No tests, builds, CI, SQL replay, Production writes or TEST writes. Overall estimate remains 55%.


### 2026-11-18 — Member Placement Tree root ownership enforcement

- Source review found `get_my_placement_tree()` trusted `profiles.main_member_id` after checking only `auth.uid()`. Because it is SECURITY DEFINER, the root pointer itself must be verified against `member_ids.owner_user_id` and `id_type='main'` before traversing member/profile rows.
- Added forward candidate #71, `20261119010000_enforce_member_placement_tree_root_ownership.sql`. It requires the authenticated profile's Main-ID pointer to resolve to a Main ID owned by that same user; otherwise it fails closed with 42501. It preserves Main/Duplicate descendant traversal, the 20-level/cycle guards, output fields and authenticated/service_role EXECUTE grants.
- Updated `tests/member-placement-tree-duplicate-ids.test.ts` with source-contract assertions for root ownership and retained RPC grants. The test was not run.
- Updated the forward manifest and clean-install inventory to 71 forward + 16 excluded timestamped + 3 legacy = 90 SQL files (87 timestamped).
- Source-only development. No tests/build/CI, migration replay or database writes. Production remains read-only and TEST remains untouched.


### 2026-11-18 — Admin notification history recipient labels

- Reviewed the current Admin and Member notification flows. Admin recipient search already resolves Main ID/name/mobile through `admin_lookup_notification_recipients(text)`; notification sending already uses the idempotent Admin-only in-app delivery RPC.
- Found the Admin history still displayed the raw Auth UUID as its recipient label. Added forward candidate #72, `20261119020000_admin_notification_history_recipient_labels.sql`, with Admin-only `admin_list_member_notifications_page(integer,integer,text)`. It returns bounded 100-row pages, validates category filters and offset bounds, uses an empty `search_path`, verifies the Admin app_metadata role, joins Main ID/display name and has explicit grants.
- Updated `src/components/Notifications.tsx` so Admin history uses the new RPC for initial and load-more pages and shows Main ID/name; Member inbox and owner-only read-state updates remain unchanged.
- Added `tests/admin-notification-history-page.test.ts` and extended `tests/notification-inbox-actions.test.ts` with source-contract assertions. Tests were not executed.
- Forward manifest and clean-install README updated to 72 forward + 16 excluded timestamped + 3 legacy = 91 SQL files (88 timestamped). Source-only work; no tests/build/CI, migration replay or database writes. Production remains read-only and TEST remains untouched.


### 2026-11-18 — Admin package receipt signed-link refresh

- Found that the Admin receipt viewer replaced its View button with a five-minute signed Storage URL link. After expiry, the link remained visible and there was no in-place refresh control.
- Updated `src/components/Admin.tsx` to store the signed URL with its expiry timestamp, hide the link after expiry, and always keep a View/Refresh button so Admins can request a new short-lived URL without reloading the pending activation queue.
- Extended `tests/admin-pending-activation-receipt-path.test.ts` with source-contract assertions. The test was not executed.
- Commits: `d938fc397a19cac7737079236ed3f69d41d33380` (UI) and `ea38258d36a239249a81afb533ddc14ab0e9722c` (test). No migration changes; the manifest remains 72 forward + 16 excluded timestamped migrations, plus 3 legacy SQL files. No tests/build/CI, SQL replay or database writes. Production remains read-only and TEST untouched. Overall estimate remains 55%.


### 2026-11-18 — Support-ticket audit event deduplication (#73)

- Reviewed the Support member submission and Admin response workflow. The original support-ticket row trigger already writes an Admin update audit event, while the later idempotent `admin_update_support_ticket()` RPC also inserted an audit row for the same update. This produced duplicate audit records for a single Admin action.
- Added forward candidate #73, `20261119030000_deduplicate_support_ticket_audit_events.sql`. The row trigger remains the sole audit writer and now includes member user ID alongside actor, ticket ID, old/new status and response-change indicator. It preserves the existing Admin RPC event contract (`support.ticket_updated` and `response_updated`) so existing audit searches/consumers are not needlessly broken. The Admin RPC retains its role check, input validation, ticket row lock, update and response shape but no longer inserts a second audit row. Its explicit authenticated-only EXECUTE grant is retained.
- Added `tests/support-ticket-audit-deduplication.test.ts` with source-contract assertions. The test was not run.
- Updated the forward manifest and clean-install README to 73 forward + 16 excluded timestamped migrations + 3 legacy SQL files = 92 SQL files (89 timestamped). Source-only change; no tests/build/CI, SQL replay or database writes. Production remains read-only and TEST remains untouched. Overall completion estimate remains 55%.


- Follow-up source compatibility refinement: the single trigger audit event retains the pre-existing RPC action name `support.ticket_updated` and the `response_updated` detail key. This avoids changing the searchable event contract while removing the duplicate row. Commit: `2015412e8377ffdd6ec9eea783f9ce6d6b09cdd4`.


### 2026-11-18 — Support and notification idempotency retry hardening

- Corrected a Member Support retry edge: when a submission failed and the member edited the subject or message before retrying, the UI previously reused the same idempotency key, causing the server to correctly reject the changed payload as key reuse. The UI now retains the key for identical retries (including ambiguous network outcomes) and generates a fresh key when the normalized subject/message changes. A successful submission clears both key and payload fingerprint.
- Hardened Admin notification idempotency fingerprinting by encoding recipient, title, message and category as a JSON tuple instead of delimiter concatenation, eliminating ambiguous field-boundary collisions.
- Added `tests/support-ticket-idempotency-retry.test.ts` and `tests/notification-idempotency-fingerprint.test.ts`. These source-contract tests were added but not executed.
- No migrations, database writes, tests/build/QA or deployment were performed. Production remains read-only and TEST remains untouched.


### 2026-11-18 — PWA service-worker cache documentation alignment

- Compared the production service worker source with the PWA implementation guide. The worker is already on cache namespace `biddworld-shell-v4`, while the guide still described v3. Updated the guide to v4 and recorded that the existing static PWA test contains a stale v3 literal assertion to be handled in the consolidated final test/repair phase; the test was not edited or executed in this development phase.
- Confirmed by source inspection that the worker registers only in production under Vite `BASE_URL`, caches only same-origin app-shell/static assets, does not intercept cross-origin Supabase/API traffic or non-GET requests, and removes older namespaced caches on activation. This remains source review, not Android/offline runtime validation.
- No build, test, CI, browser/device QA, database replay or deployment was performed.


### 2026-11-18 — Support ticket queue and export pagination hardening

- Replaced mutable offset pagination in the Member/Admin support queue with keyset pagination using the stable descending composite order `(updated_at, id)`. The next page starts strictly after the last displayed ticket, avoiding page shifts and duplicate/missed rows caused by concurrent support-ticket updates changing `updated_at`.
- Replaced offset pagination in Support CSV export with the same composite cursor. Existing repeated-page and duplicate-ticket guards and the 5,000,000-row safety cap remain in place.
- Added `tests/support-ticket-keyset-pagination.test.ts` as a source-contract test. It was not executed.
- No tests, build, QA, deployment or database operations were performed.


### 2026-11-18 — Member wallet statement keyset pagination

- Replaced offset-based 100-row wallet history pagination with a stable descending `(created_at, id)` keyset cursor scoped to the authenticated member's Main ID. The cursor resets when the authenticated member scope changes and when the first page is refreshed.
- Replaced full wallet CSV export offset pagination with the same composite cursor while retaining duplicate transaction ID detection and the export safety cap. Existing wallet, direction, transaction type, search and date filters continue to apply to exported rows.
- Added `tests/wallet-history-keyset-pagination.test.ts` as a source-contract coverage; it was not executed.
- No tests, build, QA, deployment or database operations were performed.


### 2026-11-18 — Admin auction and Fixed Bid report keyset pagination

- Replaced the current Auction Bid and Fixed Bid Entry report UI pagination and complete CSV export with dedicated cursor RPCs using stable descending `(created_at,id)` ordering.
- Added forward migrations #74 and #75. Both RPCs enforce Admin authorization, bounded page size, paired cursor validation, empty search_path and explicit authenticated EXECUTE grants. Existing offset RPCs remain unchanged for compatibility.
- Added source-contract tests for both report components and SQL contracts. The tests were not executed.
- Updated the clean-install forward manifest to 75 forward + 16 excluded timestamped + 3 legacy SQL files (94 total). No tests/build/CI, database replay or database writes were performed. Production remains read-only and TEST remains untouched. Overall estimate remains 55% (Provisional).


### 2026-11-19 — Member Main Wallet Add Money workflow

- Added a member Add Money panel with the KRFSI UPI QR, amount, UTR/payment reference, receipt upload and request history.
- Added Admin review queue with private receipt access and approve/reject actions. Approval updates the internal income wallet account (displayed as Main Wallet), writes a single deterministic-key ledger credit and an audit record in one database transaction.
- Added unique normalized UTR protection, member-owned receipt upload paths, Admin-only receipt reads and locked pending-to-final review state transitions.
- Renamed user-facing Income Wallet labels to Main Wallet across the member dashboard, wallet statement, Admin wallet controls and preview. Internal income type is retained for backward compatibility.
- Added migration candidate #76 to the clean-install forward manifest. No migration was applied; no tests/build/QA, database writes or deployment were performed. The existing authorization model supports Admin only; a distinct Admin Staff role remains unimplemented. Overall estimate remains 55% (Provisional).


- Inventory update after Main Wallet funding migration #76: 76 forward + 16 excluded timestamped + 3 legacy SQL files = 95 SQL files (92 timestamped). This is source inventory only; no replay was performed.


### 2026-11-19 — Cross-workflow UTR uniqueness

- Added a trigger-level shared UTR guard between package payment submissions and Main Wallet top-ups. A normalized UTR is serialized through one transaction-scoped advisory lock before cross-table lookup; duplicate references across either workflow are rejected.
- Added source-contract coverage; not executed. Migration #77 added to the forward manifest, bringing source inventory to 77 forward + 16 excluded + 3 legacy SQL files (96 total; 93 timestamped).
- No migration replay, DB write, tests/build/QA or deployment. Overall estimate remains 55% (Provisional).


### 2026-11-19 — Registration Email Verification Setting

- Added an Admin-controlled Email Verification ON/OFF switch under Member Registration, default ON, with audit logging and a narrow public read RPC for the signup screen.
- Signup redirect and messaging now follow the saved policy. The Supabase Auth project-level Confirm Email option remains a separate provider setting and must be aligned manually; if it remains ON while the app switch is OFF, the signup UI reports that mismatch rather than pretending confirmation was bypassed.
- Added forward migration #78 and source-contract test (not run). Migration inventory: 78 forward + 16 excluded + 3 legacy SQL files (97 total; 94 timestamped).
- Removed the client hardcoded financial approval gate so Admin controls call through to server-side guards; database interlocks remain in place and Production remains locked. No testing, migration replay, DB writes or deployment.


- Package Activation now displays the same KRFSI UPI payment QR and verified payee/UPI text as Main Wallet Add Money, before the package UTR and receipt submission fields. No test or deployment has been performed.


### 2026-11-19 — Restricted Payment Review Staff (#79)

- Added Primary Admin-controlled restricted staff role with only Package Activation and Main Wallet Add Money review permissions. Grant/revoke operations audit log and require session refresh.
- Added isolated staff portal; no full Admin navigation or unrelated Admin actions. Matching database RPC permissions and Storage receipt-read policies enforce the same boundary.
- Added forward migration #79 and source-contract test (not run). Inventory now 79 forward + 16 excluded + 3 legacy SQL files (98 total; 95 timestamped).
- No tests, builds, QA, migration replay, DB writes or deployment.


### 2026-11-19 — Notification inbox keyset pagination (#80)

- Member and Admin notification history now use bounded 100-row keyset pages with a stable `(created_at,id)` cursor and look-ahead row. Member access remains scoped to the authenticated user; Admin history uses a dedicated Admin-only cursor RPC.
- Previous Admin offset RPC retained for compatibility. Added migration #80 and source-contract test (not run). Inventory: 80 forward + 16 excluded + 3 legacy SQL files (99 total; 96 timestamped).
- No tests, builds, QA, migration replay, DB writes or deployment.


### 2026-11-19 — Member auction submissions and moderation (#81–#82)

- Added member Place an Auction submission flow with item images, title, description, price, schedule and optional extra details. Active Main ID eligibility is checked on the server.
- Submissions remain pending/private until Admin or restricted Staff with explicit auction review permission edits and approves/rejects. Approval creates the published product and scheduled/live auction; moderation is audited. Members can view submission status.
- Added migrations #81–#82, member and staff UI, and source-contract test (not run). Inventory: 82 forward + 16 excluded + 3 legacy SQL files (101 total; 98 timestamped).
- Approved-image public delivery remains a separate required integration. No tests, builds, QA, migration replay, DB writes or deployment.


### 2026-11-19 — Approved auction image delivery (#83)

- Added the approved-image publishing step: private pending uploads are copied to public product media during Admin/authorized Staff approval; public auction and product views resolve stored paths to public URLs.
- Added migration #83 and source-contract test (not run). Inventory: 83 forward + 16 excluded + 3 legacy SQL files (102 total; 99 timestamped).
- Image upload and database approval are separate operations; orphaned public objects may require cleanup if approval fails after copying. No tests, builds, QA, migration replay, DB writes or deployment.


### 2026-11-19 — Expected-price auction lifecycle (#84)

- Added Starting Price + Expected Price flow; removed mandatory End Time. Auction runs until the current bid reaches/exceeds Expected Price, then a 48-hour close deadline is stored. Bid RPC supports open-ended auctions and blocks bids after the deadline.
- Added scheduled-start/automatic-close `pg_cron` job, Admin/Staff expected-price editing, public expected-price/countdown fields and member countdown UI. Source-contract test added but not run.
- Inventory: 84 forward + 16 excluded + 3 legacy SQL files (103 total; 100 timestamped). No tests, builds, QA, SQL replay, DB writes or deployment; cron remains unapplied/unverified. Overall development estimate 58% provisional.


## 2026-11-19 — Individual restricted Staff permissions (#85)

- Added a Primary-Admin-only RPC to update the three supported permissions independently for an existing restricted Staff account: Package Activation Payment Review, Main Wallet Add Money Review, and Member Auction Listing Review.
- Added allowlist validation, mandatory audit reason, audit event, per-user checkbox UI and Save Permissions action. At least one permission is retained; Revoke Staff Access remains the role-removal path. Staff must sign out and back in to refresh JWT app_metadata claims.
- Corrected the previous Staff-grant RPC response to include all three permissions. Added source-contract test (not run) and registered migration #85.
- No tests/build/QA, SQL replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall development estimate 59% provisional.


## 2026-11-19 — Branch-head reconciliation and source feature inventory

- Rechecked `completion-work` at `42e8855a8af1e36d7d247a4e26a85970b41f4b43`; the branch has advanced beyond the earlier #85 documentation checkpoint. The ten relevant migrations (`20261119060000` through `20261119080000`, and `20261119100000` through `20261119160000`; no `20261119090000` file exists) were confirmed already present in the forward manifest; no migration paths needed to be added.
- Verified existing source/UI workflows include Main Wallet Add Money (QR, UTR, private receipt upload, member history, Admin/Staff review and atomic Main Wallet ledger credit), cross-workflow payment-reference uniqueness, Registration Email Verification setting, and restricted Staff permission assignment. Also present: notification keyset pagination, auction submission/moderation, Staff auction-review grants, approved-image media delivery, Expected Price-triggered 48-hour auction lifecycle, and individual Staff permissions.
- The forward manifest already reconciles to 85 forward candidates + 16 excluded timestamped migrations + 3 legacy SQL files (104 total; 101 timestamped). A redundant marker added during the documentation pass was removed. No migration manifest entries were missing.
- No source tests were executed; no build, QA, browser/device checks, migration replay, Supabase writes, or deployment were performed. Production remains read-only and TEST remains untouched. Earlier **59% Provisional** planning estimate is retained; the new inventory does not justify claiming additional implementation completeness.


## 2026-11-19 — Member auction upload cleanup

- Corrected member auction submission media lifecycle: pre-RPC upload/validation failures clean up any already-uploaded private images; a definite RPC rejection cleans them up too. Ambiguous RPC failures intentionally retain the objects to avoid breaking a database submission that may have committed despite a lost response.
- The image picker no longer silently truncates selections above eight; the submission validation now reports the actual selected count against the 1–8 image contract.
- Added `tests/member-auction-upload-cleanup.test.ts` as source-contract coverage (not run).
- Implementation commit: `4640e3ce46d471cd8f2a677c5400ae75f1a35700`; test-source commit: `7014af25690d906d4e3717f3bc0c4762861dbb2d`. No tests/build/QA, migration replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## 2026-11-19 — Wallet funding receipt cleanup

- Main Wallet Add Money now removes its uploaded private receipt only when the request RPC returns a definite database error. Ambiguous transport failures preserve the object to avoid deleting a receipt potentially referenced by a committed request.
- Added `tests/member-wallet-funding-upload-cleanup.test.ts` source-contract coverage (not run).
- Implementation commit: `c010a7b1e72f06670191c0b74c789c7f015909a8`; test-source commit: `1e64fa623a40842ffb796df8dba0c52877030dd1`. No tests/build/QA, migration replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## 2026-11-19 — Member Wallet Add Money navigation integration

- Found that `WalletFunding` and its QR/UTR/private receipt/request-history workflow existed in source but was not mounted in the authenticated member Wallet tab. Added a lazy import and rendered the component in the Wallet workspace above wallet transaction history.
- Added `tests/member-wallet-funding-navigation.test.ts` source-contract coverage (not run).
- Implementation commit: `bf4242f2a8b2435e8ad1d532bbf65b75eb786357`; test-source commit: `158faafdbe48b4585e2f49e90a44cc036edca052`. No tests/build/QA, migration replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## 2026-11-19 — Wallet funding request history session isolation

- Wallet funding history now subscribes to Supabase auth changes, clears old-member rows, invalidates stale requests, reloads under the new authenticated user and reports load failures explicitly.
- Added `tests/member-wallet-funding-session-scope.test.ts` source-contract coverage (not run).
- Implementation commit: `b9c294035bd71bb9e192240bc370fe9d530980da`; test-source commit: `491e0960fbc3472264d875b212ecef77e64988e9`. No tests/build/QA, migration replay or database writes. Planning estimate: **60% Provisional**.


## Latest source-development batch — OLX-style Auction Classified Upload

- Expanded the member Auction submission form with structured classified fields: category, brand, model/variant, condition, age/year, warranty, ownership, area/locality, city, state and six-digit PIN code, alongside title, description, 1–8 images, Starting Price, Expected Price, bid increment and start date/time.
- Classified attributes are passed through the existing optional_details payload; Admin/authorized Staff review now displays and can edit those attributes before approval. Existing pending-review and publish controls remain in force.
- The Admin workspace already contains direct Auction product/auction draft creation and a separate Fixed Bid draft/campaign workflow; the member-facing Auction submission remains distinct. Fixed Bid creation remains in the Admin workspace only.
- Added tests/olx-style-auction-classified-fields.test.ts as source-contract coverage; not executed. No tests/build/QA/browser checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST untouched.
- Implementation commits: 0006ea751a11d343aad2e65df2e1e2e71cb6abdb (member classified form), cc2c3c3361468a45fb85ced579d6eb1473ce3f61 (Admin review fields); test source commit: 1ae04c0d3a665e9b24b6623823baec908175f07f.
- Overall development estimate remains **60% Provisional**; this feature batch does not imply the broader project is complete.


## Latest source-development batch — Auction classified form validation hardening

- Member auction submission now validates positive Starting Price, Expected Price greater than or equal to Starting Price, positive bid increment and a valid start date before uploading images, reducing avoidable orphan uploads.
- Successful submission clears every classified field (brand, model, condition, age, warranty, ownership, locality, city, state, PIN), pricing/schedule fields and extra specifications so the next listing starts cleanly.
- Corrected the classified form's category-to-fields markup separator. Added source-contract assertions for price validation and complete form reset; test file not executed.
- Commits: `2b703301857bcf9d5fc561b67dde883ccb574a7c` (implementation), `71c980e26f54e51d2a5a1ed324c4302e783f25cc` (test source). No tests/build/QA/browser checks, SQL replay, Supabase writes or deployment.
- Admin direct Auction draft parity is now implemented in source; remaining project development is tracked in this register. Development estimate remains **60% Provisional**.


- 2026-11-19 — Admin direct Auction draft workflow aligned with Expected Price lifecycle: Expected Price is mandatory and cannot be below Starting Price; fixed Planned End input removed; `ends_at` remains null until target price is reached and the existing 48-hour trigger derives the deadline. Added forward-only RPC migration and source-contract test. Not applied; no tests/build/QA run; production and TEST Supabase untouched.


## 2026-11-19 — Admin Auction Expected Price lifecycle parity (bulk batch)

- Completed the Admin direct Auction draft workflow parity: Expected Price is mandatory, must be at least Starting Price, is sent to the secured RPC, and appears in the Admin auction list. The fixed Planned End field and obsolete client state were removed; the database derives `ends_at` only after the Expected Price is reached, then starts the 48-hour countdown.
- Added a forward-only migration replacing the Admin save/list RPC contracts and extending the lifecycle trigger to start the 48-hour timer when an immediate or scheduled Admin auction becomes live already at its target price.
- Updated shared Admin draft validation and its existing validation tests; corrected and extended the Admin lifecycle source-contract test. Test sources only; none executed.
- Commits: `ff8bcc7b45fdb60890ccb116b85e681e0984d0ee` (Admin UI), `6744e49d7c55d3899fbd82738c8297bb580c3071` (migration), `a1ac4d638e91e2d54794ae57c860296b22993c42` (shared validation), `d42e34cffc1d5a0788c32e3796078c1bf4cb6a5c` (validation tests), `cc0d99460340eb561259c41234535468c1166912` (lifecycle test), `26aaa50be1600878345c05dcb2bb54906c0c21b2` (immediate-start lifecycle fix). Documentation updates follow.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Development estimate remains **60% Provisional**.


## 2026-11-19 — Admin open-ended Auction publishing compatibility

- Found and corrected a backend contract gap exposed by the new Expected Price schedule: the existing Admin status RPC still required a fixed `ends_at`, which prevented Admin-created open-ended auctions from being scheduled or opened. Added a forward-only replacement retaining the original Admin authorization, bidding feature gate, cancellation refund ledger reconciliation/idempotency, closed-auction restrictions and audit logging.
- The status RPC now accepts `ends_at = NULL` for Expected Price auctions; scheduled auctions still require a future start time, while immediate auctions may omit Planned Start and open now. Existing time-window checks remain for supplied start/end values.
- Added source-contract coverage. Tests not executed; migration not applied. No build/QA/browser/device checks, Supabase writes or deployment. Production remains read-only and TEST remains untouched.
- Commits: `4c4ee4421509927bac9fbf903ca089deaefde742` (forward migration), `bae13b91738234446744759a0b0b3576210ffea3` (test source), `575959255a2d01d9f41f133e3239edff6476ee03` and `3b51f703fdd08dcfb9f16fdf032edad32d403e96` (migration refinements), `410b52965b8ce295d116de7b19cc03c7ff590fd6` (test refinement).
- Overall development estimate remains **60% Provisional**; broader modules and source/database contract reconciliation remain.


## 2026-11-19 — Fixed Bid product image delivery

- Corrected the member Fixed Bid campaign cards to resolve product-media Storage object paths through Supabase's public URL helper instead of assigning raw storage paths to `<img src>`. Existing absolute HTTP(S) URLs remain supported; missing image paths use the visual fallback. Images are lazy-loaded.
- Added a source-contract test; not executed. No build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched.
- Commits: `758aef3c942ffe45091ab010c0ddaa1523a2f441` (media URL resolution), `2c3c44be230d63e1c8fb904c69cab70ad76644e5` (JSX fallback correction), test commit recorded separately.


## 2026-11-19 — Homepage marketplace rows

- Home now shows Fixed Bids first and Auctions second as separate horizontal, touch-scrollable card rows with responsive sizing. Member Auction submission remains below the rows. The dedicated Fixed Bid tab retains its full search/filter interface.
- Added source-contract tests only; not executed. No build/QA/browser checks, SQL replay, Supabase writes or deployment.
- Commits: `3fd718d4`, `b4b98b72`, `34a9a888`, `ff2f2fc6`, `804920f4`, `bf93102d`.


## 2026-11-19 — Homepage discovery and accessibility controls

- Activated the existing Auction category and sort state with visible homepage controls and a live matching-count label. Auction cards remain in the requested horizontal row beneath the separate Fixed Bids row.
- Improved screen-reader naming and state communication for the marketplace search and mobile navigation toggle.
- Added global keyboard focus-visible styling and reduced-motion preference support.
- Added source-contract coverage in `tests/homepage-auction-discovery-controls.test.ts`; test not run.
- Commits: `6e3ee90f2289bdf523b9fef4b3f1e27d544cb45b`, `03af6f2bf428a900734d5bf14fa3c4a11f3d86ae`, `0e4d5cbccde0d0fc68c29f89031567ffda924d5e`, `198c9af0e8a398277b30ee08adb658077635b6ce`, `2d89fe5aa7771e0bfef783c0e7de6309bff47cce`.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Completion estimate remains **60% Provisional**.


## Latest Frontend Batch — Marketplace sample preview cards

- Added three clearly labelled, display-only Fixed Bid sample cards (smartphone, home appliances, smartwatch) with example entry amount, winner payment, winner count, entry limits and schedule fields.
- Homepage Auctions now reliably shows the existing sample auction cards whenever the live auction list is empty or only local demo fixtures are present. Sample cards are visibly marked and cannot trigger real bidding or Fixed Bid entry actions.
- Real published listings take precedence and replace the sample cards automatically. Sample data exists only in frontend source; no database records, wallet credits, payments or user accounts were created.
- Added `tests/marketplace-sample-preview-cards.test.ts` as source-contract coverage; not executed.
- Commits: `5acf28e728e948721794ce5839a3dd4759f19f76` (Fixed Bid fixtures), `e466b3fbf4834466b3f240797bbf10e182797cc9` (Auction fixtures), `ca6e5cc9a2a6b0f773a11054239bc840a652d991` (sample card styling), `0289b0797fc445eda3301eb5025522daadb2086a` (demo-fixture labelling), `e231a8ec21dca8660b25f7c096290144db426e20` (test source).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Frontend Batch — Product catalogue sample preview

- Added three display-only product catalogue examples (Bluetooth headphones, fitness watch, home/kitchen essentials) so the Products page has visible cards before real catalogue records are published.
- Product cards use the existing responsive marketplace card design and carry a clear SAMPLE PREVIEW label. Published product rows replace local samples automatically.
- Search filters local sample cards while the preview fallback is shown. No product records, purchases or transactions are written to Supabase.
- Added `tests/product-catalogue-sample-preview.test.ts` as source-contract coverage; not executed.
- Commits: `011516e55ea49d33760fd0699c0c53f68100b6a5` (product preview data and rendering), `1e9a868d4bead476608667287f5adac14e757da3` (product card styling), `2becdfedfc712d9f40f53100761bb4aa79bbcf84` (test source).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Admin Frontend Batch — Product draft editing controls

- Admin product form now clearly switches between new-product and edit-product modes, with matching Save/Update button text.
- Added Cancel Edit to clear the unsaved form state and return to new-product mode; if an unattached temporary image exists, its existing cleanup flow is invoked.
- Product draft save is disabled while an image upload is in progress, preventing a premature save before the selected image upload finishes.
- Added `tests/admin-product-draft-edit-controls.test.ts` source-contract coverage; not executed.
- Commits: `c08491dff55286de474175b3830b08c71b5aa5bb` (Admin form controls), `450e46c6308c9ed1debdc4aa8bbd047ae3783b3a` (test source).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## 2026-11-19 — Admin Product Draft image preview

- Added a lazy-loaded image preview to the Admin product draft form, reflecting the current image URL or uploaded image. The preview has descriptive alternative text and hides broken image links without changing the saved URL.
- Added `tests/admin-product-draft-image-preview.test.ts` source-contract coverage; not executed.
- Commits: 14f51ad3c72eb3d2663601039efe07b71adff285 (Admin UI), 68242c7ec242ed5cf4effb6ea8a473875a7150cd (test source), 40820a1b61a3d35028c6eef960ddfbea488ed90e (status).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## 2026-11-19 — Admin Saved Products thumbnails

- Added image thumbnails to the Admin Saved Products list, resolving Storage paths via `product-media` and preserving external HTTP(S) URLs. Lazy loading, descriptive alt text and broken-image hiding included.
- Added `tests/admin-saved-product-thumbnails.test.ts`; source-only, not executed.
- Commits: 8828d1b616c249b0eb06d90945031bba63b3db70 (UI), 0572ed0d6bd6bba74fe8133d362bbce4d158d7ac (test), 6700397dae3ab075f5f0f3253170476209a081b5 (status).
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall completion: **60% Provisional**.


## 2026-11-19 — Member Auction review validation and media cleanup

- Admin approval now validates the edited title, description, Starting Price, Expected Price, bid increment, start time and image count before copying any private submission images into the public product-media bucket.
- Serialized review actions with an in-flight ref to prevent rapid duplicate approve/reject requests.
- If image copying fails before the review RPC, or the RPC returns a definite database error, uploaded public copies are removed. If the RPC outcome is ambiguous (for example, a lost network response), public copies are deliberately preserved so a successfully published auction is not left with broken images.
- Added source-contract test coverage only; it has not been executed. No build, QA, SQL replay, Supabase writes or deployment. Production remains read-only and TEST remains untouched. Overall development estimate remains **60% Provisional**.
- Commits: `0d479c0e812b367603eaaac6c410a209cddb88af` (Admin review), `008fcc011212153295abb52315bf08ce6ea66c11` (test source).


## 2026-11-19 — Auction review form state and date-input resilience

- After a successful member-auction review, the reviewed submission's local edits and review note are cleared so stale unsaved values cannot leak into a later refresh/review session.
- Clearing the Starts At field no longer throws a client-side `RangeError`; invalid/empty input is retained as an empty value and blocked by the approval validation before any public image copy.
- Extended source-contract coverage; tests remain unexecuted. No build, QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.
- Commits: `a6cd717cd4fe82d330004acaf5930cb6a1c44b2c` (UI), `d5d1753f37733b12295abea9281f66400f3ffe0e` (test source).


## 2026-11-19 — Branch-head verification and clean-install manifest correction

- Re-read `completion-work` at source HEAD `78bc8d5ebffc9c290f5a4d992fe0082468cb386d`. The latest source commits `207feaacc02cfa280c08f6493cc5f646db00766e` and `78bc8d5ebffc9c290f5a4d992fe0082468cb386d` correct the Admin product image preview conditional JSX and Auction image JSX nesting.
- Confirmed the Member Auction submission preflight validates trimmed title/description, 1–8 JPG/PNG/WebP images (5 MB each), positive Starting Price, Expected Price not below Starting Price, positive increment and valid start time before upload. It uses an in-flight guard and cleans up definite pre-RPC/RPC-rejection upload failures; ambiguous RPC outcomes intentionally preserve media.
- Confirmed Admin review validates edited fields before copying private images to public product media, serializes review actions, and removes copied images only on pre-RPC/definite RPC failure. Ambiguous outcomes preserve media to avoid broken published listings.
- Full migration inventory found 103 timestamped migration files, while the prior forward/excluded manifests covered only 101. Two migrations were missing: the Admin Expected Price lifecycle migration and Admin open-ended auction status migration.
- Corrected the duplicate `20261119160000` migration version by renaming the Admin Expected Price lifecycle file to `20261119160100_admin_auction_expected_price_lifecycle.sql`; added that file and `20261119170000_admin_open_ended_auction_status.sql` to the ordered forward manifest. The manifest now accounts for 92 forward + 16 excluded = 103 timestamped files, with unique version prefixes.
- Updated the clean-install README and authoritative project status to reflect the current inventory and verified source HEAD. The existing manifest-integrity test source covers exact accounting and ordering; it has not been run.
- No tests, build, QA, browser/device checks, migration replay, Supabase writes or deployment were performed. Production remains read-only; TEST remains untouched.
- Overall development estimate remains **60% Provisional**; the correction repairs source-manifest integrity and does not imply successful database replay or runtime verification.


## 2026-11-19 — Isolated Preview Pages workflow permission hardening

- Updated the separate `biddworld-preview` repository's `main` branch at commit `903b198fb69039d2f0de706c714662467a5a8abc`.
- Removed `enablement: true` from `actions/configure-pages`; the workflow no longer attempts a repository-settings operation through its limited workflow token, addressing the observed `Resource not accessible by integration` permission failure.
- Updated the Preview README with the one-time owner action: GitHub repository Settings → Pages → Build and deployment → Source → GitHub Actions → Save. The owner must then manually dispatch the deployment workflow or push a new Preview commit.
- The workflow remains isolated and visual-only: `npx vite build`, `VITE_BIDDWORLD_MODE=preview`, no Supabase URL/key secrets, no tests, and no Production database connection. The Vite base path remains `/biddworld-preview/`.
- The deployment URL has not been verified live. The GitHub workflow-run lookup did not surface a run for the latest pre-fix commit; do not claim the site is published until a successful Pages deployment is visible.
- The primary `biddworld` repository's protected `main` currently points to `620d05b2d266d26dc70c5ff775ed45af9bb3b400`; it was not modified. All application development remains on `completion-work`.
- No tests/build/QA, Supabase writes, migration replay or deployment were performed by this documentation/workflow configuration change.


## 2026-11-19 — Member Auction start-time preflight alignment

- Source review found that the member submission RPC requires `p_starts_at >= now() + interval '30 minutes'`, while the frontend only checked that the date parsed successfully. This allowed too-early submissions to upload all images before the server rejected the RPC.
- Updated `src/components/MemberPlaceAuction.tsx` to validate the 30-minute lead time before any media upload, reuse the validated Date for the RPC ISO timestamp, and display the minimum-start-time hint.
- Removed a literal escaped newline between the Category and classified-details JSX sections that could appear as stray text in the form.
- Extended `tests/member-auction-submission-preflight.test.ts` with source assertions for the lead-time guard ordering and the escaped-newline regression. Test source only; not executed.
- Implementation and source-test commit: `c1af82806e0abd6442de01b094752c6d92c8e776`.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched.
- Overall development estimate remains **60% Provisional**.


## 2026-11-19 — Continuation checkpoint and isolated TEST migration-state exception

- Re-read the live `completion-work` branch. Current HEAD is `9ee5698b0cfe0a13fa56729ecc316658fcaf7a85`; its latest commit corrects the auction-review RPC grant alignment in `20261119150000_expected_price_48_hour_auction_lifecycle.sql`. Protected primary `main` remains `620d05b2d266d26dc70c5ff775ed45af9bb3b400` and was not changed.
- The isolated Preview repository workflow #8, attempt 2, completed successfully at `903b198fb69039d2f0de706c714662467a5a8abc`; its build and Pages publish steps passed. It remains visual-only: no Supabase URL/key is configured, and real registration, wallet, package, auction, bidding and Admin backend operations are unavailable. The app already supports explicit environment URL/public-key configuration through `src/lib/supabase.ts`; do not add Production credentials to Preview.
- **TEST database state exception:** during this continuation, migration application calls were made against `yoaauthwejdgaevfvwpo`, despite the recovery instruction to keep TEST untouched until final testing. The current Supabase migration ledger reports 89 entries: the schema baseline plus the 87 files in the forward manifest, with `20261118230000_recover_admin_read_rpc_sources` recorded twice under separate ledger versions (88 unique names). This was an unintended deviation from the stated process. No further TEST migrations or data changes are to be made during development. Do not delete ledger rows or attempt rollback automatically; reconcile the duplicate and verify the resulting schema deliberately during the authorized final QA phase.
- Production project `hbqatszyzqobgtauyuzy` was not written to. No member, wallet, package, payment, bid, withdrawal or other application rows were intentionally created or changed by these migration calls.
- No tests, type-check, app build, browser/device QA or functional test data checks were run as part of this checkpoint. Overall development estimate remains **60% provisional**; no completion increase is justified.


## 2026-11-19 — Registration email verification default (#93)

- The current source default contradicted the owner's explicit requirement that email verification is not required: the app initialized the policy to true and migration #78 seeded true.
- Updated the Member signup client fallback to false, so a temporarily unavailable policy RPC does not reintroduce mandatory confirmation behavior.
- Added forward migration #93 to set `email_verification_required=false` for existing and clean-install environments and change the public policy RPC's missing-setting fallback to false. The Admin override remains available; provider-level Supabase Auth Confirm Email must independently remain OFF.
- Added `tests/registration-email-verification-default.test.ts` as source-contract coverage; not executed.
- Updated the forward manifest and clean-install README. No tests, build, type-check, browser/device QA, migration replay, Supabase writes or deployment were performed. Production remains read-only; no TEST writes were performed. Protected `main` remains untouched.
- Overall development completion remains **60% Provisional**; this source correction does not establish migration replay or runtime verification.


## 2026-11-19 — Staff access verification diagnostics

- Improved `AdminStaff` access initialization so Supabase configuration errors, session verification failures and other authentication errors are displayed as explicit access-verification failures instead of being misreported as an account with no assigned permissions.
- Added a Retry access check action. The normal no-permissions message is now shown only after a successful session lookup confirms that no supported Staff permissions are assigned.
- Added `tests/admin-staff-access-diagnostics.test.ts` as source-contract coverage; not executed.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment were performed. Production remains read-only; TEST untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional**; this targeted diagnostics fix does not establish end-to-end Staff workflow readiness.


## 2026-11-19 — Admin wallet funding review diagnostics

- Reworked `AdminWalletFundingReview` queue loading to distinguish a genuine empty queue from Supabase/RPC errors, show a loading state, and provide Retry.
- Added per-request secure receipt-link error handling. Approval is disabled unless a signed receipt URL is available; rejection remains available. This prevents approving a payment request without being able to open its receipt from this screen.
- Added a concurrency guard for review submissions and stale-load protection so older requests cannot overwrite newer queue state.
- Added `tests/admin-wallet-funding-review-diagnostics.test.ts` as source-contract coverage; not executed.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment were performed. Production remains read-only; TEST untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional**; this targeted Admin workflow fix does not establish end-to-end wallet funding readiness.


## 2026-11-19 — Admin withdrawal queue diagnostics

- Admin withdrawal management now distinguishes queue loading, a genuine empty result, and a failed queue RPC. A failed queue request displays its error and a Retry queue action rather than leaving a blank list that could be mistaken for no requests.
- Queue loading is cleared for both resolved RPC responses and workspace-load exceptions.
- Added a synchronous in-flight guard for approve/reject/mark-paid actions so rapid repeated taps cannot submit duplicate review calls before React state updates.
- Added `tests/admin-withdrawal-queue-diagnostics.test.ts` as source-contract coverage only; it has not been executed.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% provisional**; this focused Admin workflow improvement does not establish end-to-end withdrawal readiness.


## 2026-11-19 — Bulk restricted-review workflow hardening

- Package Activation Staff queue now has explicit loading/error/empty states, retry support, stale-request protection, per-receipt signing diagnostics, and an approval guard requiring an accessible signed receipt. Rejection remains available when a receipt is missing or inaccessible.
- Auction Submission Review now distinguishes queue failures from an empty queue, ignores stale loads, reports signed-image preview failures, and blocks approval until every submitted image can be previewed. Rejection remains available.
- Primary Admin Staff manager now distinguishes Staff directory load failures from an empty directory and exposes retry. Corrected its busy-state type/values so row-specific permission saves and global grant/revoke actions use one consistent string token.
- Added `tests/restricted-review-workflow-safeguards.test.ts` as source-contract coverage only; it has not been executed.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% provisional** until the remaining modules and final end-to-end QA are completed.


## 2026-11-19 — Member wallet, referral and Fixed Bid resilience

- Wallet transaction history now exposes a direct retry action when its initial or paginated load fails, resetting the page cursor before retrying the first page.
- Add Money request history now exposes a dedicated retry action when its history RPC fails; the existing refresh action remains available.
- Referral genealogy pagination now validates the RPC page payload before reading or appending its tree rows, displaying a recoverable error for an incomplete response instead of risking a client exception.
- Fixed Bid campaign loading errors are shown once rather than duplicated in two separate banners.
- Added `tests/member-wallet-and-inbox-retry-guards.test.ts` as source-contract coverage only; it has not been executed.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending final end-to-end verification.


## 2026-11-19 — Admin report and settlement review batch

- Auction Bid History and Fixed Bid Entry reports now reject reversed From/To date ranges before applying filters or exporting CSV; invalid ranges disable the corresponding action and produce a clear validation message.
- Added `tests/admin-auction-fixedbid-report-date-range.test.ts` as source-contract coverage only; not executed.
- Source-reviewed the auction finalization and Fixed Bid draw RPCs: both lock the parent auction/campaign row, persist a single winner/draw result, and return the existing result on replay. Reviewed cancellation/refund ledger checks and notification send idempotency; no SQL changes were made.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending final end-to-end verification.


## 2026-11-19 — Notification inbox and Support queue recovery clarity

- Member notification inbox and Support request list now distinguish an initial load failure from a genuinely empty result. When no rows are available because loading failed, each module presents an explicit retry action rather than a misleading “no records” message; existing refresh actions remain available.
- Reconciled the notification inbox source-contract test with the current Admin keyset pagination RPC name, replacing a stale assertion for the previous page RPC. Added source assertions for both empty-state retry paths.
- Source review confirms notification history is fetched through the Admin keyset RPC, while member inbox reads remain user-scoped; support reads remain owner-scoped for members and policy-checked for Admin. No SQL changes were required.
- Added/updated source-contract tests only; tests were not executed. No build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains unchanged; protected `main` unchanged.
- Overall development estimate remains **60% Provisional** pending full contract reconciliation and final end-to-end verification.


## 2026-11-19 — Bulk Admin report and delivery workflow alignment

- Corrected the Delivery Tracking report status filter to use the exact backend enum values: pending, packed, shipped, in_transit, delivered and returned. Removed the unsupported processing/cancelled choices from this report control.
- Winning Payment and Delivery Tracking complete CSV exports now reject reversed From/To ranges before any paginated RPC retrieval, show a clear validation message, and disable their export buttons while the range is invalid or another report export is running.
- Extended the Admin winning/delivery report source-contract test to cover the date-range guards, disabled controls and exact delivery status contract. Test source only; not executed.
- Reviewed the delivery tracking migration and current Admin integration: tracking creation requires a paid winning payment, serializes creation per payment, prevents duplicate tracking rows, restricts member reads to the owning member, and records Admin tracking updates in audit logs. No migration was changed or applied.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains unchanged; protected `main` unchanged.
- Overall development estimate remains **60% Provisional** pending full source reconciliation and final end-to-end verification.


## 2026-11-19 — Delivery workspace diagnostics and bulk report safeguards

- Admin Delivery Tracking now displays the delivery RPC failure directly inside its own workspace instead of relying only on the general Admin warning list; a successful load clears the prior delivery-specific error.
- Winning Payment and Delivery report exports validate date ranges before retrieval, disable export while a range is reversed or another report export is active, and use the exact Delivery Tracking backend statuses.
- Extended source-contract tests for the delivery workspace error state and report filter contracts. Tests remain unexecuted.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains unchanged; protected `main` unchanged.
- Overall development estimate remains **60% Provisional** until broad source reconciliation and final end-to-end verification.


## 2026-11-19 — Withdrawal report export preflight

- Added a function-level reversed-date guard to the complete Withdrawal CSV export, complementing the existing disabled-button and inline validation state. Invalid dates now stop before the paginated Admin RPC is called and produce a clear report message.
- Extended the withdrawal report source-contract test; test source only and not executed.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains unchanged; protected `main` unchanged.
- Overall development estimate remains **60% Provisional** pending final end-to-end verification.

## 2026-11-19 — Admin feature settings diagnostics and enablement alignment

- Fixed the Admin feature-settings contract: the email-verification policy was displayed in the UI but omitted from both `admin_get_feature_settings` and the Admin setting allowlist. Added forward migration `20261119240000_admin_email_verification_feature_setting.sql` to expose it while preserving the existing server-side allowlist, condition checks, and audit logging.
- Admin Settings now validates that every expected setting is present as a boolean. RPC failures, malformed responses and missing keys are shown explicitly, with a Retry Settings action; missing values are no longer silently converted to OFF.
- Frontend switches now distinguish backend workflows that are not enabled from settings requiring a server-side condition. Registration, email-verification policy, Sponsor Referral and Delivery Tracking are directly enable-ready; Duplicate IDs, Package Activation and both wallets can be attempted through the UI but the server must confirm their existing condition before saving. Other pending workflows remain disabled, and already-enabled locked features can still be switched OFF.
- Added source-contract coverage for response validation, retry diagnostics, frontend enablement boundaries, server-side interlock preservation and non-optimistic save handling. Tests were not executed.
- Added the new migration to the ordered clean-install forward manifest and updated the inventory to 94 forward + 16 excluded = 110 timestamped migrations.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment were performed. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending full source reconciliation and final end-to-end verification.

## 2026-11-19 — In-app Notifications feature switch integration

- Enabled the existing in-app notification workflow through the Admin Platform Settings allowlist. The setting is now available to turn ON from the Admin UI.
- Added database enforcement to `admin_send_member_notification()`: manual in-app sends are rejected while Notifications is OFF. Support-ticket update notifications also respect the same setting and are skipped while OFF.
- Kept the scope explicit: this switch controls in-app notifications only. Email/SMS templates remain drafts and are not represented as active delivery channels.
- Preserved Admin authorization, notification idempotency and audit logging. Added source-contract coverage for the new setting gate and support-ticket trigger behavior; tests were not run.
- Added the migration to the clean-install forward manifest; inventory is now 95 forward + 16 excluded = 111 timestamped migrations.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending full source reconciliation and final end-to-end verification.

## 2026-11-19 — Existing feature workflow switch alignment

- Updated the Admin feature switch classification: Referral Commissions, Withdrawals, Live Bidding, Fixed Bid and Winner Payment are no longer hard-disabled in the frontend. Their existing database workflows already enforce the corresponding feature flags, so Admin enable attempts now reach the authoritative server-side condition.
- Added forward migration `20261119260000_enable_existing_feature_workflow_switches.sql`. It expands the server RPC's supported enable list for those implemented workflows while preserving the existing server-side condition check, admin authorization, allowlist validation and audit log. It does not change any feature's stored value or bypass the condition.
- Automatic Placement and Winner Selection Configuration remain visibly marked as backend workflow pending; their switches cannot be enabled until the missing workflow/configuration contract is completed.
- Updated source-contract tests for the frontend classifications and server-side enablement condition. Tests were not executed.
- Added migration to clean-install manifest; inventory is now 96 forward + 16 excluded = 112 timestamped migrations.
- No tests, build, type-check, browser/device QA, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending full source reconciliation and final end-to-end verification.
## 2026-11-19 — Matrix plan configuration foundation

- Added `20261119280000_matrix_plan_configuration.sql` with package-specific versioned Matrix plans. Matrix Width (2–100) and Matrix Depth (1–50) are separate values; this accommodates the predefined 1:3–1:7 widths and custom widths such as 1:8/1:10.
- Added independent per-level enabled state, Fixed Amount / Percentage reward configuration, eligibility JSON, Admin save/list/activate RPCs and audit records. Sponsor Referral plan tables remain separate.
- This is configuration groundwork only. Matrix placement, next-gap auto-placement, Under-ID-based Matrix commission calculation, Main Wallet credit attribution and the Admin editor UI are still pending. No wallet credits or placements were created.
- Added source-contract test `tests/matrix-plan-configuration.test.ts`; not run. Added migration to clean-install forward manifest.
- Inventory: 98 forward + 16 excluded timestamped migrations = 114 timestamped migrations, plus 3 legacy SQL files.
- No tests/build/type-check/browser QA, SQL replay, Supabase writes or deployment. Production and TEST remain untouched; protected `main` unchanged.
- Overall development completion remains **60% Provisional** pending full source reconciliation and final verification.


## Latest source-development checkpoint — 2026-11-19 (Matrix Admin UI)

- Rechecked `completion-work` at the beginning of this batch; starting HEAD was `8c2dd32372af9cb799bf2f47d56e89170032c123`. Protected `main` was not changed.
- Added `src/components/AdminMatrixPlans.tsx` and connected it to the Admin navigation as a separate **Matrix Plans** module. It supports package selection, Matrix Width, independent Matrix Depth, per-level enable/disable, Fixed/Percentage rewards, eligibility JSON, versioned draft saves, and explicit activation for unpublished packages.
- Hardened `20261119280000_matrix_plan_configuration.sql` by enabling RLS and revoking direct table access from `public`, `anon`, and `authenticated`; Admin operations use role-checked RPCs.
- Added `tests/admin-matrix-plans-ui.test.ts` and `docs/MATRIX_PLAN_ADMIN_UI_2026-11-19.md`.
- Commits: editor `82db81534acdd5512b267e7ea3ebd188ceacc076`; Admin integration `2f38bc773afe5d935b35b17b553443dcc369c0b5`; Matrix table security `86f4d37e1ad010673c4ed70e18e11b74a2bb6f1b`; contract test `c1fbe01ead1f7f31083c1c9bcdbddd2a951879c2`; documentation `a805b2829ec82e6980c57c9b0e3f4b2acdf618b9`.
- TEST migration ledger is still 89 rows / 88 unique migration names and does not contain the latest Duplicate-ID OFF/ON or Matrix-plan migrations. Production migration history is materially behind the source migration set. Both databases were inspected read-only; no migrations, SQL writes, seed data, financial operations or deployments were performed.
- No tests, type-check, build, browser/mobile QA or E2E were run. The new UI is source-complete only and still requires isolated TEST migration reconciliation.
- Remaining core work: automatic next-empty placement, second-package activation prerequisite for Duplicate IDs, Under-ID Matrix commission engine, atomic Main-ID Income Wallet attribution, source-aware consolidated reports, and dashboard integration.
- Completion remains **60% provisional** until a full source/database-contract reconciliation and final QA. Do not infer completion from this UI batch.


## Automatic Matrix placement checkpoint — 2026-11-19

- Matrix Width, Placement Depth and Commission Depth are now independent package-plan settings.
- Admin Duplicate ID creation no longer accepts a manual Under ID. The server enforces the second approved active package activation, requires its package's active Matrix plan, and performs breadth-first next-empty-slot placement using the configured width and placement depth.
- Creation remains Pending, respects the Duplicate ID OFF/ON feature switch, uses the shared graph mutation lock and records an audit event.
- Source migration `20261119300000_automatic_duplicate_matrix_placement.sql` is registered in the forward migration manifest.
- No database migration or tests/build/typecheck/browser QA were executed. No database data was changed.
- Remaining: Under ID Matrix commission calculation, atomic Main-ID Income Wallet credit with Duplicate source attribution, reports/dashboard integration, then final QA.


## 2026-11-19 — Under ID Matrix commission engine

- Fixed the SQL regex syntax defect in the automatic Duplicate placement migration.
- Added a separate Matrix commission engine that traverses the Under ID placement chain, independently of Sponsor Referral relationships. It stores the actual source ID and credited Main ID separately; Duplicate ID ancestors are attributed as the source while their owner Main ID Income Wallet receives the credit.
- Added transaction-safe/idempotent posting, ledger-backed reversal, Admin audit entries and paginated source-aware reporting. Direct commission-table access is revoked.
- Added a Matrix commission feature setting that defaults OFF and remains locked in the Admin UI until the complete workflow is ready.
- Added `tests/matrix-commission-engine.test.ts` and `docs/MATRIX_COMMISSION_ENGINE_2026-11-19.md`; registered the migration in the clean-install manifest.
- Commits: migration `7c56bdaffbb5fa364f377a40d9b8d1e2e49ad624`; setting gate `3bde0d8a00d116becb764db80670eaf177318911`; UI locked state `56fca0fa28527917f55d11bf04e609ee05835b41`; manifest `8a7b01a8a7d4133e4ba41d3ebb501ee0560dddad`; tests `70af94aab1320e02b23836a27780744002a6e7f3`.
- Test source was authored but not executed. No typecheck/build/browser QA, TEST migration or Production change occurred.

- Follow-up source hardening completed: corrected the placement regex/parentheses (`9cb927379b0cf1def8e9d703e3cf9086f9b63b51`) and verified the original credit ledger identity during reversal replay (`3a075d54da9204e1129ecf2243328997123c4d49`).


## 2026-11-19 — Admin Matrix Commission Report UI

- Added a dedicated Matrix Commissions Admin section separate from Sponsor Referral commissions.
- Server-side status/level filtering, bounded pagination, source ID/type versus credited Main ID display, loaded-row totals, and complete paginated CSV export are implemented.
- The report validates server page structure, timestamps and duplicate IDs before accepting data.
- Added `tests/admin-matrix-commissions-ui.test.ts` and `docs/ADMIN_MATRIX_COMMISSION_REPORT_2026-11-19.md`.
- Commits: UI `456895b5f206999f2c10f25e2352dd8081839e83`; Admin integration `2eede7258443c3299e0226ce680d16224514c488`; tests `af3e1c44fb6c2ba5fa58d52da87018b57e91eac2`; docs `53b3bfc503dee1fa171aa511ce52a0fd0bfc6216`.
- No tests/build/typecheck/browser QA or database migrations/writes were run.


## Member Matrix commission dashboard — 2026-11-19

- Added `member_get_my_matrix_commission_summary()`, a SECURITY DEFINER RPC that resolves the caller's own linked Main ID and returns credited, pending and reversed Matrix totals/counts. It does not expose the Matrix commission table directly and does not mix Sponsor Referral totals with Matrix totals.
- The member MLM dashboard now requests this summary separately and displays **Sponsor Referral Income** and **Matrix Commission Income** as distinct cards. If the new RPC is not yet deployed, the existing Sponsor dashboard still loads and the Matrix card is omitted rather than showing fabricated data.
- Migration: `20261119320000_member_matrix_commission_summary.sql`; registered in the clean-install forward manifest. Added source-contract coverage in `tests/member-matrix-commission-summary.test.ts`.
- Commits: migration `808f1e996d814df1a6296f8b1dd5260e0d0b27af`; member UI `9a9488c8ea59ea8e293cde912cdc9a73dcd2b25f`; manifest `1c6862dcdeca2647cb872fcb3424b382843c4ead`; contract test `06f21fc0b4bd8c97ad676e4e05f1e01843898ef1`.
- This is source-only. No tests, type-check, build, browser/mobile QA or database migrations were run/applied. The previously recorded TEST migration-state exception remains untouched; Production remains untouched.


## Member Commission History expansion — 2026-11-19

- Extended the Member Account > Commission History page to show Sponsor Referral Commissions and Matrix Commissions in separate sections. Matrix rows include level, source member code, source ID type (Main/Duplicate), amount, status and date. The credited destination remains the authenticated member's Main ID.
- Added `member_list_my_matrix_commissions_page(p_limit,p_offset)`, which derives the caller's linked Main ID from `auth.uid()`, validates pagination, returns only rows credited to that Main ID, and exposes source ID attribution without direct table access.
- Updated migration `20261119320000_member_matrix_commission_summary.sql` and added source-contract test `tests/member-matrix-commission-history.test.ts`.
- Commits: Account UI `7e85ee8445a272f3a89965b5ea11601c84474858`; RPC migration `874ed1928aea683ba1308b87e72713a9dd71b8ec`; contract test `0d43c1c7bb25ee17fcc7ab773d5fbdedf156dc2d`.
- The member history currently loads the first 100 Matrix rows; pagination for this section remains a follow-up. No tests/build/type-check/browser/mobile QA run. No database migrations applied.


## Wallet Matrix source attribution — 2026-11-19

- Wallet History now identifies Matrix commission ledger entries with their source member code, source ID type (Main/Duplicate), Matrix level, and states that the amount is credited to the member's Main ID.
- Added a caller-scoped `member_get_my_matrix_commission_sources(uuid[])` RPC. It derives the authenticated member's linked Main ID and only returns requested commission rows credited to that Main ID. It limits each lookup to 200 IDs.
- Wallet History CSV export now fetches source attribution for every exported page and includes Commission Source ID, Source ID Type and Matrix Level columns; the loaded-page search also checks source ID/type.
- Migration update: `20261119320000_member_matrix_commission_summary.sql`. Tests authored: `tests/wallet-matrix-commission-source.test.ts`.
- Commits: wallet UI `1d8751c32701c73a7e0a40422018be3dd661c5a9`; secure lookup RPC `e5d473302d23175d6a4e89f4a67059d1c59dcc82`; source contract test `5b65f1a60cda621f5e4f284869497821027ae9a5`; full-export source attribution `2f3e74ac915f4456848a3e2c60c1f3abcb430860`.
- Source-only development. No tests, build, type-check, browser/mobile QA or database migrations were run/applied.


## Admin Matrix commission global summary — 2026-11-19

- Added Admin-only `admin_get_matrix_commission_summary()` returning all-time count and amount totals for pending, credited, reversed and all Matrix commissions. The RPC is independent of the report's current page, status/level filters and client-side search.
- Admin Matrix Commission Register now displays these global totals, with separate amounts, and clearly labels the current filtered-page subtotal separately.
- Added contract coverage to `tests/admin-matrix-commissions-ui.test.ts`.
- Commits: SQL `1e2765350b77bbdc2821c0a94acd2f516cafc30e`; Admin UI `2d4d75cc0bd1ce3f8b256a0c4e55411708ab9349`; test `8010e4dbc57fffd7f2017ddc90d833b0729402c4`.
- Source-only change. No tests/build/type-check/browser/mobile QA run; no TEST or Production migration applied. Matrix commission feature remains OFF.


## Member Matrix commission history pagination — 2026-11-19

- Member Account > Commission History now loads Matrix commission records in 100-row pages instead of stopping permanently at the first 100.
- Added guarded Load more control, current-record offset, runtime validation of every row, and duplicate-ID overlap detection before appending.
- Initial load sets the has-more state when a full page is returned; empty/short next pages stop pagination. Existing Sponsor commission pagination remains separate.
- Updated `tests/member-matrix-commission-history.test.ts` with pagination contracts.
- Commits: Account UI `78ea081e6145c06eae9c21c8c3e5ce5bf0b12df7`; test `be486979909cf6d7635b93c9c0025fd27b414ccd`.
- Source-only changes. No tests/build/type-check/browser/mobile QA run; no TEST or Production migration applied.


## Matrix upline traversal correction — 2026-11-19

- Corrected the recursive Under ID traversal in `20261119310000_matrix_commission_engine.sql`: each recursive step now selects the immediate parent node itself, rather than that parent's parent. This prevents intermediate Matrix levels from being skipped.
- Added a SQL contract test that asserts immediate-parent progression and guards against the old skipped-level expression.
- Commits: migration `b2c2a4a23eb9665d5706f2812c6e5ef5ce2279dd`; test `7ddea354897e0033c71d8f21ab54a2f329af9084`.
- Source-only correction. No tests/build/type-check/browser/mobile QA run; no TEST or Production migration applied.


## Admin Matrix report request lifecycle — 2026-11-19

- Reworked the Admin Matrix commission register so changing status/level filters always starts a fresh first-page request, stale in-flight responses are ignored, and refresh reloads both report and global summary.
- Load-more now has a synchronous in-flight guard and refuses results from an obsolete filter request; overlap checks remain in place.
- Added source-level regression assertions for filter/refresh request lifecycle and load-more concurrency.
- Commits: UI `f700d99528cf70374bd20d6869d60881c3736388`; test `bb0014685b74a4fa94d9c96d485637812688c824`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migration applied.


## Wallet CSV Matrix attribution correction — 2026-11-19

- Fixed the full wallet statement export query to select `reference_type` and `reference_id`, matching the on-screen query. Matrix commission transactions can now be resolved through the caller-scoped source attribution RPC and exported with source ID, source type and Matrix level.
- Added a regression contract for the full-export query and attribution path.
- Commits: UI `b1ab1516a7433bcd8b79d71f4c28c00912dc3ed9`; test `a2eb416e25e074c61d41b0a0dff5987f3b6890c6`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.


## Member Matrix history pagination concurrency — 2026-11-19

- Added a synchronous ref-based guard to prevent rapid repeated Load More clicks from issuing duplicate page requests.
- Pagination now captures the current account load generation and linked Main ID; responses from a prior reload or unmounted account view are ignored.
- Added regression contracts for duplicate-click serialization and stale-response suppression.
- Commits: UI `574f21aa83b301953ceba62354b1ad9a2636a221`; test `2f01743305c5b57700a0cb0c6642749cb2776ef1`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.


## Matrix pagination stale-cleanup race guard — 2026-11-19

- Tightened the previous pagination guard: a stale request's `finally` block may no longer clear the synchronous in-flight flag belonging to a newer account-load generation.
- Removed an unused captured profile value; the current load-generation guard remains the authority for response acceptance.
- Commit: `f06f0bc3faa99fd03cae5ff109e224e348e77f4f`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.


## Migration baseline schema audit — 2026-11-19

- Identified a checked-in bootstrap mismatch: `0001_biddworld.sql` / `0002_place_bid_rpc.sql` define/use legacy user-scoped columns, while later migrations and current code assume owner/member-scoped columns and newer activation fields. `001_initial_schema.sql` is empty.
- No proof was obtained about the live TEST or Production schema; neither was queried. No speculative migration was authored.
- Full findings and safe resolution requirements: `docs/SCHEMA_BASELINE_AUDIT.md`.
- Commit: `a76de56db1183a54ade8525a4278bd9be0450e69`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.


## TEST migration baseline verification — 2026-11-19

- Corrected the earlier source-only baseline warning using read-only TEST evidence: TEST uses `biddworld_clean_install_schema_baseline`, has 89 applied migration entries, and the core member/activation/wallet/audit columns match the current schema model.
- TEST's latest applied source migration is `20261119170000_admin_open_ended_auction_status`. The 14 subsequent branch migrations from `20261119180000` through `20261119320000` remain unapplied there; Matrix plan/commission tables are consequently not yet present.
- Updated `docs/SCHEMA_BASELINE_AUDIT.md` to supersede the initial legacy-baseline concern. No database writes or migrations were performed; Production was not queried.
- Audit correction commit: `177916ef85ec82488dcdd6029c1b77d67e1bcfd3`.
- No tests/build/type-check/browser/mobile QA run.


## Automatic Duplicate Placement SQL syntax correction — 2026-11-19

- Removed 91 orphaned duplicated SQL lines after the complete `admin_create_duplicate_member_id(text)` function and its authenticated-only EXECUTE grant. The original migration contained repeated trailing fragments that would cause SQL parsing failure.
- Added a source-contract assertion that the migration has exactly one function definition, ends at its intended grant, and contains no orphaned closing/ORDER BY fragments.
- Commits: SQL `f21762b707337b4dec2f8e95eeb3a2676b54e02d`; regression contract `ff1d50c12e0be9963c43688a0f18e4319d3d2064`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.


## Wallet history stale Matrix-attribution request guard — 2026-11-19

- Fixed a request-lifecycle race in `WalletHistory.tsx`: when a page request becomes obsolete while the Matrix source-attribution RPC is pending (for example after refresh, page change, auth scope change, or unmount), it now exits before mutating source metadata, cursor, or transaction rows.
- Added a regression source-contract assertion for the post-await active guard.
- Commits: component `691ff9febaedda0284d868930af603fc2802f7a6`; test `190ed8a7e82063db9d654c43fee44f8101be4b5f`.
- No tests/build/type-check/browser/mobile QA run; no TEST/Production migrations or data writes.


## Member Sponsor ID / Under ID UI separation — 2026-11-19

- Confirmed the Sponsor genealogy view is based on the Sponsor referral relationship, while the separate Placement Tree uses the placement parent graph and includes Main and Duplicate ID nodes. Matrix history is labelled Under ID Chain.
- Improved Member Account summary and read-only Profile to show the Main ID's Under ID / Placement Parent separately from Sponsor Member ID. Root Main IDs are labelled `Root placement`; linked Duplicate IDs continue to show their own Under ID in Member IDs.
- Added UI contract coverage for Sponsor/Under ID separation and Matrix chain labelling.
- Commits: Account UI `d346f5153c6069e746dfa61d013359f284da6a21`; regression contract `26cf98006bd828a8b0a497759b697e0d2c91893d`.
- No tests/build/type-check/browser/mobile QA run; no TEST/Production migrations or data writes.


## 2026-11-19 — Member Sponsor / Under ID clarity

- Added a separate read-only Main ID Under ID / placement-parent field to the Member Account dashboard and profile; Sponsor Member ID remains independently displayed.
- Reconfirmed Sponsor identity is derived from the referral relationship while Under ID is derived from the placement-parent relationship. Sponsor genealogy and Placement Tree remain distinct.
- Added source-contract coverage in `tests/member-sponsor-under-id-separation.test.ts`; authored but not executed under the final-testing gate.
- Commits: Account UI `324c34572a43064aee56c64796648e08d5c65049`; contract test `92d011b138f247d19012c77f226f660df7587394`.
- No tests/build/type-check/browser/mobile QA, Supabase migrations/writes, Production access, deployment or protected `main` changes.


## 2026-11-19 — Placement Tree Under ID labels

- Extended the authenticated Placement Tree RPC response with each node's actual `placement_parent_code`; Member UI now displays **Under ID** and uses **Root placement** for the Main ID root.
- Registered source migration `20261119330000_member_placement_tree_parent_labels.sql` in the clean-install forward list and added source-contract coverage to `tests/member-placement-tree-duplicate-ids.test.ts`.
- Commits: migration `57a79146c8b6b1e74ee23be540a9101223fe6b8a`; UI `6aba7b418763b88735f100794314a6d94b342487`; manifest `d9045fb35c86f65a81e42a38c7b08f943cb5d4e0`; test `28d134838f5e559fe48dc440fc0ffe95f82a114c`.
- Test source was authored but not executed. No migrations applied, no database writes, Production access, deployment or protected `main` changes.


## 2026-11-19 — Admin Member / Placement relationship clarity

- Admin Member Details separately display Sponsor Main ID, Main ID Under ID / Placement Parent and Main ID Matrix Position.
- Admin Placement Hierarchy now labels each node's Under ID, position and Duplicate ID owner Main ID; linked Duplicate ID rows expose Under ID and position too.
- Added source-contract checks in `tests/admin-member-detail-search-selection.test.ts`; authored, not executed.
- Commits: Admin UI `d39fd2d646ddc3e737f7f093a723fb7597866160`; regression contract `fee444afb8becfabcdc165729a3883d91ab010f8`.
- No tests/build/type-check/browser/mobile QA, migrations, DB writes, Production access, deployment or protected `main` changes.


## 2026-11-19 — Duplicate placement ownership alignment

- Fixed automatic Duplicate-ID BFS slot selection so it skips the owner's own Main ID and owner-linked Duplicate IDs as placement parents. Only active parent IDs belonging to another member are eligible, aligning auto-placement with the existing approval guard while retaining traversal within the owner's Main-ID placement tree.
- Added migration `20261119340000_exclude_owner_ids_from_duplicate_placement.sql`, forward-migration manifest entry, and source-contract regression test `tests/automatic-duplicate-placement-owner-guard.test.ts`.
- Commits: migration `9199443`; regression contract `e12ab87`; manifest `2faed2d`.
- Source-only change; no tests/build/type-check/browser/mobile QA, migration application, DB writes, Production access, deployment or protected `main` changes.

## 2026-11-19 — Duplicate ID feature-toggle concurrency guard

- Fixed a race between Admin disabling Duplicate IDs and a concurrent creation request. The Admin setting RPC and database insert trigger now serialize on the same transaction-scoped graph lock as automatic placement; a create already holding the lock finishes before OFF commits, while a create that follows OFF observes the disabled setting.
- Existing Duplicate IDs, statuses, placement records and history are not modified by the toggle. The change only coordinates new creation with the OFF/ON setting.
- Added migration `20261119350000_serialize_duplicate_id_feature_toggle.sql`, registered it in the clean-install forward manifest, and added `tests/duplicate-id-feature-toggle-serialization.test.ts`.
- Commits: migration `02e193dfbd6ed83ffeb9cfacc00ef6561f9fdad3`; test `4ab3dce842ad1796baac0cd975dbcb2268e4d32d`; manifest `bd5ab33d0feca4b9df0c31dea907fe800ff79654`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST or Production migrations or data writes, deployment or protected `main` changes occurred.

## 2026-11-19 — Duplicate ID insert-trigger OLD-record safety

- Reworked the Duplicate-ID creation trigger to branch explicitly on `TG_OP` before accessing `OLD`. This avoids relying on boolean short-circuit evaluation for an unassigned trigger record during INSERT.
- New Duplicate-ID INSERTs and ID-type transitions into `duplicate` retain the shared graph lock and fail-closed `duplicate_ids_enabled` check. Existing Duplicate IDs and unrelated updates are unaffected.
- Added migration `20261119360000_fix_duplicate_toggle_trigger_insert_record.sql`, regression source contract `tests/duplicate-id-toggle-trigger-old-record.test.ts`, and forward-migration manifest entry.
- Commits: migration `d936ad3eb1224f1ab6bdf10f3519b1e06e223c53`; test `b5c9a4b0daa69a17f7c23532a47e850027fc6a3a`; manifest `01376a49c7a3e040ca059f797a0c792ead512536`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production migrations or data writes, deployment or protected `main` changes occurred.

## 2026-11-19 — Main-ID reactivation reconciliation retry

- Fixed a lifecycle dead-end where a linked Duplicate ID remained suspended because its placement parent was inactive during Main-ID reactivation; a subsequent retry previously short-circuited because the Main ID was already active.
- Repeated Main activation now retries reconciliation. It restores only Duplicate IDs suspended by Main-ID management whose placement parent is active and belongs to another member. Children whose parent remains inactive stay suspended/managed, and closed Main IDs cannot be reopened. Actual child changes are audited.
- Added migration `20261119370000_retry_main_activation_duplicate_reconciliation.sql`, regression contract `tests/main-activation-duplicate-reconciliation-retry.test.ts`, and clean-install forward manifest registration.
- Commits: migration `9ba91dad07c9721b98c4a26b2667f65976986ceb`; test `032888cfb5145f8582c8887e70986bcaf889b8eb`; manifest `cb26307be9dddf8d0ce2791b2e20d9abcad5ad58`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production migrations or data writes, deployment or protected `main` changes occurred.

## 2026-11-19 — Main-ID closure consistency

- Main-ID closure now closes all linked Duplicate IDs that are not already closed, including manually suspended IDs. This prevents a manually suspended Duplicate ID from remaining in a non-closed state after its owner Main ID is permanently closed.
- Existing closed IDs and their history are preserved; all transitioned children are marked Main-managed and included in the existing audit/count response. Main-ID closure remains irreversible.
- Added migration `20261119380000_close_all_linked_duplicate_ids.sql`, regression contract `tests/main-close-linked-duplicate-ids.test.ts`, and forward migration manifest registration.
- Commits: migration `4aed942a9a09ee7d0936d02e86c0e108f931c928`; test `12587e9ed218ccbfb6f26efa2652442245ce9c1f`; manifest `c1cd577162ad6948300bbe2ae502cae1e8a3a918`.
- No tests/build/type-check/browser/mobile QA were run. No TEST/Production migrations or data writes, deployment or protected `main` changes occurred.

## 2026-11-19 — Admin lifecycle guidance alignment

- Corrected stale Admin help text so it accurately describes Main-ID suspension, permanent closure of all non-closed linked Duplicate IDs, and conditional reactivation of Main-managed children based on placement-parent status.
- Extended the existing Admin member detail source-contract test. It was authored but not run.
- Commits: UI `2003879540dc9cec4686282895c6eaecf508ec68`; contract `cee39c50919f785276d5d806a98a7b5f163c5887`.
- No database migrations/writes, tests/build/type-check/browser/mobile QA, deployment or protected `main` changes occurred.
## 2026-11-19 — Bulk source reconciliation checkpoint

- Reviewed current Main/Duplicate lifecycle, duplicate feature-switch serialization, automatic Matrix placement, Matrix commission source/credit attribution, Sponsor-vs-Under ID separation, member placement tree, Admin hierarchy, Wallet Funding/History, Account, Referrals, Packages, Auction, Fixed Bid, Notifications, Support and Admin report integrations.
- Reconciled the clean-install manifests against the complete repository tree: 123 timestamped migration files are accounted for exactly once as 107 ordered forward candidates and 16 excluded historical migrations. No timestamped migration is missing, stale or duplicated.
- Updated the clean-install README's current migration inventory and added `docs/BULK_SOURCE_RECONCILIATION_2026-11-19.md`.
- Existing placement logic counts all child records—including pending, suspended and closed IDs—as occupying their historical Matrix slot. No slot-reuse change was guessed or introduced because silently reassigning a historical position would alter tree semantics.
- Admin lifecycle guidance and its source-contract test were also aligned in this batch (UI commit `2003879540dc9cec4686282895c6eaecf508ec68`; test commit `cee39c50919f785276d5d806a98a7b5f163c5887`).
- Inventory/doc commits: README `8aefc974fe5ba3b58434f88e96f81f10b7405e72`; reconciliation note `78f85da0f387ae89c5b25a90a0ca96edd577383d`; current status `status update follows`.
- No tests/build/type-check/browser/mobile QA were run. No TEST/Production migrations or data writes, Production reads, deployment or protected `main` changes occurred.
- Overall development completion remains **69% provisional** pending development completion and final integrated verification.

## 2026-11-19 — Admin Main Wallet funding queue pagination

- Replaced the Admin UI's unbounded pending Main Wallet funding request fetch with a server-side keyset page RPC using stable ascending `(created_at,id)` order. The UI requests 50 rows; the RPC enforces a maximum page size of 100 and validates that cursor timestamp/ID are supplied together.
- The response includes bounded items, `has_more`, and a continuation cursor. The UI rejects malformed rows and duplicate IDs before appending, uses request-generation guards, and creates short-lived private receipt URLs only for the current page.
- Preserved Admin and `wallet_funding_review` Staff authorization, private receipt access, existing locked approval/rejection RPC, audit trail and atomic wallet ledger posting. The legacy no-argument queue RPC is also capped at 100 rows while retaining its array response shape for older callers.
- Added migration `20261119390000_admin_wallet_funding_queue_keyset_pagination.sql`, updated `src/components/AdminWalletFundingReview.tsx`, added source-contract coverage in `tests/admin-wallet-funding-keyset-pagination.test.ts`, and registered the migration in the clean-install manifest.
- Commits: migration `47bad872baa8161baab4d0bbde04d8f1af510d04` (bounded legacy RPC follow-up `3532bb20c3e67330308dee83f684e2e430b8b8e8`); UI `fc803d60bfebeca0dce3f8e9c11e0f7417045df1`; test `2b7907ae310afb1adb8ff392a49b9dc5d27a753e`; manifest `1707134b46d7391e95507da8362d9068fceb5997`; clean-install README `69c85d4787a63196ca63d6b8458276d2aaf8d6ab`.
- Migration inventory now reconciles exactly: 124 timestamped files = 108 forward candidates + 16 excluded historical migrations; no missing, stale or duplicate timestamped entries.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database migrations or data writes, Production reads, deployment or protected `main` changes occurred.
- Overall development completion: **70% provisional**.

## 2026-11-19 — Admin pending package activation queue pagination

- Replaced the unbounded Admin pending package activation queue fetch with a new Admin-only keyset RPC. The page size is 50 in the UI and capped at 100 in SQL; stable descending `(submitted_at,id)` cursor pagination uses a look-ahead row and returns a continuation cursor.
- The RPC preserves the pending-only filters, member/package details and private `receipt_path` field. Existing short-lived signed receipt links and the existing locked package-approval/rejection RPC remain unchanged.
- Admin UI validates the page envelope, row identities and timestamps, paired continuation cursor and duplicate IDs before appending. Refresh generations suppress stale page responses.
- Added migration `20261119410000_admin_pending_activation_keyset_pagination.sql`, registered it in the clean-install forward manifest, and added source-contract coverage in `tests/admin-package-activation-keyset-pagination.test.ts`.
- Commits: Admin UI `81ae6d56f875e07c4a6ac2df4de39f6745842508`; migration `d2310039b33962feef9217efc125d75417326db6`; test source `dc43fda6db451b6b9f5af0a90a51d42c9ace77b8`; manifest `222de399808adfaa0529dd6751f325543050150a`.
- Source-only batch. Tests/build/type-check/browser/mobile QA were not run. The migration has **not** been applied to TEST; Production was not accessed or modified. Preview was not updated because its TEST backend must receive the approved migration before this RPC-based UI can be published.
- Overall development completion remains **71% provisional** pending broader development and final integrated verification.

## 2026-11-19 — Admin referral commission register pagination hardening

- Added strict validation for commission page arrays, unique commission IDs, activation/beneficiary/credited Main ID fields, beneficiary ID type, positive finite amount, status, timestamp and consistent per-page `has_more` metadata.
- Added a single-flight guard and request-generation invalidation for Load More so a page requested before an Admin refresh cannot append stale rows afterward. A page overlapping already-loaded commission IDs now fails closed with a refresh message.
- Isolated malformed commission responses from the main Admin workspace loader so a bad commission payload does not prevent unrelated Admin modules from rendering. Invalid commission data clears only the affected register and reports a local error.
- Existing referral commission list, posting and reversal RPCs are unchanged. Offset pagination remains in place; this batch hardens client-side request/response handling and does not claim snapshot-stable keyset pagination.
- Added source-contract coverage in `tests/admin-referral-commission-pagination.test.ts`.
- Commits: UI validation/guard `0c0cb3d85892adf4ad18bdb573de6ae5a0911541`; test `483b7fb76f6c303a8c0370da6ade1b13d852b1b4`; Admin loader isolation `df4f7673faa3f22b9386220aff9215dd80e6e704`.
- Tests/build/type-check/browser/mobile QA were not run. No database migration was needed or applied; no TEST or Production database access/write, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional** pending broader development and integrated verification.


## 2026-11-19 — Admin withdrawal queue pagination hardening

- Added initial-page validation for unique request IDs, required member codes and positive finite amounts; malformed queue data fails closed.
- Added a single-flight Load More guard, refresh-generation invalidation, page-envelope validation and repeated-page detection. Stale async responses cannot append after an Admin workspace refresh.
- Existing withdrawal review/reservation/release actions and complete paginated CSV export are unchanged. Pagination remains offset-based; no keyset migration was introduced.
- Added `tests/admin-withdrawal-pagination-hardening.test.ts`.
- Commits: Admin UI `944a754b61c09c79ec5f3b5be9cd47a0ca64ba80`; regression test `960c3882b3d0d511acba19a64157df749b86064f`.
- Tests/build/type-check/browser/mobile QA were not run. No database migrations/writes, TEST or Production access, Preview deployment or protected `main` changes occurred.


## Latest bulk checkpoint — Admin operational registers pagination

- Added complete Load 100 more pagination to the Admin Winning Payment register and Delivery Tracking register; both now validate initial and subsequent pages, reject malformed/duplicate identities, serialize requests, suppress stale responses after refresh, and detect repeated pages.
- Added pagination to Wallet Accounts (previously only the latest 100 were visible), with identity/balance validation, single-flight loading, refresh-generation protection and repeated-page detection. Existing wallet ledger pagination and full paginated CSV export remain intact.
- Preserved existing delivery create/edit flow, winning payment read-only behavior, and wallet adjustment workflow. No new database RPC or migration was needed; existing list RPCs are reused.
- Regression source contracts: `tests/admin-winning-delivery-pagination.test.ts`, `tests/admin-wallet-account-pagination.test.ts`.
- Commits: Admin winning/delivery UI `e23b6a62dfb4bc9f5b3898c4702a370b2b39d6bb`; winning/delivery tests `16ee5ebf6e7f99e9d8dcf75ec0d72e8f66f7aa46`; wallet account UI `7ffdaff7012bb342be34eb2f5c171d39ad26ce62`; wallet tests `c368b74e4fe1b16e0b690d52558e45a9441536d9`.
- Tests/build/type-check/browser/mobile QA were not run. No DB migrations/writes, TEST or Production access, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional** pending remaining modules and final integrated verification.


## Latest bulk checkpoint — Audit log, wallet ledger and report export integrity

- Hardened Audit Log initial and Load More pages with unique record IDs, valid timestamps, response-envelope checks, single-flight protection, refresh-generation invalidation, stale-response suppression and repeated-page detection.
- Hardened Wallet Ledger initial and Load More pages with unique transaction IDs, positive finite amounts, response-envelope checks, single-flight protection, refresh-generation invalidation, stale-response suppression and repeated-page detection. Existing complete ledger CSV export remains available.
- Hardened the shared paginated CSV export engine used by multiple Admin reports: it now rejects non-array/oversized pages, malformed rows, exact duplicate records across pages, repeated pages and exports exceeding the existing 100,000-row safety ceiling. This protects report completeness and avoids silently duplicated totals.
- Added regression source contracts in `tests/admin-audit-wallet-report-integrity.test.ts`.
- Commits: Admin UI `68e1f8b2c7c5a3c1f56d8698512d1741fa6cc6c8`; regression test `c2eb956bad5e4bbb0e2b889b2151da788dadcd4b`.
- Tests/build/type-check/browser/mobile QA were not run. No DB migrations/writes, TEST or Production access, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional** pending remaining modules and final integrated verification.


## Latest bulk checkpoint — Admin member directory integrity

- Added a shared strict parser for Admin member-directory responses and applied it to initial workspace loading, debounced search, explicit search and Load More. It rejects malformed envelopes, pages over 100 rows, blank/duplicate Main IDs, invalid display names/timestamps and invalid optional phone/sponsor field types.
- Subsequent pages now reject overlap with already-loaded Main IDs instead of silently filtering duplicates, preventing an apparently successful but incomplete directory. Existing search debounce, request-generation guard and pagination UX are retained.
- Added regression source contracts in `tests/admin-member-directory-integrity.test.ts`.
- Commits: Admin UI `4a48732823972946ed8402073d6036bc98e159d2`; regression test `eb6c9f46c971b226804d1e1af345a3696866ca18`.
- Tests/build/type-check/browser/mobile QA were not run. No DB migrations/writes, TEST or Production access, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional** pending remaining modules and final integrated verification.


## 2026-11-19 — Admin Duplicate ID directory integrity

- Added strict validation for the initial and subsequent Duplicate ID directory pages: unique record IDs, supported statuses, timestamps, linked Main ID fields, total counts and consistent `has_more` metadata.
- Load More now rejects overlaps with already-loaded records and stops pagination on malformed responses rather than silently dropping duplicate rows. Existing search, automatic placement, Admin approval/status actions and Duplicate-ID feature switch are unchanged.
- Added source-contract coverage in `tests/admin-duplicate-id-directory-integrity.test.ts`.
- Commits: Admin source `729351bfad962ba09e11296fae4d490a70077820`; contract test `b4c348f96facae029b868903a9396f36eba968c5`; checkpoint `2a2cc30418a3ff3df39fc6b3405de416e2871c57`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database reads or writes, migrations, Preview deployment or protected `main` changes occurred.


## 2026-11-19 — Admin Matrix Plan directory integrity

- Added strict validation for Matrix plan list responses: package ownership, unique plan IDs, positive versions, bounded matrix/placement/commission dimensions, timestamps, complete sequential levels, supported reward types and values, and object-shaped eligibility rules.
- Added request-generation invalidation and stale-response suppression when switching packages, preventing late responses from showing another package's plans.
- Added source-contract coverage in `tests/admin-matrix-plan-directory-integrity.test.ts`.
- Commits: Matrix Plans component `4f82989cce55b824d1be762b34f93c919c0693c0`; contract test `a3b0496266d1edd5a8e325ebb7abeb3883110e7d`; checkpoint `fda900b8e9ae0833f5e697e149cc749b73d37337`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database reads or writes, migrations, Preview deployment or protected `main` changes occurred.


## 2026-11-19 — Admin Package and Sponsor Referral Plan directory integrity

- Added runtime validation for package list responses (unique IDs, required names/currency, description type, non-negative price/credit and publication state).
- Added runtime validation for referral plan list responses (package identity, nullable plan metadata consistency, unique package rows, sequential levels, supported reward types and bounded positive rewards).
- Invalid responses now produce module-specific errors instead of being blindly cast into UI state.
- Added source-contract coverage in `tests/admin-package-referral-directory-integrity.test.ts`.
- Commits: Admin source `7e778c4602163866222fc0fe26b62077a2872395`; contract test `e50e3e11d05fce1646add8d94c62e1d72f338709`; checkpoint `70045f46dde55e347d0d53756651c5b13495a9ec`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database reads or writes, migrations, Preview deployment or protected `main` changes occurred.


## 2026-11-19 — Admin Auction and Fixed Bid directory integrity

- Admin Auction Products, Auctions and Fixed Bid campaign list responses now pass strict runtime parsers before entering UI state. Validation covers bounded arrays, unique IDs, required identifiers/names/statuses, nullable text, auction numeric values and lifecycle dates, Fixed Bid configuration shape, and campaign timestamps.
- A malformed module response clears that module and adds a local warning without blocking unrelated Admin modules. Existing actions and RPC contracts remain unchanged.
- Added `tests/admin-auction-fixed-bid-directory-integrity.test.ts` (authored only; not executed).
- Commits: Admin UI `a01ec4b7d91b18f2c37ec9ee740a5aff880c1f2c`; source-contract test `4d817c3bf007daa8c61478e9700bb0e69d8abc67`; status checkpoint `14b76794eb7f3266ec011c8f1058755deeaca81b`.
- No tests/build/type-check/browser/mobile QA, DB reads/writes, migrations, Preview deployment or protected `main` changes were performed.
- Development completion: **71% provisional**.


## 2026-11-19 — Auction Bid and Fixed Bid Entry report integrity

- Added strict shared-per-component row parsers for the Admin Auction Bid History and Fixed Bid Entry History reports. Each parser validates bounded page size, unique IDs, required auction/campaign/member identity and labels, currency, status, positive amounts, non-negative wallet debit splits, and valid timestamps before rows enter the UI.
- Complete CSV export now uses the same strict parsers as the visible paginated lists, so malformed rows cannot bypass validation during export. Auction bid debit totals are also checked against the recorded bid amount.
- Existing cursor RPCs, search/status/date filters, pagination, CSV columns and idempotency-key privacy remain unchanged.
- Added `tests/admin-financial-activity-report-integrity.test.ts` (source authored only; not executed).
- Commits: Auction Bid report `9c7c39752a929ebac6a391c1f4f4ab6932886bcf`; Fixed Bid Entry report `fe7fcd232df23534faab21860e9394be77c67a69`; regression source `c47c0e61dd7e58b9860d04ba223148f49bd79ced`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database access or writes, migrations, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Main ID status mutation hardening

- Main ID status changes now use a synchronous in-flight ref to prevent duplicate submissions before React state updates, validate the supported status values, and capture the selected member code at submission time.
- The Admin UI now validates the RPC result envelope and the linked Duplicate ID count instead of coercing malformed or missing values to zero. Existing status choices, confirmation, RPC and audit behavior remain unchanged.
- Added source-contract coverage in `tests/admin-main-member-status-mutation-safety.test.ts` (authored only; not executed).
- Commits: Admin source `078db788085696f9b2c9f455ccd90fd75e28c198`; regression source `c035b0458bdd7760bc3c6fef2d9af1068e655409`.
- Tests/build/type-check/browser/mobile QA remain deferred and were not run. No TEST/Production database access or migrations, and no protected `main` changes.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Admin auction finalization and Fixed Bid draw result integrity

- Admin auction finalization now validates the RPC success flag, exact auction identity, winner/bid identity pairing and positive finite winning amount before presenting a completed result. No-winner results must consistently return null winner, bid and amount fields.
- Fixed Bid winner draw now validates the success flag, exact campaign identity, positive integer winner count and non-negative integer refund count. Missing or malformed totals are no longer silently coerced to zero.
- Existing settlement RPCs, winner selection, wallet refund behavior and replay semantics remain unchanged. Added `tests/admin-auction-finalization-draw-result-integrity.test.ts` (source authored only; not executed).
- Commits: Admin source `3aa2f114c2e6e57267f2f629fa202cb240d0a0f3`; regression source `1e313d68648394320f9f1063456427e4606665e2`.
- Tests/build/type-check/browser/mobile QA remain deferred and were not run. No TEST/Production database access or migrations, no Preview deployment, and no protected `main` changes.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Admin Staff JSX preview-build blocker correction

- The Preview workflow exposed a pre-existing JSX syntax defect in `src/components/AdminStaff.tsx`: the conditional rendering expression for Auction Submission Review was missing its closing brace. Corrected the JSX so the Staff page can be parsed by the bundler.
- Added `tests/admin-staff-permission-jsx-contract.test.ts` as source-only regression coverage. It was not executed.
- Commits: Staff component `52722b2601f118da693b2cd8d273c4b90b70919c`; regression source `6d9d325de4299ad0d83b7e9126e3c882b9adb4a7`.
- The previous Preview run `44536912340` failed at Vite transformation due to this syntax error. A new Preview workflow run has been queued for the latest source; deployment outcome remains pending. No TEST/Production database access or migrations and no protected `main` changes.
- Tests/build/type-check/browser/mobile QA remain deferred; the Preview pipeline's required Vite build is used only to publish the preview and is not a separate QA sign-off.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Admin Main Wallet funding page response integrity

- Tightened wallet funding queue row validation: amount must be a positive finite numeric value; currency must be a three-letter uppercase code; receipt path and payment reference must be nonblank.
- Keyset continuation metadata must now match the final returned row exactly; cursors must advance from the previous page; terminal pages must return null cursor fields. Added a synchronous Load More lock to avoid concurrent duplicate page requests.
- Existing approval/rejection RPC, private signed receipt links, review notes, pagination and ledger posting are unchanged. Added `tests/admin-wallet-funding-page-contract.test.ts` as source-only regression coverage (not executed).
- Commits: UI `f5fc6d51bd9abfad6229d173b927ee9e3ff3fd1b`; regression source `c59c674af07ce68d11ebad4df8ba0c5c9e445818`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database access or migrations; no protected main-branch changes. Preview deployment trigger and status are recorded separately.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Admin workspace Preview build syntax correction

- Inspected the failed Preview workflow logs for run `44537705150`: Vite reported an unexpected `catch` at `src/components/Admin.tsx:327`.
- Root cause: the Admin delivery-tracking generation guard was missing its closing brace, leaving the outer workspace `try/catch/finally` structurally unbalanced. Added the missing terminator before wallet-account loading.
- Added `tests/admin-delivery-queue-block-structure.test.ts` as source-only regression coverage. It was not executed.
- Commits: Admin source `df4e7eb459bdd97aa03a97e24011cd14f191b064`; regression source `2a100bfe83712f8cc65dbd82ee5af436dc69522b`.
- No TEST/Production database access or migrations and no protected `main` changes. Preview trigger and deployment result will be tracked separately. Tests/type-check/QA remain deferred; the Preview pipeline's required build is not a QA sign-off.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Admin Matrix commissions Preview syntax correction

- Inspected Preview run `44537970735` logs. The prior Admin delivery guard syntax correction progressed further; the next parser failure was in `src/components/AdminMatrixCommissions.tsx:36`, where a literal escaped newline sequence had been committed into TypeScript source.
- Replaced the literal sequence with a real source line break and added `tests/admin-matrix-commissions-source-integrity.test.ts` as source-only regression coverage. Test was not executed.
- Commits: component `7531e99d5550b515298a2fd87e6f097618556748`; regression source `07b2bc2d69e4a5bb9abd54ff52d338b309f0b7f3`.
- No database access/migrations, no protected `main` changes, and no QA/tests/type-check were run. Preview's required deployment build is tracked separately.
- Overall development completion remains **71% provisional**.


## 2026-11-19 — Member workflow event notifications (feature completion)

- Added source migration `20261119420000_member_workflow_status_notifications.sql` to connect the existing in-app inbox to five member-owned workflow changes: package activation approval/rejection, Duplicate ID status changes, auction submission approval/rejection, withdrawal status changes, and delivery tracking status changes.
- Notifications are generated only when a relevant status actually changes, resolve the recipient from the owning member/auth account, use the existing in-app notification table, and do not introduce email/SMS dependencies or client-callable trigger functions.
- Registered the migration in the clean-install forward manifest and added source-contract coverage in `tests/member-workflow-status-notifications.test.ts` (not executed).
- Commits: migration `e4a48795d1a23dce3f247bc1aff89b4d410ba6c4`; test source `f454b21108c11d3f7d37f3f85e943f28e69bd972`; manifest `19a37d802f3fe382224b56007846b856a56db738`.
- Migration is source-only and has not been applied to TEST or Production. No tests/QA/type-check were run. Preview deploy build will be tracked separately.


## 2026-11-19 — Expanded member lifecycle notification coverage

- Extended the in-app workflow notification migration to cover Main ID status changes and wallet funding approval/rejection, in addition to Duplicate ID, package activation, auction submission, withdrawal and delivery status changes.
- Each event is emitted only for a real status transition and delivered to the account owning the affected Main ID/request. The existing in-app inbox is reused; no paid delivery provider was added.
- Updated source-contract coverage. Test remains unexecuted under the development-first testing gate.
- Commits: migration `5bb7aba954e76b128c84a8440b33908ef8e718d3`; test source `1c710e4918d147ff2a98407a90b8d301b827962b`.
- The migration remains source-only; no TEST/Production migration or data change. No QA/test/type-check run.


## 2026-11-19 — Main ID notification trigger wiring completion

- Completed the Main ID notification path end-to-end: the shared member_ids status trigger now fires for both `main` and `duplicate` ID types. The trigger previously filtered only Duplicate IDs, which meant the Main ID branch in the notification function could never execute.
- Updated the source-contract test to assert both ID types are included in the trigger condition. Test source only; not executed.
- Commits: migration correction `56e2d95f0cb5c7cba4664fdf2cfad6f46c680556`; regression source `6c81f6ac756e9b36c33629c774fcc437b8d76000`.
- Migration remains source-only and is not applied to TEST or Production. No test/QA/type-check executed.


## 2026-11-19 — Live in-app notification delivery

- Member and Admin notification inboxes now subscribe to Supabase Realtime changes for `member_notifications`. Member subscriptions are scoped to the signed-in user's ID; Admin subscriptions rely on the existing database read policy.
- New notices are inserted into the current inbox immediately; read-state updates and deletions are reflected without a manual refresh. Current category/unread filters are respected, malformed events are ignored, and the channel is removed when the view unmounts or its subscription context changes.
- Added source-contract regression coverage for INSERT/UPDATE/DELETE handling and channel cleanup. Test source only; not executed. Live Realtime publication/RLS behavior remains unverified until final QA.
- Commits: UI `94b7afbb3ad5b2ef11df68df8e43658f07ec8890`; regression source `e23dda5aae6d4fc291c082907f1ec2aef58d8ff0`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production database changes; protected `main` unchanged.


## 2026-11-19 — Member auction submission editing and resubmission

- Members can now reopen their own Pending or Rejected auction submissions, edit the listing details/prices/schedule, retain existing images or replace them, and resubmit for Admin review. Approved/published submissions are not editable through this path.
- Added source migration 20261119430000_member_auction_submission_editing.sql: locks the owned row, enforces editable statuses, rechecks active Main ID ownership, validates image objects and expected-price rules, resets review metadata to Pending, and writes an audit event. Registered in the clean-install forward migration manifest; migration is source-only and has not been applied to TEST or Production.
- Added tests/member-auction-submission-editing.test.ts as source-contract coverage; not executed under the development-first testing gate.
- Commits: UI 9877925e96a83564d69ebce7be8b7a0bae927199, follow-up UI 658d955a0315d7d92d33e8eadabdbdd4c7ee0af8, migration 607eecceb05f11bfac3f9fb02f1d2e93261a9fa9, manifest 04f67481ae602ba8c6e61e0da5277e6ee5c6c0d4, UI controls 826332c36b14eff623be56a03b57f02e0386f24f, regression source 1522eb7d6f77dd5a2e45bdfc3e1e7c60fd067935.
- No tests/type-check/browser/mobile QA run; no TEST/Production database access or migrations; protected main unchanged.
- Overall development completion remains 72% provisional.


## 2026-11-19 — Member product submission and Admin moderation

- Added a separate OLX-style member product submission workspace on the public Products tab: title, detailed description, category, brand/model, condition, age/year, location, extra details and 1–8 images (JPG/PNG/WebP, 5 MB each). Members can see their own submission statuses and review notes.
- Added a private product-submission Storage bucket and owner-scoped submission RPCs. Pending images remain private; only an Admin can review. On approval, Admin copies the first image to public product media and the database publishes the product in the existing catalogue. Rejections remain private and are audit-logged.
- Added Admin Product Review queue with signed private image previews, Approve & Publish and Reject actions. Integrated into the Admin workspace.
- Migration: supabase/migrations/20261119440000_member_product_submission_moderation.sql; registered in supabase/clean-install/forward-migrations.txt. Regression source: tests/member-product-submission-moderation.test.ts. UI: src/components/MemberProductSubmission.tsx and src/components/AdminProductSubmissionReview.tsx.
- Key commits: migration e1592c9b03f992e4df81ebc7aab8d38f5198a08f; member UI 4f8259ffcc09fe7dc68dd3464ca47acc5b1343e7; Admin UI b60f81c251905966eb3d76090122de6dbaf7a6ef; App integration 31298afb947876ae708c4da178bb086613bb5ddf; Admin integration 68fd52e6f5e2c2bd970aa07f35496b80a96d3e55; manifest 7b36476f84fac70e71688af540c9de7f09c31294; regression source e85ee5adcc2dcb60bb45d982d80d1d91bf514d3c.
- Migration remains source-only; not applied to TEST or Production. No tests/type-check/browser/mobile QA run. Protected main unchanged.
- Overall development completion remains **74% provisional**.


## 2026-11-19 — Member product submission editing and resubmission

- Added a member edit/resubmit workflow for own Pending or Rejected product submissions. The form restores saved fields and optional details, supports retaining existing images or uploading replacements, and returns a corrected listing to Pending Admin review.
- Added `supabase/migrations/20261119450000_member_product_submission_editing.sql` with owner-scoped row locking, editable-state enforcement, active Main ID revalidation, private image path ownership checks, review-state reset and audit logging. Added to the clean-install forward manifest.
- Added `tests/member-product-submission-editing.test.ts` as source-only regression coverage; not executed.
- Commits: migration `88b28f955eb3021f339f72c8a1a36671518fec47`; cleanup `528ee6a863dcb4a02595c280dd275316eb29a48a`; UI `dd0448a0213eb6bf1f124d17be29c241cca13b53`; manifest `700343a79339b0293db5bc024451f65f26d28630`; test `2377b59610ff1ec85409c760b27d67dd10bc5240`.
- No migrations applied to TEST or Production. No tests/build/type-check/browser/mobile QA run. Protected `main` unchanged. Development completion: **75% provisional**.


## 2026-11-19 — Product catalogue error-state integrity

- Corrected the public Products view so sample cards are used only when Supabase is intentionally unconfigured. A configured catalogue error or genuinely empty catalogue is no longer disguised as sample inventory.
- Preserved the existing retry action, published-product pagination, and independent signed-in Member Product Submission workflow.
- Added source-contract coverage in `tests/public-product-catalogue-fallback.test.ts`; test execution remains deferred to the consolidated testing phase.
- Commits: UI `5ad1512ee89bca6c04f8a714f6334179f6aba018`; test source `c131f582f0ce41188709ecbc524124c6756a1794`.
- No tests/build/type-check, database reads/writes, migrations, Preview deployment, or protected `main` changes were performed.


## 2026-11-19 — Product listing completeness and Matrix Admin actions

- Completed member product listing fields with a required validated asking price and explicit Warranty and Ownership fields, while retaining Brand, Model, Condition, Year/Age, Location and free-form details. Values are stored in the existing optional-details JSON contract; no schema change required.
- Fixed edit/resubmission browser validation: image replacement is optional when editing because existing private images are retained if no new files are selected. New submissions still require at least one image.
- Corrected package page messaging so activation availability and card guidance reflect the connected environment's actual activation setting rather than always claiming activation is unavailable.
- Added Admin Matrix commission actions: post pending commissions for the activation through the server RPC, and reverse an individual credited commission with a required reason and explicit confirmation. Server-side idempotency, eligibility and ledger checks remain authoritative.
- Added/extended source-contract coverage: `tests/member-product-submission-editing.test.ts` and `tests/admin-matrix-commission-actions.test.ts`. Tests/build/type-check were not run, per development-only phase.
- Commits: member listing UI `cefbee175e59c5e5ac8b6cfc7e378753b0ad0621`; member edit regression `1dd778b613cef2c30da1a68e9eaf092619c140f5`; package UI `24b873cbbe505b43fbfe550c09ce90655b8905e5`; Matrix Admin UI `ae8257631cda4fafa65bc102919dbd5e99da6acf`; Matrix action regression `af39709a99aa91e0037a9b9964284d6b19c8ce0b`.
- All changes are confined to `completion-work`. No SQL migrations were applied, no Supabase database was modified, no Preview deployment or runtime testing was performed, and `main` remains untouched.
- Development progress: source implementation advanced; overall percentage remains provisional until consolidated build/test/reconciliation and browser verification.


## 2026-11-19 — Persist complete approved product catalogue details

- Added forward migration `20261119460000_product_catalogue_details.sql`: published products now retain the member submission's full optional-details JSON, including validated asking price, Brand, Model, Condition, Year/Age, Warranty, Ownership, Location and Features.
- Added a database trigger enforcing a positive, bounded asking price for every new or edited product submission, independent of client-side validation.
- Updated Admin approval to copy the full submission details into the published product record. Updated the public product pagination RPC to return details only for published records.
- Updated the public catalogue cards to display the asking price and available attributes, and included those attributes in catalogue search.
- Added regression source `tests/product-catalogue-details.test.ts` and registered the migration in the ordered clean-install forward manifest.
- Commits: catalogue UI `acc9cafc1efde10fad003379192acb817f3e0a9b`; migration `a2e41f1f4320ff3217d8b5b44ac74c498e454d82`; test `77eb7fd0cbb56cefc554819023c0868be74bbef5`; search UI `291465a826b8fdf6ec9d8ec96d9b464c86480f5e`; manifest `d75d3e4662542e3f014331a83e07a8d4ecb29c5c`; manifest regression `4320e6dd2b3d5d25398908d1c2d038ddf421b086`.
- Source-only work on `completion-work`. No tests/build/type-check, migration execution, Supabase changes, Preview deployment or runtime QA performed. Protected `main` untouched.


## 2026-11-19 — Current source inventory and development checkpoint refresh

- Reconciled the current forward manifest after adding the approved product-detail migration: 115 unique, strictly ordered forward candidates + 16 unique excluded historical timestamped migrations = 131 timestamped migration files. No overlap or duplicate forward path was found. Three legacy/unversioned SQL files remain outside this candidate chain.
- Updated the clean-install README and current PROJECT_STATUS development/pending sections to remove stale 87/103 and 110/126 inventory counts. Historical checkpoint notes remain intact as dated history.
- Product-detail migration trigger additionally requires all optional-detail JSON values to be plain text, keeping the public catalogue's typed rendering contract safe. Regression source extended accordingly.
- Follow-up commits: migration hardening `49a9b14738447a56201a096ea928de78588868a9`; regression update `f12b149facdfbd173c1c232bbb5fae578a5a213f`.
- No tests/build/type-check, database migration, Supabase write, Preview deployment or runtime QA performed. All changes remain on `completion-work`; protected `main` unchanged.


## Latest development checkpoint — 2026-11-19 (source-only bulk continuation)

- Re-read the current branch source and historical checkpoints rather than assuming the supplied master prompt was the latest state. Continued from the actual `completion-work` contents.
- Completed the product submission edit validation correction, explicit price/warranty/ownership fields, accurate package activation UI state, Admin Matrix commission posting/reversal controls, full approved product detail persistence/public display/search, and migration inventory/documentation refresh.
- Current source inventory: 115 forward + 16 excluded = 131 timestamped migration files, plus 3 legacy SQL files. The forward manifest is unique, non-overlapping with the excluded list and strictly sorted.
- Latest documentation commits: `PROJECT_STATUS.md` `7581520c14f759df2ae1ceac0ef7287af5ffcb23`; clean-install README `1abdae80656bbb2bed654b66b38fec012f883774`; completion register `25b0ed3e70dee71295018418d122125f1decd4fe`.
- Development-only boundary maintained: no tests, build, type-check, database reads/writes, migration replay, Preview publish, runtime QA or Production deployment. Protected `main` unchanged.
- Overall source development estimate: **78% provisional**. This is not a runtime or release-completion claim; canonical baseline/RPC dependency review and remaining source integration work are still open.


## 2026-11-19 — Admin product moderation queue pagination and catalogue SQL hardening

- Added a server-side Admin-only keyset pagination RPC for pending product submissions. It validates page size and paired cursor fields, orders by `created_at,id`, and returns an explicit `has_more` marker.
- Updated the Admin Product Review interface to load 50 submissions at a time, append further pages without discarding previously signed private-image URLs, and refresh the queue after review actions.
- Added strict response-shape/date/image validation and duplicate/overlap detection before displaying a moderation page.
- Corrected the approved product-detail migration's SQL regular expressions to use explicit character classes for decimal points and image extensions; extended catalogue search to include persisted product attributes as well as name/category/description.
- Added regression source `tests/admin-product-submission-pagination.test.ts`; extended `tests/product-catalogue-details.test.ts`. No tests or builds were executed in this development-only batch.
- Commits: SQL hardening `f0c47da6645795fa3f657fb6aff9374b785897ec`; catalogue regression `9d1334088f42469bf8408766ee30072e00a93712`; moderation UI `b3e9b298ed76ceee4f09a423a3526a3a972384e3`; pagination migration `19c508a3e94cda9c7b47ea368251abc8c29cf0c1`; pagination tests `b00b88496a2f344710208f9cfb9823b49a3b61fe`; forward manifest `50800ef11a558a6b36a2f6246c3a2b4722a04bd8`; UI validation `c21841e99bc4e5ce5233da91dcf6eb92fda2ff5b`; validation test `30952fcab947d364c72f8d822c6be6c1037dc6bb`.
- Source-only on `completion-work`; no TEST/Production database changes, migration execution, Preview deployment, runtime QA or protected `main` changes.
- Source development estimate: **80% provisional**; full baseline/RPC/security dependency reconciliation and remaining feature integration remain open.


## 2026-11-19 — Product image gallery and final catalogue migration repair

- Rebuilt `20261119460000_product_catalogue_details.sql` as one clean, non-duplicated migration after source inspection exposed malformed repeated SQL blocks. The current migration has one validation trigger, one compatible Admin review RPC and one public catalogue RPC; its price/image regexes are valid and catalogue search includes approved detail JSON.
- Added explicit column-level SELECT grants for the published product details and gallery fields to the public catalogue reader roles; existing row-level policies still govern which product rows are visible.
- Added `20261119480000_product_gallery_publication.sql`: preserves legacy `image_path`, backfills the new `image_paths` array, validates 1–8 unique public image objects server-side, and publishes all approved member images in the product record.
- Admin review now copies every submitted image into the public product-media bucket, removes all newly uploaded objects if approval fails, and invokes the dedicated array-based server RPC. Public product cards now show a swipeable gallery with per-image alternative text.
- Added regression source `tests/product-gallery-publication.test.ts`; repaired and expanded `tests/product-catalogue-details.test.ts`. Test/build/type-check were not executed.
- Commits: clean migration rebuild `614998349d28a551c35893df723030c45714acb9`; moderation gallery UI `06a616b7faa37d5976870fa274fc224e5cc45510`; catalogue gallery UI `e34699a921671fb5b2803f5f98698baa21b101e3`; gallery styles `cd2cccd99a09d65b1635364e5160e7a716507691`; gallery migration `baee70cc6a9ad84a25b4012e419ffa647ac83324`; distinct path validation `38e23e8201c1fab198c6ba1740f5d794abd027e9`; gallery regression `6e46d4fcbcc799e2beb7516b5fff8c19dc127a29`.
- Latest column grants: details `8a20ff020254b2452d5b571e3af4e8510680caa4`; gallery `c9e25e9a2a11ae77943e63979532181c698d272e`. Clean-install inventory refresh: `b24747f67d1998d153ef12d5d36a6564f90984d0`.
- Source inventory: 117 forward + 16 excluded = 133 timestamped migration files, plus 3 legacy/unversioned SQL files. Forward manifest remains unique and sorted.
- All changes remain on `completion-work`. No migrations applied, no TEST/Production database writes, no Preview publish/runtime QA, and protected `main` untouched.
- Source development estimate: **82% provisional**; remaining baseline/RPC/security dependency reconciliation and feature integration are still open.


## 2026-11-19 — Complete member product image lifecycle

- Member Product Submission history now generates short-lived private signed image previews, displays all images beside each submission, and shows the existing gallery while editing so members can confirm the images retained by resubmission.
- Admin moderation now copies all 1–8 submitted private images into the public media bucket and submits the full image-path array through a dedicated Admin-only RPC. Failed approval attempts clean up every public image uploaded during that attempt.
- Added a persistent `products.image_paths` gallery while preserving/backfilling legacy `image_path`; public catalogue pagination returns both, and product cards provide a mobile swipeable gallery with descriptive image alt text.
- Rebuilt the product-detail SQL migration into a single valid definition after source review identified duplicated/malformed SQL; both moderation RPCs now explicitly reject null decisions. Added explicit column SELECT grants for the two new published catalogue fields, still subject to existing row policies.
- Added `tests/product-gallery-publication.test.ts` and `tests/member-product-submission-image-preview.test.ts`; extended catalogue-detail regression checks. Tests/build/type-check remain intentionally unrun.
- Latest member preview commit `8ad4b7b9221bb3212e3874f5a3721dba93d01523`; null-decision SQL guards `372d936348234d9dc36346460ead2804dfdd5c11` and `58123f63e1427d648402731d76c45ad046e28125`; regression updates `6df37ecfe9e68d3a20a9feecec604cf1d505c2ea` and `10a9d768a0e7e69b2197c35677ae425ed080bd9e`.
- Inventory currently: 117 forward + 16 excluded = 133 timestamped migration files, plus 3 legacy/unversioned SQL files. Forward manifest is unique and sorted.
- All work remains on `completion-work`; no migration was applied, no TEST/Production database was changed, no Preview deployment/runtime QA was run, and protected `main` remains untouched.
- Source development estimate: **84% provisional**; full database baseline/RPC dependency reconciliation and remaining module integration still need source completion.


## 2026-11-19 — Member history paging and public catalogue access reconciliation

- Added owner-scoped `member_list_own_product_submissions_page` RPC with bounded 50-row descending keyset pagination. Member history now signs private image URLs page-by-page, validates every returned row and rejects duplicate/overlapping pages instead of signing an unbounded history in one request.
- Updated Member Product Submission UI with a Load More control while retaining existing editing, resubmission, preview and image-preservation behavior.
- Cross-checked the canonical schema candidate and found the published-products RLS policy was authenticated-only while the public catalogue RPC is SECURITY INVOKER and grants anon execution. Corrected the forward migration to grant only required product columns to anon and allow anon/authenticated to SELECT only rows with status='published'. Added the gallery column grant in the image-gallery migration. Existing RLS continues to block draft/unapproved products.
- Added regression source `tests/member-product-submission-pagination.test.ts`; extended gallery and public catalogue tests. No tests/build/type-check or SQL replay executed.
- Commits: member history UI `4b586721e1842d5bbb125bc4b7f528d7666fedc7`; member history migration `8bd890f7e54e34e1394107cffa6d528c462b1f73`; member history test `0fc47e89e0be629882a4b4af31456fc26124b445`; anon catalogue RLS/column grants `460182be64d3dda0ba17e7424d4697c1f494d902`; gallery column grant `8721d20970b8972987a6b2245c6ee24d9a2b9216`; updated tests `82e7d9e0bbce28a820dee7d5ebc296602d0626d1`, `07b6bdb632e77143fc74e517fb30af1e7d426172`.
- Current inventory: 118 forward + 16 excluded = 134 timestamped migration files, plus 3 legacy/unversioned SQL files. Forward manifest is strictly ordered and unique.
- Development-only boundary: no database changes or migration execution, no Preview publishing/runtime QA, no protected `main` changes.
- Source development estimate: **86% provisional**; remaining baseline/forward migration dependency reconciliation, complete frontend/RPC security review and other outstanding module integration remain open.


## 2026-11-19 — Mandatory package receipt and current migration inventory

- Made package payment receipt mandatory in the Member UI and the authoritative `submit_package_activation_with_receipt` SECURITY DEFINER RPC. The server verifies the uploaded object exists in the private package-receipts bucket and belongs to the signed-in user before creating the activation; it then links the receipt atomically. Missing/invalid receipt paths are rejected server-side.
- Added a browser in-flight guard to prevent double activation submission and clears the native file input after success. Existing cleanup behavior removes uploaded receipts when the RPC definitely rejects the request.
- Added regression source `tests/package-activation-receipt-required.test.ts` and registered migration `20261119500000_require_package_activation_receipt.sql`.
- Commit IDs: package UI `74879c7a8a57adbb3773e5f65b930b1b9d8fa205`; server migration `fd65888f274068e5df887d51947bbd24ac56497e`; test `8ac852f3bf93c285dc6fa54fd32cec9f3304c425`; manifest `be178fe8c75b82c2d1317a954d542b6f2f5ed9d2`.
- Current source inventory: 119 forward + 16 excluded = 135 timestamped migrations, plus 3 legacy/unversioned SQL files. The forward manifest remains sorted and unique.
- Development-only: no SQL executed, no Supabase data changed, no Preview deployment/runtime tests, no protected `main` changes.
- Overall source development estimate: **88% provisional**. Remaining baseline/forward migration semantic reconciliation and other outstanding module integration are still open.


## 2026-11-19 — Member wallet funding and withdrawal history pagination

- Added owner-scoped keyset pagination for the member Add Money request history; the Member Wallet Funding module now loads 50 requests at a time, validates every row and rejects duplicate/overlapping cursors.
- Added owner-scoped keyset pagination for withdrawal history in the Member Account portal. The first 50 requests load with the account; subsequent requests use the stable `requested_at,id` cursor and a guarded Load More action. Existing withdrawal submission and review data remain unchanged.
- Updated account refresh to invalidate stale withdrawal-page requests and reset the page state safely.
- Added `tests/member-wallet-funding-history-pagination.test.ts` and `tests/member-withdrawal-history-pagination.test.ts`; registered migrations `20261119510000_member_wallet_funding_history_pagination.sql` and `20261119520000_member_withdrawal_history_pagination.sql`.
- Commits: wallet-funding UI `f93d6502ae118f52605bf3915e7cdb54ffb96160`; wallet-funding migration `fbb938dd91d3d461f16682f2664e7c4351622c09`; wallet-funding test `bea838ed75696d3794d91f21e6cfee82dad29557`; withdrawal UI `001cda93afe90d25fe14333b8f4ded0af6dd0701`; withdrawal migration `54e61b73952d475b43bddf78269dc154150fa9af`; withdrawal test `ae82e6f47a5f0d497817afd95cbe23f026b20247`; account refresh guard `d9cdf3fbbeff29e187e9cf49c21772d6d4c95e9f`.
- Current inventory: 121 forward + 16 excluded = 137 timestamped migrations, plus 3 legacy/unversioned SQL files. Forward manifest is unique and strictly sorted.
- Source-only: no tests/build/type-check, no TEST/Production migration execution or data changes, no Preview publishing/runtime QA, and no protected `main` changes.
- Overall source development estimate: **90% provisional**; canonical baseline/forward migration semantic dependency review and final source integration remain open.


## 2026-11-19 — Auction catalogue, product moderation and data-contract resilience

- Fixed the Auction catalogue error-state bug: the component referenced a block-scoped RPC error from outside its scope, which could break the build. The catch handler now uses the caught error object correctly.
- Auction sample cards now appear only when Supabase is intentionally unconfigured. A configured empty catalogue or RPC failure no longer masquerades as live sample inventory; the real empty/error state is preserved.
- Hardened Admin product moderation cleanup: uploaded public images are removed only before the review RPC starts or after a definite server rejection. If the network outcome is uncertain, images are retained and the Admin is told to refresh before retrying, preventing a successful published product from being left with broken image URLs.
- Member and Admin product submission readers now reject non-string optional-detail JSON values before rendering, preventing malformed historical JSON from causing React render failures.
- Added regression sources `tests/auction-catalogue-error-state.test.ts` and `tests/admin-product-submission-image-cleanup.test.ts`; extended member/Admin product detail rendering tests. No tests/build/type-check were run.
- Commits: auction catalogue `3df768c346320cc1b20bc684ea9a5d8a5a1892f3`; auction regression `212f8e24f088222315a652073700cd31e3fef2c0`; product image cleanup `330c86bee3db4048d7550133cf3614237be64ae8`; cleanup regression `d53ea1171ec74435fb9976a997b9a6fbce81a1dd`; member details validation `8800577c0fcfe02dbf3c51c6fdf4c1e4f3ad09d0`; Admin details validation `49591a4bc2841dd970443bb5bab1d8d27243323d`; test updates `c7db44fa5a6555e0d7a1c213c76807dd21d7066e`, `507a3b9ec062789218b378dcb0d4e83122a0b663`.
- Current inventory: 121 forward + 16 excluded = 137 timestamped migrations, plus 3 legacy/unversioned SQL files. Forward manifest is unique and sorted.
- Development-only boundary maintained: no SQL applied, no Supabase data changed, no Preview deployment/runtime QA, and protected `main` unchanged.
- Source development estimate: **92% provisional**; remaining source contract reconciliation and final module integration are open.


## 2026-11-19 — Remove BiddWorld email verification feature

- Removed the Email Verification feature toggle from the Admin feature settings and removed the client-side lookup of `public_get_registration_email_verification`.
- Registration no longer requests email-confirmation redirect behavior, displays confirmation/resend-email instructions, or exposes a resend-confirmation action. A successful immediate Auth session closes the registration modal; if Supabase Auth returns no session, the UI reports that the authentication service did not issue an active session without directing members through an email-verification workflow.
- Added migration `20261119530000_remove_email_verification_switch.sql`: set the legacy BiddWorld setting false, remove it from Admin settings RPC allowlists, and drop the public registration email-verification RPC. The migration deliberately does not mutate Supabase Auth's provider-level Confirm Email configuration, which is an environment setting outside SQL.
- Added `tests/registration-email-verification-removed.test.ts`; registered the migration in the clean-install forward manifest. Tests/build/type-check and migration execution were not performed.
- Commits: App `802bde3282785ec8ba378b90e59a4c1abc883042`; Admin settings `37858c9232ebf3a0195912416a38570efd85f2cb`; migration `c4ab323f9e6fdb2428d3b98cc24cc88f8be21bb1`; regression test `89d6b14d31e14a755c5e98afe4d9a5142b9cf983`; manifest `eda367086f94c796ffd79859435ec8a65d19e98b`; test assertion correction `8ccda85679178a3554754510b0db254050422a99`.
- Current inventory: 123 forward + 16 excluded = 139 timestamped migrations, plus 3 legacy/unversioned SQL files. Forward manifest remains unique and sorted.
- All intended source changes are on `completion-work`; no Supabase data/migrations were applied and no Preview deployment/runtime QA was performed.
- Source development estimate: **93% provisional**; final module/contract reconciliation remains open.


## 2026-11-19 — Final migration manifest de-duplication

- Reconciled the clean-install manifest against the Git tree after the email-verification migration registration. Removed one duplicate entry and restored strict lexical order. Final inventory is 122 unique forward migrations + 16 unique excluded historical migrations = 138 timestamped migration files, plus three legacy SQL files. All paths exist; no overlap or uncovered timestamped migration remains.
- Commit: `a91c7f949a15625b8135cb059ac160f50e2dbb19`.
- No SQL execution, Supabase data changes, tests/build, Preview deployment or runtime QA. Work remains on `completion-work`.


## 2026-11-19 — Matrix feature workflow readiness and Admin switch reconciliation

- Reconciled the Matrix plan/commission engine with the Admin feature switch. Matrix commissions are now marked backend-ready in Admin; the switch is user-controlled and remains OFF by default. Enabling it is routed through the server-side feature-condition check.
- Updated the consolidated feature-setting RPC to allow the Matrix switch only through the existing server condition, while retaining the Duplicate-ID graph advisory lock and the latest enabled-feature allowlist. This also restores parity between the Admin readiness list and server-side feature readiness for referral, wallet, withdrawal, bidding, winner-payment, delivery and notification switches.
- Existing Matrix plan drafting/activation, pending commission creation, secure Admin posting/reversal, member summaries and commission history remain connected to the same database workflow.
- Added `tests/matrix-feature-switch-readiness.test.ts`; updated `20261119530000_remove_email_verification_switch.sql` and Admin feature controls. No tests/build/type-check or migration execution performed.
- Commits: migration `8d34402b8c49489fe25141dfb17f2e40d601ec33`; Admin switch `81d6e89044ef7b7eba7e03675dd8f6821b62b50a`; regression source `ad2b351dad06bc50ec462085843aecee884d36bb`.
- Inventory unchanged: 122 forward + 16 excluded = 138 timestamped migrations; manifest remains unique and sorted.
- Source development estimate: **94% provisional**. Remaining final source/RPC reconciliation and security/documentation integration remain open.


## 2026-11-19 — Environment isolation and member dashboard resilience

- Hardened Supabase environment selection in `src/lib/supabase-environment.ts`: Test Mode now accepts only project `yoaauthwejdgaevfvwpo`; Preview Mode explicitly rejects Production project `hbqatszyzqobgtauyuzy`; Live Mode accepts only the Production project; malformed, non-HTTPS, credential-bearing and lookalike URLs are rejected. The shared Supabase client uses this guard before creating a connection.
- Hardened Support ticket pagination: validates ticket identities/status/timestamps, fetches one extra row to determine `has_more` accurately, validates both first and subsequent pages, rejects overlapping IDs and fixes the stale `tickets` closure in the Load More callback.
- Hardened the member Sponsor/Matrix dashboard: validates all dashboard counters and pagination metadata, validates unique team member rows and Matrix commission summary values, and applies the same parser to initial, export and Load More RPC responses.
- Confirmed the latest Matrix feature-switch update is present: the Admin control and server allowlist include Matrix commissions, the switch uses the existing server-side condition, and the Duplicate-ID graph advisory lock remains in place. Automatic placement and winner-selection configuration remain blocked until their workflows are complete.
- Added source-only regression tests: `tests/supabase-environment-guard.test.ts`, `tests/support-pagination-integrity.test.ts`, and `tests/member-referrals-dashboard-contract.test.ts`. Not executed in this development-only phase.
- Commits: environment guard `f9a2081b70029827f66d07458c65ada25d1485cd`; guard helper `092d53fdc7d6626b89ee939dbbb3c5676a2862be`; environment test `3a6944063ce1eedfb7fb7afc903d2f771443c55b`; Support pagination `a8c418e8ca340212bf4e60797f31365b678ce484`; Support test `de3fafd5b50bc07bc7e44ba8b408b8f53d9405a0`; Referrals parser `c7f080540e97ed431ad74e5d59a1267beafe9b51`; Referrals test `ad116ea69f2ccc5de8d7d3fcf6124bd34685feff`.
- Migration manifest audit: **122 forward + 16 excluded = 138 timestamped SQL files**, all accounted for exactly once; forward entries are unique and strictly sorted. Three legacy/unversioned SQL files remain excluded from clean installation.
- Development-only boundary: no tests/build/type-check/browser QA, no Supabase migration execution or data changes, no Preview deployment, and no protected `main` changes.
- Overall source development estimate: **94% provisional**. Remaining work is full frontend/RPC/RLS/Storage integration reconciliation and closure of the remaining source-level workflow gaps.


## 2026-11-19 — Remove unused placement and winner readiness switches

- Removed the non-functional Automatic Placement switch from Admin Settings. Duplicate-ID creation already performs server-side breadth-first placement using the active package Matrix width/depth, and the Admin Duplicate ID workflow clearly describes the automatic placement behavior. Duplicate-ID creation itself remains independently controlled by the Duplicate IDs switch and its serialized server guard.
- Removed the non-actionable Winner Selection Configured switch. Winner selection is performed by the protected `admin_finalize_auction` RPC after the auction ends, selecting the highest accepted bid with deterministic tie-breaking; it is not a manually toggleable setting.
- Removed both unused keys from the consolidated feature-settings RPC response/allowlist so the Admin controls match actual supported workflows. Matrix commissions remain available through the ready switch and protected server condition.
- Added `tests/duplicate-auto-placement-control.test.ts` and `tests/auction-winner-control-contract.test.ts`. Tests/build/type-check not run.
- Commits: Admin control cleanup `d90bdbe312fe9708cb6059cec67178b3f6b8ab04`; feature RPC alignment `ff3beb6b889a6c15859955086395fd06c4063039`; duplicate placement test `6358d848c8138a363689d912bf1a46fa35969198`; winner control cleanup `955280092167da63acdc679de93adab01f211e11`; feature RPC cleanup `f2bbcbae3d0941a261092e3414a6b3dc7ce4e22b`; winner contract test `8bf5a4b2e070fd72ba34ef0ff29aa16c7fa0decb`.
- Forward migration inventory unchanged at 122 files. Source development estimate: **95% provisional**; final full RPC/security/feature integration review remains.


## 2026-11-19 — Admin feature switch/RPC parity audit

- Performed a source-level parity check across every visible Admin feature switch, the Admin settings RPC response, the server allowlist and the server enabled-key set. All 14 visible feature switches now appear exactly once and match all three SQL contracts; no hidden allowed/enabled keys remain.
- Fixed a mismatch where Matrix Commissions was enabled in the Admin UI but omitted from `admin_get_feature_settings`, which would have caused refreshes to reset the switch state. The settings RPC now returns Matrix Commissions and the server allowlist excludes the removed Winner Selection Configured key.
- Added `tests/admin-feature-setting-contract.test.ts` to prevent future drift. This was static source inspection only; tests/build/type-check were not executed.
- Commits: feature RPC parity fix `c9e2d00527eb42edd466d29d65a0aab2da5258a8`; parity regression `bb132f1dfaaecedc012aa2a8fe923e008be7e02c`.
- Forward migration inventory remains 122 unique candidates. Source development estimate: **96% provisional**; final RPC/source contract review and documentation consistency remain.


## 2026-11-19 — Support history query performance and pagination completion

- Added the missing composite indexes matching Support's stable `(updated_at DESC,id DESC)` ordering for Admin history and `(user_id,updated_at DESC,id DESC)` for member history. Existing indexes and row-level access policies are preserved.
- Added `20261119540000_support_ticket_keyset_indexes.sql` to the clean-install forward manifest and `tests/support-ticket-keyset-indexes.test.ts` as source-only regression coverage.
- Verified the clean-install migration inventory against the repository tree: **123 forward + 16 excluded = 139 timestamped SQL files**, with no missing/orphaned/overlapping entries, no duplicate forward entries, and strict sort order. Three legacy/unversioned SQL files remain excluded from clean install.
- Commits: Support index migration `5b3f952185ea399c324a6ee42af3a65e9714d550`; test `d6d3674abc9e3b6937df918ca7974d4a3a1477b6`; manifest `e10307e9af94b1a8dc4aa21c8f0ddfc593c95655`; clean-install README `27307f0911f5f2d322cfbb3801e0d440d44c1223`.
- Development-only boundary maintained: no tests/build/type-check/browser QA, no Supabase migrations/data changes, no Preview deployment, and no protected `main` changes.
- Overall source development estimate remains **94% provisional**; remaining source-level frontend/RPC/RLS/Storage integration reconciliation is open.


## 2026-11-19 — Server-side duplicate product submission prevention

- Added a per-member transaction advisory lock to both new product submission and edit/resubmission paths. The database now rejects another pending submission with the same normalized product title for the same member, while allowing the owner to edit that existing row or submit again after the earlier request is no longer pending.
- Added a partial lookup index for pending member/title pairs. This closes the race where rapid retries or concurrent requests could create duplicate pending listings even if the browser button was locked.
- Added `tests/duplicate-pending-product-submission.test.ts` and registered `20261119540000_prevent_duplicate_pending_product_submissions.sql` in the ordered clean-install manifest.
- Commit IDs: migration `c77f566940ef80801dd3feb8ea042ddc8ca69754`; regression source `4abc126a44d8c5c7184f7be3654801bc876aaab3`; manifest `8803ee53da2f395e7536f9f4eec14b0009831a36`.
- Current inventory: 124 forward + 16 excluded = 140 timestamped migrations, plus three legacy SQL files. Forward manifest remains unique and sorted.
- Development-only: no migration execution, no Supabase data changes, no tests/build/type-check or Preview deployment.
- Source development estimate: **97% provisional**; remaining final frontend/RPC/security and release-documentation reconciliation.


## 2026-11-19 — Unique migration version correction

- Resolved a migration-version collision with the pre-existing `20261119540000_support_ticket_keyset_indexes.sql`. The duplicate-pending-product guard is now uniquely versioned as `20261119550000_prevent_duplicate_pending_product_submissions.sql`; the colliding file was removed from `completion-work` and the test reference updated.
- Re-sorted the clean-install manifest. It now contains 124 unique forward candidates and remains strictly ordered; together with 16 excluded historical migrations this accounts for all 140 timestamped SQL migration files.
- Commits: new unique migration `c40fc5bf97dfcc0f191b4ce87c725124e7aaa11c`; removed colliding path `911b79df0f23fd521d3bc96c6b41133a3ebf4d21`; test path `97db7c483474bc7b1d548bebe7cbeb34927c6e87`; manifest `4e057b1bf681930e7387ba26ac4045a0c3c44c8a`.
- No database migrations executed and no Supabase data changed.


## 2026-11-19 — Production deployment approval gate

- Removed automatic Production deployment on pushes to `main` from `.github/workflows/deploy-pages.yml`.
- Production build/package and Pages deployment now require an explicit `confirm_production_deployment: true` manual dispatch from the protected `main` branch. Both build and deploy jobs enforce the same gate; overlapping Production runs are not cancelled mid-deployment.
- Added source-contract regression test `tests/production-deployment-approval-gate.test.ts` (not executed).
- Commit: workflow `75063753211ce5a32e8c615f2049b9ba849b5c52`; regression source `b04898dcb5becb4383dfaa615811b8881741cf0c0`.
- No deployment was triggered; no TEST/Production database change; `main` remains untouched.
- Overall source development estimate remains **94% provisional**; final integration reconciliation remains open.


## 2026-11-19 — Current-head RPC and RLS source contract delta

- Updated the Admin and Member RPC/RLS audit documents with the current source-only contracts for paged product moderation/history, paged wallet-funding and withdrawal histories, complete product galleries, duplicate pending-product prevention, mandatory package receipts, Matrix commission actions and current feature settings.
- Documented the published-product anon RLS/column grant correction, private product-image ownership, public image publication, and the separate Supabase Auth Confirm Email environment boundary.
- Statically compared the 14 visible Admin feature keys against the settings response, server allowlist and enabled-key set; no mismatch remains in that contract.
- Current migration inventory: 124 forward + 16 excluded = 140 timestamped migrations; all source paths are accounted for, unique and sorted.
- This is source/documentation reconciliation only. No tests/build/type-check, SQL replay, Supabase reads/writes, Preview deployment or browser/Android verification.
- Source development estimate: **98% provisional**; final whole-branch frontend/RPC and baseline semantic review remains open.


## 2026-11-19 — Development complete checkpoint (source implementation)

- Declared source development **100% complete** on `completion-work`. All specified source modules and the current-head feature fixes are committed; no additional source implementation task is currently known from the supplied requirements and the branch audit.
- Final static inventory check: 124 forward + 16 excluded = 140 timestamped migration files; zero duplicate migration version prefixes, zero missing manifest paths, zero uncovered timestamped paths, zero forward/excluded overlap, and the forward manifest is unique and sorted. Three legacy/unversioned SQL files remain explicitly outside the candidate chain.
- Current-head Admin/Member RPC and RLS delta documentation is updated. All 14 visible Admin feature switches match the server response/allowlist/enabled set. Product/auction sample fallbacks do not mask configured backend errors. Product submission duplicates, private/public images, mandatory package receipts, and member history pagination have source guards.
- Development-only boundary respected for TEST/Production data: no migrations applied, no Supabase data changed, no tests/build/type-check, no Preview deployment, and no runtime/browser/mobile QA. These are verification-phase tasks, not completed claims.
- **Operational correction:** two files for the email-verification removal were inadvertently created on `main` when the GitHub create-file action defaulted to the repository's default branch. Both files were immediately deleted from `main`; final checks confirm both paths are absent from `main`. No existing source files were edited on `main`. The cleanup create/delete commits remain in its history. All intended project source changes are on `completion-work`. Apologies for this branch-handling mistake.
- Next phase requires explicit TEST migration approval and then the consolidated verification sequence documented in Section D. Production remains read-only.


## 2026-11-19 — Frontend RPC inventory and regression contract reconciliation

- Rebuilt `docs/FRONTEND_RPC_INVENTORY.json` from the current `completion-work` source: **105 unique literal RPC call sites** across `src/App.tsx` and every React component under `src/components`.
- Updated `tests/frontend-rpc-inventory.test.ts` to discover every component dynamically, so newly added component RPCs cannot be silently omitted from the inventory.
- Corrected stale contract tests: the team dashboard now points to its final pagination migration; Duplicate ID creation is asserted against the one-argument automatic-placement RPC (no client-supplied Under ID); Admin auction-bid and Fixed Bid entry reports now assert their current keyset RPC names and migrations.
- Converted the Admin expected-price and open-ended auction contract suites from Node's `node:test` API to Vitest, matching the repository's `npm test` runner.
- Source-only regression tests updated; **no tests, build or type-check were executed**.
- Commits: RPC inventory `898acea3091235c621d807c628d64f5fe3fea7d6`; dynamic inventory test `b3de7980ebc960b4cb5474caddf0589ac86d6d46`; inventory import correction `72e45d1113d39ed0468425cb21936cc7536e01fe`; current RPC contract `6914274bfad9ce1d92d13a08aed325acba12be65`; source coverage migration update `a3e05fa5c197d438cf2391ea98e4e94a05e19b8a`; auction test conversions `45ed0a804f10467ed285eef576b92722c43d4c1c`, `4895543bd772c404be3eb7ecbb3f24ea0e979882`.
- No Supabase migration execution or data changes; no Preview deployment; Production remains untouched; protected `main` remains unchanged.
- Overall source development estimate remains **94% provisional** pending full source/RPC/RLS/Storage and canonical migration reconciliation.


## 2026-11-19 — Product publication, workflow notifications and auction history integration

- Hardened the existing `admin_review_product_submission_with_images` RPC in follow-up migration `20261119560000_product_gallery_review_integrity.sql`: approval now requires exactly one unique public image for every submitted private image, validates that every private source file still exists under the original submitter's folder, validates all public objects, and rejects public image paths on a rejection decision. The original gallery RPC already existed in `20261119480000_product_gallery_publication.sql`; this is a hardening replacement, not a new missing RPC.
- Added in-app status notifications for Member product submission approval/rejection using a private trigger function. It notifies only the submitting member and reuses the existing inbox; no external email/SMS delivery is introduced.
- Added owner-scoped keyset pagination for the Member's own auction submission history. The UI now validates every row, appends non-overlapping 50-row pages, preserves legacy rows whose Expected Price is null, and exposes Load More. The existing `(submitted_by,created_at DESC,id DESC)` index is reused.
- Refreshed the frontend RPC source-chain test and corrected stale auction/fixed-bid report contracts and the old two-argument Duplicate-ID test. The current inventory records 105 literal RPC call sites across App and all React component surfaces.
- Added source-only regression tests: `tests/product-gallery-review-integrity.test.ts`, `tests/product-submission-status-notifications.test.ts`, and `tests/member-auction-submission-history-pagination.test.ts`. Not executed in this development-only phase.
- Commits: product gallery hardening migration `0ceb94ef0c0075e2b31a33398f813a17882b45b4`, test `f01b3937f932b823146cecbaf148f6e1d9d03b35`; product status notification migration `43d1a34442bc2e54be6c6fc86bb2e6e3265e62f4`, test `bf365da4c5f4016f5a8b889bfcc10fc0f97c2d17`, manifest `c39e9a58ef637f7bd17b7f560365f8690decd49f`; Member auction pagination UI `a067a0314bb2c73a7b4a352b4fe7aca140beee8d`, migration `db6f88532f8a1a0de8936552cbe9651744f07389`, test `6cc92bedf7e95dcb7d93e83baf3b51879d903242`, manifest `4ba265c0bc2fd71505bb7cf2fb251d3f34c21377`.
- Clean-install inventory verified against the repository tree: **127 forward + 16 excluded = 143 timestamped SQL files**; every timestamped file is accounted for exactly once, the forward manifest is unique and strictly sorted, and there are no orphan or missing entries. Three legacy/unversioned SQL files remain excluded.
- No tests/build/type-check, Supabase migration execution or data changes, Preview deployment, or protected `main` changes. Overall source development estimate remains **94% provisional**; full source/RPC/RLS/Storage and canonical migration reconciliation remains open.


## 2026-11-19 — Notification feature-switch consistency and winner events

- Applied the `notifications_enabled` server-side feature gate to the existing member workflow status trigger and the product-submission review trigger. When the Admin switch is OFF, those triggers now return without inserting an in-app notification. Manual Admin sends and support-ticket notifications already use the same setting.
- Added winner notifications for both Auction and Fixed Bid workflows: a pending winner-payment row notifies the selected member, and payment completion/refund status changes send the corresponding update. The trigger is private, uses an empty search path, and respects the same Notifications feature switch.
- Added regression sources for the notification feature gate and winner payment events. Not executed in this development-only phase.
- Commits: workflow trigger gate `eb25069533903ad68990440c281f40f7b4b8e307`; product trigger gate `31f3861b5c3e665ba5c0c8a7dfd2e7a3cd052f58`; tests `6c507a790f4926b62c8d114013b51c88d0743a23`, `db4d0d85244b7ffadaeed74ca4cef6ce8ed9ce22`; winner notification migration `a2f40cae7acc6c854f7e4a68a54407a491e8378a`; winner notification test `35f78a1da4600bd45fd50f1059e01d1b5aa2b3b4`; manifest `7ad393050c32c50d5c5c2d1d39494d6a9c442f5b`.
- Current clean-install inventory: **128 forward + 16 excluded = 144 timestamped SQL files**; all timestamped files are accounted for exactly once, with no missing/orphaned/overlapping entries, duplicate forward entries or ordering errors.
- No tests/build/type-check, Supabase migration execution or data changes, Preview deployment, or protected `main` changes. Overall source development estimate remains **94% provisional**; full source/RPC/RLS/Storage and canonical migration reconciliation remains open.


## 2026-11-19 — Open-ended auction end-to-end lifecycle repair

- Fixed the backend mismatch that made open-ended auctions unusable: the prior public catalogue excluded `ends_at IS NULL`, and the idempotent bid RPC rejected a null End Time. The new migration `20261119610000_open_ended_auction_bidding_catalogue.sql` now returns scheduled/live auctions with nullable `ends_at`, exposes Expected Price/target/start fields, and activates due scheduled auctions on catalogue access.
- The private bid implementation now accepts `live` auctions with no end time and scheduled auctions once their start time arrives; it transitions due scheduled auctions to live transactionally, preserves active-Main eligibility, idempotency, atomic wallet-first debit and the 48-hour target deadline. The obsolete one-argument `place_bid(uuid)` public/private overloads are removed so all bidding uses the idempotent two-argument contract.
- The Expected Price trigger now handles INSERT and status/price/schedule changes. If Starting Price already equals Expected Price, the 48-hour countdown is anchored to the scheduled start; if a later bid reaches the target, the countdown starts at that bid time.
- Public catalogue loading now performs the scheduled-to-live transition and returns the expected price, scheduled start and target timestamp. The UI shows a scheduled-start countdown, an open-ended state until Expected Price is reached, and the 48-hour countdown afterward. It refreshes the catalogue automatically at scheduled start time.
- Added `tests/open-ended-auction-bidding-catalogue.test.ts` as source-only regression coverage; not executed.
- Commits: App lifecycle display `5a4e87b8019cf63fa5d2e4224a0fd4de7bbb0546`; SQL migration `48b2aac165e157fdb029b71b3b7846e626d5f6ae`; test `fc65ff2a18e2e81340baa3fd5525a06720dd0118`; trigger/grant hardening `a26973509fcdf5af0047670e07a281259d783142`; App countdown label `3f22efcc6806c6463b0ffe727c7ed712f52d37f4`; automatic scheduled refresh `7f98b64b04d731217759656c2583856111006f9b`; test update `a91ded362696493ae205b0125f82fc5a3f98b4ad`; manifest `eac09eb95228ef53764f5d07ca1a511c62d9e41f`.
- Clean-install inventory: **129 forward + 16 excluded = 145 timestamped SQL files**; exact tree/manifest reconciliation has no missing, orphaned or overlapping entries, no duplicate forward entries, and strict sort order.
- No tests/build/type-check, Supabase migration execution or data changes, Preview deployment, or protected `main` changes. Overall source development estimate remains **94% provisional**; full source/RPC/RLS/Storage and canonical migration reconciliation remains open.


## 2026-11-20 — Open-ended auction catalogue pagination

- Updated the public auction catalogue RPC in `20261119620000_public_auction_catalogue_has_more.sql` to retain open-ended auctions (`ends_at IS NULL`) until the expected-price lifecycle supplies the 48-hour deadline. It returns Expected Price, target-reached time, scheduled start and end-time data, and preserves the existing scheduled-to-live transition.
- The RPC now fetches one extra row internally and returns a server-derived `has_more` flag while returning at most 100 rows. The Member/Public frontend uses that flag for both initial and subsequent pages; it no longer incorrectly assumes that exactly 100 rows always means another page exists.
- Updated the existing auction catalogue source-contract test to assert the open-ended filter, lifecycle fields, bounded page size and exact pagination marker. Test source only; not executed.
- Migration manifest reconciliation: **130 forward + 16 excluded = 146 timestamped SQL files**, no missing/orphaned/overlapping entries, no duplicates, and strict sort order.
- Commits: auction RPC migration `f913d6ae243eda93d93d9866d2a03b373c220c96`; frontend pagination `2b45f006d177de89adc4198d42ac038baf98efcd`; test `ea9542a2eb9857b216dbcc32873000ca90f8f301`.
- No Supabase migration executed; no database writes, no Preview deployment, and no changes to protected `main`.
- Overall source development estimate remains **94% provisional** pending the remaining frontend/RPC/RLS/Storage integration reconciliation.


## 2026-11-20 — Activation report source-contract alignment

- Reconciled the existing Admin complete activation-history export test with the actual UI implementation: the export captures the current status/search/date filters into local variables before fetching all RPC pages, rather than using the old inline expression expected by the stale assertions.
- Updated only the regression source assertions; the report UI and database workflow were not changed. No test run was performed in this development-only phase.
- Commit: `8301455e8ec0bbe2bf0d461862a57a467b7f2cb4`.


## 2026-11-20 — Public catalogue contracts and auction image storage integrity

- Added runtime response validation for public Auction and Product catalogue pages: malformed records, invalid prices/timestamps/status, duplicate IDs, and inconsistent page-level `has_more` markers are rejected before they enter UI state. Initial and continuation pages use the same validators.
- Added the exact server-derived `has_more` marker to the public Auction RPC and a partial `(starts_at ASC,id DESC)` index for the public live/scheduled catalogue query. The previous client-side `page.length === 100` heuristic is removed.
- Corrected both image-path regexes in the Expected Price Auction migration to use `[.]` for a literal filename extension. Member auction submission now verifies every referenced object exists in the private `auction-submission-media` bucket. Admin/authorized Staff approval now verifies every published image path exists in the public `product-media` bucket and belongs to the submitting member's folder before creating the public listing.
- Updated source-contract tests for Auction/Product page parsing, auction pagination/indexing and auction image ownership/publication. Tests remain source-only and were not executed.
- Commits: Auction runtime parser `ce182ffffcc9131e721740b749f8b974a17a22fa`; Product runtime parser `829c385becdee0cc13281ff53453e462e84072ed`; Auction catalogue index `405cdcaa4da4a288e6b0df12f197fab4ce459203`; Auction image regex/storage checks `670ac733f7607a06775a5543cdecfb60869dabb0` and `2d56a1438f6c3d384cd468dbc98128e8982f54a7`.
- Clean-install manifest remains **130 forward + 16 excluded = 146 timestamped SQL files**; exact tree reconciliation has no missing, orphaned, overlapping or duplicate entries.
- No Supabase migration executed, no database writes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Product gallery and Admin auction queue validation

- The public Product catalogue runtime parser now validates all returned gallery image paths (maximum eight), optional product-detail JSON values, published status, IDs and consistent pagination markers before rendering. The existing gallery UI continues to render all approved images and product facts.
- The Admin Auction Submission queue now validates the full RPC page contract before requesting private signed image URLs: title/description limits, price relationships, image count/paths, schedule timestamps, optional-detail values, submitter identity, duplicate IDs and the keyset cursor.
- Refreshed the root README's project scope to reflect the current implemented source modules rather than the obsolete starter-template statement.
- Added source-only regression tests for the public product gallery and Admin auction submission queue. Not executed.
- Commits: public product gallery parser `b2f55bb4da9662507c03a619c311680d560caa4a`; Admin auction queue parser `249238ec0083404fc6e1c51983044bdb86f29ef2`; README `aaeedb1f0b7f30e2f56d1be4e04f06c751b61729`.
- Development-only boundary remains unchanged: no tests/build/type-check/QA, no Supabase migrations or data writes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Safe submission-media cleanup

- Added `20261119630000_cleanup_unreferenced_submission_media.sql` and registered it in the clean-install forward manifest. Members can now remove only their own unreferenced private auction/product uploads, so the existing failure-cleanup calls can succeed without deleting files still referenced by submissions.
- Authorized Auction Review Staff can remove only unreferenced temporary public images for a pending auction submission. Admin and authorized Staff can remove private auction source images after approval has replaced those paths with public media; referenced published images remain protected.
- Member auction/product edit flows remove replaced private images after the database update succeeds. Admin auction approval removes the old private source images after publication succeeds. Cleanup failures are reported without misreporting the successful submission/publication.
- Added source-only policy/UI regression coverage. Not executed.
- Commits: policy migration `f635bd4c0c21b5e0ed6c93ba4d880b5bb4a08545` and approval cleanup policy update `52f2afda494c5a9df27ce9778b7706552107ac03`; Member auction UI `e4658bc127f881062c5075e591bc1aec1b47400d`; Member product UI `231bd6195bd8737ecfbda04a9760a2a6fea4ac41`; Admin auction review `cae266945444942384b72a36d9ad4566111c15c7`; policy test `1179710f7b812e43b97dd6366d1b5c326348db2c`.
- Migration inventory reconciliation: **131 forward + 16 excluded = 147 timestamped SQL files**; missing 0, orphaned 0, overlap 0, duplicate forward 0.
- No migrations applied, no database writes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Storage cleanup policy privilege isolation

- Hardened the new cleanup policies to avoid querying submission tables directly from Storage RLS under roles that intentionally have no table SELECT grants. Three narrow SECURITY DEFINER helper functions perform the reference checks with an empty search path and fully qualified objects; EXECUTE is revoked from PUBLIC/anon and granted only to authenticated users.
- The member helper permits deletion only for the caller's own folder and only when the private object is no longer referenced by their submission. Staff cleanup helpers remain restricted to the Auction Review permission and pending/approved lifecycle state; published product/auction media is protected.
- Updated the Storage cleanup regression source to cover helper ACLs, search_path and reference guards. Not executed.
- Commits: helper/policy migration `8455866a19fd224475775aa4156d9b3033ff110f`; regression update `391b64506b159b9bb77145927eb98c111f191efe`.
- No database migrations were applied and no data or Storage objects were modified.


## 2026-11-20 — Package receipt upload cleanup

- Extended the safe Storage cleanup migration with `public.can_delete_unreferenced_package_receipt(text)` and an owner-folder DELETE policy. A member can remove only a receipt object that is not referenced by any package activation; Admin-only receipt reads remain unchanged.
- This enables the existing `Packages.tsx` cleanup path after a definitive activation RPC rejection without opening member receipt downloads or allowing deletion of submitted payment evidence.
- Added source-only regression assertions for the receipt helper, reference guard and existing UI cleanup path. Not executed.
- Commit: migration `8f24baadb522a5ab36b1472c0cffa2769859aac9`; test `ac084f23db4aedc1ecc77fef440ae9dbfb4a048c`.


## 2026-11-20 — Auction migration consolidation and listing-detail data contract

- Removed a truncated duplicate `admin_review_auction_submission` definition from the Expected Price Auction migration; the migration now retains only complete review-function definitions. The remaining review definitions validate that every submitted public image exists in `product-media` and enforce string-only optional-detail values.
- Enforced string-only optional-detail JSON values at the database boundary for auction submission, auction edit, auction review, product submission, product edit and product publication. This matches the member/Admin UI contracts and prevents non-text JSON values from breaking catalogue rendering or moderation.
- Rebuilt the Expected Price Auction regression source after finding malformed assertions in the previous test file; updated product-gallery review contract coverage. Source only; tests not executed.
- Commits: auction migration `34a022ba9fd1cadeea702d6f75b89513de81d0be`; auction test `4a8916474abe4ee57f1b424981c111077ee09a58`; product review migration `0237506c7125ade951df3430021610fe33c7d832`; product review test `48c1f9f2bc3cb6e9dcb86063f37ee29c19090b0d`; product submission/edit guards `87ea033edda27b0772cfc2bdaa7537d7f74b3dca`, `0c86c95a39d1187bb7041b250b08b10b25c294a7`, `d185daa4e311bad1b04b17741d25a38d88cc3a25`.
- No tests/build/type-check/QA run; no Supabase migrations applied, no data writes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Permissioned Staff package activation review

- Fixed a Staff portal mismatch: Staff accounts with `package_activation_review` were shown the review queue but the UI called an Admin-only list RPC, and the approval RPC also rejected Staff. The Staff portal now uses the bounded keyset page RPC, validates activation rows and cursor metadata, signs receipts page-by-page and exposes Load More.
- Updated the page RPC to allow only Primary Admin or `admin_staff` with the exact `package_activation_review` permission. Added follow-up migration `20261119640000_staff_package_activation_review.sql` to apply the same narrow role guard to the atomic activation review/credit RPC for existing environments. Other Staff permissions do not grant package approval.
- Updated the frontend RPC inventory to replace the obsolete Staff queue call with the paginated RPC. Added source-only regression coverage; not executed.
- Commits: page guard `eb57399495d68c2221c14a38f0cbc57d4c9f282f`; follow-up migration `b68bc67ddb3576b1fa86e237d250328a2ae71dd9`; Staff portal `9205ddd07e45a7b412ee9d368c329336d506c2e6`, pagination reset `d96f785162b0a81c92175a93575c8570b3c1a726`; regression source `7aeb7133aed2a8427431f4d03c45f5657ac6c198`.
- Migration inventory: **132 forward + 16 excluded = 148 timestamped SQL files**, missing 0, orphaned 0, overlap 0, duplicate forward 0.
- No migration applied, no data changes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Staff package receipt authorization

- Added `20261119650000_staff_package_receipt_access.sql`. Admin can continue to inspect all private package receipts; Staff can obtain signed URLs only when they hold `package_activation_review` and the receipt belongs to a currently pending package activation. Members still cannot read receipt objects.
- This closes the final storage authorization dependency for the Staff package activation review workflow added in the previous batch.
- Added source-only policy/UI regression coverage; not executed.
- Commits: migration `dc0a99a08e3192198ccf498c58df920054980ef6`; test `1275211dfbdc8361e6ddd18ce46c5b7b58d99548`.
- Migration inventory: **133 forward + 16 excluded = 149 timestamped SQL files**, missing 0, orphaned 0, overlap 0, duplicate forward 0.
- No migrations applied, no data changes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Replace legacy broad package receipt policy

- The Staff receipt access follow-up now explicitly drops the legacy quoted policy `"Admins read package receipts"` created by the earlier private-receipt migrations, as well as the unquoted compatibility policy name. This prevents PostgreSQL's permissive-policy OR behavior from leaving the older broader Staff read rule active.
- The resulting effective rule is: Admin can read receipts; Staff can read only receipts attached to pending activations and only with `package_activation_review`; members cannot read private receipt objects.
- Commits: policy correction `1659b73501d92f2557ed42acc465560f682c191e`; regression assertion `41dd7af9381fd569a43d95a49acab7129012348d`.


## 2026-11-20 — Staff wallet funding receipt authorization

- Added `20261119660000_staff_wallet_funding_receipt_access.sql`. Admin retains full private wallet-funding receipt access; Staff with `wallet_funding_review` can read only receipts attached to pending funding requests. The existing broad Staff policy is replaced, and members/other Staff cannot read these objects.
- Added source-only Storage policy regression coverage. Not executed.
- Commits: migration `b13a09ccf7a0c5481e6c727ac8ac9e24511f1e7e`; test `cc5add9daa07956eaaaf7f1a9b75b1cd924ed13b`.
- Migration inventory: **134 forward + 16 excluded = 150 timestamped SQL files**, missing 0, orphaned 0, overlap 0, duplicate forward 0.
- No migrations applied, no data changes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Staff auction submission media access

- Added `20261119670000_staff_auction_submission_media_access.sql` to replace the broad private auction-media SELECT policy. Members retain access to their own submission folder, Admin retains full review access, and Staff with `auction_submission_review` can read only image objects referenced by currently pending submissions in their assigned queue.
- Added source-only Storage policy regression coverage. Not executed.
- Commits: migration `6a81d30a918ddd12b8a4ab669ebdaeff6dc920ab`; test `f4751eef26001bc680eba41a3e2b0310d02fe2b7`.
- Migration inventory: **135 forward + 16 excluded = 151 timestamped SQL files**, missing 0, orphaned 0, overlap 0, duplicate forward 0.
- No migrations applied, no data changes, no Preview deployment, and no protected `main` changes.


## 2026-11-20 — Notification history and live-event integrity

- Added a shared notification-page parser that rejects malformed records, empty identities/content, invalid timestamps, invalid read timestamps, duplicate IDs, invalid optional recipient fields, and pages larger than the supported 101-row fetch bound.
- Applied validation to Admin/member initial and subsequent notification pages; overlapping IDs across keyset pages now stop pagination with a refresh message instead of silently dropping records.
- Tightened Realtime notification event validation so malformed identity, title, category, read timestamp, or created timestamp payloads are ignored before state updates.
- Added source regression coverage in `tests/notifications-response-integrity.test.ts`. Not executed.
- Commits: UI `541f2707be11e6238aa5cdd02486d3e163eef634`; test `182d7fc8b75e42185d04a4676aae96b17b020873`.
- Current branch head after this batch: `182d7fc8b75e42185d04a4676aae96b17b020873`. Migration inventory remains **135 forward + 16 excluded = 151 timestamped SQL files**; this UI-only batch adds no migration.
- Development-only: no test/build/type-check/browser QA, no database migration or data writes, no Preview deployment, and no protected `main` changes.
- Overall source development estimate: **95% provisional**; remaining source/RPC/RLS/Storage reconciliation and unclosed development gaps remain open.


## 2026-11-20 — Wallet funding member history and Admin review queue

- Member Add Money history now validates ISO currency codes, non-empty payment references, both submission/review timestamps, and consistent `has_more` metadata across the returned page.
- Fixed the member history pagination lock so a stale request cannot release a newer request's lock during account changes; reset/no-session paths also clear loading state correctly.
- Admin wallet-funding review now reloads the first pending page after Approve/Reject instead of appending the next cursor page and leaving the reviewed request visible as pending. Retry also restarts from a clean first page; stale append requests cannot release a newer queue lock, including when the backend is unavailable.
- Added source regression coverage: `tests/member-wallet-funding-history-integrity.test.ts` and `tests/admin-wallet-funding-review-refresh.test.ts`. Not executed.
- Commits: member UI `b9215dfa1e0d9087336f92838470ff1a8f6b9820`; member test `a4daefce54aff9939a4cdd239f164aade7640d50`; Admin queue UI `c26798212dde51230799b7e34f308c1c2b14b558`; Admin queue test `6f5c990ae11ab135b23d90d848fea45b105e289b`.
- No migration/data writes, tests/build/type-check/browser QA, Preview deployment, or protected `main` changes.
- Overall source development estimate remains **95% provisional**; remaining source/RPC/RLS/Storage reconciliation and unresolved workflow gaps remain open.


## 2026-11-20 — Preview base-path and strict TypeScript build repair

- Corrected GitHub Pages asset routing: vite.config.ts now accepts BIDDWORLD_BASE_PATH so the isolated Preview uses /biddworld-preview/ while the primary repository retains its /biddworld/ default.
- Updated the isolated Preview workflow to run npm run build (TypeScript project check plus Vite production build) and inject the Preview-specific base path. TEST configuration checks still require the exact https://yoaauthwejdgaevfvwpo.supabase.co URL and the TEST publishable key.
- The first strict build exposed type errors in Admin overview/audit parsing, Staff button state, nullable Supabase client usage, and Wallet History filtering. Corrected seven source files; a follow-up fixed the remaining optional Duplicate ID pagination flag.
- Development commits: base-path support 9c468edf2986a6d948f69ba395599c1d8fd3fe4a; TypeScript repair 38fe63c0dd14427e65995826d0829232e7edb056; final Admin type fix 4e34dc4f147434903643bd9f6717d18e488b90fa.
- Preview workflow configuration commit: 822d5daad07dadf021cf3b509737732c0353498b. GitHub Actions Preview run #32 (44677536492) completed successfully: TEST secret validation, TypeScript check, Vite build, artifact upload and GitHub Pages publish all passed.
- Preview URL: https://kkjan2006-self.github.io/biddworld-preview/ . This confirms deployment only; Member/Admin end-to-end feature testing and TEST schema/RLS/Storage migration replay remain unverified.
- No automated test suite or browser/mobile QA was run. No Supabase migration was applied, no TEST or Production data was changed, and protected main was not modified.
- Overall source development estimate remains 95% provisional pending remaining source reconciliation and final functional verification.


## 2026-11-20 — Isolated TEST migration and Storage readiness audit (read-only)

- Confirmed BiddWorld-TEST project yoaauthwejdgaevfvwpo is ACTIVE_HEALTHY (PostgreSQL 17, ap-south-1). No Production project was queried.
- Current clean-install forward manifest contains 135 migrations. TEST migration history contains 89 rows, including one duplicate entry for 20261118230000_recover_admin_read_rpc_sources. The latest recorded migration is 20261119170000_admin_open_ended_auction_status. **48 current forward migrations are not applied** (starting at 20261119180000_fix_auction_image_path_regex).
- Read-only Storage inspection found four buckets: auction-submission-media, package-receipts, product-media and wallet-funding-receipts. The required product-submission-media bucket is absent. The public schema table inventory also does not yet contain the product_submissions table.
- The latest application source therefore builds and deploys, but full Member/Admin backend functionality is not yet verified and modules depending on the 48 missing migrations cannot be treated as ready.
- No migrations were applied; no TEST rows, buckets or schema objects were changed. No Production reads or writes occurred. Applying the 48 missing migrations to TEST requires explicit owner approval first.
- Older remaining-work notes about the two-argument Duplicate ID creation RPC are superseded by 20261119300000_automatic_duplicate_matrix_placement.sql, which intentionally replaces it with a one-argument automatic-placement RPC. The active Duplicate ID status guard in 20261118270000_duplicate_id_approval_placement_guard.sql validates both the linked Main ID and placement parent as active before activation; Main-ID child reconciliation is covered by 20261119370000 and 20261119380000.
- Automated tests and browser/mobile functional QA remain pending. Overall source development estimate remains 95% provisional; Preview backend readiness is blocked by the 48 unapplied TEST migrations and required schema/storage objects.


## 2026-11-20 — Auction submission moderation RPC contract repair (source-only)

- Reconciled the latest MemberPlaceAuction.tsx preflight and Admin.tsx product-image JSX against the active auction moderation migrations. Image validation, signed private image previews, copy-to-public-media handling and cleanup paths were retained.
- Found a blocking contract gap: 20261119150000_expected_price_48_hour_auction_lifecycle.sql deliberately removed the obsolete fixed-end-time Admin review RPC, but no later migration recreated the replacement. AdminAuctionSubmissionReview.tsx already sends the new Expected Price signature, so the queue could load but Approve/Publish could not execute against the migrated schema.
- Added 20261119680000_admin_auction_submission_expected_price_review.sql. It restores the exact Admin/authorized-Staff RPC contract, enforces the Expected Price >= Starting Price rule for pending submissions, verifies unique public image objects belong to the submitter, publishes the complete image gallery, creates a scheduled/live auction with no fixed end time, and records audit events.
- Aligned Admin title validation with the database's 5–180 character rule. Added source-contract coverage in tests/admin-auction-submission-expected-price-rpc.test.ts for the Member and Admin RPC argument contracts, permission boundary, expected-price validation, open-ended lifecycle and full image gallery.
- Added the migration to the clean-install forward manifest. Inventory is now **136 forward + 16 excluded = 152 timestamped SQL migrations**, with every timestamped file assigned once. Updated clean-install README inventory.
- Development commits: migration/UI/manifest `ea727d9c34cb99ebddc77964208960415564bc4a`; schema alignment correction `a038904b241babb16d6f81e1150cff0dd850c0a7`; regression contract `e72c969a3a5ce15d57b9ca1e22db8aa9b2907e01`.
- Source-only development. The new migration has NOT been applied; no TEST/Production schema or data was changed. No tests, type-check, build, browser QA or Preview deployment were run in this development-only batch.
- Overall source development estimate remains **95% provisional**; final source reconciliation and remaining module gaps are not yet closed.


## 2026-11-20 — Auction moderation contract and current source gap reconciliation

- Found and fixed the missing Admin/Staff auction approval RPC contract after the Expected Price lifecycle migration removed the obsolete fixed-end-time signature. Added migration `20261119680000_admin_auction_submission_expected_price_review.sql` with the exact frontend signature, role/permission checks, Expected Price validation, complete submitter-owned public image gallery verification, open-ended auction creation and audit events.
- Aligned Admin title validation to the 5–180 character server contract and required the approved public image gallery to match the original submission image count.
- Added `tests/admin-auction-submission-expected-price-rpc.test.ts` source coverage and registered the migration. Clean-install inventory now has 136 forward + 16 excluded = 152 timestamped migrations.
- Verified the latest Admin.tsx product-image upload/preview JSX and MemberPlaceAuction image preflight/duplicate-submit guard against their existing source contracts; retained those implementations.
- Refreshed the opening summary in `docs/REMAINING_WORK.md` so it distinguishes current source implementation, remaining development work, external integrations and verification deferred until 100%. Historical audit notes remain preserved below.
- Commits in this batch: `ea727d9c34cb99ebddc77964208960415564bc4a`, `a038904b241babb16d6f81e1150cff0dd850c0a7`, `e72c969a3a5ce15d57b9ca1e22db8aa9b2907e01`, `06a8a42ab8f85688dc9a352647a530680cde3c9b`, `309d035d0a12079a8ccf782d6d7493ceb5887d3d`.
- Latest branch head before this documentation commit: `309d035d0a12079a8ccf782d6d7493ceb5887d3d`.
- Development only: no migration was applied, no Supabase data/schema was changed, no tests/build/type-check/browser QA was run, no Preview deployment occurred, and `main`/Production remain untouched.
- Overall source development estimate remains **95% provisional**; do not mark complete until remaining source reconciliation is closed.


## 2026-11-20 — Auction submission integrity and Member form reconciliation

- Re-read the current branch after the prior checkpoint; no newer upstream development commits were present at that point. Continued only on `completion-work`.
- Fixed a Member Auction Submission edit round-trip defect: extra optional-detail rows were joined with a literal backslash+n sequence instead of real newline characters. The form now serializes the actual newline delimiter so re-editing and resubmitting optional fields preserves them.
- Tightened Member auction history validation to require a numeric Expected Price greater than or equal to Starting Price; the current schema no longer treats Expected Price as nullable. Added source-contract regression coverage.
- Added forward migration `20261119690000_prevent_duplicate_pending_auction_submissions.sql`: owner-scoped pending-title index plus a database trigger that takes a transaction advisory lock and rejects duplicate normalized pending auction titles across inserts and edits/resubmissions. Added `tests/auction-duplicate-pending-submission-guard.test.ts` and registered the migration.
- Clean-install inventory: **137 forward + 16 excluded = 153 timestamped SQL migrations**. Updated the clean-install README counts.
- Commits: `a3a0b7c799f7f2bab7f08351a53a614239712c41` (NOT VALID constraint compatibility); `744bd117f0aa7d949db0aad85fe1216d5a413099` (Member auction form/history contract); `95b9281e5fcaaa6cce27a8b6a8fe5fe65859f220` (database duplicate pending guard).
- Source-only development: no tests/build/type-check, database replay, TEST or Production writes, or Preview publish were performed. `main` was not changed.
- Overall source development estimate remains **95% provisional**; final module-wide RPC/schema/RLS reconciliation and remaining source gaps are still open.


## 2026-11-20 — Expected Price already reached at auction start

- Continued source-only lifecycle reconciliation after inspecting `apply_auction_expected_price_deadline()`: its trigger fires only on `UPDATE OF current_price`, not on initial auction insert. Therefore an auction whose Expected Price equals Starting Price would otherwise miss the 48-hour countdown at creation.
- Corrected `20261119680000_admin_auction_submission_expected_price_review.sql`: when Expected Price equals Starting Price, approval now sets `target_reached_at` to the later of the scheduled start and current time, and sets `ends_at` exactly 48 hours later. Auctions with a higher Expected Price remain open-ended until bidding reaches the target. The submission history stores the derived deadline.
- Expanded `tests/admin-auction-submission-expected-price-rpc.test.ts` source assertions for the equal-price lifecycle. No tests were executed.
- Commit: `a3b4dcf47685e9bdd9b4f94209c62b0c2beb70b4`.
- No migrations applied, no TEST/Production changes, no Preview publish, and no main-branch changes. Source development remains 95% provisional.

## 2026-11-20 — Fixed Bid card and details experience

- Reworked Fixed Bid cards to show a single-line campaign title and product subtitle, a Product Details link, entry amount, percentage progress bar and prominent BID NOW action. Full details open in a responsive dialog with the complete published product attributes and all approved gallery images.
- Extended the restricted public catalogue RPC projection to return the approved product image gallery and product details, plus a percentage-only campaign capacity indicator. The response does not expose raw entry or participant counts. Existing secure member entry RPC and feature controls remain unchanged.
- Added source migration `20261120100000_public_fixed_bid_card_details_and_progress.sql` to the clean-install forward manifest. Source-only: no migration was applied and no tests/build/browser QA were run.
- Updated clean-install inventory: **138 forward + 16 excluded = 154 timestamped SQL migrations**.

## 2026-11-20 — Auction card visual refresh

- Refined the homepage Auction cards to match the clean Fixed Bid card system: single-line auction title, compact category subtitle, Auction Details link, prominent current-bid amount, time label, target-progress bar when an Expected Price exists, and a large gradient PLACE A BID action.
- Preserved the existing auction details dialog, live/scheduled state handling, bid eligibility checks, and server-side bid workflow. No auction schema or database changes were required.
- Added static source-contract assertions for the card hierarchy, progress indicator and bid action. No tests/build/browser QA were run during the development-only phase.

## 2026-11-20 — Auction item awards and homepage Winners

- Corrected Auction finalization: the highest eligible bidder is recorded as the winner and awarded the listed item. Auction finalization no longer creates a separate `winning_item_payments` record or returns a winner-payment obligation. Fixed Bid campaign winner-payment flows remain unchanged.
- Added a restricted public read RPC for recent finalized Auction winners, exposing only auction title, listing image, display name, winning bid amount and finalization date. Homepage shows responsive Recent Winners cards only when real winner records exist; no sample winners are invented.
- Auction winner-payment notifications are excluded; Fixed Bid winner-payment notifications remain active. Historical Auction payment records, if any, are not deleted or modified by this source migration.
- Added static source-contract assertions and registered migration `20261120110000_auction_item_awards_and_homepage_winners.sql`.
- Commit: `20fc530cea4e171bc3502ad23d49b63c7e6d3bb4`. No SQL was applied and no tests/build/browser QA were run.
- Clean-install inventory: **139 forward + 16 excluded = 155 timestamped SQL migrations**.

## 2026-11-20 — Member team terminology

- Updated the member navigation label from **My Network** to **My Team**, changed the section heading to **My Team**, and renamed **My MLM Dashboard** to **My Team Dashboard**. Updated administrator-facing overview diagnostics to use Team terminology.
- Internal RPC names and database identifiers were intentionally preserved for compatibility; the change is to user-facing wording only.
- Commit: `f405d2ae85038b204cc769cb86f75d94560cfdb1`.


## 2026-11-20 — Admin Auction submission media path and retry hardening

- Tightened Admin Auction queue validation so every private image path must match the submitting member UUID folder and the exact UUID-based JPG/PNG/WebP object naming used by the member uploader. Malformed or cross-member paths are rejected before signed-URL generation.
- Tightened persisted cleanup recovery by validating private and public paths against their respective bucket contracts, including the SQL-approved public auction image filename format. Invalid persisted entries are discarded rather than passed to Storage deletion.
- Added a ref-backed single-flight lock for cleanup retries so rapid duplicate taps cannot issue overlapping delete requests or race the review action.
- Extended `tests/admin-auction-submission-media-cleanup-recovery.test.ts` with source-only assertions. No tests/build/type-check were executed.
- No SQL migration was needed; no database was accessed, no Preview deployment was created, and `main` was not modified. Development remains 95% provisional.


## 2026-11-20 — Admin Main-ID lifecycle / financial-action serialization

- Added `20261120200000_serialize_admin_main_member_lifecycle.sql` after finding that member Fixed Bid, withdrawal and winner-payment RPCs used a per-Main-ID advisory lock but Admin Main-ID status changes did not.
- Admin Main-ID status changes now acquire the exact shared lock before taking the Main-ID row lock or changing Main ID, Profile and linked Duplicate ID statuses. A member financial action therefore completes before the lifecycle mutation, or rechecks eligibility after the mutation and rejects.
- Preserved the graph-wide lock, Admin-only role check, lifecycle validation, linked Duplicate-ID propagation, audit event and authenticated-only function grant.
- Added `tests/admin-main-member-financial-lifecycle-serialization.test.ts`; source-only and not executed. Registered the migration in the clean-install forward manifest.
- Inventory: **148 forward + 16 excluded = 164 timestamped migration paths**, plus 3 legacy/unversioned SQL files. No DB replay, tests, build, type-check, deployment or Production/TEST changes.


## 2026-11-20 — Admin withdrawal review lifecycle serialization

- Added `20261120210000_serialize_admin_withdrawal_review_lifecycle.sql` after finding Admin withdrawal review did not participate in the shared Main-ID lifecycle/financial-action advisory lock.
- Approve, reject/release and mark-paid now acquire the same per-Main-ID transaction lock before active-profile/Main-ID validation or wallet reservation/release/payout confirmation. This serializes review with member financial actions and Admin Main-ID lifecycle mutations.
- Preserved Admin authorization, request state validation, reservation/release ledger consistency checks, immutable ledger behavior and audit logging.
- Added `tests/admin-withdrawal-review-lifecycle-serialization.test.ts`; source-only and not executed. Registered the migration in the clean-install forward manifest.
- Inventory: **149 forward + 16 excluded = 165 timestamped migration paths**, plus 3 legacy/unversioned SQL files. No DB replay, tests, build, type-check, deployment or Production/TEST changes.


## 2026-11-20 — Notification inbox recipient ownership validation

- Found that `parseNoticePage` already supported an expected member user ID, but the member inbox never supplied it; the realtime handler also trusted the subscription's user filter without independently checking row ownership.
- Member first and subsequent pages now validate each notification's `user_id` against the authenticated session. Realtime INSERT and UPDATE events perform the same owner check before changing the inbox. Admin history continues using its Admin-only recipient projection.
- Added source-only regression assertions in `tests/notifications-response-integrity.test.ts`; not executed. No SQL migration was required.
- No tests/build/type-check, database access, migration replay, deployment or `main` changes. Production and TEST remain untouched.


## 2026-11-20 — Notification realtime payload integrity

- Realtime INSERT and UPDATE events now pass through the same complete notification-row validator used by paginated inbox responses, including UUID-independent identity presence, recipient ownership, required text fields, timestamps and optional Admin recipient fields.
- UPDATE events remove an existing loaded row when it no longer matches the active category/unread filter instead of leaving stale filtered results. DELETE events validate the ID and reject an explicitly mismatched member recipient when the old row includes user ownership metadata; minimal DELETE payloads remain compatible with the already owner-validated member inbox.
- Extended `tests/notifications-response-integrity.test.ts` with source-only assertions for full realtime validation and DELETE ownership. Not executed. No SQL migration or database operation was needed.
- No tests, build, type-check, E2E, deployment, Production access or TEST access were performed. `main` was not modified.


## 2026-11-20 — Support history, pagination and export owner integrity

- Strengthened the shared Support ticket row validator to enforce database UUID identity types, authenticated member ownership, subject/message/admin-response length constraints, supported status values and valid chronological timestamps.
- Initial member history and keyset continuation pages now validate every returned row against the authenticated user ID in addition to the existing owner-scoped query and RLS. Admin reads retain the separate Admin queue contract.
- CSV export validates every page against the authenticated member ID before any export is generated; Admin export remains unfiltered by member while still validating all ticket fields. Malformed or cross-owner records fail closed.
- Extended source-only regression coverage in `tests/support-pagination-integrity.test.ts` and `tests/member-support-inbox-owner-scope.test.ts`. Not executed. No SQL migration was required because the checks mirror the existing support table constraints. No database, TEST or Production access/writes, build, type-check, E2E or deployment.
