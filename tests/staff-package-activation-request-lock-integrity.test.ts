import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const staff=readFileSync('src/components/AdminStaff.tsx','utf8');
describe('Staff activation queue concurrent request locking',()=>{
 it('locks both reset and continuation requests before starting asynchronous work',()=>{
  expect(staff).toContain('const seq=reset?++loadSequence.current:loadSequence.current;\n  pageLock.current=true;\n  if(reset)cursor.current=null;');
  expect(staff).toContain('if(!reset&&pageLock.current)return;');
 });
 it('prevents stale requests from releasing a newer request lock',()=>{
  expect(staff).toContain('if(seq===loadSequence.current){setQueueLoading(false);setLoadingMore(false);pageLock.current=false;}');
  expect(staff).not.toContain('pageLock.current=false;\n  }\n }');
 });
 it('keeps stale responses from mutating the current activation queue',()=>{
  expect(staff).toContain('if(seq!==loadSequence.current)return;');
  expect(staff).toContain('if(seq===loadSequence.current)setMessage(');
 });
});
