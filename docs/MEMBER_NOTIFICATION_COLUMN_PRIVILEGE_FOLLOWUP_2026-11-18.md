# Member-notification column privilege follow-up — 2026-11-18

## Finding

The original `20261116050000_member_notifications.sql` migration grants authenticated users column-level INSERT on `(user_id, title, message, category)` and UPDATE on `(read_at)`. The notification UI uses the audited, idempotent `admin_send_member_notification(...)` RPC for delivery and owner-scoped `UPDATE(read_at)` for marking notifications as read.

Forward candidate #67 (`20261118450000_restrict_direct_support_notification_writes.sql`) revoked table-level INSERT on `member_notifications`, but did not revoke the independently granted column-level INSERT. PostgreSQL column ACL entries are independent of table-level ACL entries. The RLS INSERT policy limits direct inserts to Admin users, but the surviving column grant would still permit an Admin to bypass the audited/idempotent delivery RPC.

## Correction

Added forward candidate #69:

- `supabase/migrations/20261118470000_revoke_member_notification_column_insert.sql`
- Revokes table-level INSERT and the exact column-level INSERT grant from `authenticated`.
- Preserves SELECT for member/Admin inbox reads.
- Preserves owner-scoped UPDATE(read_at), which the member UI intentionally uses.
- Leaves Admin delivery on `admin_send_member_notification(...)`, whose SECURITY DEFINER implementation performs authorization, idempotency and audit logging.

The support-ticket column-level correction remains in candidate #68.

## Boundaries

This is static source analysis only. No tests, builds, CI, SQL execution, migration replay, Production access or TEST access were performed. Production remains read-only; TEST remains untouched. Effective PostgreSQL ACL state and RPC operation must be confirmed during the consolidated final testing phase on the isolated TEST project.
