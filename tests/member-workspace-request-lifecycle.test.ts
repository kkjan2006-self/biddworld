import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const notifications=read('src/components/Notifications.tsx');
const support=read('src/components/Support.tsx');
const referrals=read('src/components/Referrals.tsx');
describe('member workspace async request lifecycle',()=>{
 it('invalidates stale and unmounted notification requests and serializes pagination',()=>{
  expect(notifications).toContain('const requestSeq=useRef(0),loadMoreBusy=useRef(false)');
  expect(notifications).toContain('if(seq!==requestSeq.current)return');
  expect(notifications).toContain('requestSeq.current++;loadMoreBusy.current=false');
  expect(notifications).toContain('if(!supabase||loadMoreBusy.current||busy||!hasMore)return');
  expect(notifications).toContain('loadMoreBusy.current=false;setBusy(false)');
 });
 it('invalidates stale and unmounted support requests and serializes pagination',()=>{
  expect(support).toContain('const requestSeq=useRef(0),loadMoreBusy=useRef(false)');
  expect(support).toContain('if(seq!==requestSeq.current)return');
  expect(support).toContain('requestSeq.current++;loadMoreBusy.current=false');
  expect(support).toContain('if(!supabase||loadMoreBusy.current||busy||!hasMore)return');
  expect(support).toContain('loadMoreBusy.current=false;setBusy(false)');
 });
 it('protects referral auth ordering and prevents overlapping or stale team pages',()=>{
  expect(referrals).toContain('authEventObserved=false');
  expect(referrals).toContain('active&&!authEventObserved');
  expect(referrals).toContain('const request=useRef(0),loadMoreBusy=useRef(false)');
  expect(referrals).toContain('if(seq!==request.current)return');
  expect(referrals).toContain('loadMoreBusy.current=true;const seq=request.current');
  expect(referrals).toContain('loadMoreBusy.current=false;setLoadingMore(false)');
 });
});
