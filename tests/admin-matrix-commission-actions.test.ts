import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/AdminMatrixCommissions.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261119310000_matrix_commission_engine.sql','utf8');
describe('Admin Matrix commission actions',()=>{
 it('exposes pending activation posting and credited commission reversal actions',()=>{
  expect(ui).toContain("supabase.rpc('admin_post_matrix_commissions'");
  expect(ui).toContain("supabase.rpc('admin_reverse_matrix_commission'");
  expect(ui).toContain("row.status==='pending'");
  expect(ui).toContain("row.status==='credited'");
 });
 it('requires a meaningful reason before reversal and confirms financial actions',()=>{
  expect(ui).toContain('reason.trim().length<5');
  expect(ui).toContain('Reverse this Matrix commission and its matching Income Wallet ledger credit?');
  expect(sql).toContain('Matrix reversal exists without original credit; reconciliation required');
  expect(sql).toContain("jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',true)");
  expect(ui).toContain('const replayMatches=result.commission_id===commissionId;');
  expect(ui).not.toContain('result.commission_id===undefined');
 });
});
