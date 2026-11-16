import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('public product catalogue pagination',()=>{
 it('loads active products in bounded deterministic pages',()=>{
  expect(app).toContain(".eq('status','published').order('name').order('id',{ascending:true}).range(0,99)");
  expect(app).toContain(".eq('status','published').order('name').order('id',{ascending:true}).range(offset,offset+99)");
  expect(app).toContain('setProductHasMore(rows.length===100)');
 });
 it('offers continuation and reports failures without exposing drafts',()=>{
  expect(app).toContain('Load more products');
  expect(app).toContain('The product catalogue could not be loaded.');
  expect(app).toContain('More products could not be loaded.');
  expect(app).toContain("eq('status','published')");
 });
});
