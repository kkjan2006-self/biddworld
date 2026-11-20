import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin audit, wallet ledger and report export integrity',()=>{
 it('validates initial and subsequent audit log pages',()=>{
  expect(component).toContain("typeof row.id==='string'");
  expect(component).toContain('auditPageGeneration.current');
  expect(component).toContain('Malformed or duplicate audit log records.');
  expect(component).toContain('admin_list_audit_logs_page');
 });
 it('validates wallet ledger rows and suppresses stale page responses',()=>{
  expect(component).toContain("typeof row.transaction_id==='string'");
  expect(component).toContain('walletPageGeneration.current');
  expect(component).toContain('Malformed or duplicate wallet ledger records.');
  expect(component).toContain('admin_list_wallet_transactions');
 });
 it('fails closed on malformed or repeated records in full paginated exports',()=>{
  expect(component).toContain('!Array.isArray(data)||data.length>100');
  expect(component).toContain('The report contains a malformed row.');
  expect(component).toContain('The report contains a repeated record across pages.');
  expect(component).toContain('100000');
 });
});
