import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Member account refresh concurrency and lifecycle',()=>{
 it('assigns each refresh a generation and accepts only the current mounted request',()=>{
  expect(source).toContain('const loadRequest=useRef(0),loadMounted=useRef(true),withdrawSubmitBusy=useRef(false),historyPageInFlight=useRef(new Set<string>()),winningPaymentKeys=useRef(new Map<string,string>());');
  expect(source).toContain('const request=++loadRequest.current;');
  expect(source).toContain('const isCurrent=()=>loadMounted.current&&request===loadRequest.current;');
  expect(source.match(/if\(!isCurrent\(\)\)return;/g)?.length).toBeGreaterThanOrEqual(5);
 });

 it('checks request ownership after the account history and delivery reads before committing state',()=>{
  const history=source.indexOf('const [m,a,w,wr,b,fb,rc,wp]=await Promise.all([');
  const delivery=source.indexOf('const deliveryResult=paymentIds.length?',history);
  const commit=source.indexOf('setMembers((m.data??[])',delivery);
  expect(history).toBeGreaterThan(-1);
  expect(delivery).toBeGreaterThan(history);
  expect(source.slice(history,delivery)).toContain('if(!isCurrent())return;');
  expect(source.slice(delivery,commit)).toContain('if(!isCurrent())return;');
 });

 it('does not let an obsolete request clear the current loading state and invalidates requests on unmount',()=>{
  expect(source).toContain("if(isCurrent())setError('Account details could not be loaded. Check your connection and try again.');");
  expect(source).toContain('if(isCurrent())setLoading(false);');
  expect(source).toContain('return()=>{loadMounted.current=false;loadRequest.current+=1;}');
 });
});
