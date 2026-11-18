import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Withdrawal workflow authorization and ledger safety', () => {
  it('keeps the member request and Admin settlement behind the database feature gate', () => {
    const guard = read('supabase/migrations/20261116080000_financial_activity_lockdown.sql');
    expect(guard).toContain("where setting_key='financial_model_approved'");
    expect(guard).toContain("tg_table_name='withdrawal_requests'");
    expect(guard).toContain("tg_op='INSERT'");
    expect(guard).toContain("new.status in ('approved','processing','paid')");
    expect(guard).toContain('Withdrawal processing is locked until the owner approves');
    const request = read('supabase/migrations/20261118130000_withdrawal_minimum_and_server_validation.sql');
    expect(request).toContain("setting_key='withdrawals_enabled'");
    expect(request).toContain('Withdrawals are currently disabled');
  });

  it('uses a trusted Admin RPC instead of direct client-side withdrawal mutations', () => {
    const admin = read('src/components/Admin.tsx');
    const start = admin.indexOf('id="admin-withdrawals"');
    const end = admin.indexOf('id="admin-auctions"', start);
    expect(start).toBeGreaterThan(-1);
    expect(end).toBeGreaterThan(start);
    const section = admin.slice(start, end);
    expect(section).toContain('Withdrawal Management');
    expect(section).toContain("reviewWithdrawal(r.request_id,'approve')");
    expect(section).toContain("reviewWithdrawal(r.request_id,'reject')");
    expect(section).toContain("reviewWithdrawal(r.request_id,'mark_paid')");
    expect(admin).toContain("supabase.rpc('admin_review_withdrawal_request'");
    expect(admin).not.toMatch(/\.from\(['"]withdrawal_requests['"]\)\s*\.update/);
  });

  it('serializes approvals, reserves Income Wallet funds, and releases rejected reservations idempotently', () => {
    const workflow = read('supabase/migrations/20261118100000_admin_withdrawal_review_workflow.sql');
    expect(workflow).toContain("auth.jwt()->'app_metadata'->>'role','')<>'admin'");
    expect(workflow).toContain('where id=p_request_id for update');
    expect(workflow).toContain("setting_key='withdrawals_enabled'");
    expect(workflow).toContain("wallet_type='income'");
    expect(workflow).toContain("v_key:='withdrawal:'||v_request.id::text||':reserve'");
    expect(workflow).toContain("v_key:='withdrawal:'||v_request.id::text||':release'");
    expect(workflow).toContain('if not exists(select 1 from public.wallet_transactions where idempotency_key=v_key)');
    expect(workflow).toContain("values(v_uid,'withdrawal.'||p_action,'withdrawal_requests'");
    expect(workflow).toContain('grant execute on function public.admin_review_withdrawal_request(uuid,text,text) to authenticated');
  });

  it('keeps member payout history limited to the payout method label', () => {
    const member = read('supabase/migrations/20261116170000_minimize_member_withdrawal_payout_data.sql');
    expect(member).toContain("jsonb_build_object('method',w.payout_details->>'method')");
    expect(member).not.toContain("w.payout_details->>'upi_id'");
    expect(member).not.toContain("w.payout_details->>'account_number'");
  });
});
