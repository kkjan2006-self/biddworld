import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
const account = readFileSync(resolve(process.cwd(), 'src/components/Account.tsx'), 'utf8');
describe('complete personal activity report', () => {
 it('retrieves all report sources in deterministic 500-row pages', () => {
  expect(account).toMatch(/const REPORT_PAGE_SIZE\\s*=\\s*500/);
  expect(account).toMatch(/range\\(from,to\\)/);
  expect(account).toMatch(/order\\('created_at',[\\s\\S]*?order\\('id',[\\s\\S]*?range\\(from,to\\)/);
  for (const table of ['package_activations','bids','fixed_bids','referral_commissions','winning_item_payments','delivery_tracking']) expect(account).toContain("from('"+table+"')");
 });
 it('re-verifies the signed-in Main ID and provides export feedback', () => {
  expect(account).toMatch(/supabase\\.auth\\.getUser\\(\\)/);
  expect(account).toMatch(/currentProfile\\.main_member_id/);
  expect(account).toMatch(/biddworld-my-complete-personal-report\\.csv/);
  expect(account).toMatch(/Complete report exported/);
  expect(account).toMatch(/finally\\{setReportBusy\\(false\\);\\}/);
 });
});
