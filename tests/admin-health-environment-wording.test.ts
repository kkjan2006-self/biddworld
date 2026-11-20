import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

describe('Admin system health environment wording',()=>{
 const source=readFileSync('src/components/Admin.tsx','utf8');

 it('describes health checks as applying to the connected environment',()=>{
  expect(source).toContain('Check database security coverage and recent audit activity for the currently connected environment.');
  expect(source).not.toContain('Check Production database security coverage');
 });
});
