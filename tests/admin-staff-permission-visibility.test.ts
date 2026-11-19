import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const staff=readFileSync('src/components/AdminStaff.tsx','utf8');
describe('Restricted Staff review queue visibility',()=>{
 it('reads the signed-in staff permission claims before showing review queues',()=>{
  expect(staff).toContain("user?.app_metadata?.role==='admin_staff'");
  expect(staff).toContain("user.app_metadata?.permissions");
  expect(staff).toContain("setPermissions(allowed)");
 });
 it('loads and renders only queues granted to the staff account',()=>{
  expect(staff).toContain("permissions.includes('package_activation_review')");
  expect(staff).toContain("permissions.includes('wallet_funding_review')");
  expect(staff).toContain("permissions.includes('auction_submission_review')");
  expect(staff).toContain('No review permissions are assigned to this Staff account.');
 });
});
