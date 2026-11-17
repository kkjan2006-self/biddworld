import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin member directory search request ordering',()=>{
 it('debounces searches and invalidates responses from older search generations',()=>{
  expect(admin).toContain("import {useEffect,useMemo,useRef,useState} from 'react';");
  expect(admin).toContain('const memberSearchRequest=useRef(0),duplicateSearchRequest=useRef(0),memberPageInFlight=useRef(false),duplicatePageInFlight=useRef(false);');
  expect(admin).toContain('const request=++memberSearchRequest.current;');
  expect(admin).toContain('const timer=window.setTimeout(async()=>{');
  expect(admin).toContain('if(!active||request!==memberSearchRequest.current)return;');
  expect(admin).toContain('return()=>{active=false;window.clearTimeout(timer);};');
 });

 it('prevents the initial Admin workspace load from overwriting a newer member search',()=>{
  expect(admin).toContain('const memberRequestAtStart=memberSearchRequest.current;');
  expect(admin).toContain('if(!memberResult.error&&memberRequestAtStart===memberSearchRequest.current)');
 });

 it('keeps stale search responses from changing the visible loading state',()=>{
  expect(admin).toContain('finally{if(active&&request===memberSearchRequest.current)setMemberMoreBusy(false);}');
  expect(admin).toContain('if(active&&request===memberSearchRequest.current)setMemberMessage');
 });
});
