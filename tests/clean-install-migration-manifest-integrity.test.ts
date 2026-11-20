import {existsSync,readFileSync,readdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const root=process.cwd();
const migrationDir=resolve(root,'supabase/migrations');
const forward=readFileSync(resolve(root,'supabase/clean-install/forward-migrations.txt'),'utf8')
 .split(/\r?\n/).map(x=>x.trim()).filter(x=>x.startsWith('supabase/migrations/'));
const excluded=readFileSync(resolve(root,'supabase/clean-install/excluded-historical-migrations.txt'),'utf8')
 .split(/\r?\n/).map(x=>x.trim()).filter(Boolean);
const all=readdirSync(migrationDir).filter(x=>/^\d{14}_.+\.sql$/.test(x))
 .map(x=>'supabase/migrations/'+x).sort();
const baseline=readFileSync(resolve(root,'supabase/clean-install/production_schema_baseline_candidate.sql'),'utf8');
const cleanInstallReadme=readFileSync(resolve(root,'supabase/clean-install/README.md'),'utf8');

describe('Clean-install migration manifest safety',()=>{
 it('accounts for every timestamped migration exactly once between forward and excluded lists',()=>{
  expect(new Set(forward).size).toBe(forward.length);
  expect(new Set(excluded).size).toBe(excluded.length);
  expect(forward.every(p=>existsSync(resolve(root,p)))).toBe(true);
  expect(excluded.every(p=>existsSync(resolve(root,p)))).toBe(true);
  expect([...forward,...excluded].sort()).toEqual(all);
 });
 it('uses a unique 14-digit version prefix for every timestamped migration',()=>{
  const versions=all.map(p=>p.split('/').pop()!.slice(0,14));
  expect(new Set(versions).size).toBe(versions.length);
 });
 it('keeps the forward manifest in timestamp order and historical source files out of replay',()=>{
  expect(forward).toEqual([...forward].sort());
  expect(excluded).toEqual([...excluded].sort());
  expect(excluded.every(p=>{
   const version=Number(p.split('/').pop().slice(0,14));
   return version<=20261115163218 || p.endsWith('20261115180000_admin_audit_log_pagination.sql');
  })).toBe(true);
 });
 it('keeps clean-install documentation counts synchronized with the actual manifests',()=>{
  expect(cleanInstallReadme).toContain(`**${forward.length} unique entries at the latest inspected completion-work manifest checkpoint**`);
  expect(cleanInstallReadme).toContain(`**${forward.length} forward + ${excluded.length} excluded = ${all.length} timestamped SQL migration paths**`);
  expect(all.length).toBe(forward.length+excluded.length);
 });
 it('keeps the baseline explicitly marked as a schema-only candidate, not an approved executable migration',()=>{
  expect(baseline).toContain('CANDIDATE ONLY');
  expect(baseline).toContain('Schema only: no application/member/financial rows');
  expect(baseline).toContain('create schema if not exists private');
  expect(baseline.trimEnd().endsWith('commit;')).toBe(true);
 });
});
