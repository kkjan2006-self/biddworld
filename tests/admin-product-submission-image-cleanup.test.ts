import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/AdminProductSubmissionReview.tsx','utf8');
describe('Admin product image cleanup after moderation',()=>{
 it('tracks whether the review RPC was attempted and definitely rejected',()=>{
  expect(ui).toContain('let rpcAttempted=false;let rpcDefinitelyRejected=false;');
  expect(ui).toContain("rpcDefinitelyRejected=typeof(error as {code?:unknown}).code==='string'");
 });
 it('validates the moderation response before reporting approval or rejection',()=>{
  expect(ui).toContain('data:reviewResult');
  expect(ui).toContain('result.status!==expectedStatus');
  expect(ui).toContain('result.image_count!==publicPaths.length');
  expect(ui).toContain('result.product_id');
 });
 it('cleans uploaded images only before RPC or after a definite server rejection',()=>{
  expect(ui).toContain('publicPaths.length&&(!rpcAttempted||rpcDefinitelyRejected)');
 });
 it('persists failed definite-rejection cleanup and exposes a retry action',()=>{
  expect(ui).toContain('biddworld:admin-product-media-cleanup:');
  expect(ui).toContain('validPublicProductPath');
  expect(ui).toContain('retryOrphanedProductCleanup');
  expect(ui).toContain('Retry image cleanup');
  expect(ui).toContain('setOrphanedMedia(current=>[...current,...publicPaths');
 });
 it('retains uploaded images when the RPC result is uncertain to avoid broken published products',()=>{
  expect(ui).toContain('The approval outcome could not be confirmed, so the uploaded images were retained.');
 });
});
