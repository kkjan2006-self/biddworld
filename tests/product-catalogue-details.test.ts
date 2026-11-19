import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119460000_product_catalogue_details.sql','utf8');
const app=readFileSync('src/App.tsx','utf8');
const manifest=readFileSync('supabase/clean-install/forward-migrations.txt','utf8');
describe('approved member product details in public catalogue',()=>{
 it('validates positive bounded asking price and safe plain-text detail values',()=>{
  expect(sql).toContain("v_price:=new.optional_details->>'Price'");
  expect(sql).toContain("A valid product asking price is required");
  expect(sql).toContain("v_price !~ '^[0-9]{1,9}([.][0-9]{1,2})?$'");
  expect(sql).toContain("p_public_image_path !~ '^[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'");
  expect(sql).toContain("Every product detail value must be plain text");
 });
 it('copies complete submitted details into the published product record',()=>{
  expect(sql).toContain('status,product_details');
  expect(sql).toContain("'published',v_s.optional_details");
 });
 it('returns only published product details and searches all approved attributes',()=>{
  expect(sql).toContain('p.product_details');
  expect(sql).toContain("where p.status='published'");
  expect(sql).toContain('p.product_details::text');
  expect(app).toContain('product_details?:Record<string,string>|null');
  expect(app).toContain('p.product_details?.Price');
  expect(manifest).toContain('supabase/migrations/20261119460000_product_catalogue_details.sql');
 });
});
