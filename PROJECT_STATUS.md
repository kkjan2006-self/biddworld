- **Member withdrawal pagination now preserves payout-data privacy:** the paginated history RPC returns only the payout method label, matching the older history endpoint; UPI IDs and bank account numbers are not sent to the member client. Migration `20261120190000_minimize_paginated_withdrawal_payout_data.sql`; source-only regression test added (not executed).
- **Income Wallet Add Money now requires an active profile and active owned Main ID:** the submission RPC locks both eligibility rows and rejects inactive/suspended profiles before creating a funding request. Migration `20261120180000_require_active_profile_for_wallet_funding.sql`; source-only regression test added (not executed).
- **Global UTR uniqueness enforced across Package Activation and Income Wallet Add Money:** shared transaction advisory lock and reciprocal database trigger checks close the concurrent cross-workflow duplicate-reference race. Source-only regression contract added (not executed). Migration `20261120170000_global_payment_reference_uniqueness.sql`; commits: `03d088b9`, `ec1176d9`, manifest `bbabbdb2`, clean-install inventory `ae3f3915`.
- **Matrix auto-post / Staff activation integration fixed:** when Matrix auto-post is enabled, a restricted Staff package approval now invokes a private internal posting routine instead of the Admin-only public RPC. Manual posting remains Admin-only; ledger idempotency and actor audit attribution are preserved. Migration `20261120160000_matrix_staff_activation_auto_post.sql`, source-only regression contract added (not executed). Commits: `6f1138f4`, `5769c235`, manifest `49bd906f`, clean-install docs `ed634408`.
- **Member Product/Auction media ownership and cleanup concurrency hardened:** history response paths and persisted cleanup queue entries now follow the SQL owner-folder/safe-filename contract; submission UUIDs validated before signed URL creation; manual cleanup retry is single-flight and blocks overlapping submission. Source-only assertions added, not executed. Commits: `27fb0f61`, `ab9d08c9`, `302aa7c8`, `bc44e938`, `59e87091`, `9820e23b`, `699f4654`, `fb45df05`, `d344a6a4`, `caa5afce`.
- **Cross-workflow upload failure recovery improved:** Package/Income Wallet receipts and Member/Admin Product/Auction image paths are tracked before upload, so ambiguous pre-RPC upload failures can be removed or queued; ambiguous RPC outcomes continue to preserve potentially referenced media. Source-only assertions added, not executed. Commits: `9c5b1386c59dd0c5180421059446e6486a430e7f`, `eee871cb3613819217bacac0360080c106279f32`, `358678ef67a40c9e3fcc604bc569e79a616eb0a5`, `419608458dce9762e1c49fc21a0cc43363252548`, `49227047f56f492605efc13f05b0449444afe36c`, `ce0f7447763cf02a7c37d7296ca04dd6fd8a7501`, `de4cebc4db9e642e3217a45d71f6f24ecf5196d9`, `476819612bd9bba0e3958d9aca46467d8e4b6200`, `0751d2d6c1562c3d7cdf38f75b147bd8a749b88b`, `623e0ca93b5110114b799bd037adaacbb7b6c214`.
- **Admin Product moderation media cleanup made persistent:** failed cleanup after definite rejection/pre-RPC failure is saved in an Admin-scoped, 100-item queue with UUID-path validation and manual retry; ambiguous outcomes preserve potentially published images. Source-only test added, not executed. Commits: `cead67a3ded060b9b12bc9235d900bc5d344b111`, `199c0dd3632ef899ab8635b67df7bf3fcf61d17e`.
- **Wallet History, Admin templates and Member submissions hardened:** Wallet History validates to-one wallet embeds and Matrix source rows, chunks CSV source lookups at 200 IDs; Admin template save validates response identity/state; Member Product/Auction create/edit validates returned submission UUID and edit identity. Source-only tests added/extended, not executed. Commits include `7a922ce001104572b57dc1d7f5f624bcc54c6f04`, `31f62d03442779188fdb1443d4d278c5d0387f35`, `13d95f206a3df00fa1a0311a3546d557780fde72`, `e605c0a52bcbaef19bee8250246a248b6227c780`, `ad4e0b1d902d8ffac02c6d4925fcada26608e8dc`, `b3dde02738809092f91bde7c281915fe30e2573c`, `87c28b20e31f00021c1f78ccd762881c0c6e6bf3`, `2898d7f860155ffe9c9295c0f26e7301ff2356ca`, `f919142b5eeb4987e475005182ba9b00aa90a3df`, `969e4d6e745821f224d9c94c0ebd063e580b8c19`.
- **Member Product/Auction moderation responses hardened:** Product approval validates returned Product UUID and image count; Auction approval validates Auction/Product UUIDs, exact Expected Price and the SQL 48-hour deadline result before clearing edits/reporting success. Rejection validates exact status. Regression assertions added, not executed. Commits: `784ffadc2d5c13efd8d3defb470300a81f98f54a`, `c6ac457b270020f68f865faf4571fd48d242b8be`, `8cf9f9be74dbcdd2b9997a9186b7b6bff0730e45`, `c343b69c4f4a8f5f0252c083603a20c3c504f2bb`, `61232cbc336a9c615fa232ba28f7d42c0fee31a8`.
- **Matrix commission report pagination hardened:** report pages enforce the 100-row bound, numeric values and consistent required continuation flags; short pages cannot falsely advertise more records. Source-only assertions added, not executed. Commits: `1181160082b9beed61aab4997c1a85fb0dad73eb`, `acbda135266e73a7db4bf6f5694b50f67a05c65c`.
- **Support CSV export integrity hardened:** every fetched page is validated as a bounded array of complete ticket records before inclusion; malformed rows stop export. Source-only regression assertion added, not executed. Commits: `ddaccad3adfbefc7a179391676891073450100f2`, `e3edc898d4663fff5c36eacf219a73c7881a4127`.
- **Income Wallet receipt recovery hardened:** failed deletion of definitively rejected Add Money receipts is persisted in an account-scoped bounded queue, constrained to the member's wallet-funding folder and retried automatically/manual. Submission validates request UUID/status before form reset. Source-only test added, not executed. Commits: `e358c49f5d0548464f9c5d5e1623b9d2f472fe0f`, `fa3ec1bc625873d41033b9c59a2314ffcbcfc97d`, `4ff0f6dd2be9752d02106b858822da35b9539158`, `d5aec083791ad55211af2aa6187a00a25edda321`, `59442583d6f841152122c641d1fad65d90913b9d`.
- **Member package activation RPC response hardened:** exact activation UUID/number, pending statuses and receipt path are now validated before form reset; malformed/ambiguous outcomes retain the receipt and prompt history refresh. Added source-only regression test, not executed. Commit: `fd71c4cddcf00c001031642ee32d01a166dc0f4e`, `ae07e031cb06795ffd08974154a57610c3dd70d1`.
- **Package catalogue and receipt recovery hardened:** Member package catalogue RPC rows are validated before rendering; failed cleanup of definitely rejected package activation receipts is persisted in a verified user-folder queue and retried on revisit or manually. Source-only tests added, not executed. Commits: `313dc351a9d780e43fc99fa041850ec16ce4f576`, `c666ad90840ae7085869253af58e299467d13798`, `e08751bf84f73818eb1177526e1532691124ab74`, `3afa7a3471f7e2080d3dc11d6775d974a37563c8`, `c3233b96d80524448ecd06265251792112279e92`, `208a988581e0916fa87d375ab9e2cf5d0d992e14`.
- **Matrix plan mutation integrity hardened:** Admin Matrix plan draft saves and activations now validate exact server-returned identity/configuration; directory parsing rejects duplicate version numbers, multiple active versions and fixed rewards beyond the SQL ceiling. Package switching is locked during mutations. Source-only regression assertions added, not executed. Commits: `e8a2a765a8bc86f2aa8ee344eb9d358a68c3d501`, `c40d5e204c1cb4eccdc61ca6c0f80de8de04ef16`, `06563b74624055556dba3095d40e8584979a02f1`.
- **Staff grant response/SQL mismatch fixed:** the Staff grant RPC persisted three permissions (Package Activation, Income Wallet Funding, Auction Submission) but returned only two. Added `20261120150000_align_staff_grant_response_permissions.sql` so the response exactly matches persisted permissions and the UI validation. Registered in clean-install manifest (143 forward migrations). Added a regression assertion; not executed. Commits: `12681db2cb9d0c91adf9d3d16e2e19baf9119203`, `b1f72cca0e01b039f606678fe18c9ebeaa63b2a0`, `249b70ca6592bf7f11cc39645d9bbbc9a0625e5e`, `518e5156f46100b4f810a423083fb62056b0062a`.
- **Restricted Staff + Notifications contract alignment completed:** Staff grant/revoke response validation now matches the SQL default permission set exactly (Package Activation, Income Wallet Funding, Auction Submission); individual permission edits validate account identity and exact selected permissions. Updated Staff portal labels from legacy “Main Wallet” to “Income Wallet”. Notification recipient lookup validates bounded UUID/member rows, and delivery only clears its idempotency key after a valid notification UUID/replay response. Added regression assertions; not executed. Commits: `67759a013ad00b5d47a35bb700fbb504dd73bdd9`, `616a72bc30833e0c3b3fc688b40d8ea356fcdb14`, `6fd53920`, `444f4f91`, `d746bbf7`, `79b0c624c179fbd66d132c980a2ab6fe6666701b`, `48631bc22dbba619041c7be0a9720b3922b671a7`, `a9a528eb012d3c9c77853a267ed4601eb3c74958`, `2611c414f62373c311bcf3e73ee76cee9447716b`, `b8a222ad7d1ebaeadf289cf898454b07175fc476`, `da6e31a5b605e0f04511e5935ad419a4158609fe`, `8ca17618a4857f3635bfcfd382b692acb9fca3a2`.
- **Restricted Staff and notification workflows hardened:** Staff grant/revoke now validates target email, resulting role and exact returned permissions; permission edits validate Staff identity and the exact selected permission set. Restricted Staff package activation review validates approval/rejection status and Bid Wallet credit/balance. Admin notification recipient lookup validates each Main ID result and the 25-row cap; notification delivery validates success, notification UUID and replay flag before clearing the idempotency key. Corrected the Staff wallet-review label to Income Wallet. Added `tests/staff-notification-mutation-response-integrity.test.ts`; source-only, not executed. Commits: `67759a013ad00b5d47a35bb700fbb504dd73bdd9`, `616a72bc30833e0c3b3fc688b40d8ea356fcdb14`, `6fd53920e560c54f585b155a8700f5e7506158a0`, `444f4f91232c320317da05d4249f385b71ec90fa`, `d746bbf766395c219b983e3a68b96b5f5fb9f79f`.
- **Admin Product/Auction draft contracts hardened:** Product draft save validates returned Product UUID and edit identity; Product publication validates success, Product ID and exact published/draft state; Auction draft save validates returned Auction UUID and edit identity before clearing the form. Added `tests/admin-product-auction-draft-response-integrity.test.ts`; source-only, not executed. Commits: `bce4924ebce433967a64ca7d104ee85fa8982eda`, `5620eb00ba6248062abb2aa21983b5f805ad10a0`.
- **Additional Admin mutation contracts completed:** package activation review validates approval/rejection status and Bid Wallet credit/balance; minimum withdrawal settings validate the saved amount; referral-plan draft save validates plan ID/version/inactive state/level count/depth; delivery tracking validates returned UUID and exact existing tracking ID before clearing the form. Added `tests/admin-secondary-mutation-response-integrity.test.ts`; source-only, not executed. Commits: `520d35f920b052ce0268919c6a1e06d40b792f6d`, `97495b39a6b8b89fc18393d5c2a9c54bb633a28d`.
- Follow-up error-state refinement: withdrawal submission now preserves the actual server/validation error instead of labelling every malformed response as a network failure; Admin Add Money review translates legacy SQL “Main Wallet” error wording to “Income Wallet”. Commits: `45f91041a3c656e9a5a7b0586bc1ed01298f1193`, `0e2b8e3725215fade4e39bf0215e5bc865e7774f`.
- **Auction / Fixed Bid Admin mutation responses hardened:** Fixed Bid draft save now validates the returned campaign UUID (and preserves the existing ID when editing) before clearing the editor; Fixed Bid status changes validate campaign ID, requested status and refunded-entry count; Auction status changes validate success, auction ID, requested status and refunded-bid count. Added `tests/admin-auction-fixed-bid-mutation-response-integrity.test.ts`; source-only, not executed. Commits: `35d93630d52a6b85d0a992a0f0b67505627ca549`, `7430ee2e13cda5aad5282a0a8b82c1630a5d189e`.
- **Auction winner payment rule enforced end-to-end:** the winner-payment RPC now rejects new payments for records without a Fixed Bid campaign link; historical paid ledger replays remain idempotently readable. Member history only displays the Pay from Income Wallet action for Fixed Bid winners; pending Auction records explicitly state that the item is awarded without a separate payment. Added `20261120140000_restrict_winner_payment_to_fixed_bid.sql` to the forward manifest and extended `tests/member-workflow-mutation-response-integrity.test.ts`; not executed. Commits: `2d2628591f76fce4ba4ce22725d3fdf7fa8c505c`, `129c1a292b8c9a401625e817c9179828cad5e661`, `ab881865802fb5e4a3a6ae836968a714221fb044`, `699b60dd996b36605fc34828afb628e6533e3ab0`.
- **Member/staff workflow mutation contracts hardened:** Fixed Bid entry now validates entry identity, total amount, Bid/Income Wallet debit split and replay flag before clearing its request key; winner-payment validates payment identity/status/replay and Income Wallet balance before clearing its key; withdrawal creation validates request identity/status; member profile and support ticket submit/update responses are validated; Add Money submission and Admin review validate their response before confirming success. Corrected member/Admin wallet labels from legacy “Main Wallet” to “Income Wallet” wherever the actual wallet type is `income`. Added `tests/member-workflow-mutation-response-integrity.test.ts`; source-only, not executed. Commits: `4c2017d70f68cfcc9fbdc564b74658d9f31063fc`, `f2cc4a580f9ae58133c6524530955956fbd0cd37`, `7a10458c5a61c476234696c593b7b1b8c3325fbb`, `030415b2711ca80ec4b41efcd6b6f4c86f30ae58`, `19893ba84c66645cf7eba831f3db4a2ea8cf80b6`, `6bc5aeebdbdc73093432b0b80c0c05d2f74c6b08`, `8ba1f5475df0c7a734a3b1eb40691650931d20c5`, `699c732b34f0f017993cfeb254d5731ad9d340f4`, `3cdac6f9f550f6a6caac6a3301d3b901e7349320`, `9960ffee7b62884fc7e2df92731a3d8a2dda71ec`, `349dcd58e21b881124278c44c57f1cd1d0be5c96`.
- **Additional Admin mutation RPC response contracts hardened:** withdrawal review now verifies the returned request ID and action-specific status and correctly labels the reserved/released funds as Income Wallet; Primary Admin role changes verify returned user/email/role; member profile edits verify identity, submitted name/phone, changed flag and timestamp before updating local state; package publication verifies package ID/state; referral-plan activation verifies plan/version/level count. Added `tests/admin-mutation-response-integrity.test.ts`; source-only, not executed. Commits: `85bae1ab125e7beb912b1e77086ea8d540253cef`, `450afd35be20f35946adae8b81ca3a0e1bbf8eb1`.
- **Admin wallet adjustment idempotent replay repaired:** a retry using the same request key previously returned only `success/adjustment_id/replayed`, while the UI treated the missing `balance_after` as zero and cleared the retry key before validating the result. The forward SQL migration now returns the full original adjustment result, including the immutable original ledger `balance_after`, on replay. The Admin client validates success, adjustment ID, member identity, wallet, direction, amount, balance and replay flag before clearing the key; ambiguous/invalid results retain the same key. Added `tests/admin-wallet-adjustment-response-contract.test.ts`; source-only, not executed. Commits: `1319b0f9f9c4a5ba516d293ff3f1ef390fcfb5ee`, `1b4d6e7b33a36b0c8a42593f57dd1f30af1c1065`, `c66aa3e84c8b41fcd141e29bca8933b3b5125ec0`, `73225a2fac62fa34d619abccf8f12e2b000378f9`, `5e48e5cffc1d744f1fcddec3e991b091bd289923`.
- **Duplicate ID lifecycle mutation responses hardened:** Admin now validates the returned Duplicate ID, canonical member code, requested status, previous status and the SQL `changed` flag before showing success or refreshing. The no-op replay shape (`changed=false` only when old status already equals requested status) is explicitly enforced. Added source-only assertions in `tests/admin-duplicate-id-lifecycle-security.test.ts`; not executed. Commits: `205898b1899c1a4337673472c953b6d0cb691698`, `5a718f1a649644c075c8e30a1613ec7ee3803609`.
- **Admin Main ID status mutation response hardened:** the client now requires `success=true`, the exact submitted Main ID (case-insensitive canonical comparison), the exact requested status, and a non-negative integer linked-Duplicate-ID change count before showing success. This matches the latest `admin_set_main_member_status` response, including idempotent/reconciliation retries. Added source-only response-integrity assertions; not executed. Commits: `808bf9a9bcf6109837a320c5cb172f1ec0e77645`, `446f6afaf467e8ad6063abec809a383fb63fbb92`.
- **Admin Main ID lifecycle messaging corrected:** Member Details now accurately explains the implemented audited status action and linked Duplicate ID reconciliation instead of saying the workflow is still pending. Added source-only assertions to `tests/admin-main-member-status-mutation-safety.test.ts`; not executed. Commits: `d6981da16c05ad09db2401023ae430c2c32705a1`, `0aa6c0dc3389342fbe4be5cd7aa0573ca4341f97`.
- **Admin Main ID lifecycle RPC contract repaired:** source inspection found the Admin form offered `active / suspended / closed`, and SQL `admin_set_main_member_status` accepts those exact values, but the client-side guard incorrectly allowed `inactive` instead of `suspended`. The UI could therefore never submit the visible Suspended choice. Updated the guard to match the SQL contract and expanded `tests/admin-main-member-status-mutation-safety.test.ts` with UI/SQL enum alignment assertions. Source-only; test not executed. Commits: `432de61aa9103d0db85ef8a0552fbec5d6d5734f`, `3abb51231f118c1e38c29eb09d714f0f62861f53`.
- **Admin product media cleanup now survives page reloads:** temporary `product-media` objects that fail deletion are persisted in account-scoped browser storage, restored only for the authenticated Admin account, validated against the generated UUID-prefixed object-path format, capped at 100 entries, and removed from the queue after a successful retry. In-memory recovery remains available if browser storage is unavailable. Added source-only assertions in `tests/admin-product-media-cleanup-recovery.test.ts`; not executed. Commit: `1a0d63be3f8edd4e561c6021cf5784949d9868b3`.
- **Admin Auction Submission Review cleanup is now retryable and persistent:** failed deletion of private submitted images after approval and temporary public images after a definite RPC rejection are retained by bucket/path in account-scoped browser storage, restored with bucket/path validation, capped at 100 entries, and exposed through a Retry image cleanup action. Ambiguous RPC outcomes still do not delete potentially published media. Added `tests/admin-auction-submission-media-cleanup-recovery.test.ts` as source-only coverage; not executed. Commits: `3e89f0ded12dfa34380d2ac4d6831a91f462e87f`, `03ce3269951399a89d8046ded353b108c7a34181`, `9cf833a6927d4124d285f88f54afedd90988221e`.
- No tests/build/type-check, database access/replay, or deployment was performed for this batch. Production and TEST Supabase remain untouched.

# Current continuation checkpoint — 2026-11-20 (source-only, updated after latest user changes)

- **Member Product/Auction media cleanup now survives page reloads:** failed image-object removals and definite-rejection upload cleanup paths are persisted in account-scoped browser storage, restored only for the signed-in account, constrained to that account's storage prefix, capped at 100 paths, and removed from the queue after successful retry. In-memory retry remains available if browser storage is unavailable. Added/extended `tests/member-submission-media-cleanup-recovery.test.ts`; source-only, not executed. Commits: Product retry `667205ff0512076556394ac6e455d9da8478f3a0`, Auction retry `36b5253e30615411d35750cca51c902ce269470e`, persistence Product `49ef130bbb0b76aac4f6f2308c791de3ccf6ba80`, Auction `fdbd78a5292fcf3297222140144a5e3cee523a75`, test `3ea16cb108394d964053faf209b2c0deba82771c`.

- **Member Product/Auction submission media recovery:** failed removal of replaced draft images and definitely rejected upload batches is now retained in an in-session cleanup queue in both member submission screens, with a visible Retry image cleanup action. This prevents a transient Storage deletion failure from silently losing the paths needed to retry. Ambiguous network/RPC outcomes are deliberately not deleted because the submission may already have committed. Added `tests/member-submission-media-cleanup-recovery.test.ts`; source-only, not executed.

- **Commission reversal replay compatibility fixed:** the Referral and Matrix SQL RPCs intentionally return `success=true,status='reversed',replayed=true` without a commission ID when a previously reversed record is replayed. Admin clients previously rejected this valid idempotent response as a mismatch. Both screens now accept that exact replay shape (while still requiring the selected ID on first-time reversals and rejecting a conflicting ID), and show an accurate “already reversed; existing ledger state confirmed” message instead of claiming a new audit event. Extended `tests/admin-commission-mutation-result-integrity.test.ts`; source-only, not executed. Commits: `06d5685233b5fc4e02da766dbf965e8f9f15d151`, `350b78fe31fa3ba04548f57cb982ba165dc10acc`, test `938c09e7dc94727e10e1029feaa17a7c9c897308`.

- **Referral/Matrix commission mutation responses hardened:** Admin posting actions now require a JSON object with `success=true`, the exact requested activation ID, and a non-negative integer posted count; reversal actions require `success=true`, the exact commission ID and `status='reversed'`. Applied to both Referral and Matrix commission screens and matched the expected SQL return contracts. Added `tests/admin-commission-mutation-result-integrity.test.ts` (source only; not executed). Commits: `8bfefc3207b7fc497a55cbe8cd2249fd11d7e9f7`, `542d07d9ad61033c4a2a8948c6ebe30003e2104b`, test `6c1103d290c62816a29cf5db2aabc86dabfe69a5`.

- **Admin Product media cleanup recovery implemented:** when replacing an uploaded-but-unattached product image, failed removal of the previous object is now retained in a retry queue instead of becoming an untracked orphan. The Admin form exposes a Retry Temporary Image Cleanup action, reports outstanding cleanup, and clears the image URL/reference when a staged object is successfully discarded or retried. Added `tests/admin-product-media-cleanup-recovery.test.ts` as source-only regression coverage; not executed. Commits: `60623c211a2d4622c8bd78f1fc0603ae4ec10151`, `e19782e4de743b75b5463c9359be068295e79b99`, `4fa15a8b32036bc60d52608364440c849a3417a5`, test `317cf07de96ca7970245c1ad4a99b698e6d4a390`.

- **Member/Admin submission RPC reconciliation (source-only):** reconciled Member Product create/edit/history, Member Auction edit/history, Admin Product image publication, and all four Member/Admin product/auction moderation pagination call sites against their declared SQL signatures, result shapes, keyset ordering and grants. No argument-name/type or return-shape mismatch was found in this scoped batch. Added `tests/member-admin-submission-rpc-contracts.test.ts` to lock these contracts; it was not executed. This is a scoped reconciliation, not completion of the full project-wide RPC audit. Commits: test `5dff1102585f31abfb4e5814271be23bf062f719`, regex correction `9006ef30171c524eb5f597c262542fced55868ac`.

- Latest user-facing source updates are present on `completion-work`: Fixed Bid cards use a one-line campaign title and product subtitle, Product Details dialog with approved gallery images, entry amount, percentage progress and prominent BID NOW action; Auction cards use a one-line title/category, Auction Details, current bid, time/target progress and PLACE A BID; Homepage Recent Winners displays the auction item recipient and winning bid; member terminology is **My Team**.
- Confirmed the auction winner is awarded the listed item. Auction finalization no longer creates a `winning_item_payments` row; Fixed Bid winner-payment remains a separate workflow. The existing Admin winner/payment register is read-only.
- Latest Admin strict-TypeScript repairs inspected: commit `38fe63c0dd14427e65995826d0829232e7edb056`; Duplicate ID `has_more===true` narrowing repair: `4e34dc4f147434903643bd9f6717d18e488b90fa`. Preview Pages base path and `npm run build` (type-check + build) configuration are updated in the separate Preview repository; no new Preview deployment is claimed here.
- **New source defect found and repaired:** `20261120110000_auction_item_awards_and_homepage_winners.sql` joined `member_ids.user_id`, but the canonical schema baseline defines `member_ids.owner_user_id`. This would make the public Recent Winners RPC fail on the candidate schema. Added forward migration `20261120120000_fix_recent_auction_winner_profile_join.sql` to replace the RPC with the canonical ownership join, preserving bounded output, profile-active filtering, and anon/authenticated execute grants. Added source-only contract test `tests/recent-auction-winner-profile-contract.test.ts` (not executed).
- Clean-install forward manifest has **143 unique forward entries** plus **16 excluded timestamped entries**. Static source-tree accounting confirms 162 SQL files total when the 3 intentionally excluded legacy/unversioned files are included; no timestamped SQL file is missing, stale or duplicated in the two manifests. Dependency/order validation remains separate and pending.
- Fixed Bid catalogue parsing now validates bounded unique campaign rows, lifecycle status, timestamps, numeric rules, 0–100 progress, and approved product gallery/detail shapes before rendering. Added source-only contract coverage in `tests/fixed-bid-catalogue-integrity.test.ts`; commits `0e8225d9743be1beff2676cbd25167a1a7f2c7be`, `1dfa9318a51decde760a5565abbc33e03fdb38ff`, and `edfb04123ba3f77ae4adc1a8d3724be1e53886bb`.
- Member Product submission now prevents the free-form Additional Features field from overriding the validated structured fields (especially numeric Price) by case-insensitive reserved-key filtering. Added source-only coverage in `tests/member-product-submission-details-integrity.test.ts`; commits `799cd1c052835cff5b2a2521c167aa2606753e55` and `9714f81fe96b622e75573b58c72385945d58769c`.
- Member Auction submission now applies the same case-insensitive reserved-key protection to Brand, Model, Condition, Age, Warranty, Ownership and Location fields so Additional Features cannot overwrite structured fields. Added source-only coverage in `tests/member-auction-submission-details-integrity.test.ts`; commits `c24610c5df0d2d0ee961fee6760418801b2d0b3a` and `822a5e03767acbaebafc3351bc8ac57d297ec079`.
- No unit tests, build, type-check, browser/mobile QA, Supabase access, migration replay, or Preview deployment were run. Production and TEST Supabase remain untouched.
- Remaining development: finish complete Frontend RPC-to-migration signature/return/authorization reconciliation; reconcile baseline schema, migration dependency order, RLS/ACL/Storage final state; continue cross-module Admin/Member workflow and retry/error-state source review; reconcile docs to the current branch.
- Overall development completion: **95% provisional**. The new RPC/schema mismatch repair is source-only; 100% is not claimed until all remaining source reconciliation is complete.

---

# Current continuation checkpoint — 2026-11-20 (source-only)

- Re-read this file and `docs/PROJECT_COMPLETION_REGISTER.md` against the current `completion-work` source files before continuing. Protected `main` was not written. No Supabase project was accessed or changed in this batch.
- Confirmed the current forward migration manifest contains **139 unique ordered entries** and the excluded historical manifest contains **16 unique entries** (155 listed migration paths total). The clean-install README and earlier checkpoint documents still contain stale 137/124 counts; repository-wide migration-file accounting and dependency validation are not yet complete. Do not describe the 155 manifest entries as a verified complete source-tree inventory.
- Confirmed the current frontend includes the Admin product image URL/storage-path helper, member auction submission preflight (trimmed title/description, 1–8 image bounds, MIME/5 MB validation, positive prices, Expected Price >= Starting Price, start-time validation and duplicate-submit lock), and the homepage Recent Winners cards.
- Confirmed migration `20261120110000_auction_item_awards_and_homepage_winners.sql` finalizes the highest accepted auction bid as an item award and exposes recent winners. Auction winners do **not** enter the Fixed Bid winning-payment flow; that notification trigger explicitly ignores auction-linked records.
- Preview repo README documents the GitHub Pages permission error correctly: enabling Pages through the workflow token is owner-only. The workflow already uses isolated TEST secrets and fails closed when they are missing or point anywhere other than the TEST project. Preview workflow source is `.github/workflows/deploy-preview.yml`; no new deployment or live backend functionality is claimed.
- Admin product image JSX and URL helper were inspected. The existing code supports both absolute HTTP(S) URLs and product-media object paths; no safe, evidence-backed defect was identified to justify changing the rendering contract in this batch.
- Remaining source work: complete frontend RPC signature/return/authorization reconciliation; reconcile the schema baseline, every migration file and clean-install dependencies; finish any cross-module workflow gaps and static contract coverage; correct stale documentation. Development-only gate remains in force: no tests/build/type-check, no migration replay, no DB access, no Preview deployment.
- Overall development completion: **95% provisional**. This is a planning estimate only; 100% is not claimed until the remaining source reconciliation is complete.

---

- Restricted Payment Review Staff directory now enforces a bounded response, validates account identity/email/timestamps and unique allowed permissions, rejects malformed or duplicate permission drafts, and prevents overlapping role/permission mutations with a reliably released in-flight guard. Existing Primary Admin gating and server-side staff RPCs are preserved.
- Added source-contract regression coverage in `tests/admin-payment-review-staff-integrity.test.ts` (not executed).
- Commits: staff hardening `1c9940fb3cc2ec325a111379e443dacbfae9f0ba`; mutation-lock correction `a5d0c69cf8d6607ee92e412572dea8bffc774030`; regression source `32108e188b6ccdfabe6b4fa6abc9b9f141a3cadc`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production database reads/writes/migrations, no Preview deployment, and no protected `main` changes.

- Admin dashboard overview, member-structure report, notification templates and Admin account directory now validate bounded response shapes, numeric counters, unique identities, ID ownership, summary consistency, supported notification channels, required email subjects and timestamps before rendering. Invalid module data is isolated and surfaced without changing existing Admin role or notification mutation RPCs.
- Added source-contract coverage in `tests/admin-overview-notification-role-directory-integrity.test.ts` (source only; not executed).
- Commits: Admin parser hardening `bb3d0d40ee73f660f80af765a5933e3e1e27f0d0`; regression source `d310947620018601e8ffc946deaa4c7ab35c84ec`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production database reads/writes/migrations, no Preview deployment, and no protected `main` changes.

# Current development checkpoint — 2026-11-19

- Active branch: `completion-work`; protected `main` unchanged.
- Admin Auction Submission Review now loads 50 rows per page through a server-side keyset RPC, with a 100-row backend cap, stable `(created_at,id)` cursor and Admin/authorized Staff permission enforcement.
- Admin pending package activation review now loads 50 rows per page through a new Admin-only keyset RPC (100-row backend cap), stable descending `(submitted_at,id)` cursor, strict page/identity/cursor validation and stale-request protection; private receipt links and the existing approval workflow are preserved.
- UI validates response shape, required IDs/timestamps/image paths, cursor completeness and duplicate IDs; it signs private image URLs only for the current page and supports Load More/refresh with stale-request protection.
- Added migration `20261119400000_admin_auction_submission_keyset_pagination.sql` and registered it in the clean-install forward manifest. Existing approve/reject and image-publishing workflow is unchanged.
- The forward manifest now lists 110 candidate migrations plus 16 excluded historical migrations (126 listed timestamped entries); repository-wide exact file-accounting tests remain deferred and unrun.
- Admin Referral Commission Register now validates page records and metadata, blocks overlapping/stale Load More requests and isolates malformed commission responses from other Admin modules. Existing posting/reversal RPCs are unchanged; offset pagination remains and no keyset migration was introduced.
- Previous batch: Admin Main Wallet funding queue pagination, backend cap, receipt checks and contract coverage.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production migrations/data writes, no Production reads, no deployment, and no protected `main` changes.
- Next bulk focus: remaining Admin operational workflows, review other offset-based queues for mutation/race risks, complete Preview source synchronization after the required TEST migration is explicitly approved/applied, and continue baseline/RPC/RLS/Storage integration review; final testing remains deferred.
- Overall development completion: **71% provisional** (not runtime verified).

# Current development checkpoint — 2026-11-19

- Active branch: `completion-work`; protected `main` unchanged.
- Admin Main Wallet funding review now uses a server-side keyset-paginated RPC (50 rows per UI page; backend hard cap 100), stable `(created_at,id)` cursor, duplicate/malformed page rejection and short-lived private receipt URLs.
- The legacy no-argument pending-funding queue RPC is also capped at 100 rows, preserving its response shape and Admin/authorized Staff permission check.
- Approval/rejection remains through the existing locked, audited RPC. Approval still requires a receipt URL to be available in the UI; no wallet posting logic was changed.
- Added migration `20261119390000_admin_wallet_funding_queue_keyset_pagination.sql`, UI pagination and `tests/admin-wallet-funding-keyset-pagination.test.ts`; registered the migration in the clean-install forward manifest.
- Manifest reconciled against repository tree: **124 timestamped migrations = 108 forward + 16 excluded**; no missing, stale or duplicate timestamped entries.
- Commits: migration `3532bb20c3e67330308dee83f684e2e430b8b8e8`; UI `fc803d60bfebeca0dce3f8e9c11e0f7417045df1`; source-contract test `2b7907ae310afb1adb8ff392a49b9dc5d27a753e`; manifest `1707134b46d7391e95507da8362d9068fceb5997`; inventory README `69c85d4787a63196ca63d6b8458276d2aaf8d6ab`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production migrations/data writes, no Production reads, no deployment, and no protected `main` changes.
- Next bulk focus: package activation review queue and other Admin operational queues for bounded pagination and response validation; final testing remains deferred.
- Overall development completion: **70% provisional** (not runtime verified).

---

# Current development checkpoint — 2026-11-19

- Active branch: `completion-work`; protected `main` remains unchanged.
- Bulk source reconciliation reviewed the current Admin/Member workflows, Main/Duplicate lifecycle, feature-switch locking, automatic Matrix placement, Matrix commissions, Sponsor-vs-Under ID separation, wallet history/funding, auctions, Fixed Bid, notifications and Support.
- Clean-install inventory is now reconciled exactly: **123 timestamped migrations = 107 forward candidates + 16 excluded historical migrations**; no timestamped migration is missing, stale or duplicated in the manifests.
- Admin Main-ID lifecycle help text now accurately explains suspension, closure of all non-closed Duplicate IDs and conditional reactivation; source-contract test expanded.
- Updated `supabase/clean-install/README.md` inventory and added `docs/BULK_SOURCE_RECONCILIATION_2026-11-19.md`.
- Latest batch commits: README `8aefc974fe5ba3b58434f88e96f81f10b7405e72`; reconciliation note `78f85da0f387ae89c5b25a90a0ca96edd577383d`.
- Tests/build/type-check/browser/mobile QA intentionally not run. No TEST/Production migrations or data writes, no deployment, no Production reads, and no protected `main` changes.
- Next: continue bulk source hardening across cross-module workflow contracts; final integrated testing remains deferred until development is complete.
- Overall development completion: **69% provisional** (not a runtime-verified percentage).

---

## Automatic Matrix placement checkpoint — 2026-11-19

- Added `20261119300000_automatic_duplicate_matrix_placement.sql`: separate placement depth, second approved active package activation gate, active package Matrix plan requirement, breadth-first next-empty slot placement, graph lock, Duplicate-ID feature switch and audit attribution.
- Admin Matrix Plan UI now configures Matrix Width, Placement Depth and Commission Depth independently.
- Admin Duplicate ID UI no longer asks for Under ID; it calls the one-argument server RPC and displays the automatically selected parent and position.
- Added/updated contract tests and registered the migration in `supabase/clean-install/forward-migrations.txt`.
- Commits in this batch: migration `d7640258790b5dbb664ae42eb60b46b96a4dd547`; Matrix editor `3f8ed0945be481ad58b4b8d55704755e7b17d4fe`; Admin duplicate UI `80f0573bec026e7639e6413ab8dbb0fa0a963ee2`; RPC contract test `12269da8e3a2aeb1f607fc67868f6eafc95a8733`; Matrix UI test `ac050ca38180d4a332748c638558080277668064`; Matrix migration test `e8cfc127d16c87064f4330a92a096b6c489fd8be`; depth boundary fix `ffd19c22afa9be89716bc738a3918b2f46573532`; manifest `5ebe449a596436cff6073a3f046920f78b85fc88`.
- No TEST or Production migration was applied. No tests/build/typecheck/browser QA or E2E were executed.
- Remaining: Under ID Matrix commission engine, atomic Main-ID Income Wallet credit with Duplicate source attribution, reports and dashboards, then final QA.

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

## Latest source-development checkpoint — 2026-11-19

- Admin Platform Settings now routes existing referral commission, withdrawal, bidding, fixed-bid and winning-payment workflows through the existing server-side enablement condition instead of permanently blocking their switches in the UI. The new migration does not change current feature states or bypass the server condition; incomplete workflows (automatic placement and winner-selection configuration) remain disabled.
- Added source-contract coverage for the allowlist, server condition, audit logging and frontend switch readiness. The clean-install forward manifest now includes migration `20261119260000`.
- Source migration commit: `e44223bc3ac2bbdf35672be23302ab396eaf7367`.
- No tests/build/type-check/browser QA were run. No Supabase access, SQL application, deployment or protected `main` changes occurred.
- Overall development completion remains **60% provisional**.

---

## Latest source-development checkpoint — 2026-11-19

- Current `completion-work` HEAD before checkpoint refresh: `21a5f9e46b7424b86ef80fc28312e80b104b8092`.
- Member Wallet History validates transaction page arrays, non-empty IDs and valid timestamps; rejects duplicate IDs within a page or across pages before advancing the cursor.
- Fixed Bid catalogue no longer disguises a failed/invalid fetch as sample campaigns; sample cards appear only for a genuine empty result. Catalogue rows are checked for required identity/title and duplicate IDs; optional campaign configuration remains optional.
- Admin Auction Bid and Fixed Bid Entry reports now validate page and CSV response shapes, required IDs/timestamps, and duplicate records before displaying/exporting. Cursor progression is stopped on malformed/duplicate page content.
- Source commits: Wallet History `f6e88b7fd7c0de2c369cac337a7a659b1eb324a9`; Fixed Bid `2893de804389345bb2ae081d0bbf45d6244c2c0c`; Auction report `ea793c09115f09b22fdd3afafbfd59edde362eb0`; Fixed Bid report `20ec70355e098dc8264ad7e56390bde9c3a55ca9`. Test commits: Wallet/Fixed Bid `2b8b626dc3e186550e74e6e6b4ef5528f00265be`; Admin reports `21a5f9e46b7424b86ef80fc28312e80b104b8092`.
- No tests/build/type-check/browser QA were run. No Supabase access, SQL application, deployment or protected `main` changes occurred.
- Overall development completion remains **60% provisional**.

---

## Latest source-development checkpoint — 2026-11-19

- Current `completion-work` HEAD before checkpoint refresh: `e6964462245ad298640649120755e9f21896ee26`.
- Restricted payment-review Staff directory now handles missing Supabase configuration and Admin identity-check errors, ignores stale asynchronous directory loads, and validates account IDs and permission values before presenting editable access.
- Member/Admin notification inbox now validates initial and subsequent page payloads, rejects missing/duplicate notification IDs, and stops pagination rather than appending ambiguous rows.
- Source commits: Staff directory `d35fe0dee0a4a5d9afc7d79879c8a9d1d98e31de`; notification integrity `72ec7a0644f1e5d2689342f68db621417acaa692`. Test commits: notification `5778b8806360cc5198a17f804bf38fb9d4870664`; Staff directory `e6964462245ad298640649120755e9f21896ee26`.
- No tests/build/type-check/browser QA were run. No Supabase access, SQL application, deployment or protected `main` changes occurred.
- Overall development completion remains **60% provisional**.

---

## Latest source-development checkpoint — 2026-11-19

- Current `completion-work` HEAD before checkpoint refresh: `95012bfc63cbe302985a27949d81972b1a842181`.
- Member Auction submission history now distinguishes loading, empty and failed states; failures show a retry action instead of leaving an ambiguous blank list. Stale asynchronous loads are ignored, and malformed/duplicate submission IDs fail closed with a visible queue error.
- Source commit: `5198cd2d7f5e9717398ece04d96c5fbf6ec843a1`; source-contract test commit: `95012bfc63cbe302985a27949d81972b1a842181`.
- No tests/build/type-check/browser QA were run. No Supabase access, SQL application, deployment or protected `main` changes occurred.
- Overall development completion remains **60% provisional**.

---

## Latest source-development checkpoint — 2026-11-19

- Current `completion-work` HEAD before this checkpoint refresh: `7929bc9fa35c5989ac42e44cd3e11aa5db56dfbd`.
- Member complete-report pagination now validates every returned row has a non-empty ID and rejects duplicate IDs both within a page and across pages. This complements repeated-page detection and prevents an export from silently including duplicated records.
- Source commit: `113be7d17c44be252b24a99acf7cdf9bd3fdd9f2`; source-contract test commit: `7929bc9fa35c5989ac42e44cd3e11aa5db56dfbd`.
- Tests/build/type-check/browser QA were not run. No Supabase access, SQL application, deployment or protected `main` changes occurred.
- Overall development completion remains **60% provisional**.

---

## Latest source-development checkpoint — 2026-11-19

- Current `completion-work` HEAD at the start of this documentation update: `85216cea2b065c3f72c0a02595d4d3494f1cb254`.
- Latest PWA batch: `src/components/PWAInstallButton.tsx` now provides a manual Android Chrome install-help fallback when the browser does not expose `beforeinstallprompt`, detects standalone installation, and hides the control once installed. The PWA source-contract test now checks these paths and the existing service-worker cache v4.
- Batch commits: component `6781a79dbc34ce0238288b2a881ff66b5c1e0e18`; PWA test `935f42a0605d3bfb9b60514414f65c3573178a2a`; focused note `85216cea2b065c3f72c0a02595d4d3494f1cb254`.
- No tests, build, type-check, browser or Android QA were run. No Supabase reads/writes, SQL application, deployment, or changes to protected `main` occurred in this batch.
- Continue at the latest branch HEAD; preserve the development-first testing gate and the recorded TEST/Production boundaries.
- Overall development completion remains **60% provisional**.

---

## Current Preview checkpoint — 2026-11-19

- Preview workflow #12 failed closed at the TEST-secret validation; the Vite build and Pages deployment did not run. Add `BIDDWORLD_TEST_SUPABASE_URL` and `BIDDWORLD_TEST_SUPABASE_PUBLISHABLE_KEY` to the Preview repository Actions secrets before dispatching again.
- Preview source files `src/components/MemberPlaceAuction.tsx` and `src/components/Admin.tsx` have now been synchronized from `completion-work` (Preview commits `c4a095f3d413e91b2a99c29c6520e36c6fdad3c9`, `e94ec10849a2641634c17098c426c1d82127f5b6`). Other compared key files already matched.
- TEST Supabase migration state is 89 rows / 88 unique migration names due to the recorded duplicate. No more writes or rollback attempts until authorized final QA. Production remains read-only.
- Overall development completion remains **60% provisional**. No tests or QA were run.

---

# Current continuation checkpoint — 2026-11-19

- Live `completion-work` HEAD rechecked: `6648fd07033efdc904593bd60d20804adfeb0be3`; latest commit records the Preview/TEST migration-state checkpoint. Protected `main` remains `620d05b2d266d26dc70c5ff775ed45af9bb3b400` (read-only).
- Preview repository workflow was updated in commits `8a8f8eb553031404b4da244b0844e9319a496708` and `1c1530fdfb6f8f24d3d362603b3154c2acca9913` to build in `test` mode using repository secrets `BIDDWORLD_TEST_SUPABASE_URL` and `BIDDWORLD_TEST_SUPABASE_PUBLISHABLE_KEY`. The Preview source `src/App.tsx` matches `completion-work` by blob SHA. Workflow runs #9/#10 were triggered; connection/deployment is not confirmed until the owner adds the secrets and a run completes.
- **TEST state exception:** continuation migration calls applied the candidate schema baseline and all 87 forward-manifest migrations to `yoaauthwejdgaevfvwpo`; the ledger has 89 rows / 88 unique names because `20261118230000_recover_admin_read_rpc_sources` was applied twice under separate ledger versions. This violated the instruction to leave TEST untouched until final QA. Stop all further TEST writes now; do not attempt automatic rollback or ledger deletion. Reconcile during the authorized final QA phase. Production was not written to.
- No tests, build, type-check, browser/device checks or functional QA were run. Overall completion remains **60% provisional**.

---

# BiddWorld — Official Project Status

> This file is the authoritative recovery checkpoint for all future BiddWorld development chats. The detailed historical evidence remains in `docs/PROJECT_COMPLETION_REGISTER.md` and the linked audit documents. Do not restart completed work or infer deployment from source presence.

## A. Project Information

- Project: BiddWorld
- Repository: https://github.com/kkjan2006-self/biddworld
- Current development branch: `completion-work` — ongoing bulk source development; latest application-source HEAD: `c1af82806e0abd6442de01b094752c6d92c8e776`; the latest documentation/migration checkpoint is `ecd6a5075e8a6f58ffafdcb6d574ad1c3fe7715a`. Member Auction now preflights the server's 30-minute start lead time before image upload and the escaped JSX newline artifact is removed (2026-11-19).
- Latest verified source batch: Fixed Bid public catalogue projection includes `max_entries_total` and `refund_non_winners` (forward #70); Placement Tree verifies Main-ID root ownership (forward #71); Admin notification history displays recipient Main ID/name through a bounded Admin-only RPC (forward #72); Admin pending activation receipt links now track their five-minute expiry and can be refreshed without reloading the queue; Support-ticket Admin updates now write one audit record through the row trigger rather than duplicating it in the RPC; Member Support retries retain a key only for unchanged payloads; Admin notification fingerprints use an unambiguous JSON tuple; Support queue and CSV export use stable keyset pagination; Member wallet history and complete wallet CSV export now use stable `(created_at, id)` keyset pagination. Latest source commits: Member Auction preflight fix `c1af82806e0abd6442de01b094752c6d92c8e776`; Admin product/Auction JSX correction `78bc8d5ebffc9c290f5a4d992fe0082468cb386d`; clean-install manifest correction `ecd6a5075e8a6f58ffafdcb6d574ad1c3fe7715a`; isolated preview Pages workflow hardening `903b198fb69039d2f0de706c714662467a5a8abc` (separate preview repository).
- Protected branch: `main` (do not modify)
- Latest verified application/source work commit: `c1af82806e0abd6442de01b094752c6d92c8e776` (preflight member-auction start time against the server's 30-minute minimum before image uploads; remove literal escaped newline in the form).
- This bulk batch's committed updates: forward manifest `9e4ee080befb1bdafe83148487ba5a81acb31ba5`, clean-install README `22cb014748abb373880ad3b084a4e5c7191870b7`, Fixed Bid projection contract test source `3331875af097b925e0336cc9bfd88d059ae7b521`, static reconciliation `7e79fa0a36509ae6a28fe9101ab36d9e5f81005a`, completion register `071e16e058f0c54aa71884b99cd2171fa1a68ed7`; this status checkpoint was refreshed again at verified branch HEAD `7207c75c51f0340373cd12a33204a8e0cc905d0e`.
- Latest source commit message: `fix: preflight auction start-time eligibility before media upload`.
- Latest verified source/documentation batch commits: `1bee5aa29697701bc714163bc84256b46dc4b70d` (source fix), `e0692f028bda716bf3b3b909a9bf1e1e44ffe244` (forward manifest), `ab9d485766c86d8b5e9a03a4bd9e40ee4a7e2d1d` (clean-install README), `864c2ae315e512e8b3921279375cdd6dfd290de0` (status), `98abc466b7a7e812ed965b7bff54c019d352474b` (completion register), `285fa062988ee44c39706d6cd174c3bfbbf55148` (concurrency audit).
- Previous verified `completion-work` checkpoint: `4d1b05c8e42071dc805cf39663a5bfb9033c0721`. The baseline function ACL and SECURITY DEFINER/trigger dependency source reviews are committed through `7a85cdd714146e3fc8474def3c642e0d724d6254`. The protected primary-repository `main` currently points to `620d05b2d266d26dc70c5ff775ed45af9bb3b400`; this batch did not modify it. The branches remain separate; do not merge automatically.
- Latest application-source correction: `c1af82806e0abd6442de01b094752c6d92c8e776`
- Last updated: 2026-11-19 — isolated Preview TEST connection workflow configured; TEST migration-state exception recorded
- Previous historical checkpoints below are retained as evidence; they are superseded by the latest verified HEAD above.
- Protected primary-repository `main` current HEAD observed: `620d05b2d266d26dc70c5ff775ed45af9bb3b400` (read-only; no changes from this batch).
- Overall project completion estimate: **60%** (source modules and documentation are substantially present; canonical database bootstrap, remaining integrations, consolidated testing and release work are still pending). This is a planning estimate, not a verified deployment or test percentage.
- Production Supabase: `hbqatszyzqobgtauyuzy` — READ-ONLY during development
- Isolated TEST Supabase: `yoaauthwejdgaevfvwpo` — migration ledger has 89 rows / 88 unique names (schema baseline + 87 forward-manifest migrations; one migration name duplicated). No more writes or rollback attempts; reconcile at authorized final QA.
- Budget/hosting: free-tier only; no domain or hosting purchase during development

- Isolated Preview repository: `https://github.com/kkjan2006-self/biddworld-preview`, branch `main`; latest workflow/docs commits `8a8f8eb553031404b4da244b0844e9319a496708`, `1c1530fdfb6f8f24d3d362603b3154c2acca9913`, fail-closed TEST-secret guard `f4446ac0f06c3e0d64246ecb8897b979c536f2f9`, and README `80c27b58987c54d9e347c8e88c25c035d0da8054`. It is configured to consume only TEST URL/publishable-key secrets. Owner must add both secrets and ensure Settings → Pages → Source → GitHub Actions is selected. Do not add Production or service-role credentials.

## B. COMPLETED — Verified Source Work (not equivalent to deployed/live completion)

The following source/UI/documentation work is present in the current branch and must not be recreated from scratch:

- React + TypeScript + Vite responsive application, member and Admin portal foundations, Supabase Auth integration, environment-mode separation, PWA manifest/service worker/icon, and BiddWorld SEO/social metadata.
- Member auction submission now validates trimmed title/description and every selected image's type/size before starting uploads, and uses a synchronous in-flight guard to prevent duplicate submits; the RPC receives normalized title/description. Source-contract test added, not executed.
- Member profile/identity, Main ID and Duplicate ID views, member dashboard summaries, wallet balances/history, referral genealogy, placement tree, package catalogue/activation request, auction/Fixed Bid catalogues, withdrawal requests, support, notifications, account security, winner/delivery history and member exports.
- Admin member/sponsor/duplicate-ID management, package/referral-plan drafts, product/media management UI, auction and Fixed Bid management, wallet ledger/adjustments, withdrawal review, winner/payment and delivery views, support queue, notification templates/send flow, Admin access/role management, platform health, audit logs, filters, pagination and CSV exports.
- Source SQL includes wallet-first debit/idempotency patterns, referral draft versioning and commission calculation/post/reversal workflows, Duplicate ID placement and graph serialization, auction and Fixed Bid lifecycle/draw/refund/settlement workflows, withdrawal reservation/release/review, winner payment, support/notification idempotency, Admin wallet adjustment, receipt/media Storage policies, Admin role management and report RPCs.
- Numerous static source-contract tests and migration/security audit documents exist. These are source artifacts; they do not prove that migrations are deployable or live.
- Historical CI evidence: run #948 passed 102/102 test files and 431/431 tests, TypeScript check, Vite production build and GitHub Pages subpath build. Subsequent runs #996–#1003 did not establish a green CI state; the known recurring failure is a stale source-string assertion in `tests/admin-package-activation-report-filters.test.ts`. Runs #1004 and #1005 both completed with test-step failures; #1005 is the latest completed run at this checkpoint. Type-check/build results for failed runs must not be assumed. See `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`.

## C. DEVELOPMENT COMPLETE — SOURCE IMPLEMENTATION

<badge color="success">100% Development</badge>

- All currently specified Member/Admin source workflows are implemented on `completion-work`: registration without the BiddWorld email-verification flow; member profiles/IDs; duplicate-ID creation and automatic placement; sponsor/referral and Matrix plan/commission management; packages and mandatory payment receipts; Bid/Income wallets, funding and withdrawals; auctions, live bidding, expected-price/48-hour lifecycle, winner settlement; Fixed Bid; member product submissions, editing, duplicate prevention, Admin moderation, full image galleries and public catalogue; notifications, support, delivery, reports, staff controls, audit logs and PWA source integration.
- All member-facing long histories and Admin product moderation use bounded pagination where implemented. Product catalogue anonymous reads are restricted by source RLS to published products only. Wallet, commission and member mutations remain server-side RPC-driven.
- Admin feature-setting parity has been source-reconciled: 14 visible switches match the settings RPC response, server allowlist and enabled-key set. Removed non-actionable Automatic Placement and Winner Selection Configured controls; automatic placement and winner selection are handled by their protected workflows.
- Current clean-install inventory: 124 ordered forward candidates + 16 excluded historical timestamped files = 140 timestamped migrations, plus three legacy/unversioned SQL files. The manifest is unique, strictly sorted, has no duplicate version prefixes, and accounts for every timestamped migration path in the branch.
- Source changes and documentation are committed to `completion-work`. The Preview repo is still a deployment configuration repo and has not been published in this development-only phase.
- **Development is complete at source level.** This does not claim tests/build/type-check, SQL replay, Supabase runtime behavior, browser/mobile/PWA verification or user acceptance have passed.

## D. NEXT PHASE — VERIFICATION (NOT DEVELOPMENT)

1. Obtain explicit approval before applying the 124 forward migrations to isolated TEST `yoaauthwejdgaevfvwpo`; Production remains read-only.
2. Reconcile and validate the schema-only baseline candidate, then replay the ordered migrations on TEST and resolve any SQL/ACL/RLS/Storage incompatibilities.
3. Run `npm ci`, type-check, the complete Vitest suite and production build; fix all failures.
4. Run synthetic-data integration tests for Auth, Main/Duplicate IDs, referrals/Matrix, package receipts, both wallets, bidding, auctions, Fixed Bid, withdrawals, Admin/Staff permissions, notifications, support and reports.
5. Publish the functional GitHub Pages Preview using only Test Supabase; complete Android/mobile and PWA/offline checks, then let the user test Member and Admin portals.
6. Prepare Production deployment only after explicit final user approval. Never migrate or write to Production as part of this verification phase without separate authorization.

## E. BLOCKED / SAFETY BOUNDARIES

- The current `supabase/migrations` directory is not a validated clean-install sequence. `0001_biddworld.sql` is a legacy schema incompatible with later contracts; `001_initial_schema.sql` is empty; `0002_place_bid_rpc.sql` is legacy. Do not replay these as a shortcut.
- Production evidence: 21 public tables, all 21 with RLS; 110 constraints, 60 indexes, 20 policies, 10 application triggers, 43 public functions, and 30 historical migration ledger rows. These snapshots are evidence, not an executable baseline.
- Production RPC/frontend drift has been documented: the latest audit found 35 frontend RPC names present and 39 absent in Production (74 unique frontend RPC names). Some live signatures differ from current source. Never infer that source-defined functionality is deployed.
- Production Storage currently has no configured buckets/policies according to the latest read-only audit, while source migrations define `product-media` and `package-receipts`.
- Isolated TEST project was last verified empty (zero migrations/public tables/buckets). Keep it untouched until the canonical baseline has been reviewed.
- No Production writes, migrations, data changes, wallet credits/debits, commissions, payouts or package activations are permitted in development.
- CI: latest completed run #1005 failed during the test step; type-check/build and Pages build were skipped. The known recurring stale assertion is deferred to the consolidated final test/repair phase. Run #948 was a prior successful CI run, not the current state.
- Overall planning estimate: 55% source/development completion; consolidated testing and release are not included as completed work. Treat this as an estimate, not verified deployment readiness.

## F. DEVELOPMENT ROADMAP (Bulk Batches)

- Batch 1 — Source-level clean-install baseline inventory and exact migration partition completed; semantic dependency/ACL review and TEST replay remain pending.
- Batch 2 — Resolve migration dependency/order/replay blockers and validate baseline in TEST only.
- Batch 3 — Complete frontend/RPC/SQL contract reconciliation and source corrections.
- Batch 4 — Finish remaining member/Admin/report/notification/Storage/PWA source integration and dependency/security remediation.
- Batch 5 — Development-complete gate: confirm every unique requirement is implemented and source migrations are replayable in TEST.
- Batch 6 — One consolidated final testing phase: database replay/integration, auth, RLS/RPC authorization, wallet/referral/duplicate-ID, package, auction, Fixed Bid, winner payment, withdrawal, reports, notifications, Storage, PWA, Android responsiveness, build and regression.
- Batch 7 — Final readiness review, release ZIP and deployment instructions. Do not buy domain/hosting or deploy without the owner's explicit decision.

## G. TESTING STATUS

- Manual testing: NOT STARTED (deliberately deferred).
- Full isolated TEST migration replay: NOT STARTED; TEST remains empty.
- End-to-end/browser/Android checks: NOT STARTED.
- Automatic CI: latest completed run #1005 failed during the test step; type-check/build and Pages build were skipped. Manual/full final testing remains NOT STARTED.
- Do not claim modules fully complete merely because UI, SQL source or static tests exist.

- 2026-11-18 — Clarified the clean-install starting point: do not use legacy `0001_biddworld.sql`; the separate schema-only Production baseline candidate contains the key canonical fields required by the first forward migrations. Updated the clean-install README and static reconciliation. No replay or database changes; full 64-migration dependency review remains open.

- Canonical clean-install path reconciliation: documented the distinction between the legacy `0001_biddworld.sql` schema and the separate schema-only candidate baseline. Static checks confirmed the candidate includes key canonical columns consumed by the first forward migrations. Updated `supabase/clean-install/README.md`, `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`, and added `docs/CANONICAL_CLEAN_INSTALL_PATH_RECONCILIATION_2026-11-18.md`. No database replay, tests or DB writes. Latest documentation commit: `7e91a2e7ec97b75513db599913b6a827f6550483`.

- 2026-11-18 — Reviewed the package receipt Storage chain from initial upload through private bucket/Admin-only read tightening and the Admin pending-activation receipt-path RPC. Confirmed intended final source policy: member-folder INSERT only, Admin SELECT only; product-media remains a separate public-read/Admin-write bucket. Added `docs/STORAGE_POLICY_FINAL_STATE_RECONCILIATION_2026-11-18.md`. Effective policies still need TEST replay verification; no tests/build or database changes. Commit: `5b308934613b33df9f581c8c9c451b56f9774498`.

- Status checkpoint: package-receipt Storage policy sequence and product-media policy separation are documented; current inventory corrected to 82 SQL files (79 timestamped + 3 legacy), 63 forward + 16 excluded timestamped migrations. Full replay and policy verification remain pending.

- 2026-11-18 — Fixed Bid secure random-draw migration review found two source defects in `20261118340000_secure_fixed_bid_random_draw.sql`: refund variables were referenced without declarations (PL/pgSQL compilation failure), and refund selection excluded every entry from a winning member rather than excluding only the actual winning entry IDs. Declared the refund idempotency key and existing-ledger row variables; changed the losing-entry predicate to exclude only `v_winner_entries`, so additional entries from a winner are handled as non-winning entries when configured refunds are enabled. Source commit: `81c245c1688fcff306ca7b556f1f0e268eca68e3`. Not executed or tested; no DB changes.

## H. NEXT DEVELOPMENT BATCH

1. Auction cancellation and Fixed Bid refund source paths have been reconciled against original debit ledger metadata and idempotency keys. Delivery Tracking table/RLS and Member/Admin RPC callers are reconciled. The missing Delivery Tracking transition graph is documented; do not invent terminal-state or return/re-shipment rules absent an approved product contract.
2. Baseline function ACL reconciliation: read-only Production catalogue queries confirm authenticated EXECUTE on 43/43 public functions, anon EXECUTE only on public.lookup_sponsor(text), and service_role EXECUTE on 43/43 public functions. The candidate explicitly grants service_role on those 43 public functions plus private.place_bid(uuid). Production audit_logs_id_seq has broad SELECT/UPDATE/USAGE grants to anon/authenticated/service_role, but the candidate intentionally narrows this to service_role USAGE only because anon/authenticated have no audit_logs table privileges. This least-privilege deviation is documented; Production is unchanged. See docs/CLEAN_INSTALL_BASELINE_FUNCTION_ACL_RECONCILIATION_2026-11-18.md.
3. Continue the 87-forward-migration semantic dependency review, including final function bodies, trigger references, function search_path, trigger order, extensions and sequence ownership.
4. Continue remaining frontend RPC/direct-table RLS coverage and member/Admin lifecycle edge cases. Fixed Bid entry, withdrawal request and both winner-payment RPCs now share the Admin Main-ID lifecycle advisory lock and recheck activity after acquiring it. Fix only evidenced defects in source migrations; do not run tests/builds or database replay before the 100% development gate.
5. Reconcile dependency lockfile/security advisories and remaining notification provider boundary, PWA/offline source integration and operational readiness.
6. Keep Production hbqatszyzqobgtauyuzy read-only and TEST yoaauthwejdgaevfvwpo unchanged. Consolidated tests/replay remain deferred.

## I. CHANGE HISTORY

- 2026-11-18 — Verified current refs (`completion-work` starting HEAD `bd857fefef45943f14446b5c828f9d46e6c14bdb`; protected `main` `415364b71534c7fc31d6c0928dd8395e10cbd94f`). Read-only Production catalogue queries confirmed service_role EXECUTE on all 43 public functions. Narrowed the clean-install candidate's audit_logs_id_seq grants to service_role USAGE only; removed anon/authenticated sequence access because those roles have no audit_logs table privileges. Updated ACL/security audit and completion register. No tests/build/CI/replay or database writes; Production and TEST unchanged. Overall estimate remains 55%.


- 2026-11-18 — Auction winner/payment source reconciliation: Admin status/finalize calls match SQL signatures and consumed result fields; Member Account uses the shared winner-payment RPC with a stable retry key. Found that auction finalization did not recheck current Main ID/Profile activity, potentially selecting a suspended winner whom payment would reject. Added `20261118420000_active_winner_eligibility_and_payment_replay_guard.sql`: active Main ID/Profile winner filtering, shared lifecycle advisory lock before auction locking, and fail-closed replay validation for shared and legacy Fixed Bid winner-payment RPCs (payment must already be paid with paid_at). Preserved highest-bid tie-break, Income-Wallet-only debit, RPC signatures and grants. Forward manifest now 64; SQL inventory 83 (80 timestamped + 3 legacy; 65 forward + 16 excluded). No tests/build, replay or DB writes. Production and TEST untouched.


- 2026-11-18 — Auction bid creation source reconciliation: verified `src/App.tsx` calls `place_bid` with the exact two named arguments exposed by the final idempotent RPC; verified wallet debit suffixes, transaction type and reference metadata match the auction cancellation refund consumer. Found and fixed the missing active-profile eligibility check with migration `20261118410000_require_active_profile_for_auction_bids.sql`. Updated the forward manifest to 63 and clean-install README. No tests/build, TEST replay or DB writes. Production and TEST remain untouched.


- 2026-11-18 — Created this official recovery status file on `completion-work` after verifying the branch and reading the completion register. No application source or database was changed.
- 2026-11-18 — Clean-install static reconciliation: verified 81 SQL files (78 timestamped + 3 legacy), exact 62-forward / 16-excluded partition, candidate baseline object counts, function ACL/search_path counts, ordered replacement dependencies and final package-receipt Storage policy dependency. Added `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`; corrected historical inventory figures. Latest completed CI #997 failed the same stale assertion; no manual testing or database replay.
- 2026-11-18 — Compared selected Admin/Member/package/Fixed Bid frontend RPC calls with baseline and forward migration signatures. No named-argument mismatch was found in the inspected subset; confirmed wallet transaction overload first argument is required, avoiding the suspected PostgREST ambiguity. Added `docs/ADMIN_FRONTEND_RPC_SOURCE_SIGNATURE_RECONCILIATION_2026-11-18.md`. Source inspection only; no tests/build or database writes.
- 2026-11-18 — Reconciled Member Account, Package activation and Fixed Bid catalogue/entry RPC arguments and consumed result fields against their final source definitions, including final strict withdrawal payout validation. No mismatch was found in this subset; no speculative source edit was made. Added `docs/MEMBER_PACKAGE_FIXED_BID_RPC_CONTRACT_RECONCILIATION_2026-11-18.md`. Source inspection only; no tests/build or database writes.
- 2026-11-18 — Admin workspace count review found that six dashboard totals were sourced from direct table HEAD-count queries and therefore could be filtered by member-facing RLS policies. Replaced those queries with existing Admin-authorized overview/list RPC results; renamed the tile from “Registered Profiles” to “Main Member IDs”. Commit: `dd34feece77d383979a2a60b2210def738e48064`. CI #1004 failed during tests; no manual tests or database writes.
- 2026-11-18 — Reconciled Auction Bid and Fixed Bid Entry report RPC arguments/result fields, paginated catalogue exports, and member/Admin notification table access, RLS and idempotent Admin-send RPC. No mismatch found in inspected paths; recorded remaining Admin recipient UUID usability improvement. Added `docs/ADMIN_REPORT_NOTIFICATION_CONTRACT_RECONCILIATION_2026-11-18.md`. Source review only; no tests/build, migration replay or database writes. CI #1005 failed during tests; type-check/build skipped. Commit: `cfca840519a09b585e96e398036d45f210a705d6`.
- Detailed development history, evidence and prior checkpoints: `docs/PROJECT_COMPLETION_REGISTER.md`.

## Status update rule

At every development batch/chat end, update this file with the actual verified branch head, commit, completed/in-progress/pending items, testing status and next batch. Never downgrade completed source work without a documented regression/reopen reason. Never claim a GitHub commit, CI pass, migration replay or deployment without verifying it.

## J. AI continuation documentation

- Added `docs/AI_CONTINUATION_GUIDE.md` as the repository operating contract for future AI-assisted chats. It defines the source-of-truth hierarchy, mandatory new-chat startup, development-before-testing gate, Production/TEST boundaries, product scope, commit discipline and the compact Universal Master Prompt.
- New chats should paste only the compact prompt in Section 10 of that guide; then read this status file, the guide, the relevant completion-register entries and focused audit documents before continuing.
- Guide commit: `65194b9452a10de7f6d7a0527ef8c2b5ebd70dc3`.
- This documentation-only batch did not change application source, SQL, Supabase, member or financial data. No tests, builds, CI workflows or database replay were initiated.
- Existing planning estimate remains 55%; this documentation addition does not change development completion.

## K. Per-step overall completion reporting

- Owner instruction: at the end of every development step/batch, show one clear Telugu line with the **overall BiddWorld project completion percentage** (not merely the current task's progress).
- Keep the percentage evidence-based and consistent with this status file; do not increase it for documentation-only changes.
- Added this mandatory reporting rule to Section 9 and the compact prompt in `docs/AI_CONTINUATION_GUIDE.md`.
- Guide update commit: `da8d4040ab40c47bdd8dfb428d37c55263f67d32`.
- Documentation-only update; no application/SQL/Supabase changes and no tests, builds, CI workflows or database replay initiated. Overall estimate remains 55%.


- 2026-11-18 — Auction cancellation and Fixed Bid refund ledger reconciliation completed at source level. Delivery Tracking table/RLS and Member/Admin RPC calls were traced; paid-payment-only creation, payment advisory lock, owner-only member reads and Admin-only writes are confirmed in source. The status vocabulary exists but no allowed-transition graph is defined; documented this as an unresolved product contract rather than inventing state transitions. Corrected clean-install README inventory to 83 SQL files (80 timestamped = 64 forward + 16 excluded, plus 3 legacy). Added `docs/AUCTION_REFUND_DELIVERY_TRACKING_SOURCE_REVIEW_2026-11-18.md` and updated completion register. No tests/build, migration replay or database writes. Production and TEST untouched. Documentation commits: `025ec6050f5846347d682025e2cd443feaabf5f7`, `74337c27b1646887f13340d4495147189f223e4e`, `1d0103c623d207cfa1c2a24a19e7b78d0928b68e`. Overall estimate remains 55%.


- 2026-11-18 — Auction bid/Main-ID lifecycle concurrency review found a race between active-member lookup in `private.place_bid` and Admin suspension/closure. Added `20261118430000_serialize_auction_bid_member_eligibility.sql`: both RPC paths share a per-Main-ID advisory transaction lock and the bid path rechecks Main ID/Profile activity after locking, before idempotency, auction locking or wallet debit. Public RPC signature/grant and wallet debit/idempotency logic are retained. Added as forward candidate 65; inventory is now 81 timestamped (65 forward + 16 excluded) + 3 legacy = 84 SQL files. Source-only; no tests/build, CI, TEST replay or Production/TEST writes. Overall estimate remains 55%. Commit: `5f15127ec192bd04c0fcd0908e0bb441674daaa8`.


- 2026-11-18 — Reconciled candidate clean-install baseline function ACL structure against the Production public RPC security inventory. Candidate contains 43 public functions and 4 private functions; all 43 public signatures have authenticated EXECUTE, anon EXECUTE is limited to public.lookup_sponsor(text), and the two wallet-report overload pairs are granted explicitly. service_role is explicitly granted on all 43 public functions plus private.place_bid(uuid), but the Production inventory does not capture service_role parity. Also flagged unexplained anon/authenticated USAGE on the audit_logs identity sequence. No speculative ACL change made; exact live privilege and identity-sequence behavior remain to be verified. Added focused audit and updated clean-install README/status. No tests/build, migration replay or database writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Source-reviewed the clean-install baseline's 43 public SECURITY DEFINER declarations and explicit search_path settings; confirmed all 36 Admin functions include authenticated-user and exact app_metadata admin-role checks, member-scoped RPCs use auth.uid(), and public wrappers delegate to private implementations. Reconciled four private function roles and the 11-trigger creation order (one auth.users signup trigger plus ten public feature-gate triggers). No authorization or trigger-order source defect found; service_role and audit_logs identity-sequence ACL parity remain unresolved from missing live evidence. Added focused audit and linked it from clean-install README/status/register. No tests/build/CI, migration replay or database writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Reviewed the 65-file forward migration chain in focused high-impact groups (Auth/signup, member graph, package/referral, financial guards, Fixed Bid/auction settlement, withdrawal, wallet, Storage receipts, notification, reports and public catalogues). No evidenced ordering defect was found in inspected dependencies; full PostgreSQL replay remains deferred. Reviewed lockfile v3 (228 packages): Vite 6.4.6 and @vitest/mocker 4.1.12 match published patched floors for current advisories; full npm audit remains pending. Corrected CI sequencing so pushes to completion-work do not automatically run tests/builds before development completion, and changed install to npm ci. Reviewed PWA registration, manifest and service-worker scope/cache boundaries; Android/offline verification remains pending. Added focused audit. No tests/build/CI run, npm install/audit or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Member Main-ID lifecycle concurrency review found four source paths that checked active Main-ID/Profile status without sharing the per-Main-ID advisory lock already used by Admin suspension/closure and auction bids: Fixed Bid entry, withdrawal request, auction winner payment and Fixed Bid winner payment. Added `20261118440000_serialize_member_financial_eligibility.sql` as forward candidate #66. Each path now acquires the same transaction lock and rechecks ownership/type/active status before campaign/payment processing, request insertion or wallet debit. Existing RPC signatures, idempotency, wallet rules, payout validation and grants are retained. Updated forward manifest to 66; inventory is now 82 timestamped (66 forward + 16 excluded) + 3 legacy = 85 SQL files. Added `docs/MEMBER_LIFECYCLE_FINANCIAL_ACTION_CONCURRENCY_REVIEW_2026-11-18.md`. No tests/build/CI, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Frontend support/notification direct-write RLS review: `Support.tsx` reads support tickets directly under owner-or-Admin RLS, but submits and updates only through audited idempotent RPCs; the table still granted direct INSERT/UPDATE, allowing unused direct writes to bypass those RPC contracts. `Notifications.tsx` reads directly and updates only `read_at` under owner-only RLS, while Admin sends only through the audited idempotent RPC; direct authenticated INSERT was unnecessary. Added `20261118450000_restrict_direct_support_notification_writes.sql` as forward candidate #67, revoking support-ticket INSERT/UPDATE and notification INSERT from authenticated while retaining SELECT and owner-scoped notification read-state UPDATE. Added `docs/FRONTEND_SUPPORT_NOTIFICATION_DIRECT_WRITE_RLS_REVIEW_2026-11-18.md`. Updated manifest to 67 forward; inventory 83 timestamped + 3 legacy = 86 SQL files. Source-only; no tests/build/CI, SQL replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.

- Latest branch verification: `completion-work` HEAD `03a6b5b2747014c9a7b50f813438bd17c2cb9b7e`; protected `main` remains `415364b71534c7fc31d6c0928dd8395e10cbd94f` (identical to its prior checkpoint). Support/notification direct-write restriction is committed and present in the 68-entry forward manifest. No Production or TEST access/writes.

- Latest verified checkpoint before this documentation batch: `b3dd20395c115055b69c55af4e0eaef8b438e7d6`. Member/Admin direct-read and RLS review covers Account, WalletHistory, Packages, App catalogue/wallet summary, Referrals, PlacementTree, FixedBid, Notifications, Support, Admin dashboard and selected reports. No additional evidenced access defect found in this slice; full grant parity and effective policy verification remain pending for final TEST replay.

- 2026-11-18 — Focused frontend direct-read/RLS reconciliation: checked profile self-read, wallet account/transaction owner policies, allowlisted member app_settings read, Packages feature switch, public catalogue and member-scoped RPC callers, notification owner read-state updates, Support owner/Admin reads, and Admin dashboard/report RPC-only data and mutation paths. No additional evidenced authorization defect found in this slice. Documented wallet CSV export's all-visible-rows client filtering as an efficiency enhancement, not an access-control defect. Added `docs/FRONTEND_MEMBER_ADMIN_DIRECT_READ_RLS_REVIEW_2026-11-18.md`. Static source review only; no tests/build/CI, SQL replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.

- Latest documentation checkpoint verified: `a6574cfdb85f416aa0b0cde1c8304a487af6e240`; protected `main` remains exactly `415364b71534c7fc31d6c0928dd8395e10cbd94f`. No Production or TEST access/writes.


- 2026-11-18 — Follow-up static privilege review found that migration #67 revoked table-level INSERT/UPDATE on support_tickets but did not revoke the separate column-level INSERT(user_id, subject, message) and UPDATE(status, admin_response) grants introduced by migration 20261116041000_member_support_tickets.sql. Added forward candidate #68, 20261118460000_revoke_support_ticket_column_writes.sql, explicitly revoking both table-level and column-level INSERT/UPDATE from authenticated. SELECT and the audited idempotent support RPC paths remain. Added docs/SUPPORT_TICKET_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md; updated forward manifest and clean-install inventory to 69 forward + 16 excluded timestamped migrations, plus 3 legacy SQL files (88 total). Source-only; no tests/build/CI, SQL execution, migration replay or database access/writes. Production and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Notification residual column privilege correction: the original `member_notifications` migration granted authenticated column-level INSERT(user_id, title, message, category), while candidate #67 revoked only table-level INSERT. Because column ACLs are independent, an Admin could retain a direct INSERT path under the Admin-only RLS policy and bypass audited/idempotent `admin_send_member_notification(...)`. Added candidate #69, `20261118470000_revoke_member_notification_column_insert.sql`, revoking both table-level and exact column-level INSERT. Preserved owner-scoped UPDATE(read_at) for member read-state. Added `docs/MEMBER_NOTIFICATION_COLUMN_PRIVILEGE_FOLLOWUP_2026-11-18.md`; manifest now has 69 forward + 16 excluded timestamped + 3 legacy SQL files (88 total). Source-only; no tests/build/CI, SQL execution, migration replay or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


- 2026-11-18 — Completed explicit GRANT/REVOKE statement scan across all 69 ordered forward migrations. The only independently granted column-scoped write privileges identified were support-ticket INSERT/UPDATE (corrected in #68) and member-notification INSERT (corrected in #69); notification UPDATE(read_at) is intentionally retained for owner-scoped read-state changes. No other explicit column-scoped INSERT/UPDATE grants were found in the forward candidates. Broader baseline/effective ACL parity, policies, default privileges and runtime verification remain pending. Updated `docs/FORWARD_MIGRATION_DEPENDENCY_CI_SECURITY_REVIEW_2026-11-18.md`. Source-only; no tests/build/CI or database access/writes. Production remains read-only; TEST remains untouched. Overall estimate remains 55%.


- 2026-11-18 — Member Auction Bid UX source correction: the existing idempotent `place_bid` caller now maps insufficient funds to the requested “Insufficient Funds – Please Add Funds” message, explains closed/ended/non-live auctions, and avoids presenting uncertain network outcomes as confirmed failures. The same retry key is retained for ambiguous outcomes. Commit: `e055aeb5a645f64ebb54de36af803c0a341f3bd2`. No tests/build/CI or database operations.

- 2026-11-18 — Member Account report export hardening: paginated CSV export now detects repeated full pages and applies a safe upper bound, stopping with a clear error instead of hanging or silently duplicating records. Commit: `88c7c5e55510161cac4e3e7c1b4c87ae8aa6988a`.

- 2026-11-18 — Member Wallet History account-scope correction: when the authenticated user changes, wallet history rows, page/retry state, has-more state and prior errors are reset before loading the new member's records. A ref tracks the active auth scope so state-reset side effects are not placed inside a state updater. Commits: `d8d283593796ffa762c4d18eacf985e36713eda8`, `5cbe4d7d9e376fc574c817baa999712704a7d138`. No tests/build/CI, database replay or DB access/writes. Production remains read-only; TEST untouched. Overall estimate remains 55%.

- 2026-11-18 — Recovery checkpoint refreshed after verifying `completion-work` HEAD `5cbe4d7d9e376fc574c817baa999712704a7d138`. Updated latest source commits and the exact completed Account/Wallet changes above. No application or database changes in this checkpoint update; no tests/build/CI or database replay initiated.


- 2026-11-18 — Notifications pagination hardening: Load More now deduplicates by notification ID and stops pagination with a clear refresh message if a full page contains no new records, preventing an endlessly repeatable page from accumulating duplicate notifications. Commit: `947d52d14d1a8d020b73c7ce768e6ecd13490d0e`.

- 2026-11-18 — Support queue and CSV export hardening: Load More deduplicates ticket IDs and stops on a repeated full page; full CSV export now fingerprints page IDs, detects repeated pages, and has a safe upper bound with a clear error. Commit: `e8aeb776c5ab6a848e017d9e7ea57f9b13cf33ba`. Source-only changes; no tests/build/CI, migration replay or database operations. Production remains read-only; TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Admin Portal pagination hardening: member directory Load More now deduplicates by Main ID; audit log, wallet ledger and withdrawal queue stop when a full returned page contains no new unique records and show a refresh instruction. This prevents duplicate rows and repeated-page pagination loops across Admin data lists. Commit: `dea33ef8fac35d52b26e935334f353bad596258c`. Source-only update; no tests/build/CI or database operations. Production remains read-only; TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Member Portal feature integration correction: the existing account view had the Placement Tree and Commission History rendered under the same `member-network` active-section condition as My Network, while the navigation exposed only My Network. Added dedicated navigation entries and independent active-section visibility for Placement Tree and Commission History. This makes both already-implemented member features directly reachable without showing all three views together. Commit: `f5f2ccf0888118e64fcf32a885566ba608502a80`. Source-only; no tests/build/CI or database operations. Production remains read-only; TEST untouched. Overall estimate remains 55% pending broader feature inventory and final test phase.


- 2026-11-18 — Fixed Bid catalogue projection reconciliation: added forward candidate #70 (`20261119000000_fixed_bid_public_rules_projection.sql`) to expose the missing `max_entries_total` and `refund_non_winners` rules already consumed by the Member UI. Updated the forward manifest (70 + 16 excluded timestamped + 3 legacy = 89 SQL files), clean-install README and static reconciliation. Added a source-contract test but did not execute it. Branch HEAD at start of batch was `ec70002007d2b52719af7709f68dcff700f9eabc`; latest source feature there also exposes Main/Duplicate ID ownership in Placement Tree. No tests/build/CI, SQL replay or database writes. Overall estimate remains 55%.


- 2026-11-18 — Placement Tree SECURITY DEFINER root-ownership guard added as forward candidate #71 (`20261119010000_enforce_member_placement_tree_root_ownership.sql`). The authenticated profile's Main-ID pointer must now resolve to a Main ID with matching `owner_user_id`; Main/Duplicate recursive traversal and existing grants are preserved. Updated source-contract test (not run), forward manifest, clean-install README, static reconciliation and completion register. Inventory: 87 timestamped (72 forward + 16 excluded) + 3 legacy = 90 SQL files. Start-of-batch branch HEAD: `aeb0672aa48486f477d5e0ca21e78a79fc4e0f7d`; migration commit: `094185fa968b4327612e20752ef631e53914af08`. No tests/build/CI, SQL replay or database writes. Overall estimate remains 55%.


- 2026-11-18 — Admin notification history recipient projection added as forward candidate #72 (`20261119020000_admin_notification_history_recipient_labels.sql`). Admin notification history now uses an Admin-claim-protected, bounded, category-filtered RPC returning recipient Main ID/name; Member inbox and owner-only read-state behavior are unchanged. Updated Notifications UI, source-contract test coverage (not executed), forward manifest, clean-install README, notification reconciliation and completion register. Inventory: 88 timestamped (72 forward + 16 excluded) + 3 legacy = 91 SQL files. Source commit `f6846e12919ec0d940840a34af3505ed1e937563`; tests/build/CI/replay/database writes not performed. Overall estimate remains 55%.


- 2026-11-18 — Admin package-receipt viewer refresh correction: the Admin pending-activation queue previously replaced the View button with a signed URL link after generating a five-minute Storage URL. Once that URL expired, the UI retained only the dead link and offered no way to refresh it without reloading the queue. Updated `src/components/Admin.tsx` to retain the URL expiry timestamp, hide expired links, and always offer a View/Refresh action that requests a new five-minute signed URL. Extended `tests/admin-pending-activation-receipt-path.test.ts` with source assertions; test not run. Commits: `d938fc397a19cac7737079236ed3f69d41d33380` (UI), `ea38258d36a239249a81afb533ddc14ab0e9722c` (test). Forward migration inventory unchanged at 72 forward + 16 excluded + 3 legacy = 91 SQL files. No tests/build/CI, SQL replay or database writes; Production remains read-only and TEST untouched. Overall estimate remains 55%.


- 2026-11-18 — Support-ticket audit event deduplication (#73): the original `support_tickets` AFTER UPDATE trigger and the later Admin update RPC both inserted an audit row for one Admin action. Added `20261119030000_deduplicate_support_ticket_audit_events.sql` to keep the row trigger as the single writer, retain actor/ticket/member/old-status/new-status/response-change context, and remove the second RPC insert while preserving Admin authorization, validation, row locking, return shape and explicit grants. Added `tests/support-ticket-audit-deduplication.test.ts` (not run). Forward inventory: 73 forward + 16 excluded + 3 legacy = 92 SQL files. No tests/build/QA/CI, SQL replay or database writes; Production remains read-only and TEST untouched. Completion estimate remains 55% (Provisional).


## Latest development checkpoint — 2026-11-18

- Admin Auction Bid report page loading and complete CSV export now use a dedicated cursor RPC with stable descending `(created_at,id)` pagination.
- Admin Fixed Bid Entry report page loading and complete CSV export now use the equivalent cursor RPC.
- Existing offset RPCs were preserved for compatibility; new cursor RPCs are Admin-role checked, bounded to 101 rows, use an empty search_path and omit internal idempotency keys.
- Added source-contract tests: `tests/admin-auction-bid-report-keyset-pagination.test.ts` and `tests/admin-fixed-bid-entry-report-keyset-pagination.test.ts`. Not executed.
- Added forward migration candidates #74 and #75: `20261119040000_admin_auction_bid_report_keyset_pagination.sql` and `20261119050000_admin_fixed_bid_entry_report_keyset_pagination.sql`. Manifest now contains 75 forward + 16 excluded timestamped + 3 legacy SQL files = 94 SQL files (91 timestamped).
- No tests, builds, CI, QA, database replay, Production/TEST writes or deployment were performed. Production remains read-only; TEST remains untouched.
- Overall planning estimate remains 55% (Provisional); this source-only batch does not justify changing the overall estimate.


## Latest development checkpoint — 2026-11-19 Main Wallet funding

- Added member-facing Add Money to Wallet Balances with KRFSI UPI QR (krindia@bpunity), amount entry, UTR, payment screenshot/receipt upload and pending/approved/rejected request history.
- Added Admin pending funding review queue with private signed receipt links, review note, approve/reject actions. Approval credits the Main Wallet through a locked server-side transaction and immutable wallet ledger entry; duplicate UTRs and repeat reviews are rejected.
- Renamed member-facing Income Wallet labels to Main Wallet while preserving internal wallet_type='income' and existing settlement contracts. Bid Wallet unchanged.
- Added 20261119060000_member_wallet_funding_requests.sql as forward migration #76 and added private Storage policies, member submit/history RPCs, Admin list/review RPCs, audit events and idempotent ledger credit.
- The existing authorization model currently defines Admin, not a distinct Admin Staff role; no new staff role was fabricated. Admin-only approval remains enforced.
- QR payload was regenerated from the supplied UPI payment data: upi://pay?pa=krindia@bpunity&pn=KRFSI&cu=INR. No payment was made or verified.
- No tests/build/CI/QA, SQL replay, database writes, Production access or deployment. Production remains read-only; TEST untouched. Overall estimate remains 55% (Provisional).


- Inventory update after Main Wallet funding migration #76: 76 forward + 16 excluded timestamped + 3 legacy SQL files = 95 SQL files (92 timestamped). This is source inventory only; no replay was performed.


## Latest development checkpoint — shared UTR protection (#77)

- Added a database trigger-level cross-workflow payment reference guard for package activation and Main Wallet top-ups. Both insert paths use one normalized-reference advisory transaction lock and reject cross-use, preventing concurrent submissions from reusing the same UTR between these two workflows.
- Added source-contract test file `tests/cross-workflow-payment-reference-uniqueness.test.ts` (not run).
- Forward migration candidate #77 added. Inventory: 77 forward + 16 excluded timestamped + 3 legacy SQL files = 96 SQL files (93 timestamped).
- Source-only development; no tests/build/CI/QA, SQL replay, database writes, Production access or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 55% (Provisional).


## Latest development checkpoint — Registration Email Verification (#78)

- Added Admin Email Verification ON/OFF under Member Registration. Default is ON. The switch is stored in app_settings, returned through Admin settings RPC and audit logged.
- Registration reads the policy through a narrow public boolean RPC. ON keeps the confirmation redirect and confirmation messaging. OFF omits the redirect and expects Supabase Auth Confirm Email to be disabled; if provider-level confirmation remains ON, the UI clearly reports the mismatch. Browser code cannot change Supabase project-wide Auth configuration.
- Added migration 20261119080000_registration_email_verification_setting.sql as forward candidate #78 and test source tests/registration-email-verification-setting.test.ts (not executed). Inventory: 78 forward + 16 excluded timestamped + 3 legacy SQL files = 97 SQL files (94 timestamped).
- Removed the hardcoded client-side Admin approval lock so UI actions now defer to database safeguards. Server-side financial interlocks remain unchanged; Production remains protected. Isolated Test unlock/configuration remains part of final Test setup after canonical baseline review.
- No tests/build/CI/QA, database replay/writes, Production access or deployment. Overall planning estimate remains 55% Provisional.


- Follow-up in the same consolidated member-payment batch: Package Activation now displays the KRFSI UPI payee/UPI ID and payment QR beside the package selection and UTR/receipt submission form. The member can pay the selected package amount and submit the existing receipt-backed request for Admin verification. Source-only; no tests or deployment.


## Latest development checkpoint — Restricted Payment Review Staff (#79)

- Added a dedicated `admin_staff` role for an existing registered account. Only the designated Primary Admin (`Kkjan2006@gmail.com`) can grant/revoke it; grants contain exactly `package_activation_review` and `wallet_funding_review` permissions, with audit logging.
- Added isolated Staff portal with only two queues: Package Activation payment review and Main Wallet Add Money review. Staff cannot access the full Admin dashboard, member management, wallet adjustments, reports, settings, or role management.
- Updated package and Main Wallet queue/review RPCs and private receipt Storage read policies to require the corresponding explicit staff permission. Approvals remain server-side, atomic, and ledger/audit recorded; the reviewer is recorded.
- Added migration #79 `20261119100000_restricted_payment_review_staff.sql` and source-contract test `tests/restricted-payment-review-staff.test.ts` (not executed). Inventory: 79 forward + 16 excluded + 3 legacy SQL files = 98 total (95 timestamped).
- No tests/build/CI/QA, SQL replay, DB writes, Production access or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 55% Provisional.


## Latest development checkpoint — Notification inbox pagination (#80)

- Updated both Member and Admin notification inboxes to bounded keyset pagination using descending `(created_at,id)` cursors; 100 visible rows plus one look-ahead row. Member queries remain user-scoped and retain unread/category filters. Admin history uses a new Admin-only cursor RPC.
- Existing Admin offset RPC is preserved for compatibility. Added migration #80 and source-contract test (not executed). Inventory: 80 forward + 16 excluded + 3 legacy SQL files = 99 total (96 timestamped).
- No tests/build/CI/QA, migration replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 55% Provisional.


## Latest development checkpoint — Member auction submissions (#81–#82)

- Added Place an Auction member form and submission history; active Main ID and active profile are enforced server-side. Submission supports 1–8 images, title, description, optional category, starting price, bid increment, start/end times and optional additional details.
- Submissions remain private and pending until Admin or restricted Staff with `auction_submission_review` edits and approves/rejects. Approval creates the published product and scheduled/live auction transactionally; member and reviewer actions are audited.
- Added migrations #81–#82, member form, editable review queue, and source-contract test (not run). Inventory: 82 forward + 16 excluded + 3 legacy SQL files = 101 total (98 timestamped).
- Private image storage is in place, but public delivery of approved images needs a dedicated publishing/media delivery step before live rollout. No tests/build/QA, SQL replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 56% Provisional.


## Latest development checkpoint — Approved auction image delivery (#83)

- Pending member-auction images remain private. During approval, Admin/authorized Staff copy images into public `product-media`; the approval RPC publishes the product/auction with those paths. Catalogue cards and auction detail views resolve media paths to public URLs.
- Added migration #83 and source-contract test (not run). Inventory: 83 forward + 16 excluded + 3 legacy SQL files = 102 total (99 timestamped).
- Image copy and database approval are separate operations; an unsuccessful approval after a successful upload may leave an unreferenced public object for cleanup. No tests/build/QA, SQL replay, DB writes or deployment. Production remains read-only; Test Supabase untouched. Overall estimate remains 57% Provisional.


## Latest development checkpoint — Expected-price auction lifecycle (#84)

- Member auction submission now collects Starting Price and Expected Price (Expected Price must be >= Starting Price); End Time is no longer compulsory or shown. Bidding stays open until current bid reaches/exceeds Expected Price; then DB sets a 48-hour deadline.
- Bid RPC accepts null `ends_at` while target is pending and rejects bids after deadline. `pg_cron` job starts scheduled auctions and marks expired auctions ended. Public catalogue exposes expected price, target-reached timestamp, start time, and nullable end time; UI displays live countdown or Waiting for expected price.
- Admin/authorized Staff review can edit Expected Price. Added migration #84 and source-contract test (not run). Inventory: 84 forward + 16 excluded + 3 legacy SQL files = 103 total (100 timestamped).
- No tests/build/QA, migration replay, DB writes or deployment. Cron is source-defined only and not verified/applied. Overall estimate: 58% Provisional.


## Latest development checkpoint — Individual restricted Staff permissions (#85)

- Primary Admin can independently grant/revoke each existing restricted Staff member's Package Activation Payment Review, Main Wallet Add Money Review, and Member Auction Listing Review permission. At least one permission is required; use Revoke Staff Access to remove the restricted Staff role entirely.
- Added Primary-Admin-only RPC `admin_update_payment_review_staff_permissions`, allowlisted permission validation, audit logging, per-user checkbox UI and source-contract test (not run). Existing role-grant response now accurately lists all three permissions.
- Migration #85: `20261119160000_individual_payment_staff_permissions.sql`. Registered in forward manifest. All work is on `completion-work`; no test/build/QA, SQL replay, database writes or deployment. Production remains read-only; Test Supabase untouched.
- Overall development estimate: **59% Provisional**; this is a planning estimate, not verified live completion.


## 2026-11-19 — Verified branch-head reconciliation

- Latest `completion-work` HEAD inspected: `42e8855a8af1e36d7d247a4e26a85970b41f4b43` (supersedes the earlier `1577a433` recovery reference and the older #85 documentation checkpoint). Protected `main` was not changed in this batch.
- Source review confirms Main Wallet Add Money QR/UTR/private receipt workflow, Admin/Staff approval with Main Wallet ledger credit, cross-workflow UTR uniqueness, Registration Email Verification setting, restricted Staff review, individual Staff permissions, notification keyset pagination, member auction moderation, approved auction image delivery, and Expected Price/48-hour auction lifecycle are already represented in source.
- Rechecked the clean-install forward manifest: the ten relevant wallet-funding, email-verification, Staff and auction lifecycle migrations were already listed. Inventory remains 85 forward + 16 excluded timestamped + 3 legacy SQL files = 104 total (101 timestamped). This is a file inventory, not proof of replayability.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes, or deployment. Production remains read-only; TEST Supabase remains untouched.
- Remaining major work: complete baseline/function and all-forward-migration semantic dependency review; reconcile remaining frontend/RPC/RLS/Storage contracts; finish remaining Fixed Bid, referral, withdrawal, reporting and notification integrations; complete security/operational review. Consolidated testing is still deferred until the owner authorizes it.
- Overall development estimate remains **59% Provisional**. This is a planning estimate, not a verified live/deployment completion percentage.


## Latest source-development batch — Member auction upload lifecycle

- Fixed a partial-upload leak in the member auction submission UI. If image upload/validation fails before the submission RPC, already uploaded private objects are removed. If the RPC returns a definite Postgres error code, uploaded objects are also removed.
- Ambiguous RPC/network failures deliberately retain uploaded objects: the database may have committed even if the client did not receive the response, so deleting those paths could break a successfully created submission.
- File selection now preserves the actual selected count so the existing 1–8 image limit is enforced and visible instead of silently truncating selections above eight.
- Added source-contract coverage in `tests/member-auction-upload-cleanup.test.ts`. Test source written only; not executed. No build, QA, browser/device checks, SQL replay, Supabase writes or deployment.
- Source commits: `4640e3ce46d471cd8f2a677c5400ae75f1a35700` (implementation), `7014af25690d906d4e3717f3bc0c4762861dbb2d` (test source).
- Development estimate remains **59% Provisional** pending broader RPC/RLS, baseline and integration work.


## Latest source-development batch — Wallet funding receipt cleanup

- Added safe cleanup for Main Wallet Add Money receipts when the submission RPC returns a definite database error. This prevents rejected requests from leaving unnecessary private receipt objects in Storage.
- Ambiguous RPC/network failures retain the uploaded receipt because the request may have committed despite a lost response; the UI does not risk deleting a receipt referenced by a successfully created request.
- Added `tests/member-wallet-funding-upload-cleanup.test.ts` source-contract coverage (not executed).
- Source commits: `c010a7b1e72f06670191c0b74c789c7f015909a8` (implementation), `1e64fa623a40842ffb796df8dba0c52877030dd1` (test source).
- No tests/build/QA, browser/device checks, SQL replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## Latest source-development batch — Wallet funding integration in member portal

- The Add Money workflow component was present but was not mounted in the authenticated member Wallet tab. Added a lazy-loaded `WalletFunding` route section above wallet history, making the QR/UTR/receipt submission and request history reachable from the actual member navigation.
- Added `tests/member-wallet-funding-navigation.test.ts` source-contract coverage (not executed).
- Source commits: `bf4242f2a8b2435e8ad1d532bbf65b75eb786357` (Wallet navigation integration), `158faafdbe48b4585e2f49e90a44cc036edca052` (test source).
- Together with the prior auction and wallet-funding receipt cleanup commits, this batch improves orphaned private upload handling without risking cleanup after ambiguous RPC outcomes.
- No tests/build/QA, browser/device checks, SQL replay, Supabase writes or deployment. Development estimate remains **59% Provisional**.


## Latest source-development batch — Wallet funding session isolation

- Main Wallet Add Money request history now follows the active Supabase auth session. It clears the previous member's request rows on sign-out/account switch, invalidates stale in-flight responses, reloads for the new session and displays loading/retrieval errors instead of silently presenting an empty history.
- Added `tests/member-wallet-funding-session-scope.test.ts` source-contract coverage (not executed).
- Implementation commit: `b9c294035bd71bb9e192240bc370fe9d530980da`; test-source commit: `491e0960fbc3472264d875b212ecef77e64988e9`.
- No tests/build/QA, browser/device checks, SQL replay, Supabase writes or deployment. Development planning estimate: **60% Provisional**; remaining cross-module contracts, clean-install semantic review and other source integrations are substantial.


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
- Admin direct Auction draft parity is now implemented in source; remaining project development is tracked in the completion register. Development estimate remains **60% Provisional**.


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


## Latest Frontend Batch — Homepage discovery and accessibility

- Added visible Category and Sort controls to the homepage Auctions row, activating the existing category/sort state (All categories, ending soon, newest, low-to-high and high-to-low). The matching-auction count updates with the filters; the existing horizontal card row and separate Fixed Bids row are preserved.
- Added explicit accessible labels for marketplace search and expanded/collapsed state plus control association for the mobile navigation menu.
- Added keyboard-visible focus styling and reduced-motion support without changing marketplace or account workflows.
- Added `tests/homepage-auction-discovery-controls.test.ts` as source-contract coverage. It was not executed.
- Source commits: `6e3ee90f2289bdf523b9fef4b3f1e27d544cb45b` (auction filters), `03af6f2bf428a900734d5bf14fa3c4a11f3d86ae` (CSS accessibility), `0e4d5cbccde0d0fc68c29f89031567ffda924d5e` (test source), `198c9af0e8a398277b30ee08adb658077635b6ce` (search/navigation accessibility), `2d89fe5aa7771e0bfef783c0e7de6309bff47cce` (test update).
- No tests, type-check, build, browser/device QA, database replay, Supabase writes or deployment were performed. Production remains read-only and TEST remains untouched.
- Overall development estimate remains **60% Provisional**; this UI batch does not establish full frontend, database integration or release completion.


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


## Latest Admin Product UX batch — image preview

- Added a live preview beneath the Admin product draft image field. It reflects the manually entered URL or newly uploaded image, uses descriptive alt text and lazy loading, and hides a broken image link while leaving the URL available for correction.
- Added `tests/admin-product-draft-image-preview.test.ts` as source-contract coverage; not executed.
- Implementation commit: 14f51ad3c72eb3d2663601039efe07b71adff285; test-source commit: 68242c7ec242ed5cf4effb6ea8a473875a7150cd.
- No tests/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched. Overall development estimate remains **60% Provisional**.


## Latest Admin product catalogue batch — saved-product thumbnails

- Admin Saved Products now shows a compact thumbnail for each product when an image is available. Absolute HTTP(S) image URLs remain unchanged; Storage object paths resolve through the existing `product-media` bucket. Thumbnails are lazy-loaded, have product-specific alternative text, and hide broken images without affecting product data.
- Added `tests/admin-saved-product-thumbnails.test.ts` source-contract coverage; not executed.
- Source commit: 8828d1b616c249b0eb06d90945031bba63b3db70; test-source commit: 0572ed0d6bd6bba74fe8133d362bbce4d158d7ac. Overall completion remains **60% Provisional**.
- No test/build/QA/browser/device checks, SQL replay, Supabase writes or deployment. Production remains read-only; TEST remains untouched.


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


## Matrix commission engine checkpoint — 2026-11-19

- Fixed the malformed regex literal in `20261119300000_automatic_duplicate_matrix_placement.sql`; the previous expression would not parse as SQL.
- Added `20261119310000_matrix_commission_engine.sql`: Under ID placement-chain traversal (not Sponsor referrals), independent Matrix commission records, Duplicate source-ID attribution with credit to the owner Main ID Income Wallet, atomic/idempotent ledger posting, audited reversal, and a paginated Admin reporting RPC.
- Added the separate `matrix_commissions_enabled` feature setting, seeded OFF. Admin can see the setting but it remains locked until the end-to-end Matrix workflow is completed.
- Added source-contract tests in `tests/matrix-commission-engine.test.ts`, registered the migration in the clean-install forward manifest, and documented the implementation in `docs/MATRIX_COMMISSION_ENGINE_2026-11-19.md`.
- Key commits: placement SQL correction `9cb927379b0cf1def8e9d703e3cf9086f9b63b51`; Matrix engine `7c56bdaffbb5fa364f377a40d9b8d1e2e49ad624`; feature gate `3bde0d8a00d116becb764db80670eaf177318911`; Admin locked control `56fca0fa28527917f55d11bf04e609ee05835b41`; manifest `8a7b01a8a7d4133e4ba41d3ebb501ee0560dddad`; tests `70af94aab1320e02b23836a27780744002a6e7f3`; SQL guards `a83fed0f7d681014196a73db3f1b8ee0ae49afc6`, reversal replay integrity `3a075d54da9204e1129ecf2243328997123c4d49`; docs `9cf5d667e3ce2ec572c3aab82ca419996add5f49`.
- No tests, typecheck, build, browser/mobile QA or E2E were run. No TEST or Production migration was applied; no database data was changed. Protected `main` remains untouched.
- Remaining: Admin Matrix commission report UI and exports, member/Admin Matrix income dashboard totals, full source/schema reconciliation, then final QA.
- Overall development completion remains **60% provisional**; this backend batch does not establish runtime correctness.


## Admin Matrix Commission Report UI checkpoint — 2026-11-19

- Added `src/components/AdminMatrixCommissions.tsx` and a separate **Matrix Commissions** navigation section in `src/components/Admin.tsx`. Sponsor Referral commission reporting remains a separate module.
- The report loads `admin_list_matrix_commissions_page` with server-side status/level filters, client-side ID/name search and bounded 100-row pagination.
- The UI explicitly displays the placement-chain source ID and source ID type separately from the credited Main ID/name. Duplicate ID source attribution is therefore visible without suggesting a separate Duplicate wallet.
- Added loaded-row counts/totals and pending/credited counts. Complete CSV export fetches all server pages (100,000-row safety limit) and exports activation, level, source ID/type, credited Main ID, amount, status and timestamp.
- Each page is validated for required fields, valid timestamps and duplicate/overlapping commission IDs. Added `tests/admin-matrix-commissions-ui.test.ts` and `docs/ADMIN_MATRIX_COMMISSION_REPORT_2026-11-19.md`.
- Commits: report component `456895b5f206999f2c10f25e2352dd8081839e83`; Admin integration `2eede7258443c3299e0226ce680d16224514c488`; UI contract test `af3e1c44fb6c2ba5fa58d52da87018b57e91eac2`; docs `53b3bfc503dee1fa171aa511ce52a0fd0bfc6216`.
- No tests, typecheck, build, browser/mobile QA or E2E were executed. No TEST/Production migrations or database writes occurred. Protected `main` remains untouched.
- Remaining: Matrix commission dashboard totals for members/Admin, backend source/schema contract reconciliation (including all activation and wallet columns), feature readiness integration, then the user's requested final QA batch.
- Overall development completion remains **60% provisional**; UI source implementation is not runtime verification.


## Latest source-development checkpoint — 2026-11-19

- Added authenticated member Matrix commission summary RPC and separate member dashboard card. Sponsor Referral Income and Matrix Commission Income remain distinct; totals are scoped to the signed-in owner's linked Main ID.
- Commits: migration `808f1e996d814df1a6296f8b1dd5260e0d0b27af`; member UI `9a9488c8ea59ea8e293cde912cdc9a73dcd2b25f`; forward manifest `1c6862dcdeca2647cb872fcb3424b382843c4ead`; source-contract test `06f21fc0b4bd8c97ad676e4e05f1e01843898ef1`; completion register `c155447690322ea1d69b1c6f541dc96432f9f30b`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production migration applied. Protected `main` remains unchanged.
- Matrix commission feature remains OFF. Full schema reconciliation and final QA are still pending. Overall completion remains **60% provisional**.


## Latest checkpoint — Member Matrix commission history

- Member Account Commission History now separates Sponsor Referral and Matrix (Under ID chain) records. Matrix history shows source Main/Duplicate ID attribution, level, amount, status and timestamp. Secure member RPC restricts records to the authenticated user's linked Main ID.
- Commits: UI `7e85ee8445a272f3a89965b5ea11601c84474858`; RPC `874ed1928aea683ba1308b87e72713a9dd71b8ec`; source-contract test `0d43c1c7bb25ee17fcc7ab773d5fbdedf156dc2d`; completion register `dde38f7f30eedc4a8f8bc6ff0a1d0c3e03e1b2a7`.
- No tests/build/type-check/browser/mobile QA run and no TEST/Production migrations applied. Protected `main` unchanged. Matrix commission feature remains OFF. Matrix history pagination and final QA remain pending.
- Overall development estimate: **61% provisional**.


## Latest checkpoint — Wallet Matrix source attribution

- Wallet History displays Matrix commission source member code, Main/Duplicate ID type and Matrix level. CSV export includes the same fields for the complete exported statement.
- Member-scoped source lookup RPC added to `20261119320000_member_matrix_commission_summary.sql`; source rows are only returned when credited to the authenticated user's linked Main ID.
- Commits: wallet UI `1d8751c32701c73a7e0a40422018be3dd661c5a9`; RPC `e5d473302d23175d6a4e89f4a67059d1c59dcc82`; test `5b65f1a60cda621f5e4f284869497821027ae9a5`; export fix `2f3e74ac915f4456848a3e2c60c1f3abcb430860`; completion register `d1fcd405ed1e4c720193edf6967e421ffabd4ec2`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migration applied. Protected `main` unchanged. Matrix feature remains OFF. Full schema reconciliation and final QA remain pending.
- Overall development estimate: **62% provisional**.


## Latest checkpoint — Admin Matrix global summary

- Admin Matrix Commission Register now shows global totals and amounts for all/pending/credited/reversed commissions, independent of pagination and filters; current filtered-page subtotal is labelled separately.
- Admin-only summary RPC added to `20261119310000_matrix_commission_engine.sql`; test contract added.
- Commits: `1e2765350b77bbdc2821c0a94acd2f516cafc30e`, `2d4d75cc0bd1ce3f8b256a0c4e55411708ab9349`, `8010e4dbc57fffd7f2017ddc90d833b0729402c4`, completion register `cd6f34e9e3239c9fc9a4f010a11f68a7ff3aa6a6`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production migration applied. Protected `main` unchanged; Matrix feature OFF. Schema reconciliation and final QA remain pending.
- Overall development estimate: **63% provisional**.


## Latest checkpoint — Member Matrix history pagination

- Member Commission History now supports loading subsequent 100-row Matrix commission pages, with input validation and duplicate-page protection. Sponsor history remains separate.
- Commits: `78ea081e6145c06eae9c21c8c3e5ce5bf0b12df7`, `be486979909cf6d7635b93c9c0025fd27b414ccd`, completion register `9a93e439b7b8834616e810c37977a9afa91ff3a1`.
- No tests/build/type-check/browser/mobile QA run. No TEST or Production migration applied. Protected `main` unchanged; Matrix feature OFF. Schema reconciliation and final QA remain pending.
- Overall development estimate: **64% provisional**.


## Latest checkpoint — Matrix upline traversal correction

- Fixed recursive Matrix Under ID traversal so each level visits the immediate placement parent; intermediate uplines are no longer skipped. Added regression contract assertion.
- Commits: `b2c2a4a23eb9665d5706f2812c6e5ef5ce2279dd`, `7ddea354897e0033c71d8f21ab54a2f329af9084`, completion register `2f2980533ebc8c22918e4652d64b8afb1db64354`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migration applied. Matrix feature remains OFF; schema reconciliation and final QA remain pending.
- Overall development estimate: **65% provisional**.


## Latest checkpoint — Admin Matrix report lifecycle

- Fixed filter-change/refresh race conditions in the Admin Matrix commission report; obsolete requests cannot overwrite the currently selected report, and load-more calls are serialized.
- Commits: UI `f700d99528cf70374bd20d6869d60881c3736388`, regression contract `bb0014685b74a4fa94d9c96d485637812688c824`, completion register `047e8ce6be3ccc0010310a78fb2ce138a33107ed`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied. Matrix feature remains OFF.
- Overall development estimate: **66% provisional**.


## Latest checkpoint — Wallet Matrix CSV attribution

- Corrected full wallet CSV export to include commission reference fields so Duplicate/Main source ID and Matrix level metadata are preserved in exported transactions.
- Commits: UI `b1ab1516a7433bcd8b79d71f4c28c00912dc3ed9`, contract `a2eb416e25e074c61d41b0a0dff5987f3b6890c6`, completion register `9c3c331ed246dd624e634115c0c694ada266e138`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.
- Overall development estimate: **67% provisional**.


## Latest checkpoint — Member Matrix pagination hardening

- Matrix commission Load More now blocks duplicate rapid requests and ignores stale responses after reload/unmount.
- Commits: UI `574f21aa83b301953ceba62354b1ad9a2636a221`, test `2f01743305c5b57700a0cb0c6642749cb2776ef1`, register `e8169e3d1fcac644e452e65080b61263438a611f`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.
- Overall development estimate: **68% provisional**.


## Pagination guard follow-up

- Prevented stale Matrix page-request cleanup from releasing a newer request's in-flight guard.
- Commit: `f06f0bc3faa99fd03cae5ff109e224e348e77f4f`; completion register: `cc325e2897fb7984c91e637b22b75f1fd726505b`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.
- Overall development estimate remains **68% provisional**.


## Latest checkpoint — Migration baseline audit

- Documented a source migration-chain mismatch between the legacy bootstrap schema and later/current schema assumptions. No speculative schema migration was created.
- Audit commit: `a76de56db1183a54ade8525a4278bd9be0450e69`; register: `cd5eae810424ff9fe48ce25c731ebf8f8bea661e`.
- Next blocker: authoritative TEST schema-only snapshot and applied migration history, then compare before authoring any forward-only reconciliation.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production migrations applied.
- Overall development estimate remains **68% provisional** pending schema baseline resolution.


## Latest checkpoint — TEST baseline verified

- Read-only TEST migration history: 89 entries; clean-install baseline `biddworld_clean_install_schema_baseline`; latest applied source migration `20261119170000_admin_open_ended_auction_status`.
- TEST core schema columns match the current owner/member-scoped model. The earlier source-only legacy-baseline concern is corrected; no legacy migration replay is needed on this TEST environment.
- 14 later source migrations (`20261119180000` through `20261119320000`) are not yet applied to TEST; Matrix tables are therefore absent. No migrations were applied.
- Audit correction: `177916ef85ec82488dcdd6029c1b77d67e1bcfd3`; completion register: `06c6f30a51275226bf919888d5914ae3eb53feaa`.
- No tests/build/type-check/browser/mobile QA run; no TEST or Production writes. Production was not queried. Matrix feature remains OFF.
- Overall development estimate remains **68% provisional**.


## Latest checkpoint — Automatic Duplicate Placement SQL syntax

- Removed 91 orphaned repeated SQL lines after the complete Duplicate ID placement RPC. Added a source-contract guard against duplicate function bodies and trailing SQL fragments.
- Commits: migration `f21762b707337b4dec2f8e95eeb3a2676b54e02d`, test contract `ff1d50c12e0be9963c43688a0f18e4319d3d2064`, completion register `4e860f6eb9a76d5769f93aba4663d2f3d13e2023`.
- Read-only TEST schema baseline is confirmed; this migration is still unapplied there. No tests/build/type-check/browser/mobile QA run and no TEST/Production migrations applied.
- Protected `main` unchanged. Matrix commission feature remains OFF.
- Overall development estimate: **69% provisional**.


## Latest checkpoint — Wallet history request lifecycle

- Prevented stale wallet-history requests from applying Matrix source attribution, pagination cursor, or transaction rows after an async attribution lookup completes.
- Added regression contract. Commits: component `691ff9f`, test `190ed8a`, register `83181de7bf4026fa5b47422efe0cd62c70366245`.
- No tests/build/type-check/browser/mobile QA run; no TEST/Production database changes. Protected `main` unchanged.
- Overall development estimate: **69% provisional**.


## Latest checkpoint — Sponsor and Under ID display separation

- Member Account dashboard/profile now displays Main ID Under ID / Placement Parent separately from Sponsor Member ID. Root placement is labelled explicitly; Duplicate ID cards retain their own Under ID.
- Sponsor genealogy, Placement Tree, and Matrix Under ID commission history remain distinct. Added UI contract test.
- Commits: UI `d346f515`, contract `26cf980`, register `9458ca4a82d40108ed4938a9aa1455fbdc5649b4`.
- No tests/build/type-check/browser/mobile QA run; no TEST/Production data or migrations changed. Protected `main` unchanged.
- Overall development estimate: **70% provisional**.


## Member Sponsor / Under ID clarity — 2026-11-19

- Member Account now displays the Main ID's Under ID / placement parent separately from the Sponsor Member ID, including a clear root-placement label when no parent exists. The profile section carries the same distinct read-only field.
- Reconfirmed the data contract: Sponsor identity resolves through `referrals.referrer_member_id`; the member ID list resolves Under ID through `member_ids.placement_parent_id`; Sponsor genealogy and Placement Tree remain separate views.
- Added `tests/member-sponsor-under-id-separation.test.ts` to guard the UI labels and the two independent database relationships. Test source was authored but not executed.
- Source commit: Account UI `324c34572a43064aee56c64796648e08d5c65049`; contract test `92d011b138f247d19012c77f226f660df7587394`.
- No tests/build/type-check/browser/mobile QA were run. No Supabase migrations, database writes, Production access, deployments or protected `main` changes occurred.
- Overall development completion remains **69% provisional**.


## Placement Tree Under ID labels — 2026-11-19

- The member Placement Tree now returns and displays the actual placement-parent Member ID for every node, labelled **Under ID**; the Main ID root is labelled **Root placement**. This makes the automatic Duplicate-ID placement destination and every downstream placement relationship directly visible.
- Added migration `20261119330000_member_placement_tree_parent_labels.sql`, updated the component, registered the migration in the clean-install forward list, and added source-contract coverage to `tests/member-placement-tree-duplicate-ids.test.ts`.
- Commits: migration `57a79146c8b6b1e74ee23be540a9101223fe6b8a`; UI `6aba7b418763b88735f100794314a6d94b342487`; manifest `d9045fb35c86f65a81e42a38c7b08f943cb5d4e0`; contract `28d134838f5e559fe48dc440fc0ffe95f82a114c`.
- Migration is source-only and has not been applied. No tests/build/type-check/browser/mobile QA, database writes, Production access, deployments or protected `main` changes occurred.
- Overall development completion remains **69% provisional**.


## Admin Member / Placement relationship clarity — 2026-11-19

- Admin Member Details now label the Main ID's Under ID / Placement Parent separately from its Matrix position; Sponsor Main ID remains a separate field.
- Admin Placement Hierarchy now displays each node's Under ID, Matrix position and (for Duplicate IDs) owner Main ID. Linked Duplicate ID rows also show their actual Under ID and position.
- Added source-contract assertions in `tests/admin-member-detail-search-selection.test.ts`. Test source authored but not executed.
- Commits: Admin UI `d39fd2d646ddc3e737f7f093a723fb7597866160`; regression contract `fee444afb8becfabcdc165729a3883d91ab010f8`.
- No tests/build/type-check/browser/mobile QA, migrations, database writes, Production access, deployment or protected `main` changes.
- Overall development completion remains **69% provisional**.


## Duplicate placement ownership alignment — 2026-11-19

- Corrected automatic Duplicate-ID BFS placement to skip the owner's own Main ID and owner-linked Duplicate IDs as placement parents. It now chooses only active parent IDs owned by a different member, matching the existing activation guard, while searching the owner's Main-ID placement tree.
- Added source-only migration `20261119340000_exclude_owner_ids_from_duplicate_placement.sql`, registered in the clean-install forward manifest, plus regression contract `tests/automatic-duplicate-placement-owner-guard.test.ts`.
- Commits: migration `9199443`; regression contract `e12ab87`; manifest `2faed2d`.
- No tests/build/type-check/browser/mobile QA, migrations applied, database writes, Production access, deployment or protected `main` changes.
- Development completion remains **69% provisional**.

## Duplicate ID feature-toggle concurrency guard — 2026-11-19

- Serialized Admin changes to `duplicate_ids_enabled` with the same transaction-scoped member-graph advisory lock used by automatic Duplicate-ID creation.
- The database trigger now acquires that lock before checking the switch, so alternate/direct insert paths cannot race the Admin OFF operation. Existing Duplicate IDs, their statuses and history are unchanged; only new creation is gated.
- Added source-contract coverage in `tests/duplicate-id-feature-toggle-serialization.test.ts` and registered migration `20261119350000_serialize_duplicate_id_feature_toggle.sql` in the clean-install forward manifest.
- Commits: migration `02e193d`; contract test `4ab3dce`; manifest `bd5ab33`.
- Source-only. No tests/build/type-check/browser/mobile QA, TEST/Production migration, database writes, deployment or protected `main` changes.
- Overall development completion remains **69% provisional**.

## Duplicate ID insert-trigger OLD-record safety — 2026-11-19

- Hardened the database trigger that enforces `duplicate_ids_enabled`: it now branches on `TG_OP` before reading `OLD`, avoiding an unassigned-record access on INSERT.
- INSERTs of Duplicate IDs and UPDATEs that convert another ID type into `duplicate` still acquire the shared graph lock and fail closed when the feature is OFF. Unrelated updates and existing Duplicate IDs remain unaffected.
- Added migration `20261119360000_fix_duplicate_toggle_trigger_insert_record.sql`, regression contract `tests/duplicate-id-toggle-trigger-old-record.test.ts`, and clean-install manifest registration.
- Commits: migration `d936ad3`; test `b5c9a4b`; manifest `01376a4`.
- Source-only. No tests/build/type-check/browser/mobile QA, database migrations, database writes, deployment or protected `main` changes. Overall development completion remains **69% provisional**.

## Main-ID reactivation reconciliation retry — 2026-11-19

- Fixed a lifecycle edge case: when a linked Duplicate ID could not reactivate because its placement parent was still inactive, it remained suspended and Main-managed. A later retry of Main-ID activation previously returned early because the Main ID was already active.
- Main activation now retries linked Duplicate-ID reconciliation even when Main status is already active. Only Main-managed suspended duplicates with an active placement parent belonging to another member are restored; unresolved children remain suspended and managed. Closed Main IDs remain irreversible; actual changes are audited.
- Added migration `20261119370000_retry_main_activation_duplicate_reconciliation.sql`, regression contract `tests/main-activation-duplicate-reconciliation-retry.test.ts`, and forward manifest registration.
- Commits: migration `9ba91da`; test `032888c`; manifest `cb26307`.
- Source-only. No tests/build/type-check/browser/mobile QA, DB migrations/writes, deployment or protected `main` changes. Overall development completion remains **69% provisional**.

## Main-ID closure consistency — 2026-11-19

- Fixed a lifecycle inconsistency: closing a Main ID now closes every linked Duplicate ID that is not already closed, including Duplicate IDs that were manually suspended. Previously, manually suspended IDs could remain in `suspended` after their owner Main ID was permanently closed.
- The change preserves existing closed IDs and history, marks the linked status as Main-managed, retains irreversible Main-ID closure, and uses the existing audit/count response path.
- Added migration `20261119380000_close_all_linked_duplicate_ids.sql`, regression contract `tests/main-close-linked-duplicate-ids.test.ts`, and clean-install manifest registration.
- Commits: migration `4aed942a9a09ee7d0936d02e86c0e108f931c928`; test `12587e9ed218ccbfb6f26efa2652442245ce9c1f`; manifest `c1cd577162ad6948300bbe2ae502cae1e8a3a918`.
- Source-only. No tests/build/type-check/browser/mobile QA, DB migrations/writes, deployment or protected `main` changes. Overall development completion remains **69% provisional**.

## Admin lifecycle guidance alignment — 2026-11-19

- Updated the Main-ID details help text to match the implemented lifecycle: suspension affects active linked Duplicate IDs; closure closes every non-closed linked Duplicate ID, including manually suspended IDs; reactivation restores only Main-managed children whose placement parent is active.
- Extended `tests/admin-member-detail-search-selection.test.ts` with a source contract for these lifecycle explanations. Test source was authored but not executed.
- Commits: Admin UI `2003879540dc9cec4686282895c6eaecf508ec68`; contract `cee39c50919f785276d5d806a98a7b5f163c5887`.
- No tests/build/type-check/browser/mobile QA, DB migrations/writes, deployment or protected `main` changes. Overall development completion remains **69% provisional**.


## Latest checkpoint — Admin withdrawal queue pagination hardening

- Hardened the Admin withdrawal queue's initial page validation: malformed rows, duplicate request IDs, missing member IDs and non-positive/non-finite amounts now fail closed instead of being rendered as trusted queue entries.
- Added a single-flight guard and refresh-generation invalidation for Load More. Stale responses cannot append after a workspace refresh; page envelopes and row identities are validated before append, and repeated pages are detected.
- Existing withdrawal review RPC, reserve/release workflow and complete paginated CSV export are preserved. Offset pagination remains; this is lifecycle/response hardening, not a keyset migration.
- Added source-contract coverage in `tests/admin-withdrawal-pagination-hardening.test.ts`.
- Commits: Admin UI `944a754b61c09c79ec5f3b5be9cd47a0ca64ba80`; test `960c3882b3d0d511acba19a64157df749b86064f`.
- Tests/build/type-check/browser/mobile QA were not run. No database migration, TEST/Production data access or writes, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional** pending remaining modules and final integrated verification.


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


- Admin Duplicate ID directory now validates initial and Load More responses (IDs, statuses, timestamps, linked Main ID fields, counts and consistent page metadata); malformed/overlapping rows stop pagination instead of being silently filtered. Existing search, automatic placement, approval/status actions and feature-switch behavior are unchanged.
- Added source-contract coverage in `tests/admin-duplicate-id-directory-integrity.test.ts`. Commits: Admin source `729351bfad962ba09e11296fae4d490a70077820`; contract test `b4c348f96facae029b868903a9396f36eba968c5`.
- Tests/build/type-check/browser/mobile QA remain deferred and were not run. No TEST/Production database reads or writes, migrations, Preview deployment, or protected `main` changes occurred.
- Overall development completion remains **71% provisional** (not runtime verified).

- Admin Matrix Plan directory hardened: validates package ownership, unique plan IDs, version/dimensions, timestamps, complete sequential level definitions, reward bounds and eligibility JSON objects. Added request-generation guards so a slow response for a previously selected package cannot overwrite the currently selected package's plans; selection clears stale rows while loading.
- Added source-contract coverage in `tests/admin-matrix-plan-directory-integrity.test.ts`. Commits: Matrix Plans component `4f82989cce55b824d1be762b34f93c919c0693c0`; contract test `a3b0496266d1edd5a8e325ebb7abeb3883110e7d`.
- Tests/build/type-check/browser/mobile QA remain deferred and were not run. No TEST/Production database reads or writes, migrations, Preview deployment, or protected `main` changes occurred.
- Overall development completion remains **71% provisional** (not runtime verified).

- Admin Package and Sponsor Referral Plan list responses now receive strict runtime validation: unique package IDs, names, descriptions, non-negative prices/credits, currency and publication state; referral package identity, plan metadata consistency, supported reward types/ranges and sequential levels. Invalid responses now surface a module-specific error rather than being cast directly into UI state.
- Added source-contract coverage in `tests/admin-package-referral-directory-integrity.test.ts`. Commits: Admin source `7e778c4602163866222fc0fe26b62077a2872395`; contract test `e50e3e11d05fce1646add8d94c62e1d72f338709`.
- Tests/build/type-check/browser/mobile QA remain deferred and were not run. No TEST/Production database reads or writes, migrations, Preview deployment, or protected `main` changes occurred.
- Overall development completion remains **71% provisional** (not runtime verified).

## 2026-11-19 — Admin Auction and Fixed Bid directory integrity

- Replaced unchecked casts for Admin Auction Products, Auctions and Fixed Bid campaign list responses with strict runtime parsers. The parsers validate bounded arrays, unique IDs, required names/statuses, nullable text fields, auction prices/increments and optional lifecycle timestamps, plus Fixed Bid configuration objects and campaign timestamps.
- Malformed data now clears only the affected module and adds a module-specific warning; the rest of the Admin workspace can still load. Existing auction/product/campaign actions and RPC contracts are unchanged.
- Added source-contract coverage in `tests/admin-auction-fixed-bid-directory-integrity.test.ts`.
- Commits: Admin UI `a01ec4b7d91b18f2c37ec9ee740a5aff880c1f2c`; regression source `4d817c3bf007daa8c61478e9700bb0e69d8abc67`.
- Tests/build/type-check/browser/mobile QA were not run. No TEST/Production database access or writes, migrations, Preview deployment or protected `main` changes occurred.
- Overall development completion remains **71% provisional**.


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


# Development checkpoint — 2026-11-19 (Member product editing)

- Added owner-scoped editing and resubmission for member product listings in Pending or Rejected state. Members can correct the product name, description, category and optional details, keep existing private images or replace them, then return the listing to Admin review.
- Added forward-only source migration `20261119450000_member_product_submission_editing.sql`; RPC locks the row, checks owner and active Main ID, validates private image ownership, resets review metadata and records an audit event. Registered in the clean-install forward manifest.
- Updated the member product submission UI with Edit & Resubmit controls and preserved existing images when no replacement is selected. Added source-only regression contract test.
- Commits: migration `88b28f955eb3021f339f72c8a1a36671518fec47`; migration cleanup `528ee6a863dcb4a02595c280dd275316eb29a48a`; member UI `dd0448a0213eb6bf1f124d17be29c241cca13b53`; manifest `700343a79339b0293db5bc024451f65f26d28630`; regression source `2377b59610ff1ec85409c760b27d67dd10bc5240`.
- Migration is source-only; NOT applied to TEST or Production. Tests/build/type-check/browser/mobile QA remain deferred. Protected `main` unchanged.
- Overall development completion: **75% provisional** (not runtime verified).


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
- Source development estimate: **98% provisional**; remaining baseline/forward migration dependency reconciliation, complete frontend/RPC security review and other outstanding module integration remain open.


## 2026-11-19 — Mandatory package receipt and current migration inventory

- Made package payment receipt mandatory in the Member UI and the authoritative `submit_package_activation_with_receipt` SECURITY DEFINER RPC. The server verifies the uploaded object exists in the private package-receipts bucket and belongs to the signed-in user before creating the activation; it then links the receipt atomically. Missing/invalid receipt paths are rejected server-side.
- Added a browser in-flight guard to prevent double activation submission and clears the native file input after success. Existing cleanup behavior removes uploaded receipts when the RPC definitely rejects the request.
- Added regression source `tests/package-activation-receipt-required.test.ts` and registered migration `20261119500000_require_package_activation_receipt.sql`.
- Commit IDs: package UI `74879c7a8a57adbb3773e5f65b930b1b9d8fa205`; server migration `fd65888f274068e5df887d51947bbd24ac56497e`; test `8ac852f3bf93c285dc6fa54fd32cec9f3304c425`; manifest `be178fe8c75b82c2d1317a954d542b6f2f5ed9d2`.
- Current source inventory: 119 forward + 16 excluded = 135 timestamped migrations, plus 3 legacy/unversioned SQL files. The forward manifest remains sorted and unique.
- Development-only: no SQL executed, no Supabase data changed, no Preview deployment/runtime tests, no protected `main` changes.
- Overall source development estimate: **93% provisional**. Remaining baseline/forward migration semantic reconciliation and other outstanding module integration are still open.


## 2026-11-19 — Member wallet funding and withdrawal history pagination

- Added owner-scoped keyset pagination for the member Add Money request history; the Member Wallet Funding module now loads 50 requests at a time, validates every row and rejects duplicate/overlapping cursors.
- Added owner-scoped keyset pagination for withdrawal history in the Member Account portal. The first 50 requests load with the account; subsequent requests use the stable `requested_at,id` cursor and a guarded Load More action. Existing withdrawal submission and review data remain unchanged.
- Updated account refresh to invalidate stale withdrawal-page requests and reset the page state safely.
- Added `tests/member-wallet-funding-history-pagination.test.ts` and `tests/member-withdrawal-history-pagination.test.ts`; registered migrations `20261119510000_member_wallet_funding_history_pagination.sql` and `20261119520000_member_withdrawal_history_pagination.sql`.
- Commits: wallet-funding UI `f93d6502ae118f52605bf3915e7cdb54ffb96160`; wallet-funding migration `fbb938dd91d3d461f16682f2664e7c4351622c09`; wallet-funding test `bea838ed75696d3794d91f21e6cfee82dad29557`; withdrawal UI `001cda93afe90d25fe14333b8f4ded0af6dd0701`; withdrawal migration `54e61b73952d475b43bddf78269dc154150fa9af`; withdrawal test `ae82e6f47a5f0d497817afd95cbe23f026b20247`; account refresh guard `d9cdf3fbbeff29e187e9cf49c21772d6d4c95e9f`.
- Current inventory: 121 forward + 16 excluded = 137 timestamped migrations, plus 3 legacy/unversioned SQL files. Forward manifest is unique and strictly sorted.
- Source-only: no tests/build/type-check, no TEST/Production migration execution or data changes, no Preview publishing/runtime QA, and no protected `main` changes.
- Overall source development estimate: **93% provisional**; canonical baseline/forward migration semantic dependency review and final source integration remain open.


## 2026-11-19 — Auction catalogue, product moderation and data-contract resilience

- Fixed the Auction catalogue error-state bug: the component referenced a block-scoped RPC error from outside its scope, which could break the build. The catch handler now uses the caught error object correctly.
- Auction sample cards now appear only when Supabase is intentionally unconfigured. A configured empty catalogue or RPC failure no longer masquerades as live sample inventory; the real empty/error state is preserved.
- Hardened Admin product moderation cleanup: uploaded public images are removed only before the review RPC starts or after a definite server rejection. If the network outcome is uncertain, images are retained and the Admin is told to refresh before retrying, preventing a successful published product from being left with broken image URLs.
- Member and Admin product submission readers now reject non-string optional-detail JSON values before rendering, preventing malformed historical JSON from causing React render failures.
- Added regression sources `tests/auction-catalogue-error-state.test.ts` and `tests/admin-product-submission-image-cleanup.test.ts`; extended member/Admin product detail rendering tests. No tests/build/type-check were run.
- Commits: auction catalogue `3df768c346320cc1b20bc684ea9a5d8a5a1892f3`; auction regression `212f8e24f088222315a652073700cd31e3fef2c0`; product image cleanup `330c86bee3db4048d7550133cf3614237be64ae8`; cleanup regression `d53ea1171ec74435fb9976a997b9a6fbce81a1dd`; member details validation `8800577c0fcfe02dbf3c51c6fdf4c1e4f3ad09d0`; Admin details validation `49591a4bc2841dd970443bb5bab1d8d27243323d`; test updates `c7db44fa5a6555e0d7a1c213c76807dd21d7066e`, `507a3b9ec062789218b378dcb0d4e83122a0b663`.
- Current inventory: 121 forward + 16 excluded = 137 timestamped migrations, plus 3 legacy/unversioned SQL files. Forward manifest is unique and sorted.
- Development-only boundary maintained: no SQL applied, no Supabase data changed, no Preview deployment/runtime QA, and protected `main` unchanged.
- Source development estimate: **93% provisional**; remaining source contract reconciliation and final module integration are open.


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
- Forward migration inventory remains 122 unique candidates. Source development estimate: **97% provisional**; final RPC/source contract review and documentation consistency remain.


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

- Commit: `85b91cca4c8bec981204bf65f800dc5fdf1d2282`.

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

- Found that member Fixed Bid, withdrawal and winner-payment RPCs acquire the per-Main-ID advisory lock `biddworld.main_member_lifecycle:<uuid>` and recheck eligibility, but the Admin Main-ID suspend/close/reactivate RPC did not acquire that same lock.
- Added `20261120200000_serialize_admin_main_member_lifecycle.sql`. Admin status changes now acquire the shared per-Main-ID lock before taking the Main-ID row lock and mutating profile/Main/Duplicate statuses. This ensures a member financial action completes before the status change, or the action rechecks and rejects after suspension/closure.
- Preserved the graph-wide mutation lock, Admin authorization, valid status/reason checks, linked Duplicate-ID propagation, audit record and authenticated-only execute grant. Added `tests/admin-main-member-financial-lifecycle-serialization.test.ts`; source-only, not executed.
- Registered the migration in the clean-install forward manifest. Inventory: **148 forward + 16 excluded = 164 timestamped paths**, plus 3 legacy/unversioned SQL files.
- No tests/build/type-check, DB operations, migration replay, deployment or `main` changes. Production and TEST remain untouched.


## 2026-11-20 — Admin withdrawal review lifecycle serialization

- Found that Admin withdrawal approve, reject/release and mark-paid actions did not acquire the shared per-Main-ID advisory lock used by member financial actions and Admin Main-ID suspend/close/reactivate.
- Added `20261120210000_serialize_admin_withdrawal_review_lifecycle.sql`. The Admin review RPC now locks/identifies the withdrawal request, then acquires the same per-Main-ID transaction lock before active-profile/Main-ID validation or any wallet reservation, compensating release or payout confirmation.
- Preserved existing reservation/release ledger idempotency checks, state transitions, Admin authorization and audit event. Added `tests/admin-withdrawal-review-lifecycle-serialization.test.ts`; source-only, not executed.
- Registered migration in clean-install manifest. Inventory: **149 forward + 16 excluded = 165 timestamped paths**, plus 3 legacy/unversioned SQL files.
- No tests/build/type-check, DB operations, migration replay, deployment or `main` changes. Production and TEST remain untouched.


## 2026-11-20 — Notification inbox recipient ownership validation

- Closed a client-side trust gap: the member page parser accepted an optional expected user ID, but member page calls did not pass it, and realtime INSERT/UPDATE handlers relied only on the subscription filter.
- Initial and keyset member pages now validate each row against the authenticated user; realtime INSERT/UPDATE events reject records for any other user. Admin history continues using the Admin-only recipient projection.
- Added source-only assertions; not executed. No migration was required. No tests/build/type-check, DB operations, deployment or `main` changes. Production and TEST remain untouched.


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
