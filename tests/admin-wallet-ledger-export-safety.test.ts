import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin wallet ledger export uses bounded pagination',()=>{
 it('routes wallet ledger pages through the shared safe export helper',()=>{
  expect(admin).toContain("exportPagedReport<WalletTransaction>('wallet ledger','complete-wallet-ledger.csv'");
  expect(admin).toContain("offset=>client.rpc('admin_list_wallet_transactions',{p_limit:100,p_offset:offset})");
 });
 it('maps the complete wallet ledger fields without changing or writing wallet data',()=>{
  expect(admin).toContain("['Transaction ID','Member ID','Wallet','Type','Direction','Amount','Balance After','Reference Type','Reference ID','Description','Created At']");
  expect(admin).toContain('x.transaction_id,x.member_code,x.wallet_type,x.transaction_type,x.direction,x.amount,x.balance_after,x.reference_type,x.reference_id,x.description,x.created_at');
  expect(admin).not.toContain('setWalletExportBusy');
 });
 it('uses shared export progress and error feedback in the wallet panel',()=>{
  expect(admin).toContain("reportExportBusy==='wallet ledger'?'Preparing full ledger…':'Export Full Wallet Ledger CSV'");
  expect(admin).toContain('{reportExportMessage&&<small role="status">{reportExportMessage}</small>}');
 });
});
