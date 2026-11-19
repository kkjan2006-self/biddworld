import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin complete withdrawal report filters',()=>{
 it('applies search, status and inclusive request dates after paginated retrieval',()=>{
  const fn=admin.slice(admin.indexOf('function exportWithdrawalsCsv'),admin.indexOf('function exportWinningPaymentsCsv'));
  expect(fn).toContain('admin_list_withdrawal_requests');expect(fn).toContain('items.filter(x=>');
  for(const key of ['withdrawalReportSearch','withdrawalReportStatus','withdrawalReportFrom','withdrawalReportTo'])expect(fn).toContain(key);
  expect(fn).toContain('x.requested_at.slice(0,10)');
 });
 it('rejects reversed date ranges before starting a complete CSV retrieval',()=>{
  const fn=admin.slice(admin.indexOf('function exportWithdrawalsCsv'),admin.indexOf('function exportWinningPaymentsCsv'));
  expect(fn).toContain('withdrawalReportFrom>withdrawalReportTo');
  expect(fn).toContain('Withdrawal request start date must be on or before end date.');
 });
 it('labels the export as filtered and complete and guards reversed dates',()=>{
  expect(admin).toContain('Export Filtered Complete Withdrawals CSV');
  expect(admin).toContain('disabled={Boolean(withdrawalReportFrom&&withdrawalReportTo&&withdrawalReportFrom>withdrawalReportTo)}');
 });
});
