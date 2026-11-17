import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin Duplicate ID pagination request lock',()=>{
 it('prevents duplicate page requests before React state updates render',()=>{
  expect(admin).toContain('duplicatePageInFlight=useRef(false)');
  expect(admin).toContain('if(!supabase||duplicatePageInFlight.current||duplicateMoreBusy||!duplicateHasMore)return;');
  expect(admin).toContain('duplicatePageInFlight.current=true;');
 });
 it('releases only the current page lock and resets it for a new directory generation',()=>{
  expect(admin).toContain('duplicatePageInFlight.current=false;setDuplicateMoreBusy(false);');
  expect(admin).toContain('if(request===duplicateSearchRequest.current){duplicatePageInFlight.current=false;setDuplicateMoreBusy(false);}');
 });
});
