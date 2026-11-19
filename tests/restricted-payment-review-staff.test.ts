import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119100000_restricted_payment_review_staff.sql'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/AdminPaymentReviewStaff.tsx'),'utf8');
const portal=readFileSync(resolve(process.cwd(),'src/components/AdminStaff.tsx'),'utf8');
describe('Restricted payment-review staff',()=>{
 it('allows only the designated Primary Admin to grant and revoke staff',()=>{
  expect(migration).toContain("lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com'");
  expect(migration).toContain("'{permissions}','[\"package_activation_review\",\"wallet_funding_review\"]'");
  expect(migration).toContain("'payment_review_staff.granted'");
  expect(migration).toContain("'payment_review_staff.revoked'");
 });
 it('limits staff package and wallet review RPCs to explicit permission claims',()=>{
  expect(migration).toContain("? 'package_activation_review'");
  expect(migration).toContain("? 'wallet_funding_review'");
  expect(migration).toContain('reviewer_role');
 });
 it('limits private receipt reads to the matching review permission',()=>{
  expect(migration).toContain("bucket_id='package-receipts'");
  expect(migration).toContain("bucket_id='wallet-funding-receipts'");
 });
 it('routes staff into the isolated payment-review workspace',()=>{
  expect(app).toContain("user?.app_metadata?.role==='admin_staff'");
  expect(app).toContain("import('./components/AdminStaff')");
  expect(portal).toContain('AdminWalletFundingReview');
  expect(portal).toContain('admin_review_package_activation');
 });
 it('exposes staff management only in the Primary Admin role controls',()=>{
  expect(admin).toContain('admin_set_payment_review_staff');
  expect(admin).toContain('admin_list_payment_review_staff');
  expect(admin).toContain("kkjan2006@gmail.com");
 });
});
