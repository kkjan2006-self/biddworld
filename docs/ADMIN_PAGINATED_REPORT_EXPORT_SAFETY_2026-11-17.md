# Admin paginated report export safety — 2026-11-17

## Change
- The shared Admin paginated CSV export helper now detects an identical repeated page and stops with a clear error instead of looping forever or silently exporting duplicates.
- The helper caps one export at 100,000 rows and asks the operator to narrow filters when the cap is reached.
- The CSV download is only created after all fetched pages pass the repeated-page and size checks.

## Verification boundary
- Added `tests/admin-paginated-report-export-safety.test.ts` for repeated-page detection, row limits and download ordering.
- This is static source-contract coverage; no live Admin RPC or production dataset was queried.
- No Production data, schema, settings or accounts were changed.
