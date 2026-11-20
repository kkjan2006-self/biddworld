# Registration and Main ID activation lifecycle review — 2026-11-16

## Scope
Compared the member registration UI, branch signup migrations and live Production Auth trigger/settings. Production access was read-only. No signup, member record, feature setting, migration or wallet data was changed.

## Registration UI
The current signup modal:
- advertises free registration and says package activation is separate;
- treats Sponsor Referral ID as optional and verifies a supplied ID before submission;
- sends name, phone and sponsor ID as Auth user metadata;
- tells the user after signup that the account remains INACTIVE until the required Admin verification process is completed.

This messaging is consistent with the intended safe registration experience.

## Live Production state
The current Production settings read returned:
- `registration_enabled=true`;
- `sponsor_referrals_enabled=true`;
- `duplicate_ids_enabled=false`;
- `package_activations_enabled=true`;
- `bid_wallet_enabled=true`.

The configured default sponsor resolves to an existing active Main ID. This means the optional-sponsor signup path has a valid configured fallback in the inspected snapshot.

The live `auth.users` trigger calls `private.handle_new_auth_user()`. Its current function definition still creates new profiles and Main IDs with status `active`. Therefore the currently deployed signup behavior does not match the member-facing UI statement that a newly registered account remains inactive.

## Branch state
The branch contains `20261116150000_enforce_inactive_signup_until_verified.sql`, which replaces the Auth trigger function while preserving:
- the registration feature-switch check;
- sponsor-referral feature-switch enforcement;
- validation of a supplied active Main ID;
- validation of the configured default sponsor;
- zero-balance Bid and Income Wallet creation;
- referral relationship creation where applicable.

It creates new profiles and Main IDs with `inactive` status. The trigger already attached to `auth.users` continues to call the replaced function; the migration does not need to recreate the trigger.

This migration is not applied to Production in the audited state. It must not be applied blindly: reconcile the exact live function and schema, review the related package-activation/financial interlock migrations, and validate the complete registration path in a disposable TEST project first.

## Activation dependency / rollout blocker
The intended branch lifecycle activates a Main ID only after an Admin-approved package activation changes both payment and activation states to approved/active. However, package activation is currently locked in the UI while the financial/legal model is pending, and the live Production package/bid feature switches were still true in the inspected snapshot. The source-side financial lock is not a substitute for a live database guard.

As a result, the safe state is:
1. Do not open paid package submissions or accept member payments.
2. Do not enable Duplicate IDs, bidding, wallet credits, referrals/commissions or withdrawals.
3. Keep new registrations inactive once the reviewed signup migration is safely deployed.
4. Do not activate a Main ID until a separately approved, fully guarded activation process exists.
5. Do not make existing Production members inactive in bulk; historical status reconciliation needs its own reviewed plan.

## Tests and evidence
- Existing `tests/signup-inactive-until-verified.test.ts` covers inactive profile/Main ID creation and preserves registration/sponsor switches.
- Added `tests/registration-inactive-ui-contract.test.ts` to lock the free-registration, optional-sponsor and inactive-until-verification copy/metadata contract.
- The current live Production trigger and feature settings were inspected with SELECT/catalogue queries only.

## Conclusion
The front-end copy and branch migration describe an inactive-until-verified lifecycle, but Production still provisions new accounts as active. This is a material deployment mismatch. Treat the reviewed migration chain and a successful disposable TEST end-to-end run as mandatory before rollout. Production remains untouched.
