import {describe,expect,it} from 'vitest';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin member directory duplicate page-request protection',()=>{
 it('uses a synchronous ref lock in addition to React loading state',()=>{
  expect(admin).toContain('memberPageInFlight=useRef(false)');
  expect(admin).toContain('!memberHasMore||memberPageInFlight.current');
  expect(admin).toContain('memberPageInFlight.current=true;');
 });
 it('releases the page lock only for the current request',()=>{
  expect(admin).toContain('if(request===memberSearchRequest.current){memberPageInFlight.current=false;setMemberMoreBusy(false);}');
 });
 it('invalidates the previous page lock when a new search starts',()=>{
  expect(admin).toContain('memberPageInFlight.current=false;');
  expect(admin).toContain('const request=++memberSearchRequest.current;');
 });
});
