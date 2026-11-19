import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
describe('member product submission moderation contract',()=>{
 const sql=readFileSync('supabase/migrations/20261119440000_member_product_submission_moderation.sql','utf8');
 const member=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
 const admin=readFileSync('src/components/AdminProductSubmissionReview.tsx','utf8');
 const app=readFileSync('src/App.tsx','utf8');
 it('keeps member product uploads private and owner-scoped',()=>{
  expect(sql).toContain("values('product-submission-media','product-submission-media',false");
  expect(sql).toContain("submitted_by=v_uid");
  expect(sql).toContain("m.id_type='main' and m.status='active' and p.status='active'");
  expect(sql).toContain("o.bucket_id='product-submission-media' and o.name=v_path");
 });
 it('requires Admin approval before creating a published catalogue product',()=>{
  expect(sql).toContain("v_role='admin'");
  expect(sql).toContain("where s.status='pending'");
  expect(sql).toContain("values(v_s.name,v_s.description,p_public_image_path,v_s.category,'published')");
  expect(sql).toContain("'product.submission_approved'");
 });
 it('provides OLX-style member product submission and private status history',()=>{
  expect(member).toContain("member_submit_product_listing");
  expect(member).toContain("product-submission-media");
  expect(member).toContain('My Product Submissions');
  expect(member).toContain('Submit for Admin Approval');
 });
 it('connects member submissions and Admin moderation to the app',()=>{
  expect(app).toContain('MemberProductSubmission');
  expect(admin).toContain('admin_review_product_submission');
  expect(admin).toContain('Approve & Publish');
 });
});
