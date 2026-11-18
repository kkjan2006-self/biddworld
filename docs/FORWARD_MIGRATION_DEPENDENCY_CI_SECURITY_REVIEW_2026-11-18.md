# Forward migration dependency, CI sequencing and dependency security review — 2026-11-18

## Scope

Source-only review of the ordered 65-file forward migration manifest, selected high-impact migration groups, package.json/package-lock.json, CI workflow and PWA source integration. Current upstream package security advisories were checked against exact locked package versions. No tests, builds, CI workflows, npm installation/audit, migration replay or database access were initiated.

## Forward migration dependency review

Inspected migration source groups covering:
- Auth signup provisioning, sponsor graph and genealogy.
- Package activation, approval, member activation, Duplicate-ID placement and financial feature guards.
- Fixed Bid campaign entry/draw/settlement and auction lifecycle/winner payment.
- Referral plan publication, commission creation/post/reversal.
- Withdrawal validation/review, wallet adjustment and Main-ID lifecycle.
- Receipt Storage bucket/policies, Admin receipt-path access and final Admin-only receipt reads.
- Notification idempotency/templates/recipient lookup.
- Member/Admin RPCs, paginated reports, public catalogues, placement tree and auction bid/Main-ID concurrency.

Source-order observations:
1. The private Auth signup and feature-gate trigger functions are defined before their trigger registrations in the canonical candidate. The auth trigger depends on Supabase-managed `auth.users`; app migrations must not attempt to create that platform object.
2. Referral commission trigger function and trigger are created in the package/referral migration. Its called posting RPC is defined later in the same migration; the trigger cannot fire until the migration transaction completes, so the source ordering does not create a same-transaction call-before-definition defect.
3. The package receipt flow first creates the private bucket and initial policies, then later migrations replace the receipt SELECT policy with Admin-only SELECT and retain the member-owned INSERT rule. The Admin pending-activation RPC is replaced to include receipt paths before the final policy tightening. The effective Storage policy composition still requires isolated TEST replay.
4. The Fixed Bid settlement and auction winner settlement migrations precede the later report/catalogue migrations that reference their canonical tables and result rows.
5. The 65-file manifest is ordered by migration timestamp and the inspected object/function dependencies are present in the canonical baseline or earlier forward migrations. This is a focused static review, not a claim that all 65 files have been parsed/executed by PostgreSQL. Continue the full per-object dependency matrix and compare complete replacement bodies to historical source before TEST replay.
6. No new evidenced migration-order defect was found in the inspected groups. No speculative SQL migration was added.

## Dependency lockfile and current advisory review

The committed lockfile is npm lockfileVersion 3 with 228 installed package entries. The key locked versions are:
- `vite` 6.4.6
- `vitest` 4.1.12
- `@vitest/mocker` 4.1.12
- `@supabase/supabase-js` 2.57.4

The critical Vite advisory GHSA-p4f5-76q4-ffq7 affects Vite through 6.4.5 in the 6.x line and lists 6.4.6 as patched. The repository's exact Vite 6.4.6 lock is therefore at the published patched floor. This matters because the dev script intentionally uses `vite --host 0.0.0.0` for phone/LAN development; do not downgrade Vite below 6.4.6. The dev server should only be exposed on a trusted development network and stopped when not in use.

The Vitest advisories GHSA-xp26-3454-mjgp and GHSA-qxg6-89mg-rqv8 list `@vitest/mocker` 4.1.12 as the patched 4.x version. The lockfile pins that exact patched version. The repository does not use Vitest Browser Mode in the inspected package scripts; its test script is `vitest run`. This source review does not substitute for a full dependency-tree audit.

No blind version upgrade was made. The package lock is present and the package declarations match its root package record. A current npm audit was deliberately not run because verification is deferred until the 100% development gate. The final consolidated audit must include full-tree and production-only audit output, npm signature/provenance review where supported, and transitive dependency remediation.

## CI workflow correction — development-first gate and reproducible install

The existing CI workflow ran on every push to both `main` and `completion-work`, which automatically invoked dependency installation, npm audit, tests and builds during the source-development phase. That contradicted the owner's explicit instruction to finish development before the consolidated test/verification phase.

Updated `.github/workflows/ci.yml`:
- Push-triggered verification now runs on `main` only; the `completion-work` branch no longer triggers tests/builds on each development commit.
- Pull requests targeting `main` retain the verification workflow, preserving the final integration gate.
- Dependency installation changed from `npm install` to `npm ci`, so CI installs from the committed lockfile without silently rewriting dependency resolution.

The workflow was edited but not run. It must be re-enabled/used at the final consolidated testing phase after development is declared complete.

## PWA source integration checkpoint

- `src/main.tsx` registers `sw.js` only in production and scopes it using Vite's `BASE_URL`, supporting both GitHub Pages subpath and root hosting.
- `public/manifest.webmanifest` uses relative start_url/scope and includes 192px and 512px icons.
- `public/sw.js` caches only same-origin resources within the app scope; cross-origin requests (including Supabase/auth/API traffic) are not cached. Navigation uses network-first with cached shell fallback; static assets use cache-first.
- The install button handles `beforeinstallprompt` and `appinstalled`. Browser/Android install and offline behavior remain unverified until the consolidated test phase.

## Outstanding

1. Complete all 65 migration dependency/body comparisons and exact service_role / identity-sequence ACL evidence.
2. Complete frontend RPC/direct-table RLS and member/Admin lifecycle coverage.
3. Run the complete dependency audit and CI only after the development-complete gate.
4. TEST replay, browser/Android PWA/offline checks and end-to-end testing remain pending. Production remains read-only; TEST remains untouched.

No tests/builds/CI, npm install/audit, database replay or database writes were performed. Overall project completion estimate remains 55%.


## 2026-11-18 follow-up — forward candidate #68

A deeper grant review found that the original support-ticket migration granted INSERT(user_id, subject, message) and UPDATE(status, admin_response) at column scope. Forward candidate #67 revoked only table-level INSERT/UPDATE, which does not clear those independent column grants. Added candidate #68 to revoke both privilege scopes. The ordered forward manifest now contains 68 candidates; this follow-up is source-only and does not establish PostgreSQL replay success. No tests, builds, CI, npm audit, migration replay or database writes were run. Production remains read-only; TEST remains untouched.
