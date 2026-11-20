import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Member dashboard initial loading',()=>{
 it('starts the account data request automatically when the dashboard mounts',()=>{
  expect(account).toContain("import {useEffect,useRef,useState} from 'react'");
  expect(account).toContain('useEffect(()=>{loadMounted.current=true;void load();return()=>{loadMounted.current=false;loadRequest.current+=1;}},[]);');
  expect(account.indexOf('async function load(){')).toBeLessThan(account.indexOf('useEffect(()=>{loadMounted.current=true;void load();return()=>{loadMounted.current=false;loadRequest.current+=1;}},[]);'));
 });
 it('retains a manual refresh action and always releases the initial loading state',()=>{
  expect(account).toContain('onClick={()=>void load()}');
  expect(account).toContain('}finally{\n   if(isCurrent())setLoading(false);');
 });
 it('keeps the member-specific profile lookup and Main ID scoped activity queries',()=>{
  expect(account).toContain(".from('profiles').select('display_name,phone,status,main_member_id').eq('id',user.id)");
  expect(account).toContain(".eq('member_id',p.main_member_id)");
  expect(account).toContain(".eq('credited_main_member_id',p.main_member_id)");
 });
});

 it('distinguishes missing member identity, ID-list and withdrawal RPC deployments',()=>{
  expect(account).toContain("rpcContractUnavailableMessage(identityError,'Member identity details')");
  expect(account).toContain("const memberRpcError=[m.error,wr.error].find(error=>error&&rpcContractUnavailableMessage(error,'Member account details'))");
  expect(account).toContain("rpcContractUnavailableMessage(memberRpcError,'Member account details')");
  expect(account).toContain("else if(m.error||a.error||w.error||wr.error||b.error||fb.error||rc.error||wp.error||deliveryResult.error)");
 });
