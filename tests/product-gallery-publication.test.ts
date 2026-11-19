import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119480000_product_gallery_publication.sql','utf8');
const ui=readFileSync('src/components/AdminProductSubmissionReview.tsx','utf8');
const app=readFileSync('src/App.tsx','utf8');
describe('complete approved product image galleries',()=>{
 it('stores and returns all approved image paths while retaining the legacy first image',()=>{
  expect(sql).toContain('add column if not exists image_paths text[]');
  expect(sql).toContain('image_path,image_paths,category,status,product_details');
  expect(sql).toContain('p.image_paths');
  expect(app).toContain('image_paths?:string[]');
 });
 it('copies every private image and removes newly uploaded public images if approval fails',()=>{
  expect(ui).toContain('for(const privatePath of item.image_paths)');
  expect(ui).toContain("'admin_review_product_submission_with_images'");
  expect(ui).toContain("remove(publicPaths)");
  expect(sql).toContain('cardinality(p_public_image_paths)>8');
  expect(sql).toContain('count(distinct image_path)');
 });
 it('renders an accessible swipeable public image gallery',()=>{
  expect(app).toContain('productImageStrip');
  expect(app).toContain("alt={p.name+' image '+(index+1)}");
 });
});
