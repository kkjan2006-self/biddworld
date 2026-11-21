import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/AdminPaymentReviewStaff.tsx','utf8');
describe('Restricted payment-review staff directory integrity',()=>{
 it('bounds the directory and validates account identities and timestamps',()=>{
  expect(source).toContain('raw.length>1000');
  expect(source).toContain('typeof item.user_id!==\'string\'');
  expect(source).toContain('Number.isFinite(Date.parse(item.created_at))');
  expect(source).toContain('Staff directory contains duplicate accounts.');
 });
 it('rejects unknown and duplicate permission values',()=>{
  expect(source).toContain('Object.prototype.hasOwnProperty.call(permissionLabels,permission)');
  expect(source).toContain('allowed.has(permission)');
  expect(source).toContain('permission record is invalid or duplicated.');
 });
 it('validates permission drafts before sending a mutation',()=>{
  expect(source).toContain('selected.length>Object.keys(permissionLabels).length');
  expect(source).toContain('new Set(selected).size!==selected.length');
  expect(source).toContain('selected.some(permission=>!Object.prototype.hasOwnProperty.call(permissionLabels,permission))');
 });
 it('prevents overlapping role mutations and reliably releases the lock',()=>{
  expect(source).toContain('mutationInFlight.current');
  expect(source).toContain('finally{mutationInFlight.current=false;setBusy(\'\');}');
 });
 it('keeps the existing primary-admin and server-side RPC restrictions',()=>{
  expect(source).toContain("data.user?.email?.toLowerCase()==='kkjan2006@gmail.com'");
  expect(source).toContain("supabase.rpc('admin_set_payment_review_staff'");
  expect(source).toContain("supabase.rpc('admin_update_payment_review_staff_permissions'");
 });
 it('validates Staff grant/revoke identity and the exact default permission set',()=>{
  expect(source).toContain('result.email.toLowerCase()!==expectedEmail');
  expect(source).toContain('result.app_role!==expectedRole');
  expect(source).toContain("const expectedPermissions=enabled?['package_activation_review','wallet_funding_review','auction_submission_review']:[]");
  expect(source).toContain('result.permissions.length!==expectedPermissions.length');
 });
 it('validates individual permission update identity and exact selection',()=>{
  expect(source).toContain("typeof row.email!=='string'||!row.email.trim()");
  expect(source).toContain("typeof result.email!=='string'||result.email.trim().toLowerCase()!==row.email.trim().toLowerCase()");
  expect(source).toContain('new Set(returnedPermissions).size!==returnedPermissions.length');
  expect(source).toContain('returnedPermissions.some(permission=>typeof permission!==\'string\'||!Object.prototype.hasOwnProperty.call(permissionLabels,permission))');
  expect(source).toContain('selected.some(permission=>!returnedPermissions.includes(permission))');
 });
});
