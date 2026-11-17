# Frontend ↔ Production RPC reconciliation — 2026-11-17

## Scope and method

- Source branch: `completion-work`
- Source HEAD inspected: `74a08fc7b42e0a707ad98ccae679195f54cbc8f4`
- Frontend inventory: `docs/FRONTEND_RPC_INVENTORY.json` (44 literal RPC call sites)
- Production project: `BiddWorld-Production` / `hbqatszyzqobgtauyuzy`
- Production inspection: read-only PostgreSQL catalogue query of `pg_proc`, identity arguments, result types and ACLs.
- No Production schema, migration ledger, settings, Storage objects, member records or financial records were changed.

## Contract result

| Result | Count | Meaning |
|---|---:|---|
| Frontend RPC names inventoried | 44 | Source call sites |
| Names found in Production | 36 | Presence only; not all contracts have been proven compatible |
| Missing from Production | 8 | UI calls cannot succeed against current Production |
| Known signature / return-shape mismatches | 3 | Name exists, but the UI contract differs |
| Production Storage buckets | 0 | Product media upload is not available in current Production |

## Missing RPCs

| RPC | Frontend surface | Required follow-up |
|---|---|---|
| `public_list_active_products_page` | `src/App.tsx` | Add reviewed forward migration and contract test |
| `member_get_my_identity` | `src/components/Account.tsx` | Add reviewed identity projection and owner-scope test |
| `member_list_my_ids` | `src/components/Account.tsx` | Add Main/Duplicate ID owner-scoped listing and test |
| `member_update_my_profile` | `src/components/Account.tsx` | Add self-only profile update contract and test |
| `admin_list_members_sponsors_page` | `src/components/Admin.tsx` | Add bounded Admin-only paginated/search RPC |
| `admin_list_duplicate_ids_page` | `src/components/Admin.tsx` | Add bounded Admin-only Duplicate ID directory RPC |
| `admin_set_product_active` | `src/components/Admin.tsx` | Add Admin-only publish/hide RPC matching live product status schema |
| `get_my_mlm_dashboard_page` | `src/components/Referrals.tsx` | Add owner-scoped bounded genealogy/dashboard RPC |

## Known present-name contract mismatches

| RPC | Production contract | Frontend expectation | Risk |
|---|---|---|---|
| `admin_create_duplicate_member_id` | `(p_main_member_code text) returns jsonb` | UI submits Main ID plus Under / Placement ID | Duplicate creation fails until forward migration is reconciled |
| `place_bid` | `(p_auction_id uuid) returns jsonb` | UI submits auction ID plus idempotency key | Bid submission contract mismatch; do not enable bidding |
| `lookup_sponsor` | `(p_member_code text) returns TABLE(member_code text, display_name text)` | UI helper expects a boolean validity result | Signup sponsor validation must be reconciled; public lookup also needs enumeration/rate-limit review |

## Production RPC catalogue observations

- The 44-name source inventory was compared with the current public-schema function catalogue. The eight missing names above were absent.
- Other source names are present by name, but name presence is not proof of matching parameter names, argument types, defaults, result shape, authorization checks, or side effects.
- Targeted catalogue inspection confirms the Production `admin_list_members_sponsors_page` function is absent; the branch migration source exists but is not recorded as applied in Production.
- The Production `admin_list_duplicate_ids_page` function is absent while the branch UI uses it.
- The Production `admin_set_product_active` function is absent while the branch UI calls it.
- `admin_list_members_sponsors` is an older unpaged function and is not an automatic substitute for the paginated UI contract.

## Member-management readiness

- Production `profiles` fields include `display_name`, `phone`, `status`, `main_member_id`, `created_at`, and `updated_at`.
- Production Main/Duplicate ID status constraint permits `pending`, `active`, `suspended`, and `closed`; the profile status constraint permits the same values.
- Existing Admin member directory supports server-side search, bounded pagination, CSV export, sponsor correction and a read-only details panel.
- The details panel explicitly states that profile edits and account lifecycle actions are not editable yet.
- There is no Production RPC in the audited catalogue for Admin member-profile editing or Main ID/profile lifecycle transitions.
- Do not invent whether suspension/closure of a Main ID must also update the profile and its linked Duplicate IDs. That cascade and login/session behavior require an owner-defined rule before implementation.

## Storage and security observations

- Production Storage currently has zero buckets. The branch's product-media bucket migration is source-only and requires reviewed rollout.
- All 21 inspected Production public tables have RLS enabled. This is not a complete authorization certification.
- The Supabase Security Advisor reports multiple public `SECURITY DEFINER` RPCs executable by `authenticated`; each function body must be reviewed for trusted Admin or owner authorization rather than treating the advisor warning as automatically exploitable.
- The advisor also reports leaked-password protection disabled. This is an Auth configuration item, not a source migration.
- `lookup_sponsor(text)` is executable by `anon` in Production and returns member code/display name; minimize public disclosure and add abuse/rate controls before launch.

## Migration drift

- Source tree: 42 SQL migration files.
- Production migration ledger: 30 rows.
- Version/name matching is incomplete. Existing `docs/MIGRATION_RECONCILIATION_MATRIX_2026-11-16.md` records the earlier detailed drift analysis.
- Never replay baseline migrations, blindly apply all source migrations, or treat a matching timestamp as proof of SQL equivalence.
- Any forward rollout must be reconciled as an ordered chain and tested outside Production first.

## Next safe implementation batch

1. Finish Admin member profile editing through a new trusted Admin RPC, preserving self-service profile restrictions and adding audit logging.
2. Add read-only Admin detail retrieval that is independent of the currently loaded 100-row directory page.
3. Implement account lifecycle only after the owner defines the Main ID/profile/linked Duplicate ID cascade and sign-in/session behavior.
4. Add contract tests for every new RPC and run CI.
5. Keep all database changes source-only until a separate test database exists and the migration chain is validated.

**Verification boundary:** this report is a read-only catalogue and source-call comparison. It does not certify every Production function body, test live RPC execution, validate every return shape, or apply any migration.
