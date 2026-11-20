import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const source=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
describe('Admin auction submission queue request locking',()=>{
 it('uses one lock for refresh and pagination instead of clearing it on refresh',()=>{
  expect(source).toContain('if(!supabase||pageLock.current)return;\n  pageLock.current=true;\n  if(reset)cursor.current=null;');
  expect(source).not.toContain('if(reset){pageLock.current=false;cursor.current=null;}else pageLock.current=true;');
 });
 it('releases the lock only from the active request generation',()=>{
  expect(source).toContain('finally{if(seq===loadSequence.current){setQueueLoading(false);setLoadingMore(false);pageLock.current=false;}}');
 });
 it('invalidates pending queue loads during component cleanup',()=>{
  expect(source).toContain('return()=>{active=false;loadSequence.current++;pageLock.current=false;};},[]);');
 });
 it('retains stale response protection before queue state updates',()=>{
  expect(source).toContain('if(seq!==loadSequence.current)return;');
 });
});
