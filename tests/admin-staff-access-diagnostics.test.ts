import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const staff=readFileSync(resolve(process.cwd(),'src/components/AdminStaff.tsx'),'utf8');

describe('Staff access diagnostics',()=>{
 it('distinguishes an authentication/configuration failure from missing permissions',()=>{
  expect(staff).toContain("setAccessError(e instanceof Error?e.message:'Staff access could not be verified. Please retry.')");
  expect(staff).toContain('!accessReady?<div className="empty">Checking your assigned review permissions…</div>:accessError?');
  expect(staff).toContain('No review permissions are assigned to this Staff account.');
 });
 it('provides a retry action for access verification failures',()=>{
  expect(staff).toContain('Retry access check');
  expect(staff).toContain('setAccessAttempt(value=>value+1)');
 });
});
