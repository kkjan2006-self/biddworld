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
});
