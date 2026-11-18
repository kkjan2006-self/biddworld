import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118260000_secure_withdrawal_payout_details_validation.sql'),'utf8');

describe('Withdrawal payout details are validated server-side',()=>{
 it('accepts only the two supported payout methods and their matching credential field',()=>{
  expect(sql).toContain("v_method='UPI'");
  expect(sql).toContain("v_method='Bank Transfer'");
  expect(sql).toContain("p_payout_details ? 'account_number'");
  expect(sql).toContain("p_payout_details ? 'upi_id'");
  expect(sql).toContain("'upi_id'");
  expect(sql).toContain("'account_number'");
 });
 it('validates account-holder, UPI and bank-account formats independently of the UI',()=>{
  expect(sql).toContain('length(v_holder)<2 or length(v_holder)>100');
  expect(sql).toContain("^[A-Za-z0-9._-]{2,256}@[A-Za-z0-9.-]{2,64}$");
  expect(sql).toContain("^[0-9]{6,18}$");
  expect(sql).toContain("jsonb_typeof(p_payout_details->'method')<>'string'");
 });
 it('rejects unknown fields and keeps payout credentials out of audit logs',()=>{
  expect(sql).toContain("supplied.key not in ('method','account_holder_name','upi_id','account_number')");
  expect(sql).toContain("jsonb_build_object('amount',p_amount,'payout_method',v_method)");
  const auditSection=sql.slice(sql.indexOf('insert into public.audit_logs'),sql.indexOf('return jsonb_build_object'));
  expect(auditSection).not.toMatch(/upi_id|account_number|account_holder_name/);
 });
 it('preserves active Main ID, Income Wallet, minimum and authenticated-only checks',()=>{
  expect(sql).toContain("m.id_type='main' and m.status='active'");
  expect(sql).toContain("wallet_type='income'");
  expect(sql).toContain("setting_key='minimum_withdrawal_amount'");
  expect(sql).toContain('grant execute on function public.member_create_withdrawal_request(numeric,jsonb) to authenticated');
 });
});
