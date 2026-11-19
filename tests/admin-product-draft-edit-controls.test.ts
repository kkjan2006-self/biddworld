import {describe,expect,it} from 'vitest';
import {readFileSync} from 'node:fs';
const admin=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin product draft editing controls',()=>{
 it('distinguishes new and edit modes and offers a safe cancel action',()=>{
  expect(admin).toContain("editingProductId?'Edit Product Draft':'1. Product Details'");
  expect(admin).toContain("editingProductId?'Update Product Draft':'Save Product Draft'");
  expect(admin).toContain('Cancel Edit');
  expect(admin).toContain('Product editing cancelled. No changes were saved.');
 });
 it('prevents saving while image upload is in progress',()=>{
  expect(admin).toContain('disabled={auctionBusy||productUploadBusy||productName.trim().length<2}');
 });
});
