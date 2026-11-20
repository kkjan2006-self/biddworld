# Fixed Bid implementation contract

Status: requirements captured; implementation remains disabled and unshipped.
Branch: `completion-work`
Reviewed source snapshot: `a81e1f08362f26bf64cf8c1760528d83dffb87f6`

## Confirmed owner requirements

1. Every campaign has one fixed entry fee; each entry is charged that fee.
2. A member may submit unlimited entries to the same campaign. There must be no per-member entry cap.
3. The random draw is the primary winner-selection mechanism. It must be server-side, auditable, and weighted by individual entry tickets (not one chance per member).
4. Admin may designate a Special Winner before campaign closure. The special-winner decision must be recorded separately and must not overwrite the random-draw result or audit history.
5. Cancellation refunds every entry in full. Refunds must be idempotent and reconcile exactly to the original wallet debits.
6. Campaign creation requires exactly one closing mode:
   - `time`: Admin sets Start Time and End Time. The backend closes the campaign at End Time and runs the draw.
   - `entry_target`: Admin sets a positive target entry count. The backend closes the campaign as soon as the target is reached and runs the draw.
7. For `entry_target` campaigns, member-facing cards show a percentage progress bar only. They must not expose the raw entry count or participant count.
8. No campaign may accept entries before its start or after its close; concurrent entries at the target boundary must not produce duplicate closures or multiple random winners.

## Owner decision still required

**Special Winner eligibility is unresolved.** Does the Admin have to choose a member who has at least one entry in that campaign, or may the Admin choose any registered member, including a non-entrant?

Do not implement the eligibility check, UI wording, or database constraint until this is answered. Preserve the special-winner record separately from the random draw regardless of the answer.

## Existing source facts

- Baseline schema in `supabase/migrations/0001_biddworld.sql` defines `fixed_bid_campaigns` with mandatory `starts_at` and `ends_at`, positive `entry_amount`, status and JSON rules.
- Baseline `fixed_bids` has `unique(campaign_id,user_id)`, which conflicts with unlimited entries.
- The baseline `auction_status` enum already includes `cancelled`; do not add a duplicate enum value.
- Admin UI currently calls `admin_save_fixed_bid_campaign_draft` and `admin_list_fixed_bid_campaigns`. The checked migration `20261116040000_admin_auction_draft_management.sql` defines auction draft RPCs, but does not define either Fixed Bid RPC. Their authoritative definitions and live Production signatures must be located and reconciled before changing callers or schema.
- Member Fixed Bid catalogue currently selects only title, description, status and creation date. It is read-only; it does not display fees, progress, entries, or winners.
- `20261116080000_financial_activity_lockdown.sql` blocks Fixed Bid entry inserts while the financial model is unapproved. `fixed_bid_enabled` is seeded false. Both safeguards must remain in place.

## Required backend design before activation

- Add an explicit close-mode field and target-entry field with a database check enforcing exactly one valid mode. Time mode requires an end timestamp after the start; target mode requires a positive target and must not rely on a client timer.
- Remove the one-entry-per-member uniqueness constraint only in a reviewed forward migration. Keep each entry as a distinct ticket with its own immutable identifier.
- Use a transaction/row lock for entry creation and target closure so the target can be reached only once. The draw must create one immutable random-winner result and an audit event in the same transaction.
- Implement reliable server-side time closure using a verified scheduler/worker. A browser countdown is presentation only and is not a reliable closing mechanism.
- Store special-winner designation as a distinct audited event/result, with actor, timestamp, selected member and reason. Eligibility remains blocked pending the owner decision above.
- For refunds, persist the exact debit allocation across Bid Wallet and Income Wallet at entry time. Refunds must reverse those exact allocations with unique idempotency keys and compensating ledger entries; never edit or delete historical wallet ledger rows.
- Campaign cancellation, refund batch status and per-entry refund status must be recoverable and idempotent. A failed partial batch must safely resume without double-crediting.
- Entry-target progress exposed to members must be a derived percentage, capped at 100, without returning raw counts in the member-facing response.
- Enforce role checks, RLS, server-side authorization, audit logging, concurrency controls and feature switches in database functions—not only in React.

## Delivery gates

1. Reconcile the actual Production schema, migration ledger and RPC signatures read-only. Do not replay the existing migration set.
2. Prepare forward-only source migrations and automated SQL/static tests; do not apply them to Production.
3. Build Admin campaign configuration and member progress display while entries remain disabled.
4. Build server-side entry, draw, special-winner, cancellation and refund workflows against a separate TEST Supabase project only.
5. Verify scheduler reliability, concurrency, idempotency, wallet split reversals, audit history, RLS and failure recovery.
6. Keep `fixed_bid_enabled=false` and the financial approval interlock intact until the owner explicitly approves the financial/legal model and rollout.

This document records requirements and safe sequencing; it does not claim that the Fixed Bid workflows have been implemented or tested.


## Authoritative Production snapshot (read-only, 2026-11-16)

Project identity was confirmed as `BiddWorld-Production`, ref `hbqatszyzqobgtauyuzy`, PostgreSQL 17.11. The following facts come from read-only project metadata, `list_migrations`, `list_tables`, `pg_proc`, `pg_constraint`, `pg_trigger`, `pg_indexes`, and `pg_policies` queries. No write statements were run.

### Live schema — authoritative over the stale baseline file

- `fixed_bid_campaigns` uses `configuration jsonb`, `status text`, `created_at`, and `updated_at`; it does **not** have `entry_amount`, `starts_at`, or `ends_at` columns.
- Its status check allows `draft`, `scheduled`, `live`, `paused`, `ended`, `cancelled`. The member catalogue's `live` filter is correct for Production; the interim `active` change was reverted.
- `fixed_bids` contains `campaign_id`, `member_id`, `bid_amount`, `status`, `idempotency_key`, `created_at`. Its status check allows `submitted`, `accepted`, `rejected`, `voided`.
- The only unique constraint/index on `fixed_bids` beyond its primary key is unique `idempotency_key`; there is no unique `(campaign_id, member_id)` constraint in Production. Therefore the live database does not currently impose a one-entry-per-member restriction.
- The Admin RPCs exist in Production: `admin_list_fixed_bid_campaigns()` and `admin_save_fixed_bid_campaign_draft(uuid,uuid,text,text)`. The save RPC only creates/updates a draft and writes an audit log; it does not configure fees, closing mode, target entries or winner rules.
- Production RLS exposes only SELECT for `fixed_bids`, scoped to the current owner's member ID. No INSERT policy was found. The public campaign SELECT policy permits only `scheduled`, `live`, `ended`.
- No entry, random draw, special-winner, campaign close, cancellation refund, or Fixed Bid settlement RPC was found in the Production function catalogue.
- The only Fixed Bid table trigger found is `enforce_fixed_bid_feature` on campaign insert/status update. No financial-approval trigger is attached to `fixed_bids` in Production. Entry writes are currently unavailable through the member Data API because there is no INSERT policy, and `fixed_bid_enabled=false`; do not enable it.
- Production currently reports `fixed_bid_enabled=false` and `winning_payment_enabled=false`. The queried settings did not return a `financial_model_approved` row. Wallet feature settings currently report true, so the source-only financial lockdown migration must not be assumed to be active in Production.

### Migration-history drift

- Production's migration ledger currently lists 30 migrations, ending at `20261115163241_admin_platform_health_summary`.
- The source branch currently contains 43 migration files with different timestamps/names and includes later lockdown and pagination migrations that are not in the Production ledger.
- Production lists `20261115151930_admin_fixed_bid_campaign_draft_management`, but no matching migration file is present in the current source tree.
- Consequently, do not apply the source migration directory wholesale, do not replay migrations, and do not infer that a source-only trigger or feature setting exists in Production. A formal migration reconciliation is a prerequisite to any deployment.

### Implementation implications

- Design the future campaign configuration around the live `configuration jsonb` contract or first prepare a reviewed forward migration to normalized columns. Do not write code against the obsolete baseline columns without a migration plan.
- The existing `fixed_bids` table can represent multiple entries for a member, with each row being a ticket, but any new entry RPC must enforce a unique idempotency key and secure atomic debit. Keep the current lack of INSERT access and the feature flag disabled.
- Before any entry flow is built, add a database-enforced financial approval interlock to the reconciled schema, ensure exact per-wallet debit allocation is retained for refunds, and add a secure server-side entry RPC. No client-side direct insert.
- Existing production wallet ledger is append-only by project requirements; refunds must be compensating, idempotent credits to the same wallet sources. This is not implemented for Fixed Bid.
