import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119280000_matrix_plan_configuration.sql'),'utf8');
const followup=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119300000_automatic_duplicate_matrix_placement.sql'),'utf8');

describe('package-specific Matrix plan configuration contract',()=>{
  it('keeps Matrix width and Matrix depth as independent plan fields',()=>{
    expect(sql).toContain('matrix_width integer not null');
    expect(sql).toContain('matrix_depth integer not null');
    expect(sql).toContain('check (matrix_width between 2 and 100)');
    expect(sql).toContain('check (matrix_depth between 1 and 50)');
  });
  it('supports separately enabled fixed or percentage commission rules for every level',()=>{
    expect(sql).toContain('is_enabled boolean not null default false');
    expect(sql).toContain("reward_type text not null check (reward_type in ('fixed','percentage'))");
    expect(sql).toContain('unique(plan_version_id, level_number)');
    expect(sql).toContain('exactly one commission rule for every configured Matrix level');
  });
  it('stores independent versioned plans per package and restricts edits after publication',()=>{
    expect(sql).toContain('unique(package_id, version_number)');
    expect(sql).toContain('Matrix plan drafts can only be changed before package publication');
    expect(sql).toContain('Matrix plans can only be activated before package publication');
  });
  it('keeps placement depth independent from commission depth and applies the second activation placement gate',()=>{
    expect(followup).toContain('placement_depth integer not null default 5');
    expect(followup).toContain('p_placement_depth integer');
    expect(followup).toContain('activation_number=2');
    expect(followup).toContain('v_plan.placement_depth');
  });
  it('does not post wallet credits or merge Matrix commissions into Sponsor Referral commissions',()=>{
    expect(sql).not.toContain('wallet_accounts');
    expect(sql).not.toContain('wallet_transactions');
    expect(sql).not.toContain('referral_commissions');
  });
});
