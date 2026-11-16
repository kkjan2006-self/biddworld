import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Package approval atomic financial guard contract', () => {
  const review = read('supabase/migrations/20261115020000_admin_package_activation_review.sql');
  const guard = read('supabase/migrations/20261116080000_financial_activity_lockdown.sql');

  it('keeps balance, ledger, activation and audit writes inside one Admin RPC', () => {
    const start = review.indexOf('create or replace function public.admin_review_package_activation');
    const end = review.indexOf('$function$;', start);
    const body = review.slice(start, end);
    expect(start).toBeGreaterThanOrEqual(0);
    expect(body).toContain('for update');
    const balance = body.indexOf('update public.wallet_accounts');
    const ledger = body.indexOf('insert into public.wallet_transactions');
    const activation = body.indexOf("payment_status = 'approved', activation_status = 'active'");
    const audit = body.indexOf("'package_activation_approved'");
    expect(balance).toBeGreaterThan(-1);
    expect(ledger).toBeGreaterThan(balance);
    expect(activation).toBeGreaterThan(ledger);
    expect(audit).toBeGreaterThan(activation);
    expect(body).toContain("'package-activation:' || v_activation.id::text || ':bid-credit'");
  });

  it('guards both the ledger insert and activation approval before commit', () => {
    expect(guard).toContain('before insert on public.wallet_transactions');
    expect(guard).toContain('before update of payment_status,activation_status on public.package_activations');
    expect(guard).toContain('raise exception');
    expect(guard).toContain("where setting_key='financial_model_approved'");
  });

  it('preserves the pre-existing feature gates as separate checks', () => {
    const featureGate = read('supabase/migrations/20261115154434_fix_feature_gate_trigger_row_access.sql');
    const walletGate = read('supabase/migrations/20261115154510_extend_wallet_and_sponsor_feature_gates.sql');
    expect(featureGate).toContain('private.enforce_feature_gate()');
    expect(featureGate).toContain('enforce_package_activation_feature');
    expect(walletGate).toContain('enforce_package_wallet_credit_feature');
  });
});
