# Frontend direct-write and RLS contract review — support and notifications — 2026-11-18

## Scope

Compared `src/components/Support.tsx` and `src/components/Notifications.tsx` direct table operations against the source grants, RLS policies and RPC implementations in the migrations that create and secure those tables.

## Confirmed findings

### Support tickets

- The frontend reads `support_tickets` directly; member queries are filtered to the signed-in user and Admin queries use the Admin view. RLS policy `support_tickets_read_owner_or_admin` enforces owner-or-Admin visibility.
- Member submission uses `member_submit_support_ticket(text,text,text)`, which validates the authenticated user, content bounds and idempotency key, serializes duplicate submissions, inserts the ticket, and writes an audit event.
- Admin updates use `admin_update_support_ticket(uuid,text,text)`, which checks the exact Admin app-metadata role, locks the ticket, validates status/response, updates it and records an audit event.
- However, the table migration separately granted authenticated users direct INSERT and UPDATE privileges. INSERT RLS constrained the owner and initial state, but direct INSERT bypassed the RPC idempotency key and its submission audit record. UPDATE was additionally Admin-RLS-scoped, but the frontend does not use it; Admin changes already go through the audited RPC.

### Member notifications

- The frontend reads notifications directly under owner-or-Admin SELECT RLS.
- Mark-read and mark-all-read use direct UPDATE of `read_at`, constrained by the owner-only UPDATE policy and the column-level UPDATE grant.
- Admin delivery exclusively uses `admin_send_member_notification(uuid,text,text,text,text)`, which enforces Admin role, validates the target/content/category, serializes idempotency, inserts and audits.
- The table migration also granted authenticated direct INSERT. Its Admin-only INSERT RLS prevents member self-insertion, but a direct Admin insert could bypass the idempotent audited RPC. No frontend path needs direct INSERT.

## Source correction

Added forward migration `20261118450000_restrict_direct_support_notification_writes.sql` (candidate #67):

- Revokes direct INSERT and UPDATE table privileges on `public.support_tickets` from authenticated users. SELECT remains available under existing owner-or-Admin RLS. Member submission and Admin updates continue through their audited RPCs.
- Revokes direct INSERT on `public.member_notifications` from authenticated users. SELECT and the existing owner-scoped column-level UPDATE(read_at) remain available. Admin delivery continues through its audited idempotent RPC.
- No RLS policy was broadened and no client-facing RPC signature was changed.

## Verification boundary

Static source review and source-only migration authoring. No tests/build/CI, SQL execution, migration replay or database access/writes. Production `hbqatszyzqobgtauyuzy` remains read-only; TEST `yoaauthwejdgaevfvwpo` remains untouched. Consolidated testing remains deferred until development is 100% complete.
