import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';

describe('Admin saved product image thumbnails',()=>{
 it('resolves stored product-media paths and renders accessible lazy thumbnails',()=>{
  const source=readFileSync('src/components/Admin.tsx','utf8');
  expect(source).toContain("function adminProductImageUrl(path:string|null|undefined)");
  expect(source).toContain("supabase?.storage.from('product-media').getPublicUrl(path).data.publicUrl");
  expect(source).toContain("alt={p.name+' product'}");
  expect(source).toContain('loading="lazy"');
 });
});
