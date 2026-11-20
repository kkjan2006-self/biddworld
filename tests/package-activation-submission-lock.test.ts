import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Package activation request server-side lock', () => {
  it('requires both the package feature switch and owner financial approval', () => {
    const migration = read('supabase/migrations/20261116200000_lock_package_activation_submission.sql');
    expect(migration).toContain("setting_key='package_activations_enabled'");
    expect(migration).toContain("setting_key='financial_model_approved'");
    expect(migration).toContain('if not coalesce(v_enabled,false) or not coalesce(v_financial_approved,false) then');
    expect(migration).toContain('Package activation requests are locked');
  });

  it('keeps the package request pending-only and does not activate or credit wallets', () => {
    const migration = read('supabase/migrations/20261116200000_lock_package_activation_submission.sql');
    expect(migration).toContain("'pending', 'pending'");
    expect(migration).not.toMatch(/update\s+public\.(profiles|member_ids|wallet_accounts)/i);
    expect(migration).not.toMatch(/insert\s+into\s+public\.wallet_transactions/i);
  });

  it('retains the active Main ID requirement for withdrawal requests', () => {
    const withdrawal = read('supabase/migrations/20261116140000_require_active_main_id_for_withdrawals.sql');
    expect(withdrawal).toContain("m.id_type='main' and m.status='active'");
    expect(withdrawal).toContain('An active Main ID belonging to this account is required');
  });
});
