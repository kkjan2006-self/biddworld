# BiddWorld Production Reconciliation Audit — 2026-11-15

## Scope and safety
- Target: Supabase project `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`), Mumbai region.
- Repository: `kkjan2006-self/biddworld`, default branch `main`.
- This audit was read-only. No Production schema, data, auth users, migration history, or GitHub application code was changed as part of the database audit.
- Do not replay historical migrations or mark migrations applied until every object and dependency is reconciled.

## Live migration history
Production reports exactly these five migration versions:
1. `20261114161950_secure_bid_rpc_and_signup_provisioning`
2. `20261114181107_sponsor_referral_validation_and_admin_management`
3. `20261114181114_admin_member_sponsor_listing`
4. `20261114183412_secure_admin_member_sponsor_directory`
5. `20261114183454_prevent_circular_member_sponsor_changes`

The repository's current default branch did not return files for at least the historical paths checked for versions `20261114181107` and `20261114181114`. This is a migration-source/history reconciliation issue; a 404 from the current branch does not prove the files never existed in Git history.

## Live RPC inventory
The following RPCs exist in Production:
- `admin_get_member_structure()`
- `admin_get_mlm_overview()`
- `admin_list_members_sponsors()`
- `get_my_mlm_dashboard()`
- `lookup_sponsor(text)`

The following RPCs called by the current Admin/Packages UI were not found in Production:
- `submit_package_activation(uuid,text)`
- `admin_list_pending_activations()`
- `admin_review_package_activation(uuid,boolean)`
- `admin_list_audit_logs(integer)`

The current repository contains a migration named `20261115020000_admin_package_activation_review.sql` that defines package activation review RPCs and also replaces MLM dashboard functions. That migration is not in Production's reported migration history. The repository's expected earlier package activation migration `20261115010000_package_activation_workflow.sql` was not found on the current default branch at the checked path. The later migration must not be applied alone without reconstructing and validating all prerequisites.

## Confirmed live schema details
- `package_activations` currently has no `bid_wallet_credit` column.
- `package_activations.payment_status` permits: `pending`, `approved`, `rejected`, `refunded`.
- `package_activations.activation_status` permits: `pending`, `active`, `rejected`, `cancelled`.
- `referral_commissions.status` permits: `pending`, `credited`, `reversed`.
- `member_ids.id_type` permits `main` and `duplicate`; status permits `pending`, `active`, `suspended`, `closed`.
- Wallet transaction idempotency key is unique.
- All 20 public tables were previously observed with RLS enabled.
- Production currently has zero Auth users, Main IDs, Duplicate IDs, referrals, and package activation rows. No live member balances or activation records were found in the earlier read-only inventory.

## Security observation
- `lookup_sponsor(text)` is SECURITY DEFINER and its current ACL includes `anon`, `authenticated`, and `service_role`.
- Do not revoke anonymous execution blindly: signup sponsor validation may rely on this public lookup. First inspect the function body, returned fields, input validation, rate-limit strategy, and frontend call sites. Narrow the response to only the minimum sponsor-validation data and preserve signup functionality.
- The four admin/member RPCs listed above are SECURITY DEFINER and executable by authenticated. Their function bodies must be reviewed for explicit `auth.uid()` and admin-role checks before declaring them secure.
- Supabase Security Advisor had already flagged the public sponsor lookup and SECURITY DEFINER functions for review.

## Current frontend/backend mismatch
- `src/components/Packages.tsx` submits package activation through `submit_package_activation`.
- `src/components/Admin.tsx` calls `admin_list_pending_activations`, `admin_review_package_activation`, and `admin_list_audit_logs`.
- These four RPCs were absent from the live Production RPC inventory above. Consequently, these UI flows cannot work against the current Production database until a reviewed migration is deployed.
- The Admin component also uses direct table counts for several totals. With RLS, those counts must not be presented as global totals unless an explicit authorized server-side aggregate is used.

## Safe forward plan
1. Recover the exact source of all five applied historical migrations from Git history/backups and compare each with the live schema. Do not synthesize replacement historical migrations.
2. Produce a full schema diff covering columns, constraints, indexes, triggers, RLS policies, grants, functions, and function bodies.
3. Reconstruct the missing package activation base migration from the actual current schema and the intended feature contract. Validate all referenced columns, enum/check values, audit fields, wallet constraints, and idempotency behavior.
4. Prepare one or more new, forward-only migrations with new timestamps. Keep them unapplied until reviewed.
5. Add a server-side admin overview aggregate that checks the JWT admin role and returns global counts; remove misleading direct table counts from the Admin UI.
6. Add package submission/review/audit RPCs only after prerequisite schema and authorization checks pass. Approval must atomically update activation state, wallet balance, transaction ledger, and audit log.
7. Test on an isolated Supabase branch or disposable environment with SQL assertions and authenticated/unauthenticated role tests before Production deployment.
8. After deployment, verify RPC inventory, RLS, advisor results, application tests, and actual frontend calls. Do not enable bidding or real-money activity as part of reconciliation.

## Explicitly not inferred or enabled
- No placement slot assignment or binary/matrix placement rules.
- No referral commission rates, payout percentages, withdrawal limits, or winner-payment rules.
- No Admin account creation or role assignment.
- No Production migration application, data seeding, or wallet crediting.
