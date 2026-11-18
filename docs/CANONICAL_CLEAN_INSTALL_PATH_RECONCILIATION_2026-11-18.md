# Canonical clean-install path reconciliation — 2026-11-18

## Finding

The repository contains two different concepts that must not be conflated:

- `supabase/migrations/0001_biddworld.sql` is a legacy schema snapshot. It uses older column contracts such as `member_ids.user_id`, `wallet_accounts.user_id`, and legacy package activation/referral fields. It is not the starting point for the current clean-install chain.
- `supabase/clean-install/production_schema_baseline_candidate.sql` is a separate schema-only candidate reconstructed from read-only Production catalogue metadata. It is the intended starting-point candidate for review, followed by the ordered entries in `supabase/clean-install/forward-migrations.txt`.

## Static precondition comparison

Compared the candidate's table definitions with the first forward migration contracts:

| Canonical object/column | Candidate baseline | Forward migration use |
|---|---|---|
| `profiles.phone` | Present | Member self-service profile update and signup provisioning |
| `profiles.main_member_id` | Present | Member identity lookup and signup provisioning |
| `member_ids.owner_user_id` | Present | Main ID ownership and signup provisioning |
| `member_ids.id_type`, `member_ids.status` | Present | Main ID/sponsor eligibility and signup provisioning |
| `wallet_accounts.member_id` | Present | Signup wallet account creation |
| `referrals.source_member_id` | Present | Signup sponsor attribution |
| `package_activations.activation_number` | Present | Package activation numbering |
| `package_activations.payment_status`, `activation_status` | Present | Package activation workflow |

These observations show that the candidate starting point has the key canonical columns absent from the legacy `0001_biddworld.sql` schema. The legacy mismatch does not, by itself, invalidate the separate candidate-baseline route.

## Intended candidate sequence

1. Review `production_schema_baseline_candidate.sql` as a schema-only candidate; it is not approved executable SQL.
2. Apply the ordered 62 entries in `forward-migrations.txt` only during the consolidated final testing phase and only to isolated TEST after explicit authorization.
3. Verify every migration, function body, grant, RLS policy, trigger, sequence and Storage policy in the resulting TEST schema against source expectations and the read-only Production inventory.
4. Run synthetic-data integration and end-to-end checks only after the replay succeeds.

## Boundaries and remaining uncertainty

- No migration was executed and no TEST or Production data/schema was changed.
- This is a static source comparison, not proof that the candidate SQL executes or that all 62 forward migrations compile in order.
- Supabase-managed schemas/extensions and platform prerequisites still require explicit review.
- Function replacement compatibility, ACL/RLS semantics, trigger order, Storage policy end state and frontend RPC runtime behavior remain open.
- Do not replay `0001_biddworld.sql`, `0002_place_bid_rpc.sql`, or the empty `001_initial_schema.sql` as part of this candidate path.
- Production remains read-only; TEST remains untouched until the final testing phase.

## Related evidence

- `supabase/clean-install/README.md`
- `supabase/clean-install/forward-migrations.txt`
- `supabase/clean-install/excluded-historical-migrations.txt`
- `docs/CLEAN_INSTALL_STATIC_RECONCILIATION_2026-11-18.md`
- `tests/clean-install-migration-manifest-integrity.test.ts` (read, not executed)
