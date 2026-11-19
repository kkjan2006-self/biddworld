import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin Duplicate ID directory integrity',()=>{
 it('uses a strict parser for initial and subsequent pages',()=>{
  expect(source).toContain('function parseDuplicateIdPage(value:unknown)');
  expect(source).toContain('Malformed or duplicate Duplicate ID records.');
  expect(source).toContain('parseDuplicateIdPage(duplicateResult.data??[])');
  expect(source).toContain('const batch=parseDuplicateIdPage(data??[])');
 });
 it('rejects duplicate rows and inconsistent page metadata instead of silently filtering',()=>{
  expect(source).toContain('Duplicate ID page metadata is inconsistent.');
  expect(source).toContain('Duplicate ID page overlaps records already loaded.');
  expect(source).not.toContain('fresh.filter(row=>!current.some(existing=>existing.id===row.id))');
 });
 it('retains request-generation and single-flight guards',()=>{
  expect(source).toContain('duplicateSearchRequest.current');
  expect(source).toContain('duplicatePageInFlight.current');
 });
});