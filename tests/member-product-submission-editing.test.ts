import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';

describe('member product submission editing contract',()=>{
 const sql=readFileSync('supabase/migrations/20261119450000_member_product_submission_editing.sql','utf8');
 const ui=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
 it('restricts edits to the authenticated owner and pending/rejected states',()=>{
  expect(sql).toContain('submitted_by=v_uid');
  expect(sql).toContain("v_row.status not in ('pending','rejected')");
  expect(sql).toContain('for update');
 });
 it('revalidates active Main ID and private image ownership',()=>{
  expect(sql).toContain("m.id_type='main' and m.status='active' and p.status='active'");
  expect(sql).toContain("o.bucket_id='product-submission-media' and o.name=v_path");
 });
 it('resets a corrected submission to pending review and records an audit event',()=>{
  expect(sql).toContain("status='pending',review_note=null,reviewed_by=null,reviewed_at=null");
  expect(sql).toContain("'product.edited_and_resubmitted'");
 });
 it('offers member edit/resubmit and preserves existing images when no replacement is selected',()=>{
  expect(ui).toContain("row.status==='pending'||row.status==='rejected'");
  expect(ui).toContain('member_update_product_submission');
  expect(ui).toContain('Edit & Resubmit');
  expect(ui).toContain('const imagePaths=files.length?uploaded:(current?.image_paths??[])');
  expect(ui).toContain('required={!editingId}');
  expect(ui).toContain('Enter a valid product price greater than zero.');
  expect(ui).toContain('Warranty:warranty,Ownership:ownership');
 });
});
