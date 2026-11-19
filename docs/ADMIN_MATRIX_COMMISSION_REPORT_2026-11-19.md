# Admin Matrix Commission Report — 2026-11-19

## Implemented

- Added a separate **Matrix Commissions** item to the Admin navigation and a dedicated `AdminMatrixCommissions` report component.
- Reads the paginated `admin_list_matrix_commissions_page` RPC, with server-side status and level filters.
- Supports client-side search over commission ID, activation ID, activated Main ID, source ID/type and credited Main ID/name.
- Clearly separates the placement-chain source ID from the credited Main ID. Duplicate sources are labelled as Duplicate IDs and their owner Main ID is displayed as the wallet beneficiary.
- Shows loaded-row counts, loaded-row amount totals, pending/credited counts and status.
- Validates required fields, timestamps and IDs in every returned page; refuses duplicate/overlapping rows.
- Complete CSV export fetches every server page (up to a 100,000-row safety limit) and includes activation, level, source ID/type, credited Main ID, amount, status and timestamp.
- Sponsor Referral commission UI and reporting remain separate and unchanged.

## Not performed

- No tests, typecheck, build, browser/mobile QA or E2E were run.
- No TEST or Production migration was applied and no database records or wallet balances were changed.
