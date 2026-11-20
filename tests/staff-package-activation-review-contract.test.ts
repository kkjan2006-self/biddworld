import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const staff=readFileSync('src/components/AdminStaff.tsx','utf8');
const page=readFileSync('supabase/migrations/20261119410000_admin_pending_activation_keyset_pagination.sql','utf8');
const review=readFileSync('supabase/migrations/20261119640000_staff_package_activation_review.sql','utf8');
const submission=readFileSync('supabase/migrations/20261116200000_lock_package_activation_submission.sql','utf8');
describe('Staff package activation review permission contract',()=>{
 it('uses bounded keyset pages and validates each activation before signing receipts',()=>{
  expect(staff).toContain("rpc('admin_list_pending_activations_page'");
  expect(staff).not.toContain("rpc('admin_list_pending_activations'");
  expect(staff).toContain('function validActivation(value:unknown):value is Activation');
  expect(staff).toContain('payload.items.length>50');
  expect(staff).toContain('Load more requests');
 });
 it('allows only Admin or Staff with the package activation review permission to list',()=>{
  expect(page).toContain("role','')='admin_staff'");
  expect(page).toContain("? 'package_activation_review'");
 });
 it('allows the same narrowly permissioned Staff role to review and activate',()=>{
  expect(review).toContain("v_role='admin_staff' and v_permissions ? 'package_activation_review'");
  expect(review).toContain('admin_review_package_activation(uuid,boolean)');
 });
 it('validates activation UUIDs, bounded payment fields and member-owned receipt path structure',()=>{
  expect(staff).toContain('const UUID_PATTERN=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i');
  expect(staff).toContain('UUID_PATTERN.test(row.id)');
  expect(staff).toContain('function validActivationReceiptPath(value:unknown):value is string');
  expect(staff).toContain("/^[a-f0-9]{32}-[a-z0-9._-]{1,90}$/i.test(parts[1])");
  expect(staff).toContain("/^[A-Za-z0-9./_-]{6,80}$/.test(row.payment_reference)");
  expect(staff).toContain("/^[A-Z]{3}$/.test(row.currency)");
 });
 it('requires continuation pages to begin strictly before the prior cursor',()=>{
  expect(staff).toContain('if(after&&page.length){const first=page[0],timeDelta=Date.parse(first.submitted_at)-Date.parse(after.submitted_at)');
  expect(staff).toContain('first.id.localeCompare(after.id)>=0');
  expect(staff).toContain('did not continue strictly before the previous cursor');
 });
 it('requires exact keyset cursor agreement, page size and descending record order',()=>{
  expect(staff).toContain("page.length!==50||page[page.length-1].id!==payload.next_id||page[page.length-1].submitted_at!==payload.next_submitted_at");
  expect(staff).toContain('previous.id.localeCompare(current.id)<0');
  expect(staff).toContain('payload.next_submitted_at!==null||payload.next_id!==null');
 });
 it('matches the SQL integer activation_number JSON value instead of rejecting valid rows',()=>{
  expect(staff).toContain("type Activation={id:string;activation_number:number;");
  expect(staff).toContain("typeof row.activation_number==='number'&&Number.isSafeInteger(row.activation_number)&&row.activation_number>=1");
  expect(submission).toContain('v_activation_number integer');
  expect(submission).toContain("'activation_number', v_activation_number");
  expect(page).toContain("'activation_number',activation_number");
 });
 it('keeps legacy pending activations with no receipt visible but never enables approval without a receipt',()=>{
  expect(staff).toContain('receipt_path:string|null');
  expect(staff).toContain('(row.receipt_path===null||validActivationReceiptPath(row.receipt_path))');
  expect(staff).toContain("if(!item.receipt_path){failures[item.id]='No payment receipt is attached.';return;}");
  expect(staff).toContain("disabled={!!busy||!urls[item.id]}");
  expect(page).toContain("'receipt_path',receipt_path");
 });
});
