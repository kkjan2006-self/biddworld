# BiddWorld Production read-only catalog and RPC snapshot — 2026-11-16

## Scope and safety

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Branch HEAD inspected: `7b447936e72ef95647536195f4c3897357328a40`
- Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`), region `ap-south-1`, PostgreSQL `17.11.0.019`, status `ACTIVE_HEALTHY`.
- This snapshot used read-only project metadata, migration listing, table catalog, and SELECT/catalog queries only.
- No DDL, DML, migration, setting, Auth, Storage, wallet, or financial operation was executed.

## Latest source CI

- GitHub Actions workflow run: `43798685460`
- Branch: `completion-work`
- Commit: `7b447936e72ef95647536195f4c3897357328a40`
- Result: `success` (completed).

## Production catalog counts observed

| Catalog item | Count |
|---|---:|
| Public application tables | 21 |
| Public routines | 43 |
| Non-internal public-table triggers | 10 |
| Public RLS policies | 20 |
| Storage buckets | 0 |
| Applied Supabase migrations | 30 |

Latest applied migration: `20261115163218_admin_audit_log_pagination`.

The current catalog count of 10 public triggers differs from older recovery notes that reported 17. Treat this fresh query as the current snapshot and re-check before any rollout. All 21 public tables reported RLS enabled in the table inventory. This does not certify policy completeness or function safety.

## Critical live Production findings

### 1. Package approval is not protected by the owner financial approval interlock

The live `public.admin_review_package_activation(uuid,boolean)` is SECURITY DEFINER, pins an empty search_path, and checks the trusted Admin app_metadata role. However, its approval path updates the Bid Wallet balance, inserts a `wallet_transactions` credit, and approves/activates the package without checking a separate owner financial approval gate.

The source-only financial approval and activity-lockdown migrations are not in the Production migration ledger. Do not approve package activations or run wallet/bid/commission/withdrawal/settlement operations in Production.

### 2. Current Production feature values include enabled financial switches

The read-only `app_settings` snapshot returned:

- `package_activations_enabled = true`
- `bid_wallet_enabled = true`
- `income_wallet_enabled = true`
- `bidding_enabled = false`
- `fixed_bid_enabled = false`
- `duplicate_ids_enabled = false`
- `referral_commissions_enabled = false`
- `withdrawals_enabled = false`
- `winning_payment_enabled = false`
- No `financial_model_approved` row was returned.

The live `admin_set_feature_setting(text,boolean)` routine's accepted key list includes package activation and wallet switches. Its current enable allowlist includes package activation, Bid Wallet and Income Wallet. This means the database currently lacks the source branch's owner-only financial interlock and a normal Admin feature-setting RPC can enable these currently allowed keys. Do not change any setting in this audit. This is a high-priority blocker for a separately approved, forward-only security migration after full reconciliation and disposable testing.

### 3. Public sponsor lookup still discloses member display name

Live `public.lookup_sponsor(text)` returns `(member_code, display_name)`, is SECURITY DEFINER, and its ACL grants EXECUTE to `anon`, `authenticated`, and `service_role`. The source branch has a newer privacy-minimized exact-match boolean contract, but it is not deployed. This is a public enumeration/PII exposure risk; do not apply the source migration until reconciled and tested.

### 4. Duplicate ID RPC signature drift is confirmed

Production exposes `admin_create_duplicate_member_id(p_main_member_code text)` (one argument). The current branch's placement-aware flow expects the two-argument contract. The branch Admin flow must not be treated as Production-compatible until the authoritative forward migration is reconciled, tested in a disposable database, and separately approved for rollout.

### 5. Referral plan depth remains hard-coded to five in Production

Live `admin_save_referral_plan_draft(uuid,jsonb)` rejects any rule array not exactly five entries and writes eligibility metadata with `max_depth = 5`. The branch migration for configurable referral depth is not recorded in Production.

### 6. Product media Storage is not provisioned in Production

The catalog query returned zero rows in `storage.buckets`. Product media upload UI/source foundation therefore does not establish that a Production bucket or Storage policies exist. Do not upload objects or create buckets in Production as part of this audit.

## Security catalog observations

- The 20 observed public RLS policies are SELECT policies; table RLS being enabled and SELECT policies existing do not prove all required writes are safely implemented.
- The targeted live RPCs above use SECURITY DEFINER and pin search_path, but that is not sufficient by itself: authorization, exact grants, caller ownership, state transitions, idempotency, and side effects must each be reviewed.
- The full function body and ACL inventory was queried for the target routines only in this snapshot. The remaining routines still require a complete body-by-body security review.
- Production has existing member and financial data. No row contents or personally identifying member details are reproduced here.

## Required next bulk batch

1. Recover authoritative SQL for every Production migration version that has no same-version source file; do not fabricate migration history.
2. Build a complete live object matrix for all 43 public routines, 10 public triggers, 20 policies, grants, views, and Storage.
3. Diff source versus live definitions, including the five confirmed high-risk RPC/settings/Storage findings above.
4. Design a forward-only migration sequence only after every historical source and live object is mapped.
5. Rehearse the complete ordered sequence, failure rollback, concurrency, RLS, and RPC behavior in a disposable non-Production PostgreSQL/Supabase environment.
6. Keep Production untouched until the owner explicitly approves a reviewed migration plan.
7. Keep all real financial actions disabled. The retained draft package economics remain unsafe: ₹3,000 revenue against ₹3,500 Bid Wallet credit plus up to ₹1,000 referral obligations.

## Completion status

This snapshot improves evidence quality; it does not complete migration reconciliation, deploy any change, or certify launch readiness. The branch CI success is source-level evidence only, not live integration or Production certification.
