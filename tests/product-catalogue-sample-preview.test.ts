import {describe,expect,it} from 'vitest';
import {readFileSync} from 'node:fs';
const app=readFileSync('src/App.tsx','utf8');
const css=readFileSync('src/style.css','utf8');
describe('Product catalogue sample preview',()=>{
 it('provides three local sample products and labels the fallback clearly',()=>{
  expect(app).toContain('demoProducts:Product[]');
  expect(app).toContain('demo-product-1');
  expect(app).toContain('demo-product-2');
  expect(app).toContain('demo-product-3');
  expect(app).toContain('showingProductSamples');
  expect(app).toContain('Published products automatically replace these samples.');
 });
 it('filters sample cards locally and styles the preview row',()=>{
  expect(app).toContain('visibleProducts=productSource.filter');
  expect(app).toContain('productCatalogueGrid');
  expect(css).toContain('.productCatalogueGrid');
 });
});
