# Signup-to-package-activation status synchronization audit — 2026-11-17

## Scope

Read-only review of the final source definitions on `completion-work` for signup provisioning, package activation submission, Admin review, financial/feature interlocks, and the member dashboard. This audit does not apply or execute migrations.

## Current intended path found in source

1. The final signup migration creates the Profile and Main ID with `inactive` status. It preserves the registration and sponsor feature switches.
2. The final private package-request implementation allows the authenticated owner to submit a request against their Main ID without requiring that Main ID to already be active. It creates only a pending activation request; it does not update profile/member status or write wallet ledger rows.
3. The public request wrapper remains authenticated-only. The later private implementation checks both `package_activations_enabled` and `financial_model_approved`, defaulting missing values to false.
4. Admin approval locks the pending activation, validates its Main ID, locks the Bid Wallet, writes the wallet balance and idempotent ledger entry, then changes the activation to approved/active. These operations occur within the RPC transaction.
5. A separate trigger promotes an inactive Main ID and its inactive Profile to active only after the activation row changes to approved/active.
6. Financial interlock triggers reject package activation approval and wallet ledger credits while `financial_model_approved` is false. The feature-gate trigger separately enforces the package activation switch. The Admin UI also has a fail-closed lock.

## Important state-synchronization limitation

The activation trigger updates the Main ID only when its current status is `inactive`. It separately updates the owning Profile only when that Profile's current status is `inactive`; the Profile update is joined to the Main ID but does not require the Main ID update to have succeeded.

Consequently, if a legacy or future lifecycle state creates a mismatch such as Main ID `suspended` with Profile `inactive`, a verified activation can leave the Main ID suspended while changing the Profile to active. Likewise, any non-inactive status is deliberately not overwritten by this trigger. The trigger does not currently assert that the final Profile and Main ID statuses are equal.

This is a source-level edge case, not evidence that any Production member is currently in that state.

## Other lifecycle boundaries

- The final request RPC does not filter Main ID status. That is necessary for first-time inactive members, but the desired treatment of suspended/closed Main IDs is not yet specified.
- The Admin approval RPC validates that the target is a Main ID, but it does not itself decide whether suspended/closed Main IDs may receive an activation credit. Existing financial and feature-gate triggers do not define that account lifecycle policy.
- The member dashboard calculates its activation lock using both Profile and Main ID status, which is safer than trusting either field alone.
- The package catalogue is informational-only in the current UI and explicitly says it is not accepting payments or activation requests. Admin approval and financial switches are also fail-closed in the UI.

## Safe follow-up

Before adding lifecycle writes, define the permitted activation target statuses and the expected result for each combination of Profile status and Main ID status. In particular, distinguish a new inactive member from a suspended or closed Main ID. Then implement the promotion as a single, consistency-checked server-side operation and test it in a disposable Supabase project.

## Verification and data boundary

This is a static review of source migrations and frontend code. It is not a live Auth, trigger, or PostgreSQL integration test. No Production Supabase schema, setting, member, activation, wallet, or ledger row was read or changed by this batch. The existing production project remains read-only; a separate free test project is still required for integration verification.
