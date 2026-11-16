import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116080000_financial_activity_lockdown.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('global financial approval interlock',()=>{
 it('defaults to fail-closed and checks the trusted owner approval setting',()=>{
  expect(sql).toContain("coalesce((setting_value#>>'{}')::boolean,false)");
  expect(sql).toContain("where setting_key='financial_model_approved'");
  expect(sql).toContain("coalesce(v_approved,false) is not true");
 });
 it('blocks every wallet ledger insert, not only package activation credits',()=>{
  expect(sql).toContain("tg_table_name='wallet_transactions' and tg_op='INSERT'");
  expect(sql).toContain("before insert on public.wallet_transactions");
 });
 it('blocks package approvals, credited commissions, auction bids, Fixed Bid entries, withdrawals and winner settlement',()=>{
  for(const value of [
   "new.payment_status='approved' or new.activation_status='active'",
   "tg_table_name='referral_commissions'",
   "new.status='credited'",
   "tg_table_name='bids' and tg_op='INSERT'",
   "tg_table_name='fixed_bids' and tg_op='INSERT'",
   "tg_table_name='withdrawal_requests'",
   "'approved','processing','paid'",
   "tg_table_name='winning_item_payments'",
   "new.status='paid'"
  ])expect(sql).toContain(value);
 });
 it('does not expose the privileged trigger function to client roles',()=>{
  expect(sql).toContain('revoke all on function private.require_financial_model_approval()');
  expect(sql).toContain('from public,anon,authenticated');
 });
 it('installs guards on all seven financial write surfaces',()=>{
  for(const table of ['wallet_transactions','package_activations','withdrawal_requests','winning_item_payments','referral_commissions','bids','fixed_bids'])expect(sql).toContain('on public.'+table);
 });
 it('blocks Admin attempts to enable financial switches until trusted owner approval',()=>{
  expect(sql).toContain('v_financial_keys text[]');
  expect(sql).toContain('Financial feature % is locked until the owner approves');
  expect(admin).toContain('FINANCIAL_FEATURE_KEYS.has(key)');
 });
});

 it('does not allow the ordinary Admin feature RPC to set the trusted approval key',()=>{
  const start=sql.indexOf('create or replace function public.admin_set_feature_setting');
  const end=sql.indexOf('$function$;',start);
  const body=sql.slice(start,end);
  expect(start).toBeGreaterThanOrEqual(0);
  const allowlistStart=body.indexOf('if p_setting_key is null');
  const allowlistEnd=body.indexOf(']) then',allowlistStart);
  const allowlist=body.slice(allowlistStart,allowlistEnd);
  expect(allowlist).not.toContain("'financial_model_approved'");
  expect(body).toContain('auth.jwt()');
  expect(body).toMatch(/<>\s*'admin'/i);
 });

 it('guards the ledger write used by balance-changing RPCs and relies on PostgreSQL statement rollback',()=>{
  expect(sql).toContain('before insert on public.wallet_transactions');
  expect(sql).toContain("tg_table_name='wallet_transactions' and tg_op='INSERT'");
  expect(sql).toContain('raise exception');
 });
