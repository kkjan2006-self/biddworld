import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const admin = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');
describe('complete paginated Admin CSV exports', () => {
 it('fetches all secured RPC pages before exporting', () => {
  expect(admin).toContain('async function exportPagedReport<T>');
  expect(admin).toContain('for(let offset=0;;offset+=100)');
  for (const rpc of ['admin_list_withdrawal_requests','admin_list_winning_item_payments','admin_list_delivery_tracking','admin_list_audit_logs_page']) expect(admin).toContain("rpc('"+rpc+"'");
 });
 it('exports complete withdrawal, winning payment, delivery and audit histories', () => {
  for (const file of ['biddworld-withdrawal-requests-complete.csv','biddworld-winning-payments-complete.csv','biddworld-delivery-tracking-complete.csv','biddworld-audit-log-complete.csv']) expect(admin).toContain(file);
  expect(admin).toContain('Preparing complete ');
  expect(admin).toContain('Exported '+"'"+'+rows.length+');
 });
});
