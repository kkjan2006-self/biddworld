import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119520000_member_withdrawal_history_pagination.sql','utf8');
const ui=readFileSync('src/components/Account.tsx','utf8');
describe('member withdrawal history pagination',()=>{
 it('scopes rows to the authenticated user Main ID',()=>{
  expect(sql).toContain('select main_member_id into v_member from public.profiles where id=v_uid');
  expect(sql).toContain('where w.member_id=v_member');
 });
 it('adds the member history index and uses bounded stable descending keyset pagination',()=>{
  expect(sql).toContain('withdrawal_requests_member_history_idx');
  expect(sql).toContain('v_limit<1 or v_limit>100');
  expect(sql).toContain('(w.requested_at,w.id)<(p_before_requested_at,p_before_id)');
  expect(sql).toContain('count(*) over() as total_count');
  expect(sql).toContain('(page.total_count>v_limit)');
 });
 it('validates and appends member withdrawal pages in Account',()=>{
  expect(ui).toContain("'member_list_my_withdrawals_page'");
  expect(ui).toContain('function validWithdrawal(value:unknown)');
  expect(ui).toContain('Load more withdrawal requests');
 });
 it('validates initial and continuation pages against the SQL keyset contract',()=>{
  expect(ui).toContain('function validateWithdrawalPage(value:unknown,previous:WithdrawalRow[]=[]):WithdrawalRow[]');
  expect(ui).toContain('page[0]?.has_more&&page.length!==50');
  expect(ui).toContain('prior.request_id.localeCompare(row.request_id)<=0');
  expect(ui).toContain('validateWithdrawalPage(wr.data??[])');
  expect(ui).toContain('validateWithdrawalPage(data,withdrawals)');
  expect(ui).toContain("['pending','approved','rejected','paid'].includes(row.status)");
 });
 it('accepts only the privacy-safe payout method projection',()=>{
  expect(ui).toContain("Object.keys(payout).every(key=>key==='method')");
  expect(ui).toContain("typeof payout.method==='string'&&payout.method.length<=40");
  expect(ui).not.toMatch(/payout_details\?\.(upi_id|account_number)/i);
 });
});
