import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
const editor=readFileSync(resolve(process.cwd(),'src/components/AdminMatrixPlans.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119280000_matrix_plan_configuration.sql'),'utf8');

describe('Admin package Matrix plan editor contract',()=>{
 it('exposes a separate Matrix Plans Admin section without replacing Sponsor plans',()=>{
  expect(admin).toContain('AdminMatrixPlans packages={packages}');
  expect(admin).toContain("setActiveSection('matrix')");
  expect(admin).toContain("setActiveSection('commission')");
 });
 it('supports independent width/depth and per-level fixed/percentage rules',()=>{
  expect(editor).toContain('Matrix Width');
  expect(editor).toContain('Matrix Depth');
  expect(editor).toContain("value=\"fixed\"");
  expect(editor).toContain("value=\"percentage\"");
  expect(editor).toContain('eligibility_rule:eligibility');
 });
 it('creates versioned drafts and requires explicit activation',()=>{
  expect(editor).toContain('admin_save_matrix_plan_draft');
  expect(editor).toContain('admin_activate_matrix_plan');
  expect(editor).toContain('window.confirm');
  expect(editor).toContain('selectedPackage?.is_active');
 });
 it('protects Matrix configuration tables from direct Data API access',()=>{
  expect(migration).toContain('enable row level security');
  expect(migration).toContain('revoke all on table public.matrix_plan_versions from public, anon, authenticated');
  expect(migration).toContain('revoke all on table public.matrix_level_rules from public, anon, authenticated');
 });
});
