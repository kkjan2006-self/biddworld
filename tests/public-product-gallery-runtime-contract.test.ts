import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/App.tsx','utf8');
describe('public product gallery runtime contract',()=>{
 it('validates the complete public image gallery and optional product facts',()=>{
  expect(ui).toContain('!Array.isArray(row.image_paths)||row.image_paths.length>8');
  expect(ui).toContain('row.image_paths.every(path=>typeof path===');
  expect(ui).toContain('Object.entries(row.product_details as Record<string,unknown>)');
 });
 it('keeps product card gallery rendering aligned with validated page fields',()=>{
  expect(ui).toContain('(p.image_paths?.length?p.image_paths:p.image_path?[p.image_path]:[])');
  expect(ui).toContain('Object.entries(p.product_details)');
 });
});
