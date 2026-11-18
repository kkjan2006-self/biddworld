import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118260000_secure_withdrawal_payout_details_validation.sql'),'utf8');

describe('Withdrawal payout details are validated server-side',()=>{
 it('accepts only the two supported payout methods and their matching credential field',()=>{
  expect(sql).toMatch(/v_method\s*=\s*'UPI'/);
  expect(sql).toMatch(/v_method\s*=\s*'Bank Transfer'/);
  expect(sql).toContain("p_payout_details ? 'account_number'");
  expect(sql).toContain("p_payout_details ? 'upi_id'");
  expect(sql).toContain("'upi_id'");
  expect(sql).toContain("'account_number'");
 });
 it('validates account-holder, UPI and bank-account formats independently of the UI',()=>{
  expect(sql).toMatch(/length\(v_holder\)\s*<\s*2\s+or\s+length\(v_holder\)\s*>\s*100/);
  expect(sql).toContain("^[A-Za-z0-9._-]{2,256}@[A-Za-z0-9.-]{2,64}$");
  expect(sql).toContain("^[0-9]{6,18}$");
  expect(sql).toMatch(/jsonb_typeof\(p_payout_details->'method'\)\s*<>\s*'string'/);
 });
 it('rejects unknown fields and keeps payout credentials out of audit logs',()=>{
  expect(sql).toMatch(/supplied\.key\s+not in\s*\('method',\s*'account_holder_name',\s*'upi_id',\s*'account_number'\)/);
  expect(sql).toMatch(/jsonb_build_object\(\s*'amount',\s*p_amount,\s*'payout_method',\s*v_method\s*\)/);
  const auditSection=sql.slice(sql.indexOf('insert into public.audit_logs'),sql.indexOf('return jsonb_build_object'));
  expect(auditSection).not.toMatch(/upi_id|account_number|account_holder_name/);
 });
 it('preserves active Main ID, Income Wallet, minimum and authenticated-only checks',()=>{
  expect(sql).toMatch(/m\.id_type\s*=\s*'main'\s+and\s+m\.status\s*=\s*'active'/);
  expect(sql).toMatch(/wallet_type\s*=\s*'income'/);
  expect(sql).toMatch(/setting_key\s*=\s*'minimum_withdrawal_amount'/);
  expect(sql).toMatch(/grant execute on function public\.member_create_withdrawal_request\(numeric,\s*jsonb\) to authenticated/);
 });
});
