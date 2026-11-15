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
 it('re-verifies the signed-in Main ID and provides export feedback', () => {
  expect(account).toContain('supabase.auth.getUser()');
  expect(account).toContain('currentProfile?.main_member_id');
  expect(account).toContain('biddworld-my-complete-personal-report.csv');
  expect(account).toContain('Complete report exported:');
  expect(account).toContain('finally{setReportBusy(false);}');
 });
});
