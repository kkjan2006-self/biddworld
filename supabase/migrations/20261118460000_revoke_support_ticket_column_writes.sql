-- Remove the column-level grants left behind by the original support-ticket migration.
-- REVOKE table-level INSERT/UPDATE does not revoke independently granted column privileges.
-- Support submission and Admin ticket changes must use the audited, idempotent RPCs.

revoke insert on table public.support_tickets from authenticated;
revoke insert (user_id, subject, message) on table public.support_tickets from authenticated;

revoke update on table public.support_tickets from authenticated;
revoke update (status, admin_response) on table public.support_tickets from authenticated;

-- Preserve SELECT under owner-or-Admin RLS. The RPC functions execute as their
-- secured definer and remain the only application write path for support tickets.
