# Production financial RPC review — 2026-11-16

## Scope and safety

- Repository branch: `completion-work`
- Production project: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`), PostgreSQL 17.11, `ap-south-1`.
- Read-only inspection of live PostgreSQL function definitions, signatures and EXECUTE privileges.
- No Production DDL/DML, settings, migrations, Auth, Storage, wallet or financial operations were performed.

## CI correction

- Commit `3137f22230c0a519d890f9d719df4c1d773087d9` added Admin UI source assertions but initially omitted loading `src/components/Admin.tsx` in the test.
- CI run `43853959911` failed only because the test referenced an undefined `admin` variable (2 test failures; 211 tests passed).
- Commit `f2bce4c5b9e8608a91a3d13d8064d1aa86bc3dbe` adds the missing source-file read.
- CI run `43854387609` for that commit completed successfully.

## Live package approval and feature-toggle exposure

- `admin_review_package_activation(uuid,boolean)` is SECURITY DEFINER, requires authenticated Admin app_metadata, locks the activation, Main ID and Bid Wallet rows, and on approval credits the Bid Wallet, inserts a ledger transaction, activates the package and writes an audit log.
- The live function does not itself check a trusted `financial_model_approved` owner-approval setting.
- Live `admin_set_feature_setting(text,boolean)` also lacks that owner-approval check. Its enable allowlist includes `package_activations_enabled`, `bid_wallet_enabled` and `income_wallet_enabled`.
- The source branch migration `20261116080000_financial_activity_lockdown.sql` contains the stronger owner-approval guard and forces financial switches off, but it is not applied in Production.
- Do not approve package activations, issue wallet credits or enable financial switches in Production. Do not treat the frontend lock as a substitute for a database guard.

## Live withdrawal workflow findings

### Member request RPC

Live `member_create_withdrawal_request(numeric,jsonb)`:
- Requires an authenticated user, positive amount rounded to two decimals, and a JSON object for payout details (maximum serialized length 2,000).
- Checks `withdrawals_enabled`.
- Resolves `profiles.main_member_id`, locks the Income Wallet row and checks the current balance.
- Rejects a request if that member already has an open request in `pending`, `approved` or `processing`.
- Inserts a `pending` withdrawal request and an audit log row.

Gaps/limitations observed in this function:
- It does not reserve or debit the Income Wallet balance when the request is created. The wallet balance can therefore remain apparently available while a request is pending; downstream processing must independently reserve/reconcile funds atomically before any payout.
- The function does not enforce an Admin-configured minimum withdrawal amount.
- It resolves the Main ID from the profile but does not independently check that the Main ID is active.
- This inspection did not establish a safe end-to-end withdrawal settlement path.

### Admin workflow

- Live `admin_list_withdrawal_requests(integer,integer)` is a read/list RPC with Admin metadata authorization and bounded pagination.
- The inspected public RPC inventory did not contain an Admin approve/reject/process/paid withdrawal mutation RPC. Do not infer that the UI can safely settle withdrawals.
- Source-only `20261116080000_financial_activity_lockdown.sql` adds a database interlock on withdrawal request creation and status transitions, but that trigger is not deployed to Production.

## Other live financial RPC catalogue

Observed relevant public RPCs include:
- `place_bid(uuid)` — SECURITY DEFINER wrapper around `private.place_bid(uuid)`.
- `submit_package_activation(uuid,text)` — SECURITY DEFINER wrapper around `private.submit_package_activation(uuid,text)`.
- `member_list_my_withdrawals()`.
- Admin wallet account, wallet transaction and withdrawal request list RPCs.

The relevant listed functions deny EXECUTE to `anon` and grant it to `authenticated`; the function bodies still require individual authorization and side-effect review. The wallet and withdrawal Admin list functions reviewed check Admin app_metadata. No conclusion about all other financial RPCs is implied by this limited sample.

## Required engineering before financial activation

1. Reconcile Production migration history and live object definitions; do not replay the source migration folder wholesale.
2. Install and independently verify a fail-closed owner-approval interlock on the actual Production schema only after explicit owner approval.
3. Implement a withdrawal reservation/settlement model using atomic ledger entries, idempotency, balance reservation and compensating transactions; never edit/delete ledger history.
4. Enforce active Main-ID eligibility and configured minimums server-side.
5. Implement audited Admin approve/reject/process/paid actions with safe concurrency and payout reconciliation, or keep withdrawals disabled.
6. Test all money-moving paths in a disposable non-Production project before rollout.

## Completion boundary

This is a read-only Production RPC review plus source-side CI test repair. It is not a penetration test, complete RPC audit, migration rehearsal, live E2E test or launch certification. No Production state was changed.
