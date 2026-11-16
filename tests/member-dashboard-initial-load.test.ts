import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Member dashboard initial loading',()=>{
 it('starts the account data request automatically when the dashboard mounts',()=>{
  expect(account).toContain("import {useEffect,useState} from 'react'");
  expect(account).toContain('useEffect(()=>{void load();},[]);');
  expect(account.indexOf('async function load(){')).toBeLessThan(account.indexOf('useEffect(()=>{void load();},[]);'));
 });
 it('retains a manual refresh action and always releases the initial loading state',()=>{
  expect(account).toContain('onClick={()=>void load()}');
  expect(account).toContain('}finally{\n   setLoading(false);');
 });
 it('keeps the member-specific profile lookup and Main ID scoped activity queries',()=>{
  expect(account).toContain(".from('profiles').select('display_name,phone,status,main_member_id').eq('id',user.id)");
  expect(account).toContain(".eq('member_id',p.main_member_id)");
  expect(account).toContain(".eq('credited_main_member_id',p.main_member_id)");
 });
});
