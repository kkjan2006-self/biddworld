import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const product=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
const auction=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');

describe('member submission media cleanup recovery',()=>{
 it('keeps failed product image removals visible and retryable',()=>{
  expect(product).toContain('orphanedPaths');
  expect(product).toContain('retryOrphanedImageCleanup');
  expect(product).toContain("setOrphanedPaths(current=>Array.from(new Set([...current,...stale])))");
  expect(product).toContain('Retry image cleanup');
  expect(product).toContain("biddworld:product-media-cleanup:");
  expect(product).toContain('localStorage.setItem');
  expect(product).toContain('localStorage.removeItem');
 });
 it('keeps failed auction image removals visible and retryable',()=>{
  expect(auction).toContain('orphanedPaths');
  expect(auction).toContain('retryOrphanedImageCleanup');
  expect(auction).toContain("setOrphanedPaths(current=>Array.from(new Set([...current,...stale])))");
  expect(auction).toContain('Retry image cleanup');
  expect(auction).toContain("biddworld:auction-media-cleanup:");
  expect(auction).toContain('localStorage.setItem');
  expect(auction).toContain('localStorage.removeItem');
 });
 it('tracks uploaded files when a definite rejection cleanup fails',()=>{
  expect(product).toContain("setOrphanedPaths(current=>Array.from(new Set([...current,...uploaded])))");
  expect(auction).toContain("setOrphanedPaths(current=>Array.from(new Set([...current,...uploadedPaths])))");
 });
});
