# Registration-to-activation follow-up security review — 2026-11-16

## Findings
1. The current Auth signup UI and inactive-signup migration agree that new accounts remain inactive pending Admin verification. The live Production Auth trigger is still the older active-provisioning implementation; do not treat the branch migration as deployed.
2. The package submission RPC in the branch intentionally permits an inactive Main ID to submit a pending package activation request, because verified Admin approval is the intended activation step. However, the RPC implementation did not independently check `package_activations_enabled` or `financial_model_approved`. The UI lock alone could be bypassed by a direct authenticated RPC call.
3. The branch contains `20261116140000_require_active_main_id_for_withdrawals.sql`, which adds a server-side active Main ID ownership check to withdrawal requests. It is source-only in the audited state and does not make the withdrawal settlement lifecycle complete.
4. The financial approval trigger migrations block package approval/credits only when deployed. The live Production approval RPC still lacks the owner approval interlock in the previously recorded Production review.

## Change prepared on completion-work
Added `20261116200000_lock_package_activation_submission.sql`. It replaces the private package submission implementation with a fail-closed check requiring both:
- `package_activations_enabled=true`; and
- `financial_model_approved=true`.

When either is false/missing, the RPC rejects before creating a payment request. If allowed in a future owner-approved state, it still only creates a pending request; it does not activate an account or credit a wallet. The existing narrow authenticated public wrapper remains the entry point; the private implementation stays revoked from public/anon/authenticated direct execution.

Added `tests/package-activation-submission-lock.test.ts` to assert both gates, pending-only behavior, no direct activation/wallet-credit statements, and the existing active-Main-ID withdrawal guard.

## Safety / rollout
- No Production SQL writes, migrations, member updates, package submissions, payment actions, wallet transactions or setting changes were performed.
- Do not apply this or any related migration until the full migration chain is reconciled and tested in a disposable TEST project.
- Package payments and activation remain closed; do not ask members to pay.
- The ₹3,000 package / ₹3,500 Bid Wallet credit / up to ₹1,000 referral obligations model remains inactive pending legal/compliance and economic review.
