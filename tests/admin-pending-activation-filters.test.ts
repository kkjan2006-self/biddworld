import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin pending package activation review filters',()=>{
 it('searches loaded requests by request number, Main ID, member, package and payment reference',()=>{
  expect(admin).toContain('const filteredActivations=useMemo(');
  expect(admin).toContain('[item.activation_number,item.member_code,item.member_name,item.package_name,item.payment_reference]');
 });
 it('uses inclusive UTC submission date filters and warns on reversed ranges',()=>{
  expect(admin).toContain('(!activationFrom||day>=activationFrom)&&(!activationTo||day<=activationTo)');
  expect(admin).toContain('activationFrom>activationTo');
 });
 it('keeps financial approval locked while filters only change the displayed request list',()=>{
  expect(admin).toContain('disabled={FINANCIAL_APPROVAL_LOCKED||reviewingActivation!==\'\'}');
  expect(admin).toContain('Filters do not change payment status or approval controls.');
  expect(admin).toContain('Export Filtered Activations CSV ({filteredActivations.length})');
 });
});
