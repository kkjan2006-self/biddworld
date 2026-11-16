import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin initial workspace request resilience',()=>{
 it('catches rejected initial RPC batches and exposes an actionable error',()=>{
  expect(admin).toContain('}catch(loadError){');
  expect(admin).toContain("loadError instanceof Error?loadError.message:'Admin workspace could not be loaded. Please retry.'");
 });
 it('exposes a keyboard-accessible retry action for workspace load errors',()=>{
  expect(admin).toContain('<div className="notice" role="alert">');
  expect(admin).toContain('Retry loading Admin data');
  expect(admin).toContain('onClick={()=>setRefresh(v=>v+1)}');
 });
 it('always releases the initial loading state while mounted',()=>{
  expect(admin).toContain('}finally{\n    if(active)setLoading(false);');
 });
 it('does not update state after the Admin component unmounts',()=>{
  expect(admin).toContain('if(active)setError(loadError instanceof Error?');
  expect(admin).toContain('if(active)setLoading(false);');
  expect(admin).toContain('void load();return()=>{active=false;};');
 });
 it('prevents a late initial session lookup from overriding an Auth event',()=>{
  expect(admin).toContain('let active=true,authEventReceived=false;');
  expect(admin).toContain('if(active&&!authEventReceived)applyRole(session);');
  expect(admin).toContain('}).catch(()=>{');
  expect(admin).toContain("if(active&&!authEventReceived)setRole('');");
 });
});
