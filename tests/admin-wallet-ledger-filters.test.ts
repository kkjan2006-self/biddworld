import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin wallet ledger loaded-record filters',()=>{
 it('filters loaded rows by member, wallet, type, direction and reference text',()=>{
  expect(admin).toContain('const filteredWalletLedger=useMemo(');
  expect(admin).toContain('[x.member_code,x.wallet_type,x.transaction_type,x.direction,x.reference_type,x.reference_id,x.description]');
 });
 it('applies inclusive UTC calendar date bounds and blocks reversed ranges',()=>{
  expect(admin).toContain('(!walletLedgerFrom||day>=walletLedgerFrom)&&(!walletLedgerTo||day<=walletLedgerTo)');
  expect(admin).toContain('walletLedgerFrom>walletLedgerTo');
 });
 it('keeps the full paginated CSV export independent of loaded-row filters',()=>{
  expect(admin).toContain('for(let offset=0;;offset+=100)');
  expect(admin).toContain('all.map(x=>[x.transaction_id,x.member_code');
  expect(admin).toContain('Filters do not limit the complete CSV export.');
 });
});
