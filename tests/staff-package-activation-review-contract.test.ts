import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const staff=readFileSync('src/components/AdminStaff.tsx','utf8');
const page=readFileSync('supabase/migrations/20261119410000_admin_pending_activation_keyset_pagination.sql','utf8');
const review=readFileSync('supabase/migrations/20261119640000_staff_package_activation_review.sql','utf8');
describe('Staff package activation review permission contract',()=>{
 it('uses bounded keyset pages and validates each activation before signing receipts',()=>{
  expect(staff).toContain("rpc('admin_list_pending_activations_page'");
  expect(staff).not.toContain("rpc('admin_list_pending_activations'");
  expect(staff).toContain('function validActivation(value:unknown):value is Activation');
  expect(staff).toContain('payload.items.length>50');
  expect(staff).toContain('Load more requests');
 });
 it('allows only Admin or Staff with the package activation review permission to list',()=>{
  expect(page).toContain("role','')='admin_staff'");
  expect(page).toContain("? 'package_activation_review'");
 });
 it('allows the same narrowly permissioned Staff role to review and activate',()=>{
  expect(review).toContain("v_role='admin_staff' and v_permissions ? 'package_activation_review'");
  expect(review).toContain('admin_review_package_activation(uuid,boolean)');
 });
});
