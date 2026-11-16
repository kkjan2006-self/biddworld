import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116140000_require_active_main_id_for_withdrawals.sql'),'utf8');
describe('Withdrawal active Main ID authorization',()=>{
 it('requires the profile Main ID to belong to the authenticated caller and be active',()=>{
  expect(sql).toContain('p.main_member_id');
  expect(sql).toContain('m.owner_user_id=v_uid');
  expect(sql).toContain("m.id_type='main' and m.status='active'");
  expect(sql).toContain("An active Main ID belonging to this account is required");
 });
 it('keeps withdrawals disabled by default and Income Wallet only',()=>{
  expect(sql).toContain("setting_key='withdrawals_enabled'");
  expect(sql).toContain("wallet_type='income'");
  expect(sql).toContain('for update');
  expect(sql).toContain('not enable withdrawals');
 });
 it('retains authenticated-only RPC entry',()=>{
  expect(sql).toContain('from public,anon');
  expect(sql).toContain('to authenticated');
 });
});
