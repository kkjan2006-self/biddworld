import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119310000_matrix_commission_engine.sql'),'utf8');
const placement=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119300000_automatic_duplicate_matrix_placement.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Under ID Matrix commission engine contract',()=>{
 it('uses the placement parent chain and never the Sponsor referral graph',()=>{
  expect(migration).toContain('current_node.placement_parent_id');
  expect(migration).toContain('placement_parent_id');
  expect(migration).not.toContain('public.referrals');
  expect(migration).not.toContain('referrer_member_id');
 });
 it('keeps Matrix width, placement depth and commission levels independently configured',()=>{
  expect(migration).toContain('public.matrix_plan_versions');
  expect(migration).toContain('public.matrix_level_rules');
  expect(migration).toContain('level_number');
  expect(migration).toContain('v_rule.is_enabled');
 });
 it('tracks a Duplicate source ID but credits its linked Main ID Income Wallet',()=>{
  expect(migration).toContain('source.id_type');
  expect(migration).toContain("source.id_type='duplicate' then source.main_member_id");
  expect(migration).toContain('credited_main_member_id');
  expect(migration).toContain("wallet_type='income'");
  expect(migration).toContain("'matrix_commission','credit'");
 });
 it('uses atomic wallet balance updates, immutable ledger rows and idempotency checks',()=>{
  expect(migration).toContain('matrix-commission:');
  expect(migration).toContain('wallet_transactions');
  expect(migration).toContain('idempotency_key=v_key');
  expect(migration).toContain('balance_after');
  expect(migration).toContain('for update');
 });
 it('provides audited reversals and paginated source-aware Admin reporting',()=>{
  expect(migration).toContain('admin_reverse_matrix_commission');
  expect(migration).toContain('matrix_commission.reversed');
  expect(migration).toContain('admin_list_matrix_commissions_page');
  expect(migration).toContain('source_member_code');
  expect(migration).toContain('credited_main_member_code');
  expect(migration).toContain('has_more');
 });
 it('keeps direct table access revoked and the feature switch OFF/locked until completion',()=>{
  expect(migration).toContain('enable row level security');
  expect(migration).toContain('revoke all on table public.matrix_commissions from public, anon, authenticated');
  expect(migration).toContain("'matrix_commissions_enabled','false'::jsonb");
  expect(migration).toContain("'matrix_commissions_enabled'");
  expect(admin).toContain("key:'matrix_commissions_enabled'");
  expect(admin).toContain("'matrix_commissions_enabled'");
  expect(placement).toContain("child.placement_position !~ '^[0-9]+$'");
 });
});
