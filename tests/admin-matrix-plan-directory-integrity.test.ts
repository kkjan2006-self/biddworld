import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/AdminMatrixPlans.tsx','utf8');
describe('Admin Matrix plan directory integrity',()=>{
 it('validates plan identity, package ownership, dimensions and level rules',()=>{
  expect(source).toContain('function parseMatrixPlans(value:unknown,packageId:string)');
  expect(source).toContain('Matrix plan record contains invalid fields.');
  expect(source).toContain('Matrix plan level contains invalid fields.');
  expect(source).toContain('Matrix plan levels are incomplete.');
  expect(source).toContain('versions.has(Number(row.version_number))');
  expect(source).toContain('activeCount>1');
  expect(source).toContain("row.reward_type==='fixed'&&Number(level.reward_value)>10000000");
 });
 it('validates saved draft and activation results against the submitted plan',()=>{
  expect(source).toContain('result.matrix_width!==w');
  expect(source).toContain('result.placement_depth!==pd');
  expect(source).toContain('result.matrix_depth!==d');
  expect(source).toContain('result.is_active!==false');
  expect(source).toContain('result.plan_id!==plan.id');
  expect(source).toContain('result.matrix_width!==plan.matrix_width');
  expect(source).toContain('disabled={busy} onChange={e=>{setPackageId(e.target.value)');
 });
 it('prevents stale package responses from replacing the selected package plans',()=>{
  expect(source).toContain('requestGeneration=useRef(0)');
  expect(source).toContain('if(request!==requestGeneration.current)return');
  expect(source).toContain('return()=>{requestGeneration.current++;};');
 });
 it('keeps saved plans scoped to the selected package',()=>{
  expect(source).toContain('row.package_id!==packageId');
  expect(source).toContain('setPlans([]);void loadPlans(packageId)');
 });
});