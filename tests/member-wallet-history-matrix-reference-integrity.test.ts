import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/WalletHistory.tsx','utf8');
describe('Wallet history Matrix reference integrity',()=>{
 it('requires a canonical UUID for every Matrix commission ledger reference',()=>{
  expect(source).toContain("row.reference_type==='matrix_commission'&&(typeof row.reference_id!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(row.reference_id))");
  expect(source).toContain('member_get_my_matrix_commission_sources');
 });
 it('rejects blank reference types and reuses the validator for list and CSV responses',()=>{
  expect(source).toContain("typeof row.reference_type!=='string'||!row.reference_type.trim()");
  expect(source).toContain('data.every(validTransaction)');
  expect(source).toContain('wallet statement returned malformed or oversized transaction records');
 });
});
