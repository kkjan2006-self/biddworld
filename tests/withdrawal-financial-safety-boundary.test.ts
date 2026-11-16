import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Withdrawal financial safety boundary', () => {
  it('keeps request creation and settlement blocked until owner approval', () => {
    const guard = read('supabase/migrations/20261116080000_financial_activity_lockdown.sql');
    expect(guard).toContain("where setting_key='financial_model_approved'");
    expect(guard).toContain("tg_table_name='withdrawal_requests'");
    expect(guard).toContain("tg_op='INSERT'");
    expect(guard).toContain("new.status in ('approved','processing','paid')");
    expect(guard).toContain('Withdrawal processing is locked until the owner approves');
  });

  it('keeps the Admin withdrawal queue read-only and does not expose payout credentials', () => {
    const admin = read('src/components/Admin.tsx');
    const start = admin.indexOf('id="admin-withdrawals"');
    const end = admin.indexOf('id="admin-auctions"', start);
    expect(start).toBeGreaterThan(-1);
    expect(end).toBeGreaterThan(start);
    const section = admin.slice(start, end);
    expect(section).toContain('read-only withdrawal request queue');
    expect(section).toContain('No approvals, wallet debits, bank transfers or payouts');
    expect(section).not.toMatch(/admin_review_withdrawal|approveWithdrawal|rejectWithdrawal|payout_details/i);
  });

  it('requires an active caller-owned Main ID and checks Income Wallet balance before request creation', () => {
    const request = read('supabase/migrations/20261116140000_require_active_main_id_for_withdrawals.sql');
    expect(request).toContain('m.owner_user_id=v_uid');
    expect(request).toContain("m.id_type='main' and m.status='active'");
    expect(request).toContain("wallet_type='income'");
    expect(request).toContain('for update');
    expect(request).toContain('v_balance<p_amount');
    expect(request).toContain("status in ('pending','approved','processing')");
  });
});
