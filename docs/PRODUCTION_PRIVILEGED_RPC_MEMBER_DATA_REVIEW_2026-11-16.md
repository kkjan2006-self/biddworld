# Production privileged RPC and member-data review — 2026-11-16

## Scope
Read-only inspection of selected live SECURITY DEFINER functions and function ACLs in `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`). No Production data, settings, grants, schema or financial state was changed.

## Positive controls confirmed
- Privileged Admin RPCs inspected (`admin_create_duplicate_member_id`, `admin_review_package_activation`, `admin_save_package_draft`, `admin_set_default_sponsor`, `admin_set_duplicate_id_status`, `admin_set_feature_setting`, `admin_set_member_sponsor`) check authenticated identity and `auth.jwt()->'app_metadata'->>'role' = 'admin'`.
- `admin_create_duplicate_member_id` checks `duplicate_ids_enabled`, requires an active Main ID, creates the duplicate in pending status, and writes an audit event.
- `admin_set_duplicate_id_status` validates status transitions and prevents reopening a closed Duplicate ID.
- Package draft editor only creates or edits inactive packages.
- `get_my_mlm_dashboard` and `get_my_placement_tree` derive the root Main ID from the authenticated user's own profile row, not a caller-supplied member ID.
- `member_list_my_withdrawals` scopes results to the authenticated profile's Main ID.
- `lookup_sponsor` is intentionally executable by anon and authenticated users and returns only an active Main ID's member code/display name for sponsor lookup. This is a public data-disclosure surface and should be rate-limited or otherwise protected against enumeration if the product requires it.

## High-priority findings
1. **Financial feature-setting enablement is still insufficiently guarded.** The live `admin_set_feature_setting` has an enable allowlist including `package_activations_enabled`, `bid_wallet_enabled`, `income_wallet_enabled`, `sponsor_referrals_enabled`, and `duplicate_ids_enabled`. It blocks enabling several other workflows but does not check a trusted owner-level `financial_model_approved` interlock. This is consistent with the earlier finding: direct RPC calls can bypass the current Admin UI lock. Keep financial features disabled and install/reconcile the database guard before launch.
2. **Package approval still lacks the owner approval interlock.** The inspected live `admin_review_package_activation` checks Admin role and pending state, then atomically credits Bid Wallet, writes ledger entry, and marks activation active. It does not check a trusted financial approval flag.
3. **Sponsor reassignment concurrency.** `admin_set_member_sponsor` prevents self-sponsorship and checks whether the proposed sponsor is already in the member's downline using a recursive query. It does not lock both relevant Main ID rows / the referral graph during validation and update. Concurrent sponsor reassignment operations could race and create a cycle. Required fix: serialize graph mutations (e.g. transaction-scoped advisory lock or a rigorously ordered lock strategy), re-check ancestry under that lock, and add database-level invariant tests.
4. **Public sponsor lookup.** `lookup_sponsor` grants EXECUTE to anon as well as authenticated. It returns member code and display name for an exact active Main ID code. Consider rate limiting, minimal returned data, abuse monitoring and privacy review before public launch.

## Function ACL observations
- Inspected privileged public RPCs have EXECUTE granted to `authenticated` (and service_role); their bodies contain Admin-role checks where applicable.
- `private.place_bid` ACL includes service_role but not authenticated; public wrapper `place_bid` is authenticated-callable and delegates to it.
- `private.submit_package_activation` is postgres-only in the inspected ACL; public wrapper handles authenticated access.
- Private trigger/helper functions inspected are postgres-only. Continue auditing schema USAGE and default privileges; function ACL alone is not a complete privilege proof.

## Member dashboard notes
- `get_my_mlm_dashboard` returns recursive downline names/statuses and wallet/commission summaries for the profile's Main ID. This is intended member-facing data but should be checked against the approved privacy/data-minimization policy.
- `get_my_placement_tree` similarly returns placement tree member codes, display names and statuses rooted at the caller's profile Main ID.
- `member_list_my_withdrawals` returns at most 100 own withdrawal rows.

## Required work before launch
- Add database-enforced owner approval checks to package activation approval and every financial feature enablement path.
- Add stable client-supplied idempotency to bid RPC (previous report).
- Serialize sponsor graph edits and test concurrent cycle attempts.
- Decide whether sponsor lookup may remain public; add abuse controls and privacy review.
- Audit all SECURITY DEFINER functions, schema privileges, table grants, default privileges and scheduled/background jobs.
- Validate member-facing MLM tree data minimization and profile ownership assumptions.
- Do not enable financial features or perform real credits, commissions, bids, refunds or withdrawals during testing.

This is a focused review, not a complete security audit or launch certification.
