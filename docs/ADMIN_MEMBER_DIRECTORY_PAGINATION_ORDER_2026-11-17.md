# Admin Member Directory pagination request ordering — 2026-11-17

## Change
- Debounced member search now advances its request generation immediately when the search effect runs, rather than only after the debounce delay.
- Load More captures the active request generation, applied search term and page offset before issuing the RPC.
- A page response, error or loading-state cleanup is ignored if a newer search has superseded it.
- Existing bounded server-side search and 100-row pagination remain unchanged.

## Verification boundary
- Added `tests/admin-member-directory-pagination-order.test.ts` to protect generation invalidation, captured pagination arguments and stale-response handling.
- This is a static source-contract test; no live Admin account or Supabase RPC was exercised.
- No Production data, schema, settings or accounts were changed.
