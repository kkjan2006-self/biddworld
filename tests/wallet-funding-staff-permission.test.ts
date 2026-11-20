import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const migration=readFileSync('supabase/migrations/20261119190000_wallet_funding_staff_permission.sql','utf8');
describe('Restricted Staff wallet funding review backend access',()=>{
 it('grants queue listing and review only to Admin or wallet_funding_review Staff',()=>{
  expect(migration).toContain("v_role='admin_staff'");
  expect(migration).toContain("? 'wallet_funding_review'");
  expect(migration).toContain('Wallet funding review permission required');
 });
 it('allows only authorized Admin or wallet-review Staff to read private receipts',()=>{
  expect(migration).toContain("bucket_id='wallet-funding-receipts'");
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'");
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review'");
 });
 it('keeps approval atomic, ledger-backed and protected from repeat review',()=>{
  expect(migration).toContain("v_request.status<>'pending'");
  expect(migration).toContain("'wallet-fund-request:'||v_request.id::text");
  expect(migration).toContain('insert into public.wallet_transactions');
  expect(migration).toContain('for update');
 });
});
