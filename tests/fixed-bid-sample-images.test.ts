import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const source=readFileSync('src/components/FixedBid.tsx','utf8');
describe('Fixed Bid sample product images',()=>{
 it('maps the three supplied sample assets to the matching sample products',()=>{
  assert.match(source,/title:'Smartphone Mega Fixed Bid'[\s\S]*?sample-products\/smartphone\.webp/);
  assert.match(source,/title:'Home Appliances Fixed Bid'[\s\S]*?sample-products\/mixer-grinder\.webp/);
  assert.match(source,/title:'Lifestyle Accessories Fixed Bid'[\s\S]*?sample-products\/smartwatch\.webp/);
 });
 it('resolves app-base-path assets directly instead of through Supabase Storage',()=>{
  assert.match(source,/path\.startsWith\(import\.meta\.env\.BASE_URL\)/);
 });
});
