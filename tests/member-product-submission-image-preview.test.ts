import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
describe('member product submission image previews',()=>{
 it('creates short-lived signed URLs only for the owner-visible private submission images',()=>{
  expect(ui).toContain("from('product-submission-media').createSignedUrl(path,300)");
  expect(ui).toContain('setImageUrls(signed)');
  expect(ui).toContain("Object.values(row.optional_details as Record<string,unknown>).every(value=>typeof value==='string')");
 });
 it('shows the current private images while editing and explains that they are retained',()=>{
  expect(ui).toContain('Current images — kept unless replaced');
  expect(ui).toContain('imageUrls[editingId]');
 });
 it('shows image previews in the member submission history with descriptive alternative text',()=>{
  expect(ui).toContain("alt={row.name+' image '+(index+1)}");
 });
});
