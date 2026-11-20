import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const ui=read('src/components/Admin.tsx');
const activation=read('supabase/migrations/20261115020000_admin_package_activation_review.sql');
const referral=read('supabase/migrations/20261116030000_admin_configurable_referral_plan_depth.sql');
const minimum=read('supabase/migrations/20261118130000_withdrawal_minimum_and_server_validation.sql');
const delivery=read('supabase/migrations/20261116070000_delivery_tracking_backend.sql');
describe('Admin secondary mutation response integrity',()=>{
 it('validates package activation outcome and Bid Wallet credit fields',()=>{
  expect(ui).toContain("result.status!==(approve?'approved':'rejected')");
  expect(ui).toContain('result.bid_wallet_credit');
  expect(ui).toContain('result.wallet_balance');
  expect(activation).toContain("'success', true, 'status', 'approved'");
  expect(activation).toContain("'success', true, 'status', 'rejected'");
 });
 it('validates minimum withdrawal amount and inactive referral draft result',()=>{
  expect(ui).toContain('Number(result.minimum_withdrawal_amount)!==amount');
  expect(ui).toContain('result.is_active!==false');
  expect(ui).toContain('result.rule_count!==rules.length');
  expect(minimum).toContain("'success',true,'minimum_withdrawal_amount',p_amount");
  expect(referral).toContain("'is_active', false");
  expect(referral).toContain("'rule_count', v_rule_count");
 });
 it('validates delivery tracking UUID and existing-record identity before clearing the form',()=>{
  expect(ui).toContain("typeof data!=='string'||!data.trim()||(trackingId&&data!==trackingId)");
  expect(delivery).toContain('returns uuid');
  expect(delivery).toContain('return v_id;');
 });
});
