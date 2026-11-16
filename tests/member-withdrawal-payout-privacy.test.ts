import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116170000_minimize_member_withdrawal_payout_data.sql'),'utf8');
const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');
describe('Member withdrawal payout privacy',()=>{
 it('preserves the existing RPC return shape while exposing only payout method',()=>{
  expect(migration).toContain('returns table(');
  expect(migration).toContain('payout_details jsonb');
  expect(migration).toContain("jsonb_build_object('method',w.payout_details->>'method')");
  expect(migration).toContain('grant execute on function public.member_list_my_withdrawals() to authenticated');
  expect(migration).not.toMatch(/w\.payout_details\s*,/i);
 });
 it('member UI only displays the payout method label from history',()=>{
  expect(account).toContain("Boolean(w.payout_details?.method)");
  expect(account).toContain("String(w.payout_details?.method)");
  expect(account).not.toMatch(/payout_details\?\.(upi_id|account_number)/i);
 });
});
