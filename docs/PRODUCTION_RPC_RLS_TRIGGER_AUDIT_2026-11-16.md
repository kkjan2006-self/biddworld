# BiddWorld Production RPC, RLS, trigger and Storage audit — 2026-11-16

## Scope

- Repository: `kkjan2006-self/biddworld`
- Branch: `completion-work`
- Source HEAD audited: `87ca82f6f2d9aade5c6640e401e1a4339b2ffe08`
- Production: `BiddWorld-Production` (`hbqatszyzqobgtauyuzy`), PostgreSQL 17.11, `ap-south-1`.
- This audit used catalog metadata, function definitions and SELECT-only catalog queries. No production DDL, DML, migration, settings, Auth, Storage, wallet or financial operation was executed.

## CI evidence

GitHub Actions run `43800661284` (workflow `BiddWorld CI`, run #383) for source commit `87ca82f6f2d9aade5c6640e401e1a4339b2ffe08` completed with conclusion `success`. This is repository CI evidence only; it is not a live database integration test or Production certification.

## Live catalog inventory

| Item | Observed |
|---|---:|
| Public application tables | 21 |
| Public routines | 43 |
| Public RLS policies | 20 |
| Distinct non-internal public trigger names | 10 |
| Trigger event bindings (table/event rows) | 17 |
| Private-schema routines | 4 |
| Storage buckets | 0 |
| Applied Supabase migration ledger rows | 30 |

All 21 public tables reported RLS enabled in the earlier table inventory. The 20 policies enumerated in this audit are SELECT policies only. RLS enabled is not proof that policies, RPCs or write paths are correct.

## Function and permission findings

- All 43 enumerated `public` routines are SECURITY DEFINER and have a pinned search_path in the catalog snapshot.
- `authenticated` has EXECUTE on all 43 public routines in the observed privilege check.
- `anon` has EXECUTE on `public.lookup_sponsor(text)`; the other 42 routines did not report anon EXECUTE.
- The current Production `lookup_sponsor(text)` returns `(member_code, display_name)`, not a boolean. It is SECURITY DEFINER and callable by anon/authenticated. This exposes member display-name information through a public exact-code lookup and creates an enumeration/privacy risk.
- The source-only migration `20261116160000_minimize_public_sponsor_lookup.sql` changes the return value to a boolean but still grants anon/authenticated EXECUTE. That is data minimization, not rate limiting; public abuse controls remain an edge/API gateway responsibility.
- A SECURITY DEFINER declaration and fixed search_path are necessary hardening details, not proof of safe authorization. The body, caller identity, ownership predicates, row locking, state transitions, idempotency, grants and side effects need review for every routine.

## RLS and direct table grants

- The 20 current public policies are SELECT policies. They include owner-scoped reads for profiles, member IDs, package activations, bids, fixed bids, referrals, commissions, wallet accounts/transactions, withdrawals, winning payments and delivery tracking; public catalogue-like reads are scoped to visible/published records through authenticated policies.
- Authenticated direct table grants observed on exposed business tables are SELECT-only; service_role retains broad operational privileges. The intended write path is therefore RPC-mediated.
- This does not prove that every RPC is properly authorized. Each SECURITY DEFINER routine must be checked independently, especially Admin reports and any financial state transition.
- No views or materialized views were returned by the public-schema view inventory.

## Trigger inventory and feature gates

The public trigger event inventory includes feature-gate triggers for:
- bid insertion;
- delivery tracking insert/update;
- Fixed Bid campaign insert/update;
- Duplicate ID insert/update;
- package activation insert/update;
- referral insert/update;
- wallet transaction insert;
- winning payment insert/update;
- withdrawal request insert.

These route to `private.enforce_feature_gate()`. The trigger checks ordinary feature switches. It is not equivalent to the source branch's separate owner-approved financial-model interlock.

Four private routines were enumerated: `private.enforce_feature_gate()`, `private.handle_new_auth_user()`, `private.place_bid(uuid)`, and `private.submit_package_activation(uuid,text)`. Their definitions were inspected. The feature-gate function reads the corresponding `app_settings` key; for package activation and wallet transaction paths it checks `package_activations_enabled`, `bid_wallet_enabled` or `income_wallet_enabled`. Since the live values for package activation and both wallets were true in the previous snapshot, these ordinary gates do not substitute for an owner financial approval lock.

## Critical source-versus-Production gaps

1. **Financial approval interlock absent in Production.** Source migrations `20261116000000_financial_approval_guard.sql` and `20261116080000_financial_activity_lockdown.sql` are not recorded as applied. The later lockdown migration adds a trusted owner approval flag check for wallet ledger writes, referral credits, auction bids, Fixed Bid entries, withdrawal requests/processing, package approval and winner settlement. It also prevents wallet ledger row mutation and hardens the Admin feature toggle. Live Production does not yet have this owner-approval protection.
2. **Admin feature switch remains unsafe.** Live `admin_set_feature_setting(text,boolean)` allows enablement of package activation, Bid Wallet and Income Wallet, with no `financial_model_approved` check. Source lockdown migration changes that behavior. Do not toggle these settings.
3. **Package approval remains a live credit path.** Live `admin_review_package_activation(uuid,boolean)` can approve/activate a package and credit Bid Wallet. Its ordinary feature-gate setting is currently true. The source-only owner approval interlock is not applied. Do not approve activations or perform wallet operations.
4. **Public sponsor lookup privacy drift.** Live RPC returns member code and display name. Source migration changes it to boolean but remains unauthenticated-by-design for signup lookup; rate limiting is still needed.
5. **Duplicate-ID RPC signature drift.** Production exposes `admin_create_duplicate_member_id(p_main_member_code text)`; branch placement-aware UI expects a two-argument contract. Do not treat the branch workflow as Production-compatible.
6. **Referral plan depth drift.** Production `admin_save_referral_plan_draft(uuid,jsonb)` requires exactly five rules and persists max depth five. Source migration supports configurable depth and inactive drafts.
7. **Product media Storage absent.** Production has zero Storage buckets. Source migration `20261116020000_admin_product_management_and_media.sql` proposes a public `product-media` bucket and trusted-Admin write policies. It remains source-only; no bucket or policy was created.
8. **Migration history is not reconciled.** Production has 30 ledger rows while the branch has 42 migration SQL files; many Production versions have no same-version source file. Do not replay the migration directory, fabricate migration history, or mark migrations applied based on names alone.

## Rollout blockers and safe next actions

1. Recover authoritative SQL for every Production migration version without a same-version source file, or document the live object reconstruction and independent review evidence.
2. Complete body-by-body review of all 43 public routines, all private routines, exact ACLs, 20 policies, 10 trigger definitions/17 event bindings, table grants and Storage state. The catalog summary here is not a complete code audit.
3. Compare source and live definitions for every object and prepare a forward-only reconciliation plan with explicit preconditions and rollback/compensation notes.
4. Rehearse the full ordered migration sequence, grants, RLS, RPC authorization, trigger behavior, concurrency and failure rollback in a disposable non-Production PostgreSQL/Supabase environment. If such an environment is not available within the zero-budget constraint, record the test as blocked rather than using Production.
5. Keep all Production financial switches unchanged. Do not approve packages, create credits/commissions, bid, withdraw or settle winners.
6. Obtain explicit owner approval before any Production migration or setting change.

## Financial safety note

The retained draft package economics are still unsafe: ₹3,000 package revenue versus ₹3,500 Bid Wallet credit and up to ₹1,000 referral obligations (potential ₹1,500 deficit before expenses). The package and referral plan must remain inactive until the economic and legal/compliance model is reviewed and approved.

## Completion status

This is an expanded read-only evidence snapshot. It does not deploy code, reconcile migration history, prove live application behavior, or certify launch readiness. No Production state was changed.
