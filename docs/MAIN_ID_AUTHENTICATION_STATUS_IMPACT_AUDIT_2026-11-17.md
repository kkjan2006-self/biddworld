# Main ID account-status and authentication impact audit — 2026-11-17

## Scope

Read-only source audit of the `completion-work` branch. This document checks how `profiles.status` and Main ID status are currently used by the browser session, member workspace, and database workflows. It does not change lifecycle behavior.

## Findings

1. **The browser authentication listener does not enforce account status.** In `src/App.tsx`, Supabase auth events update the local `user` state, and the initial `getUser()` result is accepted without reading `profiles.status` or Main ID status. The member/Admin tab selection is based on the trusted `user.app_metadata.role`, not account status.
2. **A signed-in inactive profile can still reach the member workspace.** `src/components/Account.tsx` reads the signed-in user's own profile, including `status`, and displays it read-only. The member dashboard does not itself sign the user out or redirect based on that status.
3. **Baseline RLS is owner-scoped, not active-status-scoped.** The initial migration enables RLS and defines `profiles_self_read` with `id = auth.uid()`, and `member_ids_self_read` with owner scope. Those policies do not include an active-status predicate. Other later migrations may add or replace policies; this baseline alone is not proof of the complete current Production policy set.
4. **Important business RPCs separately require an active Main ID.** The inspected bid RPC resolves the caller's Main ID only when `member_ids.status = 'active'`. Signup provisioning in the later inactive-until-verified migrations creates both the Main ID and profile as `inactive`; successful verified package activation changes both to `active`.
5. **Profile and Main ID statuses are currently synchronized in the inspected activation path only.** The activation trigger changes an inactive Main ID to active and changes its owning profile from inactive to active. No corresponding Main ID suspend/reactivate/close lifecycle RPC or Admin UI action was found in the prior Admin lifecycle audit.
6. **No global session revocation or login block was found in the inspected frontend flow.** Therefore changing `profiles.status` alone cannot currently be assumed to prevent an already authenticated user from opening the member workspace. Server-side RPCs that explicitly check active Main ID may still reject protected operations.

## Safe conclusions

- `profiles.status` is currently visible to the member as a read-only account field.
- The authentication session and member workspace are not globally gated by that field in the inspected frontend.
- Active Main ID checks exist in selected backend workflows; they are not a substitute for a complete account suspension policy.
- Duplicate ID status is independently managed today. No cascade from Main ID to Duplicate IDs has been established.

## Deliberately not implemented

- No Main ID Suspend, Reactivate, or Close controls or RPCs.
- No automatic cascade to Duplicate IDs.
- No change to Supabase Auth sessions, RLS, profile status, or existing member records.
- No migration was applied to Production.

These are intentionally deferred because the Main ID-to-Duplicate-ID cascade rule and the intended meaning of suspend versus close have not been specified. A future implementation must define the state transitions, whether existing sessions are revoked or merely blocked from protected operations, and how linked Duplicate IDs behave before any lifecycle write is introduced.

## Verification limits

This is a static source/migration audit. It is not a live Auth, RLS, or RPC integration test. The initial schema migration is historical and the current Production database may contain additional policy changes; a separate free test Supabase project is required for safe live verification.

## Next work

Continue auditing Admin member-management actions and backend authorization contracts. Keep Main ID lifecycle writes deferred until its state machine and Duplicate ID behavior are explicitly defined. Maintain the read-only Production boundary.
