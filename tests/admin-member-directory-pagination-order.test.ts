import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin member directory pagination request ordering',()=>{
 it('invalidates in-flight page requests as soon as the search effect changes',()=>{
  expect(admin).toContain('const request=++memberSearchRequest.current;');
  expect(admin).toContain('const search=memberSearch.trim();');
  expect(admin).toContain('p_search:search||null,p_limit:100,p_offset:0');
  expect(admin).toContain('if(!active||request!==memberSearchRequest.current)return;');
 });

 it('captures the applied search and offset before requesting the next page',()=>{
  expect(admin).toContain('const request=memberSearchRequest.current,search=appliedMemberSearch.trim(),offset=members.length;');
  expect(admin).toContain('p_search:search||null,p_limit:100,p_offset:offset');
 });

 it('ignores stale page results, errors and loading cleanup after a newer search begins',()=>{
  expect(admin).toContain('if(request!==memberSearchRequest.current)return;const batch=(data??[]) as SponsorMember[];setMembers(current=>[...current,...batch]);');
  expect(admin).toContain("if(request===memberSearchRequest.current)setMemberMessage(rpcContractUnavailableMessage(e,'Admin member directory')??(e instanceof Error?e.message:'Could not load more member records.'));");
  expect(admin).toContain('if(request===memberSearchRequest.current){memberPageInFlight.current=false;setMemberMoreBusy(false);}');
 });
});
