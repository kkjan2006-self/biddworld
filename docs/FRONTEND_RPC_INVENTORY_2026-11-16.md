# Frontend RPC inventory — 2026-11-16

- Snapshot branch: \`completion-work\`
- Snapshot commit: \`12be672b9b5930a0f87130fd96251457842860a1\`
- Literal frontend RPC call names inventoried: **44**
- React call surfaces inspected: **10**
- Machine-readable list: \`docs/FRONTEND_RPC_INVENTORY.json\`
- Regression test: \`tests/frontend-rpc-inventory.test.ts\`

The inventory is generated from literal \`.rpc('function_name', ...)\` calls in the ten React surfaces. CI now fails if a new literal RPC call is added without updating the inventory, if an inventory entry points to the wrong surface, or if stale entries remain.

This is deliberately a **source inventory**, not a live database contract certification. It does not prove that Production has each function, that argument/return types match, or that a function's body has safe authorization and side effects. The eight known missing live RPC contracts, Duplicate ID signature mismatch, referral-depth mismatch and sponsor lookup privacy mismatch remain recorded in \`docs/FRONTEND_PRODUCTION_RPC_AND_ADVISOR_REVIEW_2026-11-16.md\`.

No Production database operation was performed. No migrations were applied. Financial functions remain locked.
