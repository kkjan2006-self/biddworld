import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116080000_financial_activity_lockdown.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('global financial approval interlock',()=>{
 it('defaults to fail-closed and checks the trusted owner approval setting',()=>{
  expect(sql).toMatch(/coalesce\(\(setting_value#>>'\{\}'\)::boolean,false\)/i);
  expect(sql).toMatch(/financial_model_approved/i);
  expect(sql).toMatch(/coalesce\(v_approved,false\) is not true/i);
 });
 it('blocks every wallet ledger insert, not only package activation credits',()=>{
  expect(sql).toMatch(/tg_table_name='wallet_transactions' and tg_op='INSERT'/i);
  expect(sql).toMatch(/before insert on public\.wallet_transactions/i);
 });
 it('blocks commissions, auction bids, Fixed Bid entries, withdrawal processing and winner settlement',()=>{
  expect(sql).toMatch(/tg_table_name='referral_commissions'[\\s\\S]*?new.status='credited'/i);
  expect(sql).toMatch(/tg_table_name='bids' and tg_op='INSERT'/i);
  expect(sql).toMatch(/tg_table_name='fixed_bids' and tg_op='INSERT'/i);
  expect(sql).toMatch(/new\.payment_status='approved' or new\.activation_status='active'/i);
  expect(sql).toMatch(/tg_table_name='withdrawal_requests'[\s\S]*?tg_op='INSERT'[\s\S]*?'approved','processing','paid'/i);
  expect(sql).toMatch(/tg_table_name='winning_item_payments'[\s\S]*?new\.status='paid'/i);
 });
 it('does not expose the privileged trigger function to client roles',()=>{
  expect(sql).toMatch(/revoke all on function private\.require_financial_model_approval\(\)\s*from public,anon,authenticated/i);
 });
 it('installs guards on all seven financial write surfaces',()=>{
  for(const table of ['wallet_transactions','package_activations','withdrawal_requests','winning_item_payments','referral_commissions','bids','fixed_bids']){
   expect(sql).toMatch(new RegExp('on public\\.'+table,'i'));
  }
 });
 it('blocks Admin attempts to enable financial switches until trusted owner approval',()=>{
  expect(sql).toMatch(/v_financial_keys text\\[\\]/i);
  expect(sql).toMatch(/financial_model_approved/i);
  expect(sql).toMatch(/Financial feature % is locked until the owner approves/i);
  expect(admin).toContain('FINANCIAL_FEATURE_KEYS.has(key)');
 });
});
