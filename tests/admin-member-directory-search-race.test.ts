import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin member directory search request ordering',()=>{
 it('uses a request generation to prevent older responses replacing newer searches',()=>{
  expect(admin).toContain("import {useEffect,useMemo,useRef,useState} from 'react'");
  expect(admin).toContain('const memberSearchRequest=useRef(0);');
  expect(admin).toContain('const request=++memberSearchRequest.current;');
  expect(admin).toContain('if(!active||request!==memberSearchRequest.current)return;');
 });

 it('prevents the initial Admin workspace load from overwriting a newer member search',()=>{
  expect(admin).toContain('const memberRequestAtStart=memberSearchRequest.current;');
  expect(admin).toContain('if(!memberResult.error&&memberRequestAtStart===memberSearchRequest.current)');
 });

 it('protects manual search and Clear from stale results and stale loading cleanup',()=>{
  expect(admin).toContain('if(request!==memberSearchRequest.current)return;');
  expect(admin).toContain('if(request===memberSearchRequest.current)setMemberSearchBusy(false);');
  expect(admin).toContain('const request=++memberSearchRequest.current;void (async()=>{if(!supabase)return;');
  expect(admin).toContain('if(request===memberSearchRequest.current)setMemberMessage(e instanceof Error?e.message:"Could not reset member search.");');
 });
});
