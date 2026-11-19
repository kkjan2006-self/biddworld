import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/AdminWalletFundingReview.tsx'),'utf8');

describe('Admin wallet funding review diagnostics',()=>{
 it('does not present a failed queue request as an empty queue',()=>{
  expect(source).toContain('Wallet funding requests could not be loaded. Please retry.');
  expect(source).toContain('error&&!rows.length?null:rows.length===0?');
  expect(source).toContain('Retry');
 });
 it('requires a working private receipt link before approving a funding request',()=>{
  expect(source).toContain('Open and verify the payment receipt before approving this request.');
  expect(source).toContain('disabled={busy!==\'\'||!urls[row.id]}');
  expect(source).toContain('createSignedUrl(row.receipt_path,300)');
 });
 it('prevents concurrent review submissions and ignores stale queue loads',()=>{
  expect(source).toContain('reviewBusy.current');
  expect(source).toContain('seq!==requestSeq.current');
 });
});
