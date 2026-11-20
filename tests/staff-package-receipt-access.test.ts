import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119650000_staff_package_receipt_access.sql','utf8');
const staff=readFileSync('src/components/AdminStaff.tsx','utf8');
describe('Staff package receipt access contract',()=>{
 it('allows Admin and only assigned package-review Staff to sign pending receipts',()=>{
  expect(sql).toContain("role','')='admin'");
  expect(sql).toContain("role','')='admin_staff'");
  expect(sql).toContain("? 'package_activation_review'");
  expect(sql).toContain("a.payment_status='pending' and a.activation_status='pending'");
  expect(sql).toContain('drop policy if exists "Admins read package receipts" on storage.objects');
  expect(sql).toContain("bucket_id='package-receipts'");
 });
 it('keeps receipt access private and wired to Staff signed URLs',()=>{
  expect(sql).toContain('revoke all on function public.can_read_package_activation_receipt(text) from public,anon');
  expect(sql).toContain('grant execute on function public.can_read_package_activation_receipt(text) to authenticated');
  expect(staff).toContain("storage.from('package-receipts').createSignedUrl(item.receipt_path,300)");
 });
});
