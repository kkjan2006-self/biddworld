import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Account.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261119320000_member_matrix_commission_summary.sql','utf8');
describe('Member Matrix commission history integrity',()=>{
 it('validates the initial RPC page before displaying Matrix history',()=>{
  expect(source).toContain('const matrixRows=validateMatrixCommissionPage(mc.data??[])');
  expect(source).toContain('setMatrixCommissions(matrixRows)');
 });
 it('validates UUID identity, level, source attribution, amount, status and timestamp',()=>{
  expect(source).toContain('const MATRIX_COMMISSION_UUID=');
  expect(source).toContain('!MATRIX_COMMISSION_UUID.test(raw.commission_id)');
  expect(source).toContain("!['main','duplicate'].includes(raw.source_id_type)");
  expect(source).toContain("!['pending','credited','reversed'].includes(raw.status)");
  expect(source).toContain("typeof raw.amount!=='number'||!Number.isFinite(raw.amount)||raw.amount<=0");
 });
 it('enforces the SQL descending created_at and commission UUID order across page boundaries',()=>{
  expect(migration).toContain('order by c.created_at desc,c.id desc');
  expect(source).toContain('strict descending (created_at,commission_id) order');
  expect(source).toContain('prior.commission_id.localeCompare(raw.commission_id)<=0');
  expect(source).toContain('validateMatrixCommissionPage(data,matrixCommissions)');
 });
 it('rejects overlap before appending and stops pagination after an invalid continuation',()=>{
  expect(source).toContain('if(seen.has(raw.commission_id))throw new Error');
  expect(source).toContain('setMatrixCommissions(current=>[...current,...page])');
  expect(source).toContain('setMatrixHistoryHasMore(false);setError');
 });
});
