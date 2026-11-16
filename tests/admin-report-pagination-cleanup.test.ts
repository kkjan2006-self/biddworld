import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const admin = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');

describe('Admin paginated report request cleanup', () => {
  it('releases the audit-log pagination lock after success or rejection', () => {
    expect(admin).toContain("try{const {data,error}=await supabase.rpc('admin_list_audit_logs_page'");
    expect(admin).toContain("catch(e){setError('Could not load more audit log entries: '");
    expect(admin).toContain('finally{setAuditMoreBusy(false);}');
  });

  it('releases the wallet-ledger pagination lock after success or rejection', () => {
    expect(admin).toContain("try{const {data,error}=await supabase.rpc('admin_list_wallet_transactions'");
    expect(admin).toContain("catch(e){setWalletMessage('Could not load more wallet transactions: '");
    expect(admin).toContain('finally{setWalletMoreBusy(false);}');
  });

  it('releases the withdrawal pagination lock after success or rejection', () => {
    expect(admin).toContain("try{const {data,error}=await supabase.rpc('admin_list_withdrawal_requests'");
    expect(admin).toContain("catch(e){setWithdrawalMessage('Could not load more withdrawal requests: '");
    expect(admin).toContain('finally{setWithdrawalMoreBusy(false);}');
  });
});
