-- Keep support-ticket creation/status changes and notification delivery on
-- their audited, idempotent SECURITY DEFINER RPC paths.
-- Member notification read-state updates remain owner-scoped through RLS.

-- Support UI reads tickets directly under owner-or-Admin RLS, but submits
-- and updates exclusively through member_submit_support_ticket() and
-- admin_update_support_ticket(). Remove unused direct table write grants
-- that would otherwise allow bypassing idempotency and RPC audit records.
revoke insert, update on public.support_tickets from authenticated;

-- Admin notification delivery is exclusively performed by
-- admin_send_member_notification(), which enforces role, idempotency and audit.
-- Keep SELECT for member/Admin inboxes and UPDATE(read_at) for owner mark-read.
revoke insert on public.member_notifications from authenticated;
