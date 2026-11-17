# Admin Member Profile Editing — 2026-11-17

## Delivered in source
- Added an Admin-only edit form inside the existing Main ID detail panel.
- Editable fields are limited to the existing profiles.display_name and profiles.phone columns.
- The client calls admin_update_member_profile; it never writes directly to the profiles table.
- Successful edits update the current directory row without discarding search or pagination state.
- Existing member identity, sponsor, registration date, placement and linked Duplicate ID details remain visible.

## Forward migration
- Added 20261117120000_admin_update_member_profile.sql.
- The SECURITY DEFINER RPC checks the authenticated JWT app_metadata Admin role, resolves only a Main ID, locks the target profile row, validates input lengths and writes an audit event.
- Audit details record which fields changed, not old/new phone or name values.
- Execute is revoked from PUBLIC and anon and granted to authenticated; authorization is enforced inside the function.
- The migration is source-only and has not been applied to Production.

## Scope boundary
- This change does not alter profile or member-ID status.
- It does not edit Auth email, passwords, roles, wallets, sponsor links, package state or Duplicate ID state.
- Main ID / linked Duplicate ID suspension, closure, reactivation and session revocation remain pending until cascade rules are explicitly defined.

## Verification
- Added tests/admin-member-profile-editing.test.ts static source/migration contract coverage.
- CI must pass on the latest commit. No live Admin RPC execution or Production database mutation was performed.


## CI and schema verification — 2026-11-17

- GitHub Actions run `43994891990` passed on the profile-editing source baseline.
- A read-only Production `information_schema.columns` check confirmed `profiles.id/display_name/phone/updated_at`, `member_ids.owner_user_id/member_code/id_type`, and `audit_logs.actor_user_id/action/entity_type/entity_id/details` match the migration's referenced columns.
- The Admin editor now provides Reset changes and blocks no-op Save operations. These are frontend-only safeguards and do not alter database behavior.
- The migration has not been applied to Production; live RPC execution still requires a disposable test project.


## Server-side no-op protection — 2026-11-17

- The RPC now compares the locked profile values before writing. An unchanged submission returns `changed: false` without touching `updated_at` or inserting an audit event.
- A real change still updates the profile and records one audit event containing only changed-field flags, not the old/new personal data.
- Added regression coverage for the server-side no-op path. This is source-level contract coverage; live RPC execution still requires the disposable Supabase test project.
