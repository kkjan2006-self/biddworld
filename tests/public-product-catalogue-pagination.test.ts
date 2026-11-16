import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('public product catalogue pagination',()=>{
 it('loads active products in bounded deterministic pages',()=>{
  expect(app).toContain("rpc('public_list_active_products_page',{p_search:query.trim()||null,p_limit:100,p_offset:0})");
  expect(app).toContain("p_offset:products.length");
  expect(app).toContain('setProductHasMore(rows[0]?.has_more===true)');
 });
 it('offers continuation and reports failures without exposing drafts',()=>{
  expect(app).toContain('Load more products');
  expect(app).toContain('The product catalogue could not be loaded.');
  expect(app).toContain('More products could not be loaded.');
  expect(app).toContain("eq('status','published')");
 });
});

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116120000_public_product_catalogue_search.sql'),'utf8');
describe('public product catalogue search RPC',()=>{
 it('uses caller RLS and returns published products only',()=>{
  expect(migration).toContain('security invoker');
  expect(migration).toContain("where p.status='published'");
  expect(migration).toContain('position(lower(v_search)');
 });
 it('bounds search length, page size and offset and grants only public read execution',()=>{
  expect(migration).toContain('length(v_search)>100');
  expect(migration).toContain('v_limit>100');
  expect(migration).toContain('v_offset>1000000');
  expect(migration).toMatch(/grant execute on function public\.public_list_active_products_page\(text,integer,integer\) to anon,authenticated/i);
  expect(migration).toMatch(/revoke all on function public\.public_list_active_products_page\(text,integer,integer\) from public/i);
 });
});
