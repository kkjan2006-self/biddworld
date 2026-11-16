# Production RPC Security and Contract Matrix — 2026-11-17

## Snapshot and method

- Repository source: `completion-work`.
- Live backend: `BiddWorld-Production` / `hbqatszyzqobgtauyuzy`.
- Read-only catalogue and function-definition inspection. No RPC was invoked.
- This is a static contract/security review, not an execution test or launch certification.

## Catalogue and privilege summary

| Check | Live result |
|---|---:|
| Public functions (including overloads) | 43 |
| Admin function overloads | 36 across 34 names |
| Admin overloads with both `auth.uid()` and JWT `app_metadata` role guard markers | 36/36 |
| Admin overloads executable by anon | 0 |
| Admin overloads executable by authenticated | 36 |
| SECURITY DEFINER functions with explicit function search_path | 43/43 |
| SECURITY DEFINER functions executable by anon | 1 |

The 36 Admin overloads are callable by authenticated sessions because authorization is enforced inside each SECURITY DEFINER function. The legacy `admin_list_members_sponsors()` is SQL rather than PL/pgSQL: its authorization is in the query predicate (`auth.uid() is not null` and JWT app_metadata role equals `admin`) and it returns no rows otherwise. A text scan looking only for an exception string would misclassify it; the actual body was inspected.

## RPC contract matrix — current Production

| RPC / family | Live signature | Caller boundary observed | Current contract / finding |
|---|---|---|---|
| Admin RPC family (34 names / 36 overloads) | 36 overloads | Authenticated EXECUTE; no anon EXECUTE; all 36 bodies contain auth UID + app_metadata role guard markers | Admin role is checked inside the function. Continue semantic review of each mutation and output; ACL alone is not authorization. |
| `lookup_sponsor` | `(p_member_code text)` | anon + authenticated | SECURITY DEFINER; no auth UID requirement; returns member_code and display_name. Only anon-callable SECURITY DEFINER function. Source migration changes it to boolean, but is not deployed. |
| `place_bid` public/private | `(p_auction_id uuid)` | Authenticated public wrapper; private implementation is auth-gated | Private body requires auth, active Main ID and bidding feature, locks auction and wallets, debits Bid Wallet first then Income Wallet. It generates a new UUID per call, so client retries are not stable/idempotent. UI already calls two-argument `(uuid,text)`; source migration exists but live signature is old. |
| `submit_package_activation` public/private | `(p_package_id uuid, p_payment_reference text)` | Authenticated public wrapper; private implementation is auth-gated | Private body requires auth and an active Main ID. Source lifecycle expects inactive signup to submit a pending request; live implementation therefore conflicts with intended onboarding. Latest source wrapper-lock migration is not deployed. |
| `member_create_withdrawal_request` | `(p_amount numeric, p_payout_details jsonb)` | Authenticated; body checks auth UID | Checks amount shape, withdrawal setting, Income Wallet balance and open request. Live body does not enforce active Main ID ownership; source migration adds it. |
| `member_list_my_withdrawals` | `()` | Authenticated; body checks auth UID and resolves caller's profile Main ID | Live response returns full payout_details JSON. Source migration narrows it to method label only. |
| `get_my_mlm_dashboard` | `()` | Authenticated; body derives caller identity via auth UID | Legacy non-paginated contract. Current UI expects `get_my_mlm_dashboard_page`, which is absent. |
| `get_my_placement_tree` | `()` | Authenticated; body derives caller identity via auth UID | Name/argument shape matches UI; returned structure has been inspected against the component but not integration-tested. |
| `admin_list_members_sponsors` | `()` | Authenticated EXECUTE; no anon EXECUTE; SQL predicate checks auth UID + app_metadata Admin role | Legacy non-paginated directory returns member code, display name, phone, sponsor code and created time. Current UI expects missing paginated `admin_list_members_sponsors_page`. |
| `admin_list_duplicate_ids` | `()` | Authenticated Admin-only function | Legacy non-paginated response; current UI expects missing paginated `admin_list_duplicate_ids_page`. |
| `admin_create_duplicate_member_id` | `(p_main_member_code text)` | Authenticated Admin-only function | Live one-argument signature; current UI passes a second placement-under ID argument. Source placement-aware contract is not deployed. |

## Admin authorization review

- All 36 Admin overloads inspected have both an authenticated identity check and an `auth.jwt()->'app_metadata'->>'role'` check.
- None of those overloads is executable by anon in the inspected privilege snapshot.
- All are executable by authenticated, which is expected for an RPC architecture only because the body guard is present.
- The `admin_list_members_sponsors()` SQL body enforces the guard in its WHERE predicate rather than raising an exception.
- This review establishes presence of role gates, not that every query's row scope, state transitions, or response fields are correct. Mutation RPCs still need individual behavior tests using member/support/finance/admin JWT roles in a disposable database.

## Additional implementation risk: sponsor graph concurrency

The live `admin_set_member_sponsor(text,text)` checks self-sponsorship and recursively checks whether the proposed sponsor is already in the member's descendants before upserting the referral edge. The matching source migration `20261114183454_prevent_circular_member_sponsor_changes.sql` contains the same check but does not serialize graph mutations with an advisory lock or a deterministic row-lock protocol. Two concurrent sponsor changes can both validate against the pre-change graph and then race. This remains a source-level concurrency gap; do not run live sponsor mutations to test it. Prepare a serialized graph-write implementation and a concurrent regression test for the disposable TEST project.

## Known UI/live mismatches retained

The existing frontend contract audit identifies eight UI RPC names absent in Production:
- `public_list_active_products_page`
- `member_get_my_identity`
- `member_list_my_ids`
- `member_update_my_profile`
- `admin_list_members_sponsors_page`
- `admin_list_duplicate_ids_page`
- `admin_set_product_active`
- `get_my_mlm_dashboard_page`

Three live names also have incompatible contracts:
- `admin_create_duplicate_member_id`: one live argument versus two UI arguments.
- `place_bid`: one live argument versus two UI arguments.
- `lookup_sponsor`: live table result versus source boolean result.

## Priority sequence

1. Rehearse and validate the source-only sponsor lookup privacy change, withdrawal ownership guard, member payout-data minimization, signup lifecycle, idempotent bid RPC and package submission lock in a disposable TEST database.
2. Add a transaction-scoped advisory lock or a provably safe ordered locking strategy around sponsor graph validation and mutation; add concurrent cycle-attempt regression coverage.
3. Reconcile all UI RPC signatures and result shapes, then integration-test each against the TEST database.
4. Inspect every Admin mutation's allowed state transitions, feature gates, ownership constraints and audit writes; keep the role guard in place.
5. Do not apply migrations to Production until full historical replay and forward migration rehearsal are complete.

## Safety

Read-only metadata/function-definition inspection only. No live function execution, DDL, DML, Auth, Storage, wallet, payment, bidding, withdrawal or member mutation was performed. The `main` branch remains unchanged.
