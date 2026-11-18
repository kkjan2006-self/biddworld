# Clean-install baseline function ACL reconciliation — 2026-11-18

## Scope

Source-only comparison of the candidate baseline with the read-only Production public RPC security inventory. No database was queried in this batch. No tests, builds, migration replay or database writes were performed.

## Function inventory

The candidate baseline contains 47 function definitions: 43 in public and 4 in private (enforce_feature_gate, handle_new_auth_user, place_bid(uuid), submit_package_activation(uuid,text)).

The candidate revokes function privileges from PUBLIC, anon, authenticated and service_role in both app schemas, then applies explicit per-signature grants.

## Public function ACL parity

- The baseline contains 43 unique authenticated EXECUTE grants for 43 public signatures, matching the Production inventory's 43/43 authenticated-executable public functions.
- The baseline grants anon EXECUTE on exactly one public function, public.lookup_sponsor(text), matching the Production inventory's 1/43 anon-executable exception. No other public function receives anon EXECUTE in the candidate ACL block.
- The baseline also grants service_role EXECUTE on all 43 public functions and on private.place_bid(uuid), 44 signatures total. The Production public RPC inventory does not record a service_role privilege result, so exact live service-role ACL parity remains unverified. Do not claim this role's grants have been live-reconciled.
- Both overload pairs are granted by explicit signatures: admin_list_wallet_accounts() and admin_list_wallet_accounts(integer,integer); admin_list_wallet_transactions(integer,integer) and admin_list_wallet_transactions(uuid,integer,integer).
- There is no blanket function EXECUTE grant after the revocation block. Private trigger functions remain without grants to app-facing roles; only private.place_bid(uuid) is explicitly granted to service_role.

## Sequence privilege observation

The candidate revokes all sequence privileges from app-facing roles, then grants USAGE on public.audit_logs_id_seq to anon, authenticated and service_role. The baseline defines audit_logs.id as bigint GENERATED ALWAYS AS IDENTITY. The Production RLS/function-grant audit documents direct table grants but does not provide the corresponding sequence ACL snapshot or explain why anon and authenticated require sequence USAGE.

This is an ACL question requiring authoritative live catalogue evidence and a PostgreSQL identity-sequence privilege review. Do not remove or retain these grants based only on assumption. Reconcile the exact Production sequence ACL and identity insert behavior before approving the executable baseline.

## Decision / outstanding checks

1. Public function count and authenticated/anon ACL counts align with the 2026-11-18 Production RPC inventory.
2. The candidate's service_role EXECUTE grants are explicit, not accidental PUBLIC grants, but live parity has not yet been proven.
3. audit_logs_id_seq USAGE grants to anon and authenticated remain an unexplained least-privilege item pending exact source evidence.
4. Count parity does not certify function-body equivalence, exact SECURITY DEFINER authorization predicates, search_path parity, trigger execution privileges or successful clean replay. Continue per-function and migration dependency review.
5. Do not make speculative ACL changes. No Production or TEST changes were made.
