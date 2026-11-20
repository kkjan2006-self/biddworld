import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const legacy=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116170000_minimize_member_withdrawal_payout_data.sql'),'utf8');
const page=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120190000_minimize_paginated_withdrawal_payout_data.sql'),'utf8');
const ui=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Member withdrawal payout privacy across history endpoints',()=>{
 it('keeps the legacy history endpoint limited to the payout method',()=>{
  expect(legacy).toContain("jsonb_build_object('method',w.payout_details->>'method')");
  expect(legacy).not.toMatch(/w\.payout_details\s*,/i);
 });
 it('keeps the paginated endpoint on the same allowlisted payout response',()=>{
  expect(page).toContain("jsonb_build_object('method',w.payout_details->>'method')");
  expect(page).toContain("else '{}'::jsonb end as safe_payout_details");
  expect(page).toContain('page.safe_payout_details');
  expect(page).not.toMatch(/w\.payout_details\s*,/i);
  expect(page).toContain('grant execute on function public.member_list_my_withdrawals_page(integer,timestamptz,uuid) to authenticated');
 });
 it('does not render payout identifiers in the member account UI',()=>{
  expect(ui).toContain("String(w.payout_details?.method)");
  expect(ui).not.toMatch(/payout_details\?\.(upi_id|account_number)/i);
 });
});
