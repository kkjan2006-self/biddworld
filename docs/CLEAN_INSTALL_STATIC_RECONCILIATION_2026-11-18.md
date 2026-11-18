# BiddWorld clean-install static reconciliation — 2026-11-18

## Scope and safety

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Branch head inspected before this documentation batch: `dd72209c1da51d7953da14245d6520431f03469c`
- Production Supabase: `hbqatszyzqobgtauyuzy` — no writes.
- TEST Supabase: `yoaauthwejdgaevfvwpo` — no writes.
- This is a source/catalogue review only. No migration was executed, no build or test was manually run, and no application or financial data was read or changed.

## 1. Current migration inventory — verified

GitHub directory listing and both clean-install manifests were compared directly.

| Inventory | Count |
|---|---:|
| SQL files in `supabase/migrations` | 80 |
| Timestamped migration files | 77 |
| Legacy/unversioned files | 3 |
| Forward migration manifest | 61 |
| Excluded historical manifest | 16 |
| Timestamped files accounted for exactly once | 77 |

The three legacy files are:
- `0001_biddworld.sql` — incompatible legacy schema.
- `0002_place_bid_rpc.sql` — incompatible legacy RPC/schema contract.
- `001_initial_schema.sql` — empty placeholder.

The 62 forward paths and 16 excluded paths were checked against the live GitHub directory listing:
- No forward or excluded path is missing.
- No path appears in both lists.
- No timestamped migration is missing from the combined manifests.
- All 62 forward candidates and all 16 excluded entries are in lexical/timestamp order.
- Existing test `tests/clean-install-migration-manifest-integrity.test.ts` asserts the exact partition, path existence, order and candidate-only marker. This test was inspected but not run in this batch.

Older documents referred to 48 or 56 forward candidates and 72 timestamped migrations. Those figures belong to earlier source checkpoints and are superseded by the current 61 + 16 = 77 inventory.

## 2. Baseline candidate — static inventory

File: `supabase/clean-install/production_schema_baseline_candidate.sql`

The candidate contains:
- 21 public tables.
- 175 public columns (from the Production catalogue snapshot).
- 110 public constraints.
- 28 explicit non-constraint indexes; the Production catalogue reports 60 indexes total when constraint-backed indexes are included.
- 21 RLS enable statements.
- 20 public RLS policies.
- 47 function definitions: 43 public and 4 private.
- 11 app-owned triggers: 10 public-table triggers and one trigger on Supabase-managed `auth.users`.
- Table, sequence and function ACL statements, including revocation of default function/sequence privileges before explicit grants.
- A transaction wrapper ending in `commit;`.

The candidate creates only the app-owned `private` schema. Supabase-managed schemas such as `auth`, `storage`, `extensions`, `realtime`, `vault` and `supabase_migrations` are platform prerequisites and must not be recreated by the application baseline.

The baseline has no Storage bucket or Storage object policy DDL. This matches the read-only Production observation of zero configured buckets and zero Storage policies. Application buckets and policies are provided by forward migrations instead.

This is still a candidate, not a canonical approved executable migration. Static counts do not prove successful PostgreSQL replay, exact function-body equivalence or runtime authorization.


### Function ACL and search-path pass

A second static scan of the baseline SQL confirmed:
- 47 function definitions, representing 45 distinct function names because the wallet-account and wallet-transaction list RPCs each have two overloads.
- All 47 definitions are marked SECURITY DEFINER.
- 47 function-level `SET search_path` clauses are present; the additional 48th search_path occurrence is the baseline session setting.
- Two schema-wide function revocations reset PUBLIC/API execution before explicit grants. There are 88 explicit EXECUTE grant statements across 42 distinct public/private function names.
- The three private trigger/activation helper functions `private.enforce_feature_gate()`, `private.handle_new_auth_user()` and `private.submit_package_activation(uuid,text)` receive no direct client EXECUTE grant. `private.place_bid(uuid)` is granted to `service_role`; the public wrapper remains the authenticated entry point.
- 38 table grant statements correspond to authenticated SELECT grants on 17 public tables and service_role privileges on all 21 public tables.
- The baseline defines all 11 app-owned triggers after the function definitions. This is a static ordering observation, not runtime permission verification.

## 3. Ordered migration dependency observations

A source-level pass inspected all 62 forward migration files and their DDL/object references. These sequencing relationships are material:

1. `20261116020000_admin_product_management_and_media.sql` creates the `product-media` bucket and its public-read/Admin-write Storage policies. The Supabase Storage schema is assumed to exist.
2. `20261116041000_member_support_tickets.sql` creates `support_tickets`; `20261116060000_support_ticket_notifications.sql` adds a notification trigger that depends on it.
3. `20261116070000_delivery_tracking_backend.sql` adds delivery tracking policies, triggers and RPCs; it depends on baseline winner-payment, member identity and feature-gate objects.
4. `20261116000000_financial_approval_guard.sql` establishes an initial private approval trigger function. `20261116080000_financial_activity_lockdown.sql` intentionally replaces/extends it and adds further financial activity triggers. Preserve timestamp order; do not select only one of the two migrations.
5. `20261115220000_inactive_until_verified_package_activation.sql` replaces the private signup and package-activation functions. `20261116150000_enforce_inactive_signup_until_verified.sql` later replaces the signup function again. The later definition is the intended final body.
6. `20261116100000_member_genealogy_pagination.sql` and `20261118250000_member_mlm_dashboard_pagination.sql` both define the same argument signature and JSONB return type for `get_my_mlm_dashboard_page`; the later definition replaces the earlier one. The later version adds Main-ID ownership validation and bounded search input.
7. `20261115230000_duplicate_under_id_placement_attribution.sql` initially defines the eight-column `member_list_my_ids()` result. `20261118200000_member_identity_ids_rpc.sql` correctly drops the exact zero-argument signature before recreating the seven-column contract, because PostgreSQL cannot change a table-returning function's row type with `CREATE OR REPLACE`.
8. `20261117110000_serialize_admin_duplicate_id_placement.sql` supplies the two-argument placement-aware Duplicate ID creation contract; later Duplicate ID lifecycle migrations replace/guard that workflow. The obsolete one-argument creation overload is explicitly removed.
9. `20261118220000_member_placement_tree_rpc.sql` creates the placement-tree RPC; `20261118380000_include_duplicate_ids_in_member_placement_tree.sql` later replaces it to include Duplicate IDs.
10. `20261118150000_package_receipt_uploads.sql` creates the private `package-receipts` bucket and initially allows an owner-folder SELECT policy. `20261118350000_private_package_receipt_storage.sql` adds the final named Admin-read policy, but the earlier permissive owner-read policy still exists at that intermediate point. `20261118370000_restrict_package_receipt_reads_to_admin.sql` drops the older owner-read policy and recreates the intended owner-folder INSERT and Admin-only SELECT policies. Therefore the complete ordered chain through `20261118370000` is required to reach the intended final receipt access state.
11. `20261118360000_admin_pending_activation_receipt_path.sql` adds the Admin receipt-path queue RPC after the receipt-path column and bucket are introduced.

These are source-order and signature observations, not a successful migration replay. A full dependency and semantic review remains open for any object reference, grants, RLS predicate or Supabase platform prerequisite not covered above.

## 4. Confirmed manifest test contract

`tests/clean-install-migration-manifest-integrity.test.ts` checks:
- Every timestamped migration exists.
- Forward and excluded lists contain no duplicates.
- The combined lists equal the exact sorted timestamped migration directory.
- Forward and excluded lists are individually sorted.
- Excluded migrations are historical (at or before the Production baseline cutoff), except the audit-log pagination migration whose effect is already in the captured baseline.
- The baseline retains its candidate-only and schema-only guard text and ends with `commit;`.

The test file itself was read, not executed.

## 5. CI observation at this checkpoint

GitHub Actions run #996 on the inspected branch head `f7274c13053ad593c3fa303560d0e4f06f51c42a` completed with failure (runs #989–#996 repeated the same test failure):
- 105/106 test files passed.
- 443/444 tests passed.
- The sole failure is `tests/admin-package-activation-report-filters.test.ts`, which expects the old literal expression `activationHistoryStatus==='all'?null:activationHistoryStatus`.
- The failure is a source-string assertion mismatch. Type-check/build and GitHub Pages subpath build were skipped because the test step failed.
- This is an automatically triggered CI result, not a manual final test phase. The stale assertion is recorded for the consolidated final test/repair phase; no code was changed to make the assertion pass in this batch.

## 6. Remaining blockers

- No canonical baseline has been executed against the isolated TEST project.
- The full 61-migration sequence has not been replayed or proven to compile in PostgreSQL.
- Function-body equivalence, grants, RLS, trigger behavior, Storage policies and frontend RPC integration remain unverified at runtime.
- The final receipt-storage state depends on the entire ordered sequence through migration `20261118370000`.
- Current branch CI #996 has one failing static assertion and no successful build step for that commit.
- Production remains read-only; TEST remains unchanged.

## 7. Next development work

1. Continue semantic dependency review of the baseline's 47 functions, 11 triggers, ACLs, identity sequences and all forward migration object replacements.
2. Reconcile the 61-migration list against the exact baseline object inventory and identify any prerequisite not created by either the baseline or Supabase platform.
3. Review frontend RPC contracts against final source function signatures and result shapes.
4. Keep all database replay and full integration testing for the agreed consolidated final testing phase, using TEST only.
5. Correct stale historical counts in the official status and audit documentation; never treat this candidate as production deployment SQL.


## Follow-up migration added after this audit

`20261118400000_admin_notification_recipient_lookup.sql` is the 62nd forward candidate. It adds a bounded, Admin-only recipient lookup for the Notifications UI. The forward manifest now includes it; static manifest integrity still needs to be run during the consolidated final test phase. No database has been modified.
