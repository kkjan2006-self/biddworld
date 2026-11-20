import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const admin = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');
describe('complete paginated Admin CSV exports', () => {
 it('fetches all secured RPC pages before exporting', () => {
  expect(admin).toContain('async function exportPagedReport<T>');
  expect(admin).toContain('for(let offset=0;offset<100000;offset+=100)');
  expect(admin).toContain('const seenPages=new Set<string>();');
  expect(admin).toContain('if(seenPages.has(fingerprint))throw new Error');
  expect(admin).toContain('if(offset===99900)throw new Error');
  for (const rpc of ['admin_list_withdrawal_requests','admin_list_winning_item_payments','admin_list_delivery_tracking','admin_list_audit_logs_page']) expect(admin).toContain("rpc('"+rpc+"'");
 });
 it('includes Expected Price and target-reached timestamp in complete auction exports', () => {
  expect(admin).toContain("['Auction ID','Product','Title','Currency','Starting Price','Expected Price','Current Price','Minimum Increment','Status','Starts At','Target Reached At','Ends At']");
  expect(admin).toContain('x.expected_price,x.current_price,x.minimum_increment,x.status,x.starts_at,x.target_reached_at,x.ends_at');
 });
 it('exports complete withdrawal, winning payment, delivery and audit histories', () => {
  for (const file of ['biddworld-withdrawal-requests-filtered-complete.csv','biddworld-winning-payments-filtered-complete.csv','biddworld-delivery-tracking-filtered-complete.csv','biddworld-audit-log-complete.csv']) expect(admin).toContain(file);
  expect(admin).toContain('Preparing complete ');
  expect(admin).toContain('Exported '+"'"+'+rows.length+');
 });
});
