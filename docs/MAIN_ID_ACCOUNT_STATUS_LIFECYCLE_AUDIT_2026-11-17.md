# Main ID Account Status Lifecycle Audit — 2026-11-17

## Result

Main ID profile and directory management are present, but Main ID account-status lifecycle controls are not implemented in the current Admin frontend or inspected SQL migrations.

## Verified current behavior

- Admin Member Details displays the Main ID's current status as read-only information.
- Admin can edit the member's display name and phone through `admin_update_member_profile`.
- The selected Main ID's linked Duplicate IDs are listed.
- Duplicate ID management has separate Suspend, Reactivate and Close actions through `admin_set_duplicate_id_status`.
- Duplicate ID status transitions are limited to `active`, `suspended`, and `closed`; closed Duplicate IDs cannot be reactivated.
- The Admin UI explicitly labels Main ID account-status changes and suspension workflows as pending work.

## Missing implementation

- No Main ID suspend/reactivate/close RPC was found in the inspected migrations.
- No Main ID lifecycle action controls were found in the Admin Member Details UI.
- No Main ID lifecycle-specific regression test or deployment migration was found in the current branch audit.

## Safe implementation boundary

Do not add Main ID lifecycle actions until the desired relationship between Main ID and its Duplicate IDs is specified. In particular, the current audit does not authorize cascading status changes, login blocking, or automatic Duplicate ID reactivation/closure. Keep the existing Duplicate ID lifecycle independent and unchanged.

## Next development work

1. Confirm the intended Main ID lifecycle state machine and authorization rules.
2. Define whether Main ID changes affect linked Duplicate IDs, and if so exactly how.
3. Implement a transactional, audited Admin RPC and matching UI only after those rules are settled.
4. Add tests for allowed transitions, forbidden transitions, duplicate linkage behavior, and idempotent no-op requests.
5. Apply/test migrations only in a separate free test Supabase project; Production remains read-only.

## Scope and verification

This was a source and migration audit only. No database was changed, no user/account status was changed, and no deployment was performed.
