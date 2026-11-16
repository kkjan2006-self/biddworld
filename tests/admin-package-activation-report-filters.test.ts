import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin package activation report filters',()=>{
 it('reuses the same pending activation search and inclusive date filter for export',()=>{
  expect(admin).toContain('const filteredActivations=useMemo(');
  expect(admin).toContain('activationSearch,activationFrom,activationTo');
  const fn=admin.slice(admin.indexOf('function exportReportActivations'),admin.indexOf('function exportReportWithdrawals'));
  expect(fn).toContain('filteredActivations.map(');expect(fn).not.toContain('pendingActivations.map(');
 });
 it('shows matching count, date controls and reversed-range guard',()=>{
  expect(admin).toContain('Submitted from');expect(admin).toContain('Submitted to');
  expect(admin).toContain('{filteredActivations.length} matching of {pendingActivations.length} pending requests');
  expect(admin).toContain('disabled={Boolean(activationFrom&&activationTo&&activationFrom>activationTo)}');
 });
 it('clearly identifies the RPC result as pending review, not activation history',()=>{
  expect(admin).toContain('not historical approved/rejected activations');
 });
});
