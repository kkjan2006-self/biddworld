import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Packages.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261119500000_require_package_activation_receipt.sql','utf8');
describe('Member package activation response integrity',()=>{
 it('validates the exact pending activation identity and receipt path before clearing the form',()=>{
  expect(source).toContain('data:activationResult');
  expect(source).toContain('result.success!==true');
  expect(source).toContain('result.activation_number');
  expect(source).toContain("result.payment_status!=='pending'");
  expect(source).toContain("result.activation_status!=='pending'");
  expect(source).toContain('result.receipt_path!==receiptPath');
  expect(source).toContain('activationSubmitted=true');
 });
 it('preserves uploaded receipts after an ambiguous or malformed response',()=>{
  expect(source).toContain('The request may already have been recorded; refresh your activation history before retrying.');
  expect(source).toContain('activationRpcAttempted=true');
  expect(source).toContain("activationRpcRejected=typeof (error as {code?:unknown}).code==='string'");
  expect(source).toContain('if(uploadedReceiptPath&&!activationSubmitted&&(!activationRpcAttempted||activationRpcRejected))');
 });
 it('matches the receipt wrapper response contract',()=>{
  expect(migration).toContain("return v_result||jsonb_build_object('receipt_path',p_receipt_path)");
  expect(migration).toContain('submit_package_activation_with_receipt');
 });
});
