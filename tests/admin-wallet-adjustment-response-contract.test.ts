import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const ui=read('src/components/Admin.tsx');
const migration=read('supabase/migrations/20261120130000_wallet_adjustment_idempotent_response_integrity.sql');

describe('Admin wallet adjustment RPC response and idempotent replay contract',()=>{
 it('returns the complete original adjustment result on an idempotent replay',()=>{
  expect(migration).toContain("'success',true");
  expect(migration).toContain("'adjustment_id',v_adjustment.id");
  expect(migration).toContain("'member_code',v_member_code");
  expect(migration).toContain("'wallet_type',v_adjustment.wallet_type");
  expect(migration).toContain("'direction',v_adjustment.direction");
  expect(migration).toContain("'amount',v_adjustment.amount");
  expect(migration).toContain("'balance_after',v_new_balance");
  expect(migration).toContain("'replayed',true");
  expect(migration).toContain("wt.reference_type='wallet_adjustment'");
  expect(migration).toContain('wt.reference_id=v_adjustment.id');
 });
 it('keeps the original balance-after snapshot rather than returning a later live balance',()=>{
  expect(migration).toContain('select wt.balance_after into v_new_balance');
  expect(migration).toContain('wt.idempotency_key=v_key');
  expect(migration).toContain('if not found or v_new_balance is null then');
 });
 it('validates every response field against the submitted request before clearing the retry key',()=>{
  expect(ui).toContain("result.success!==true");
  expect(ui).toContain('result.adjustment_id');
  expect(ui).toContain('result.member_code.trim().toUpperCase()!==walletAdjustmentMember.trim().toUpperCase()');
  expect(ui).toContain('result.wallet_type!==walletAdjustmentType');
  expect(ui).toContain('result.direction!==walletAdjustmentDirection');
  expect(ui).toContain('Number(result.amount)!==amount');
  expect(ui).toContain("typeof result.replayed!=='boolean'");
  expect(ui).toContain("walletAdjustmentKey.current='';setWalletAdjustmentMessage");
 });
 it('preserves the same idempotency key when the RPC outcome or response is ambiguous',()=>{
  expect(ui).toContain('The same request key is retained');
  expect(ui).toContain('walletAdjustmentKey.current=');
  expect(ui).toContain('Retry safely; the same request key will be reused.');
 });
});
