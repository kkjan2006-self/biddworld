import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/Packages.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261119500000_require_package_activation_receipt.sql','utf8');
describe('mandatory package activation receipt',()=>{
 it('requires a supported receipt in the member activation form',()=>{
  expect(ui).toContain("if(!receiptFile){setActivationMessage('Upload your payment receipt before submitting the activation request.')");
  expect(ui).toContain('id="package-activation-receipt" type="file" required');
 });
 it('requires an owned uploaded private receipt before creating the activation',()=>{
  expect(sql).toContain('p_receipt_path is null');
  expect(sql).toContain("(storage.foldername(p_receipt_path))[1]<>v_uid::text");
  expect(sql).toContain("bucket_id='package-receipts'");
  expect(sql).toContain('private.submit_package_activation(p_package_id,p_payment_reference)');
 });
 it('prevents duplicate in-flight browser submissions and cleans the file input on success',()=>{
  expect(ui).toContain('activationInFlight.current');
  expect(ui).toContain("receiptInput.value=''");
 });
});
