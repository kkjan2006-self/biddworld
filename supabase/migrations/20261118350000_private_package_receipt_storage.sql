-- Private storage for package activation receipts.
-- Members can upload only inside their own auth.uid() folder.
-- Only authenticated Admins can read receipts to review payment evidence.
-- No public access, member download, update, or delete policy is granted.

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values (
  'package-receipts',
  'package-receipts',
  false,
  5242880,
  array['image/jpeg','image/png','application/pdf']::text[]
)
on conflict (id) do update
set public=false,
    file_size_limit=excluded.file_size_limit,
    allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "Members upload own package receipts" on storage.objects;
create policy "Members upload own package receipts"
on storage.objects for insert to authenticated
with check (
  bucket_id='package-receipts'
  and (storage.foldername(name))[1]=(select auth.uid())::text
);

drop policy if exists "Admins read package receipts" on storage.objects;
create policy "Admins read package receipts"
on storage.objects for select to authenticated
using (
  bucket_id='package-receipts'
  and (select auth.jwt()->'app_metadata'->>'role')='admin'
);
