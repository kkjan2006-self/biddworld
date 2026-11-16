import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin wallet ledger export access from Reports',()=>{
 it('reuses the existing complete paginated wallet export action',()=>{
  expect(admin).toContain('const exportAllWalletTransactions=async()=>');
  expect(admin).toContain("rpc('admin_list_wallet_transactions',{p_limit:100,p_offset:offset})");
  expect(admin).toContain("downloadReport('complete-wallet-ledger.csv'");
  expect(admin).toContain('onClick={()=>void exportAllWalletTransactions()}>Export Complete Wallet Ledger CSV');
 });
 it('includes ledger reference metadata and never calls a wallet mutation RPC',()=>{
  expect(admin).toContain('x.reference_type,x.reference_id,x.description,x.created_at');
  expect(admin).not.toContain('exportAdminWalletTransactionsCsv');
 });
 it('describes which Admin reports are complete versus limited to loaded source records',()=>{
  expect(admin).toContain('Package activation, referral-plan, auction and Fixed Bid exports remain limited');
 });
});
