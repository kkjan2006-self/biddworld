import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/AdminWalletFundingReview.tsx','utf8');
describe('Admin wallet funding review queue refresh safety',()=>{
 it('restarts from the first page after approving or rejecting a request',()=>{
  expect(ui).toContain("setMessage(approve?'Payment approved.");
  expect(ui).toContain('await load();');
  expect(ui).not.toContain('await load(false);');
 });
 it('retries from a clean first-page cursor and prevents stale requests releasing a newer lock',()=>{
  expect(ui).toContain('if(append)pageBusy.current=true;else pageBusy.current=false;');
  expect(ui).toContain('if(seq===requestSeq.current){setLoading(false);setLoadingMore(false);if(append)pageBusy.current=false;}');
  expect(ui).toContain('onClick={()=>void load()}');
 });
});
