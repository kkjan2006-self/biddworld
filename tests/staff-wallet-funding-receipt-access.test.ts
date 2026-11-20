import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119660000_staff_wallet_funding_receipt_access.sql','utf8');
const ui=readFileSync('src/components/AdminWalletFundingReview.tsx','utf8');
describe('Staff wallet funding receipt access contract',()=>{
 it('allows Admin and only assigned Staff to read pending funding receipts',()=>{
  expect(sql).toContain("role','')='admin'");
  expect(sql).toContain("role','')='admin_staff'");
  expect(sql).toContain("? 'wallet_funding_review'");
  expect(sql).toContain("r.status='pending'");
  expect(sql).toContain("bucket_id='wallet-funding-receipts'");
 });
 it('replaces the previous broad policy and preserves signed receipt review',()=>{
  expect(sql).toContain('drop policy if exists wallet_funding_receipts_admin_read on storage.objects');
  expect(sql).toContain('revoke all on function public.can_read_wallet_funding_receipt(text) from public,anon');
  expect(ui).toContain("storage.from('wallet-funding-receipts').createSignedUrl(row.receipt_path,300)");
 });
});
