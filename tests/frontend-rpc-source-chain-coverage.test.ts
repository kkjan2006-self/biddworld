import {readFileSync,readdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const root=process.cwd();
const read=(path:string)=>readFileSync(resolve(root,path),'utf8');
const surfaces=['src/App.tsx',...readdirSync(resolve(root,'src/components')).filter(path=>path.endsWith('.tsx')).map(path=>'src/components/'+path)];
const forward=read('supabase/clean-install/forward-migrations.txt').split(/\r?\n/).map(path=>path.trim()).filter(path=>path.startsWith('supabase/migrations/'));
const sqlSources=[read('supabase/clean-install/production_schema_baseline_candidate.sql'),...forward.map(read)].join('\n');
const definedFunctions=new Set([...sqlSources.matchAll(/create\s+(?:or\s+replace\s+)?function\s+(?:public|private)\."?([a-zA-Z0-9_]+)"?\s*\(/gi)].map(match=>match[1].toLowerCase()));
const frontendCalls=new Set<string>();
for(const path of surfaces){const source=read(path);for(const match of source.matchAll(/\.rpc(?:<[^>]+>)?\s*\(\s*['"\x60]([a-zA-Z0-9_]+)['"\x60]/g))frontendCalls.add(match[1].toLowerCase());}
describe('Frontend RPC coverage against the canonical clean-install source chain',()=>{
 it('defines every literal RPC called by App and all React components in the baseline or forward migrations',()=>{
  const missing=[...frontendCalls].filter(name=>!definedFunctions.has(name)).sort();
  expect(missing).toEqual([]);
 });
 it('scans every React component and only the ordered forward migration chain plus schema baseline',()=>{
  expect(surfaces).toContain('src/components/AdminMatrixCommissions.tsx');
  expect(surfaces).toContain('src/components/MemberProductSubmission.tsx');
  expect(forward.length).toBeGreaterThan(100);
  expect(definedFunctions.size).toBeGreaterThan(frontendCalls.size);
 });
});
