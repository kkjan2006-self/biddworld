import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('complete Admin wallet ledger export',()=>{
 it('uses the secured paginated Admin wallet transaction RPC until the final page',()=>{
  expect(admin).toContain("async function exportPagedReport<T>");
  expect(admin).toContain("rpc('admin_list_wallet_transactions',{p_limit:100,p_offset:offset})");
  expect(admin).toContain('biddworld-admin-wallet-transactions-complete.csv');
  expect(admin).toContain("'Transaction ID','Member Main ID','Wallet','Type','Direction','Amount','Balance After'");
 });
 it('includes reference metadata and does not mutate wallet data',()=>{
  expect(admin).toContain('x.reference_type,x.reference_id,x.description,x.created_at');
  expect(admin).toContain('Export Complete Wallet Ledger CSV');
  expect(admin).not.toContain("rpc('admin_adjust_wallet'");
 });
 it('describes which Admin reports are complete versus limited to loaded source records',()=>{
  expect(admin).toContain('Package activation, referral-plan, auction and Fixed Bid exports remain limited');
 });
});
