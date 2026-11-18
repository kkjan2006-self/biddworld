import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const legacy=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118150000_package_receipt_uploads.sql'),'utf8');
const tightening=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118370000_restrict_package_receipt_reads_to_admin.sql'),'utf8');

describe('Package receipt Storage policy tightening',()=>{
 it('removes the legacy member-own-read policy and duplicate legacy upload policy',()=>{
  expect(legacy).toContain('create policy package_receipts_select_own_or_admin');
  expect(tightening).toContain('drop policy if exists package_receipts_select_own_or_admin on storage.objects');
  expect(tightening).toContain('drop policy if exists package_receipts_insert_own on storage.objects');
 });
 it('leaves only owner-folder member upload and Admin-role read access',()=>{
  expect(tightening).toContain('(storage.foldername(name))[1]=(select auth.uid())::text');
  expect(tightening).toContain("(select auth.jwt()->'app_metadata'->>'role')='admin'");
  expect(tightening).not.toContain("or (storage.foldername(name))[1]=(select auth.uid())::text");
  expect(tightening).not.toContain('for select to authenticated using (bucket_id=');
 });
});
