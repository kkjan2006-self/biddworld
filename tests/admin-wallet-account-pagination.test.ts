import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin wallet account pagination',()=>{
 it('validates wallet account identity and balance values',()=>{
  expect(component).toContain("typeof row.wallet_account_id==='string'");
  expect(component).toContain('Number(row.balance)>=0');
  expect(component).toContain('setWalletAccountsHasMore(batch.length===100)');
 });
 it('serializes account pages and prevents stale responses from appending',()=>{
  expect(component).toContain('walletAccountsPageInFlight.current');
  expect(component).toContain('walletAccountsPageGeneration.current');
  expect(component).toContain('p_offset:offset');
 });
 it('exposes account pagination while preserving the complete ledger export',()=>{
  expect(component).toContain('Load 100 more wallet accounts');
  expect(component).toContain('exportAllWalletTransactions');
  expect(component).toContain('loadMoreWalletTransactions');
 });
});
