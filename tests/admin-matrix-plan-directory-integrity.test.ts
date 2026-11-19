import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/AdminMatrixPlans.tsx','utf8');
describe('Admin Matrix plan directory integrity',()=>{
 it('validates plan identity, package ownership, dimensions and level rules',()=>{
  expect(source).toContain('function parseMatrixPlans(value:unknown,packageId:string)');
  expect(source).toContain('Matrix plan record contains invalid fields.');
  expect(source).toContain('Matrix plan level contains invalid fields.');
  expect(source).toContain('Matrix plan levels are incomplete.');
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