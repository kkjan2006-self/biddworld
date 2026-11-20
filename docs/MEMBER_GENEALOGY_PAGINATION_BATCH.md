# Member genealogy pagination batch (2026-11-16)

- Added a new authenticated, bounded RPC, `get_my_mlm_dashboard_page`, for Sponsor Referral genealogy.
- The RPC returns the existing dashboard summary plus a deterministic 50-row page, total matching count and continuation flag. It supports server-side member-code/name/sponsor search and level filtering, caps page size at 100, rejects invalid offsets/depths, and retains cycle-safe recursive traversal.
- The member Referrals screen now searches across the full downline through the RPC and loads additional pages on demand instead of fetching the complete genealogy JSON in one response.
- Added static regression tests for the frontend RPC contract and SQL authorization/pagination/cycle safeguards.
- Migration `20261116100000_member_genealogy_pagination.sql` is source-only. It has NOT been applied to Production. The existing `get_my_mlm_dashboard()` RPC remains untouched for compatibility.
- No Production data, schema, migration history, settings, or financial records were changed. No commissions or wallet activity were created.
- CI verification is pending for the commit containing this batch; do not treat source tests as proof of live Supabase behavior.
