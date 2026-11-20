# Clean-install baseline function ACL reconciliation — 2026-11-18

## Scope

Source-only comparison of the candidate baseline with read-only Production PostgreSQL catalogue evidence. No application rows, member records, wallet balances, payment records, credentials or secrets were queried. No tests, builds, migration replay or database writes were performed.

## Function inventory

The candidate baseline contains 47 function definitions: 43 in public and 4 in private (enforce_feature_gate, handle_new_auth_user, place_bid(uuid), submit_package_activation(uuid,text)).

The candidate revokes function privileges from PUBLIC, anon, authenticated and service_role in both app schemas, then applies explicit per-signature grants.

## Public function ACL parity

- The baseline contains 43 unique authenticated EXECUTE grants for 43 public signatures, matching the Production inventory's 43/43 authenticated-executable public functions.
- The baseline grants anon EXECUTE on exactly one public function, public.lookup_sponsor(text), matching the Production inventory's 1/43 anon-executable exception.
- A fresh read-only Production catalogue query for this batch confirmed service_role EXECUTE on **43/43 public functions**. This matches the candidate's 43 explicit public service_role grants. The candidate additionally grants service_role EXECUTE on private.place_bid(uuid), as required by its private implementation boundary.
- Both overload pairs are granted by explicit signatures: admin_list_wallet_accounts() and admin_list_wallet_accounts(integer,integer); admin_list_wallet_transactions(integer,integer) and admin_list_wallet_transactions(uuid,integer,integer).
- There is no blanket function EXECUTE grant after the revocation block. Private trigger functions remain without grants to app-facing roles; only private.place_bid(uuid) is explicitly granted to service_role.

## audit_logs identity-sequence privileges — resolved with least privilege

A fresh read-only Production catalogue inspection found the live audit_logs_id_seq ACL grants SELECT, UPDATE and USAGE to anon, authenticated, postgres and service_role. The audit_logs table itself grants application table privileges only to service_role (plus postgres ownership); anon and authenticated have no direct table privileges.

The clean-install candidate previously granted sequence USAGE to anon, authenticated and service_role. That was not exact ACL parity and exposed sequence operations to roles that cannot insert into audit_logs. The candidate is now narrowed after its sequence-wide REVOKE:
- anon: no sequence privileges;
- authenticated: no sequence privileges;
- service_role: USAGE only, sufficient for nextval during its permitted audit_logs inserts;
- postgres retains ownership privileges.

SELECT and UPDATE on the sequence are not needed by the service_role audit insert path; anon/authenticated do not have audit_logs table INSERT privileges and do not need sequence access. This is an intentional least-privilege improvement in the candidate baseline, not a claim of byte-for-byte Production ACL parity. Production remains unchanged.

## Decision / remaining checks

1. Public function EXECUTE parity is now confirmed for authenticated (43/43), anon (1/43, lookup_sponsor only) and service_role (43/43).
2. The candidate deliberately narrows audit_logs_id_seq privileges to service_role USAGE only. No Production ACL was changed.
3. Function-body equivalence, exact SECURITY DEFINER authorization semantics, trigger behavior, and successful clean replay remain open. Continue complete baseline function-body and forward-migration semantic review.
4. Do not execute the candidate against Production. TEST replay remains deferred until the development-complete gate and explicit authorization.
