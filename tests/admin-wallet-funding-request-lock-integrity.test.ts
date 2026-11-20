import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const source=readFileSync('src/components/AdminWalletFundingReview.tsx','utf8');
describe('Admin wallet funding queue request locking',()=>{
 it('serializes refresh and continuation requests through one shared lock',()=>{
  expect(source).toContain('if(pageBusy.current)return;\n  pageBusy.current=true;\n  const seq=++requestSeq.current;');
  expect(source).not.toContain('if(append)pageBusy.current=true;else pageBusy.current=false;');
 });
 it('releases the shared lock only when the current request generation finishes',()=>{
  expect(source).toContain('finally{if(seq===requestSeq.current){setLoading(false);setLoadingMore(false);pageBusy.current=false;}}');
  expect(source).not.toContain('if(append)pageBusy.current=false');
 });
 it('preserves stale-response protection during queue refreshes',()=>{
  expect(source).toContain('if(seq!==requestSeq.current)return;');
  expect(source).toContain('return()=>{requestSeq.current++;};');
 });
});
