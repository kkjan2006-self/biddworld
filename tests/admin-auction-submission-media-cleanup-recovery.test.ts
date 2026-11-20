import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const source=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');

describe('Admin auction submission media cleanup recovery',()=>{
 it('persists account-scoped private and public media cleanup paths across reloads',()=>{
  expect(source).toContain("biddworld:admin-auction-media-cleanup:");
  expect(source).toContain('localStorage.getItem');
  expect(source).toContain('localStorage.setItem');
  expect(source).toContain('localStorage.removeItem');
  expect(source).toContain("['auction-submission-media','product-media']");
  expect(source).toContain('validCleanupPath');
  expect(source).toContain("validCleanupPath(path,'auction-submission-media')");
  expect(source).toContain("validCleanupPath(item.path,bucket)");
  expect(source).toContain("path.split('/')[0].toLowerCase()===String(row.submitted_by).toLowerCase()");
 });
 it('retains failed cleanup after successful approval and definite RPC rejection',()=>{
  expect(source).toContain("bucket:'auction-submission-media' as const");
  expect(source).toContain("bucket:'product-media' as const");
  expect(source).toContain('Retry image cleanup');
  expect(source).toContain('retryOrphanedMediaCleanup');
 });
 it('rejects malformed or cross-submitter private paths and enforces SQL-compatible public paths',()=>{
  expect(source).toContain("bucket==='auction-submission-media'?");
  expect(source).toContain("bucket==='product-media'?");
  expect(source).toContain('validUuid(row.submitted_by)');
 });
 it('does not delete published images after an ambiguous RPC outcome',()=>{
  expect(source).toContain('if(publishedPaths.length>0&&(!rpcAttempted||rpcDefinitelyRejected))');
 });
 it('serializes review and cleanup retry actions',()=>{
  expect(source).toContain('reviewInFlight.current||busy');
  expect(source).toContain("setBusy('cleanup')");
  expect(source).toContain('cleanupInFlight.current||reviewInFlight.current||busy');
  expect(source).toContain('cleanupInFlight.current=false');
 });
});
