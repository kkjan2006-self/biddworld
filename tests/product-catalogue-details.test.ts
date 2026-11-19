import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119460000_product_catalogue_details.sql','utf8');
const app=readFileSync('src/App.tsx','utf8');
describe('approved member product details in public catalogue',()=>{
 it('validates a positive bounded asking price on the database write path',()=>{
  expect(sql).toContain("v_price:=new.optional_details->>'Price'");
  expect(sql).toContain("A valid product asking price is required");
 });
 it('copies the complete submitted details into the published product record',()=>{
  expect(sql).toContain('status,product_details');
  expect(sql).toContain("'published',v_s.optional_details");
 });
 it('returns approved details only for published products and renders them in the catalogue',()=>{
  expect(sql).toContain('p.product_details');
  expect(sql).toContain("where p.status='published'");
  expect(app).toContain('product_details?:Record<string,string>|null');
  expect(app).toContain("p.product_details?.Price");
 });
});
