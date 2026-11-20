import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const source=readFileSync('src/components/FixedBid.tsx','utf8');
describe('Fixed Bid product media delivery',()=>{
 it('resolves storage object paths through the public product-media bucket',()=>{
  assert.match(source,/storage\.from\('product-media'\)\.getPublicUrl\(path\)/);
 });
 it('preserves already absolute image URLs and handles missing images',()=>{
  assert.match(source,/https\?:\\\/\\\//);
  assert.match(source,/if\(!path\)return ''/);
 });
 it('uses the resolved URL in the campaign image and lazy-loads it',()=>{
  assert.match(source,/src=\{productImageUrl\(r\.product\?\.image_path\)\}/);
  assert.match(source,/loading="lazy"/);
 });
});
