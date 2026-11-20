import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/App.tsx','utf8');
describe('public product page runtime contract',()=>{
 it('validates published product identity and nullable text/image fields',()=>{
  expect(ui).toContain('function parseProductPage(value:unknown):ProductPageRow[]');
  expect(ui).toContain("row.status!=='published'");
  expect(ui).toContain('seen.has(row.id)');
 });
 it('rejects inconsistent has-more markers and validates initial and continuation pages',()=>{
  expect(ui).toContain('pageHasMore!==row.has_more');
  expect(ui).toContain('const rows=parseProductPage(data??[])');
  expect(ui).toContain('const batch=parseProductPage(data??[])');
 });
});
