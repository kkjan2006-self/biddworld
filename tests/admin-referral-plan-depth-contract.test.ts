import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const adminSource = readFileSync(
  resolve(process.cwd(), 'src/components/Admin.tsx'),
  'utf8',
);

const sql = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261116030000_admin_configurable_referral_plan_depth.sql'),
  'utf8',
);

describe('Admin configurable referral plan depth contract', () => {
  it('rejects non-array JSON before calling array functions', () => {
    const typeGuard = sql.indexOf("if jsonb_typeof(p_rules) is distinct from 'array' then");
    const arrayLengthCheck = sql.indexOf('if jsonb_array_length(p_rules) < 1 then');
    expect(typeGuard).toBeGreaterThan(-1);
    expect(arrayLengthCheck).toBeGreaterThan(typeGuard);
    expect(sql).toContain('Referral rules must be a JSON array');
  });

  it('allows one to twenty configurable levels and rejects larger plans', () => {
    expect(sql).toMatch(/jsonb_array_length\\(p_rules\\) > 20[\\s\\S]*?cannot exceed 20 levels/i);
    expect(sql).toMatch(/v_level < 1 or v_level > 20/i);
  });

  it('requires sequential levels beginning at level one', () => {
    expect(sql).toMatch(/v_level <> v_rule_count \\+ 1[\\s\\S]*?must be sequential starting at level 1/i);
    expect(sql).toMatch(/v_rule_count := v_rule_count \\+ 1/i);
  });

  it('keeps plan versions inactive and limits writes to Admin sessions', () => {
    expect(sql).toMatch(/auth\\.uid\\(\\) is null[\\s\\S]*?app_metadata.*?role.*?admin/is);
    expect(sql).toMatch(/values \\(p_package_id, v_version, false, v_uid\\)/i);
    expect(sql).toMatch(/is_active.*?false/is);
    expect(sql).toMatch(/revoke all on function public\\.admin_save_referral_plan_draft\\(uuid, jsonb\\) from public, anon/i);
    expect(sql).toMatch(/grant execute on function public\\.admin_save_referral_plan_draft\\(uuid, jsonb\\) to authenticated/i);
  });

  it('prevents the Admin editor from adding more than twenty levels', () => {
    expect(adminSource).toMatch(/disabled=\\{levelValues\\.length>=20\\}/);
    expect(adminSource).toMatch(/old\\.length>=20\\?old:\\[\\.\\.\\.old,'200'\\]/);
    expect(adminSource).toContain('of 20 levels configured');
  });

  it('does not implement commission posting or wallet credits', () => {
    expect(sql).not.toMatch(/insert into public\\.referral_commissions/i);
    expect(sql).not.toMatch(/insert into public\\.wallet_transactions/i);
  });
});
