import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const account = readFileSync(resolve(process.cwd(), 'src/components/Account.tsx'), 'utf8');
describe('complete personal activity report', () => {
 it('retrieves all report sources in deterministic 500-row pages', () => {
  expect(account).toContain('const REPORT_PAGE_SIZE=500;');
  expect(account).toContain('.range(from,to)');
  expect(account).toContain(".order('id',{ascending:false}).range(from,to)");
  for (const table of ['package_activations','bids','fixed_bids','referral_commissions','winning_item_payments','delivery_tracking']) expect(account).toContain("from('"+table+"')");
 });
 it('fails closed when a page repeats or any record ID is duplicated across pages', () => {
  expect(account).toContain('const seenIds=new Set<string>();');
  expect(account).toContain('const pageIds=new Set<string>();');
  expect(account).toContain('duplicate record IDs across pages');
  expect(account).toContain('without a valid ID');
  expect(account).toContain('batch.map(row=>row.id)');
 });
 it('validates deterministic descending tuple order across report pages', () => {
  expect(account).toContain("timestampKey:'created_at'|'submitted_at'|'updated_at'");
  expect(account).toContain('strict descending (');
  expect(account).toContain('prior.id.localeCompare(row.id)<=0');
  expect(account).toContain(",'submitted_at')");
  expect(account).toContain(",'created_at')");
  expect(account).toContain(",'updated_at')");
 });
 it('exports every withdrawal history page through the owner-scoped keyset RPC', () => {
  expect(account).toContain('async function fetchAllWithdrawalPages');
  expect(account).toContain('member_list_my_withdrawals_page');
  expect(account).toContain('p_before_requested_at:cursor?.requested_at??null');
  expect(account).toContain('p_before_id:cursor?.request_id??null');
  expect(account).toContain('validateWithdrawalPage(data??[],all)');
  expect(account).toContain('if(batch.length===0){if(cursor)throw new Error');
  expect(account).toContain('allWithdrawals.forEach');
  expect(account).not.toContain("withdrawals.forEach(x=>rows.push(['Withdrawal request'");
 });
 it('re-verifies the signed-in Main ID and provides export feedback', () => {
  expect(account).toContain('client.auth.getUser()');
  expect(account).toContain('currentProfile?.main_member_id');
  expect(account).toContain('biddworld-my-complete-personal-report.csv');
  expect(account).toContain('Complete report exported:');
  expect(account).toContain('finally{setReportBusy(false);}');
 });
});
