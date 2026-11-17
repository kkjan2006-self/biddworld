# Admin member-management RPC authorization contract audit — 2026-11-17

## Scope

Reviewed the Admin Main ID structure report, paginated Main ID and Duplicate ID directories, profile editor, Duplicate ID status mutation, and sponsor graph mutation. Added a regression test that protects the security contract of these privileged RPCs.

## Verified source contracts

Each inspected RPC:
- Runs as `SECURITY DEFINER` with an empty `search_path`.
- Requires a non-null `auth.uid()`.
- Checks the trusted `app_metadata.role = 'admin'` claim, not user-editable metadata.
- Raises an authorization error for non-Admin callers.
- Revokes default execution from `PUBLIC` and `anon`, then grants execution to `authenticated`; the function body remains responsible for checking the Admin role.

The test covers:
- `admin_get_member_structure()`
- `admin_list_members_sponsors_page(text,integer,integer)`
- `admin_list_duplicate_ids_page(text,integer,integer)`
- `admin_update_member_profile(text,text,text)`
- `admin_set_duplicate_id_status(uuid,text)`
- `admin_set_member_sponsor(text,text)`

## Regression coverage

Added `tests/admin-member-rpc-authorization-contract.test.ts`. It statically inspects the source migration definitions to catch removal of the Admin role check, trusted claim, hardened search path, or execution ACL.

## Boundaries and verification

This is a source-contract test, not a live PostgreSQL privilege test. No RPC was executed against Production; no Supabase schema, settings, users, or data were changed. Live verification still requires a separate free test Supabase project.
