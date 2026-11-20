import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const adminSource = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');
const sql = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261116030000_admin_configurable_referral_plan_depth.sql'), 'utf8');

describe('Admin configurable referral plan depth contract', () => {
  it('rejects non-array JSON before calling array functions', () => {
    const typeGuard = sql.indexOf("if jsonb_typeof(p_rules) is distinct from 'array' then");
    const arrayLengthCheck = sql.indexOf('if jsonb_array_length(p_rules) < 1 then');
    expect(typeGuard).toBeGreaterThan(-1);
    expect(arrayLengthCheck).toBeGreaterThan(typeGuard);
    expect(sql).toContain('Referral rules must be a JSON array');
  });

  it('allows one to twenty configurable levels and rejects larger plans', () => {
    expect(sql).toContain('if jsonb_array_length(p_rules) > 20 then');
    expect(sql).toContain('if v_level is null or v_level < 1 or v_level > 20 then');
    expect(sql).toContain('Referral plans cannot exceed 20 levels');
  });

  it('requires sequential levels beginning at level one', () => {
    expect(sql).toContain('if v_level <> v_rule_count + 1 then');
    expect(sql).toContain('v_rule_count := v_rule_count + 1;');
    expect(sql).toContain('Referral levels must be sequential starting at level 1');
  });

  it('keeps plan versions inactive and limits writes to Admin sessions', () => {
    expect(sql).toContain("if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then");
    expect(sql).toContain('values (p_package_id, v_version, false, v_uid)');
    expect(sql).toContain('revoke all on function public.admin_save_referral_plan_draft(uuid, jsonb) from public, anon');
    expect(sql).toContain('grant execute on function public.admin_save_referral_plan_draft(uuid, jsonb) to authenticated');
  });

  it('prevents the Admin editor from adding more than twenty levels', () => {
    expect(adminSource).toContain('disabled={levelValues.length>=20}');
    expect(adminSource).toContain("if(levelValues.length>=20)return;setLevelValues(old=>[...old,'200']);");
    expect(adminSource).toContain('of 20 levels configured');
  });

  it('does not implement commission posting or wallet credits in the draft RPC', () => {
    expect(sql).not.toContain('insert into public.referral_commissions');
    expect(sql).not.toContain('insert into public.wallet_transactions');
  });
});
