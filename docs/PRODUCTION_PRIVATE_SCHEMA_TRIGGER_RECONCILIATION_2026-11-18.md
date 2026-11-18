# BiddWorld Production private-schema and trigger reconciliation — 2026-11-18

## Scope and safety

- Inspected Production project `hbqatszyzqobgtauyuzy` using read-only PostgreSQL catalogue queries only.
- No table rows, member data, wallet data, auth credentials, or secrets were exported.
- No DDL/DML, migration replay, test, build, or deployment was run.
- Production and TEST databases remain unchanged.

## Current repository inventory

At branch `completion-work`, the repository contains **66 SQL files in `supabase/migrations`**:
- 63 timestamped migration files.
- 3 legacy/unversioned files: `0001_biddworld.sql`, `0002_place_bid_rpc.sql`, and `001_initial_schema.sql`.
- One additional SQL audit script is outside the migration directory: `supabase/audit/production_migration_recovery.sql`.
- Total repository SQL files: **67**.

The empty `001_initial_schema.sql` and incompatible `0001_biddworld.sql` remain disqualified as a clean-install baseline.

## Production app-owned private schema

Production has an app-owned `private` schema, owned by `postgres`, containing exactly four functions:

| Function | Return | Security | Current source alignment |
|---|---|---|---|
| `private.enforce_feature_gate()` | trigger | SECURITY DEFINER, empty search_path, postgres-only EXECUTE | Final body is represented by `20261115154510_extend_wallet_and_sponsor_feature_gates.sql`; earlier versions are superseded by `20261115154434_fix_feature_gate_trigger_row_access.sql` and this extension |
| `private.handle_new_auth_user()` | trigger | SECURITY DEFINER, empty search_path, postgres-only EXECUTE | Signup/sponsor-gated final body is represented in `20261115154433_enforce_platform_feature_switches.sql`; initial provisioning is in `20261114161950_secure_bid_rpc_and_signup_provisioning.sql` |
| `private.place_bid(uuid)` | jsonb | SECURITY DEFINER, fixed `pg_catalog, public` search_path; postgres/service_role EXECUTE only | `20261114161950_secure_bid_rpc_and_signup_provisioning.sql` |
| `private.submit_package_activation(uuid,text)` | jsonb | SECURITY DEFINER, empty search_path, postgres-only EXECUTE | The original private implementation is in the package activation submission source migration; the public wrapper contract must be reconciled with later idempotency/receipt replacements |

The schema must be created as an app-owned schema in a future clean-install baseline. Do not attempt to recreate Supabase-managed `auth`, `storage`, `realtime`, `vault`, `extensions`, or `supabase_migrations` schemas.

## Trigger inventory

Production has one app-owned trigger on `auth.users`:

- `on_biddworld_auth_user_created`: AFTER INSERT, calls `private.handle_new_auth_user()`.
- The trigger provisions a profile, Main ID and empty Bid/Income wallet accounts, and conditionally links the sponsor according to platform settings.
- The current function rejects signup when `registration_enabled` is false and validates the selected/default sponsor when sponsor referrals are enabled.

Production has **10 non-internal triggers across public tables**. All call `private.enforce_feature_gate()`:

| Table | Trigger | Event |
|---|---|---|
| `bids` | `enforce_bid_wallet_and_bidding_features` | BEFORE INSERT |
| `delivery_tracking` | `enforce_delivery_tracking_feature` | BEFORE INSERT OR UPDATE |
| `fixed_bid_campaigns` | `enforce_fixed_bid_feature` | BEFORE INSERT OR UPDATE OF status |
| `member_ids` | `enforce_duplicate_id_feature` | BEFORE INSERT OR UPDATE OF status, id_type |
| `package_activations` | `enforce_package_activation_feature` | BEFORE INSERT OR UPDATE OF activation_status |
| `referral_commissions` | `enforce_referral_commission_feature` | BEFORE INSERT OR UPDATE OF status |
| `referrals` | `enforce_sponsor_referral_feature` | BEFORE INSERT OR UPDATE |
| `wallet_transactions` | `enforce_package_wallet_credit_feature` | BEFORE INSERT |
| `winning_item_payments` | `enforce_winning_payment_feature` | BEFORE INSERT OR UPDATE OF status |
| `withdrawal_requests` | `enforce_withdrawal_feature` | BEFORE INSERT |

The previous schema snapshot's 17-trigger figure is a broader catalogue count. This audit specifically counts non-internal application triggers on `public` plus the separate app-owned trigger on `auth.users`; do not mix these counting scopes.

## Feature-gate body reconciliation

The live `private.enforce_feature_gate()` uses JSONB conversion of NEW/OLD trigger rows to avoid referencing an unavailable OLD/NEW record in INSERT/UPDATE branches. Its final behavior covers:

- Duplicate ID activation.
- Sponsor referral insert/update.
- Package activation submission/activation.
- Bid and Income wallet transaction gating based on the wallet account type.
- Auction bid feature and wallet debit feature gates.
- Referral commission credit only when the source package activation is approved and active.
- Withdrawal requests.
- Fixed Bid campaign publication/live state.
- Winning payment paid state.
- Delivery tracking changes.

The final Production body aligns with the later source migration `20261115154510_extend_wallet_and_sponsor_feature_gates.sql`; do not treat the earlier migration bodies as the final implementation in a clean replay. Preserve the full migration order so the final replacement is applied after the earlier function definition.

## Installed extensions

The Production catalogue reports:
- `pgcrypto 1.3`
- `pg_stat_statements 1.11`
- `plpgsql 1.0`
- `supabase_vault 0.3.2`
- `uuid-ossp 1.1`

Only required application dependencies should be represented in the clean-install plan. Supabase-managed extensions and schemas must be treated as platform prerequisites, not recreated from application SQL.

## Clean-install implications and remaining work

1. The private schema and its four functions are now explicitly catalogued as required app-owned objects.
2. The auth.users trigger must be recreated only after the private signup function and all referenced public tables/functions exist. The trigger is app-owned even though it attaches to a Supabase-managed table.
3. The 10 public feature-gate triggers must be recreated after their target tables and the final `private.enforce_feature_gate()` body exist.
4. Preserve the private function ACLs: trigger functions are not client-callable; `private.place_bid(uuid)` is restricted to postgres/service_role and reached through the public invoker wrapper.
5. Continue reconciling all 43 public functions, all 243 constraints, 60 indexes, 20 RLS policies, table/sequence grants, storage buckets/policies, and migration dependencies against source files.
6. The repository migration directory is still not a canonical replayable baseline. Do not replay it wholesale to TEST or Production until dependency order and structural equivalence have been established.

## Checkpoint

- Branch: `completion-work`
- Verified HEAD: `e7050df1c973c6c73ce4ca6e94a84439a530c0f4`
- No database writes or migration applications.
- No build/tests run; final testing remains deferred until development is complete.


## Storage catalogue reconciliation

A separate read-only Production query confirmed that `storage.buckets` and `storage.objects` exist, but the live project currently has:
- **0 Storage buckets**
- **0 Storage RLS policies**
- `storage.objects` has RLS enabled.

The branch source migrations declare two application buckets that are therefore source-only and not installed in Production:

| Bucket | Source migration | Intended access |
|---|---|---|
| `product-media` | `20261116020000_admin_product_management_and_media.sql` | Public read; authenticated Admin-only insert/update/delete; JPG/PNG/WebP; 5 MB |
| `package-receipts` | `20261118150000_package_receipt_uploads.sql` | Private; owner upload/read and Admin read; no member delete; JPG/PNG/PDF; 5 MB |

This is an explicit frontend/backend deployment gap: the source supports product image and package receipt storage, but the Production Storage catalogue currently has no buckets or policies. Do not create these in Production as part of development. Include them in the eventual clean-install/TEST replay and verify both bucket metadata and policy predicates there before any deployment decision.
