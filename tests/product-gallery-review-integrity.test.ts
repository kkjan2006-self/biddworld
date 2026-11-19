import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119560000_product_gallery_review_integrity.sql','utf8');
const ui=readFileSync('src/components/AdminProductSubmissionReview.tsx','utf8');
describe('Admin product gallery publication integrity',()=>{
 it('requires a one-to-one unique mapping from submitted private images to public images',()=>{
  expect(sql).toContain('cardinality(p_public_image_paths)<>cardinality(v_s.image_paths)');
  expect(sql).toContain('count(distinct path) from unnest(v_s.image_paths)');
  expect(sql).toContain('count(distinct path) from unnest(p_public_image_paths)');
 });
 it('verifies every private source image belongs to the submitting member and still exists',()=>{
  expect(sql).toContain("v_s.submitted_by::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'");
  expect(sql).toContain("o.bucket_id='product-submission-media' and o.name=v_source_path");
 });
 it('verifies every public image exists and rejects image publication for rejected submissions',()=>{
  expect(sql).toContain("o.bucket_id='product-media' and o.name=v_path");
  expect(sql).toContain('Rejected submissions cannot publish product images');
  expect(ui).toContain("rpc('admin_review_product_submission_with_images'");
 });
});
