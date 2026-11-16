# Admin Duplicate ID and sponsor controls review — 2026-11-16

## Scope and safety
Reviewed the Admin UI call sites, branch migrations and live Production function catalogue/definitions. Production queries were read-only. No member status, sponsor, Duplicate ID, feature setting or financial data was changed.

## Confirmed Admin UI / Production RPC signature mismatch
The current Admin UI calls:
`admin_create_duplicate_member_id({p_main_member_code, p_under_member_code})`.

The live Production function catalogue currently exposes only:
`public.admin_create_duplicate_member_id(p_main_member_code text)`.

The branch migration `20261115230000_duplicate_under_id_placement_attribution.sql` replaces the one-argument function with the two-argument signature, records placement_parent_id and placement_position, and updates the returned JSON. This migration is branch-only in the audited state. Until the migration is reconciled and deployed to an approved TEST database, the Admin Duplicate ID creation call is expected to fail against the currently inspected Production signature. Do not enable Duplicate IDs or create any IDs in Production as a workaround.

## Duplicate ID status RPC
The live `admin_set_duplicate_id_status(uuid,text)`:
- checks the caller's JWT app_metadata role is admin;
- accepts active, suspended or closed;
- locks the selected Duplicate ID row;
- prevents reopening a closed ID;
- updates status and writes an audit log.

It does not verify that the parent/placement ID remains active before activating a pending Duplicate ID, and it does not re-check the duplicate feature switch when changing status. Review desired lifecycle semantics and add explicit server-side validation before enabling this workflow. Do not assume UI controls alone provide enforcement.

## Sponsor graph concurrency issue
The live `admin_set_member_sponsor(text,text)` checks self-sponsorship and recursively checks whether the proposed sponsor is already in the member's downline. It then upserts the referral edge and audit record. It does not take a graph-wide advisory lock or another serialization lock covering the read-check-write sequence. Two concurrent sponsor changes can each pass against the old graph and together create a cycle. Add a single transaction-scoped advisory lock for all referral graph mutations (including any other RPC that edits referrals), then run concurrent cycle tests in a disposable TEST project.

## Admin member status controls
The inspected Admin UI exposes the member/sponsor directory and duplicate lifecycle controls. No general-purpose Main ID active/suspended/closed status mutation control or corresponding Admin RPC was identified in the reviewed UI segment and live function inventory. Do not add a broad status-changing action until the business rules for account suspension, package state, wallet freezes, auction access, withdrawals, and appeals are specified.

## Required validation before rollout
1. Apply branch migrations only to a disposable TEST project after schema reconciliation.
2. Verify two-argument Duplicate ID creation, under-ID validation, pending status, audit record, and duplicate-owner routing.
3. Verify attempts to activate under inactive/suspended/closed placement parents are rejected according to the approved rule.
4. Verify closed IDs cannot be reopened and all allowed transitions are audited.
5. Run concurrent sponsor graph mutation tests that attempt A→B and B→A; exactly one must fail.
6. Check every referral mutation entry point uses the same serialization mechanism.
7. Keep `duplicate_ids_enabled=false` and all financial features locked until tests and owner/legal approval are complete.

## Conclusion
The source contains a newer Duplicate ID placement design, but the inspected Production function signature has not caught up. Sponsor-cycle protection is correct for sequential changes but not demonstrably safe under concurrency. These are rollout blockers, not reasons to modify live Production.
