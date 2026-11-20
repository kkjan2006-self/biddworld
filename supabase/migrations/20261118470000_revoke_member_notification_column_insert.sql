-- Remove the original column-level INSERT grant on member notifications.
-- Revoking table-level INSERT alone does not clear independently granted column privileges.
-- All notification delivery must use the audited, idempotent Admin RPC.

revoke insert on table public.member_notifications from authenticated;
revoke insert (user_id, title, message, category) on table public.member_notifications from authenticated;

-- Preserve owner-scoped UPDATE(read_at) for marking an existing notification as read.
-- Admin delivery remains available through admin_send_member_notification().
