import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const ui=readFileSync('src/components/Account.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261118260000_secure_withdrawal_payout_details_validation.sql','utf8');
describe('Member withdrawal creation RPC response integrity',()=>{
 it('requires a valid UUID, pending status and bounded server minimum in the success payload',()=>{
  expect(ui).toContain("function validWithdrawalCreateResult(value:unknown):value is {success:true;request_id:string;status:'pending';minimum_amount:number}");
  expect(ui).toContain('WITHDRAWAL_UUID.test(result.request_id)');
  expect(ui).toContain("result.status==='pending'");
  expect(ui).toContain('typeof result.minimum_amount===\'number\'');
  expect(ui).toContain('result.minimum_amount>=0&&result.minimum_amount<=10000000');
 });
 it('matches the authoritative SQL success response and rejects malformed payloads before clearing the form',()=>{
  expect(sql).toContain("'request_id', v_id");
  expect(sql).toContain("'status', 'pending'");
  expect(sql).toContain("'minimum_amount', coalesce(v_minimum, 0)");
  expect(ui).toContain('if(!validWithdrawalCreateResult(data))');
  expect(ui).toContain('setWithdrawAmount(\'\');setPayoutName(\'\');setPayoutReference(\'\')');
 });
});
