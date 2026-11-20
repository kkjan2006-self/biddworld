import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const migration=readFileSync('supabase/migrations/20261119190000_wallet_funding_staff_permission.sql','utf8');
describe('Private payment receipt access for restricted review Staff',()=>{
 it('keeps wallet funding receipts private and permission-scoped',()=>{
  expect(migration).toContain("bucket_id='wallet-funding-receipts'");
  expect(migration).toContain("? 'wallet_funding_review'");
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'");
 });
 it('allows only package-review Staff to read private package receipts',()=>{
  expect(migration).toContain("bucket_id='package-receipts'");
  expect(migration).toContain("? 'package_activation_review'");
  expect(migration).toContain('drop policy if exists "Admins read package receipts"');
 });
 it('does not grant receipt reads to ordinary members or unrelated Staff',()=>{
  const policy=migration.slice(migration.indexOf('create policy "Admins read package receipts"'));
  expect(policy).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'");
  expect(policy).toContain("coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb)");
  expect(policy).not.toContain("or coalesce(auth.jwt()->'app_metadata'->>'role','')='authenticated'");
 });
});
