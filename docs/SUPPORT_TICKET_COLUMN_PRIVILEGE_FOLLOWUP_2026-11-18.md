# Support-ticket column privilege follow-up — 2026-11-18

## Finding

The original support-ticket migration `20261116041000_member_support_tickets.sql` first revokes all table privileges, then grants authenticated users column-level INSERT on `(user_id, subject, message)` and column-level UPDATE on `(status, admin_response)`.

The later forward candidate `20261118450000_restrict_direct_support_notification_writes.sql` revokes table-level INSERT and UPDATE only. PostgreSQL column-level grants are independent ACL entries; revoking the table-level privilege does not remove those separately granted column privileges. Therefore migration #67 did not fully close the direct support-ticket write path.

## Source correction

Added forward candidate #68: `20261118460000_revoke_support_ticket_column_writes.sql`.

It explicitly revokes:
- Table-level INSERT and UPDATE from authenticated.
- Column-level INSERT on `user_id, subject, message`.
- Column-level UPDATE on `status, admin_response`.

It leaves SELECT and the existing owner-or-Admin SELECT RLS policy intact. The audited, idempotent `member_submit_support_ticket(text,text,text)` and `admin_update_support_ticket(uuid,text,text)` RPCs remain the intended application write paths. No RPC signature or business rule changes.

## Scope and verification

This was a static source finding based on the original grant statements and the follow-up revoke migration. No SQL was executed, no tests/build/CI were run, and no database ACL was queried or changed in this batch. Effective privileges must be confirmed during the consolidated final TEST replay. Production remains read-only; TEST remains untouched.
