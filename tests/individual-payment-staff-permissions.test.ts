import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119160000_individual_payment_staff_permissions.sql'),'utf8');
const ui=readFileSync(resolve(process.cwd(),'src/components/AdminPaymentReviewStaff.tsx'),'utf8');
const staffMigration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119100000_restricted_payment_review_staff.sql'),'utf8');
describe('Individual restricted Staff permissions',()=>{
 it('allows only the Primary Admin to update an existing restricted Staff account',()=>{
  expect(migration).toContain("lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com'");
  expect(migration).toContain("v_role<>'admin_staff'");
  expect(migration).toContain('payment_review_staff.permissions_updated');
 });
 it('accepts only the three supported review permissions',()=>{
  expect(migration).toContain("'package_activation_review','wallet_funding_review','auction_submission_review'");
  expect(migration).toContain('cardinality(v_clean)=0');
  expect(migration).toContain("'{permissions}'");
 });
 it('renders per-user permission controls and calls the protected RPC',()=>{
  expect(ui).toContain('Package Activation Payment Review');
  expect(ui).toContain('Main Wallet Add Money Review');
  expect(ui).toContain('Member Auction Listing Review');
  expect(ui).toContain('admin_update_payment_review_staff_permissions');
  expect(ui).toContain('Save Permissions');
  expect(staffMigration).toContain('admin_set_payment_review_staff');
 });
});
