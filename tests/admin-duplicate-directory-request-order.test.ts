import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin Duplicate ID directory request ordering',()=>{
 it('assigns a new generation to each workspace directory load and resets its page lock',()=>{
  expect(admin).toContain('duplicateSearchRequest=useRef(0)');
  expect(admin).toContain('duplicatePageInFlight=useRef(false)');
  expect(admin).toContain('const duplicateRequestAtStart=++duplicateSearchRequest.current;');
  expect(admin).toContain('duplicatePageInFlight.current=false;setDuplicateMoreBusy(false);');
  expect(admin).toContain('if(active&&duplicateRequestAtStart===duplicateSearchRequest.current)');
 });

 it('only appends the next page when its search generation is still current',()=>{
  expect(admin).toContain('const request=++duplicateSearchRequest.current;const search=appliedDuplicateSearch.trim()||null;const offset=duplicateIds.length;');
  expect(admin).toContain('if(request!==duplicateSearchRequest.current)return;');
  expect(admin).toContain('if(request===duplicateSearchRequest.current)setDuplicateMessage(e instanceof Error?e.message');
  expect(admin).toContain('if(request===duplicateSearchRequest.current){duplicatePageInFlight.current=false;setDuplicateMoreBusy(false);}');
 });
});
