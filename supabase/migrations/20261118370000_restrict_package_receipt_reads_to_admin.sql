-- Tighten the legacy receipt policies to match the current private Admin-only
-- review workflow. The earlier migration allowed members to read their own
-- uploaded receipt objects; the current Member UI does not need that access.
-- Drop legacy policy names before retaining the single owner-folder INSERT
-- policy and the Admin-only SELECT policy from the preceding migration.

drop policy if exists package_receipts_select_own_or_admin on storage.objects;
drop policy if exists package_receipts_insert_own on storage.objects;

-- Recreate the current member upload rule (own auth.uid() folder only).
drop policy if exists "Members upload own package receipts" on storage.objects;
create policy "Members upload own package receipts"
on storage.objects for insert to authenticated
with check (
  bucket_id='package-receipts'
  and (storage.foldername(name))[1]=(select auth.uid())::text
);

-- Recreate the current Admin-only receipt read rule.
drop policy if exists "Admins read package receipts" on storage.objects;
create policy "Admins read package receipts"
on storage.objects for select to authenticated
using (
  bucket_id='package-receipts'
  and (select auth.jwt()->'app_metadata'->>'role')='admin'
);
