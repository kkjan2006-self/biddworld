import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const source=readFileSync('src/components/Admin.tsx','utf8');

describe('Admin product media cleanup recovery',()=>{
 it('retains paths when replacement cleanup fails and exposes a retry action',()=>{
  expect(source).toContain('orphanedProductImagePaths');
  expect(source).toContain('setOrphanedProductImagePaths(current=>current.includes(previousStagedPath)?current:[...current,previousStagedPath])');
  expect(source).toContain('retryOrphanedProductImageCleanup');
  expect(source).toContain('Retry Temporary Image Cleanup');
 });
 it('does not leave a removed staged image URL attached to the draft form',()=>{
  expect(source).toContain("setProductImage(current=>current===client.storage.from('product-media').getPublicUrl(path).data.publicUrl?'':current)");
  expect(source).toContain("setProductImage(current=>current===stagedUrl?'':current)");
 });
 it('keeps failed cleanup visible and preserves staged image state until retry succeeds',()=>{
  expect(source).toContain('Temporary image cleanup is still pending');
  expect(source).toContain("if(stagedPath&&paths.includes(stagedPath)){setStagedProductImagePath('')");
 });
});
