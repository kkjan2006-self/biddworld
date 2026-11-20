import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';

describe('public product catalogue fallback integrity',()=>{
 const app=readFileSync('src/App.tsx','utf8');
 it('shows sample cards only when the backend is intentionally unconfigured',()=>{
  expect(app).toContain('const showingProductSamples=products.length===0&&!productError&&!configured;');
 });
 it('does not disguise a configured catalogue error or empty result as sample products',()=>{
  expect(app).toContain("setProductError('The product catalogue could not be loaded. Please retry later.')");
  expect(app).toContain("visibleProducts.length===0&&<div className=\"empty\">No products match your search. Try another keyword.</div>");
 });
 it('keeps member product submission available independently of public catalogue fallback',()=>{
  expect(app).toContain('<MemberProductSubmission/>');
 });
});
