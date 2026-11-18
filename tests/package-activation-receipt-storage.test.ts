import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118350000_private_package_receipt_storage.sql'),'utf8');
const member=readFileSync(resolve(process.cwd(),'src/components/Packages.tsx'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Private package receipt storage contract',()=>{
 it('creates a private 5 MB bucket restricted to supported receipt MIME types',()=>{
  expect(migration).toContain("'package-receipts'");
  expect(migration).toContain('public=false');
  expect(migration).toContain('5242880');
  expect(migration).toContain("array['image/jpeg','image/png','application/pdf']::text[]");
 });
 it('allows members to upload only to their own folder',()=>{
  expect(migration).toContain('for insert to authenticated');
  expect(migration).toContain("(storage.foldername(name))[1]=(select auth.uid())::text");
 });
 it('allows receipt reads only to Admin app-metadata role and keeps client workflows aligned',()=>{
  expect(migration).toContain("(select auth.jwt()->'app_metadata'->>'role')='admin'");
  expect(member).toContain("storage.from('package-receipts').upload");
  expect(admin).toContain("storage.from('package-receipts').createSignedUrl");
  expect(migration).not.toContain('for select to authenticated using (bucket_id=');
 });
});
