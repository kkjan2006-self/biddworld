# Member Operations and Fixed Bid Workflow Integration Audit — 2026-11-17

Branch: `completion-work`
Scope: Fixed Bid campaign UI/backend contract, referral plan configuration, delivery tracking, member notifications, support tickets, and member account delivery visibility.
Method: Read-only source and migration review. No database writes or Production changes.

## Confirmed implementation

### Fixed Bid
- Admin can create and edit campaign drafts through `admin_save_fixed_bid_campaign_draft`; the UI explicitly says no pricing, entries or winner rules are activated.
- Member-facing `FixedBid.tsx` loads scheduled/live/ended campaigns, supports search/status filters and pagination, and is read-only.
- The current Fixed Bid contract captures unlimited entries, ticket-weighted server-side random draw, time/entry-target closing, progress percentage-only display, idempotent full refunds, and separately recorded Special Winner.
- No end-to-end entry, draw, cancellation/refund or settlement workflow is implemented in the reviewed source.
- Special Winner eligibility remains unresolved in `docs/FIXED_BID_IMPLEMENTATION_CONTRACT.md`; do not guess or implement that rule.
- Keep Fixed Bid disabled and do not add a client-side substitute for server-side closure or draw.

### Referral plan
- Admin can create versioned inactive referral-plan drafts with configurable level count and fixed rewards.
- Database RPC validation accepts `fixed` and `percentage` reward types; current Admin UI only sends fixed rewards.
- Referral plan display reports stored reward values, but no automatic commission calculation, posting, reversal or complete commission engine was found.
- Percentage reward basis is not defined in the inspected UI/contract. Do not expose percentage editing until its calculation base and rounding rule are specified.
- Referral plan drafts remain inactive; no wallet movements are made by draft creation.

### Delivery tracking
- Admin can create tracking only for a winning-item payment whose status is `paid`; duplicate tracking rows are prevented.
- Admin can update carrier, tracking number and status. Writes pass through the `delivery_tracking_enabled` feature gate and create audit-log events.
- Member Account loads the member's own winning payments and associated delivery rows; delivery details are fetched only for those payment IDs.
- The source migration grants members SELECT only and uses an owner-scoped RLS policy. Admin write operations are through Admin-only security-definer RPCs.
- Status history is not separately persisted as a dedicated timeline table in the reviewed migration; audit logs record Admin save events.

### Notifications
- The in-app inbox supports owner-scoped reads, mark-read and mark-all-read; Admin can send a notification to a selected Auth user UUID.
- Support-ticket status/response changes create an in-app notification.
- The UI explicitly states that email, SMS and push delivery are not configured. Notification templates are drafts and do not send messages.

### Support
- Members can create and view their own support tickets; Admin can view the queue and update status/response.
- RLS scopes member reads/inserts to the authenticated owner and restricts updates to Admin.
- Admin ticket updates create audit events and a corresponding member notification.
- No attachment upload or external email/SMS escalation workflow was found in the reviewed components/migrations.

## Gaps and safe next work

1. Fixed Bid remains a catalogue plus draft-management shell. Implementing entries, draw, cancellation and refunds requires a reviewed forward-only design, separate disposable TEST Supabase project, and confirmation of Special Winner eligibility.
2. Referral plan Admin UI is fixed-only despite backend schema support for fixed/percentage. Keep fixed-only until percentage basis/rounding is defined; automatic commission engine is still absent.
3. Main ID status lifecycle and account-wide session blocking remain unimplemented per the separate lifecycle audit. Do not invent Main ID/duplicate cascade behavior.
4. Verify delivery RLS and feature-gate behavior against a disposable TEST project. Add a member-facing test for delivery visibility and ensure Admin-only mutation cannot be performed through direct Data API writes.
5. Notification delivery beyond in-app is not configured. Template drafts are not evidence of email/SMS/push delivery.
6. Support attachments and escalation are not implemented.
7. The branch's migrations remain source files only. Do not apply the branch migration directory wholesale to Production; Production migration-history drift and RPC signature differences require a separate reconciliation.

## Verification boundaries

- Source and SQL text reviewed only; no live Supabase transaction tests were run.
- No migrations were applied to Production.
- No Production member, wallet, payment, referral, auction, delivery, notification or support records were modified.
- No financial feature switch was enabled.
- This is an audit/integration batch, not a claim that the missing workflows are complete.
