import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin withdrawal queue pagination hardening',()=>{
 it('validates withdrawal identities and positive finite amounts on the initial page',()=>{
  expect(component).toContain("typeof row.request_id==='string'");
  expect(component).toContain('!ids.has(row.request_id)');
  expect(component).toContain('Number(row.amount)>0');
  expect(component).toContain('Withdrawal queue returned malformed or duplicate records.');
 });
 it('serializes page requests and suppresses stale responses after refresh',()=>{
  expect(component).toContain('withdrawalPageInFlight.current');
  expect(component).toContain('withdrawalPageGeneration.current');
  expect(component).toContain('generation!==withdrawalPageGeneration.current');
  expect(component).toContain('p_offset:offset');
  expect(component).toContain('if(generation===withdrawalPageGeneration.current)');
 });
 it('preserves the existing withdrawal review actions and paged export contract',()=>{
  expect(component).toContain("admin_review_withdrawal_request");
  expect(component).toContain("admin_list_withdrawal_requests");
  expect(component).toContain('exportPagedReport<WithdrawalRequest>');
 });
 it('validates every Admin withdrawal field and exact supported payout-detail shape',()=>{
  expect(component).toContain('function validAdminWithdrawal(value:unknown):value is WithdrawalRequest');
  expect(component).toContain('WITHDRAWAL_UUID.test(row.request_id)');
  expect(component).toContain("['pending','approved','rejected','paid'].includes(row.status)");
  expect(component).toContain("payout.method==='UPI'");
  expect(component).toContain("payout.method==='Bank Transfer'");
  expect(component).toContain("payout.account_holder_name.trim().length<2");
  expect(component).toContain("row.rejection_reason.length<=500");
 });
 it('validates every CSV export page and detects repeated request IDs even when row contents change',()=>{
  expect(component).toContain('data:parseAdminWithdrawals(data??[])');
  expect(component).toContain(']),x=>x.request_id);');
  expect(component).toContain('getRowKey?:(row:T)=>string');
  expect(component).toContain('const key=getRowKey?getRowKey(row):JSON.stringify(row)');
  expect(component).toContain('repeated record identity across pages');
 });
 it('uses one shared parser for first and subsequent pages and rejects cross-page overlap',()=>{
  expect(component).toContain('const batch=parseAdminWithdrawals(withdrawalResult.data??[])');
  expect(component).toContain('const batch=parseAdminWithdrawals(data,withdrawalRequests)');
  expect(component).toContain('batch.some(item=>seen.has(item.request_id))');
  expect(component).toContain('setWithdrawalRequests(current=>[...current,...batch])');
 });
 it('validates strict descending request-time and UUID ordering within and across pages',()=>{
  expect(component).toContain('function parseAdminWithdrawals(value:unknown,previous:WithdrawalRequest[]=[]):WithdrawalRequest[]');
  expect(component).toContain('Date.parse(prior.requested_at)-Date.parse(row.requested_at)');
  expect(component).toContain('prior.request_id.localeCompare(row.request_id)<=0');
  expect(component).toContain('strict descending (requested_at,id) order');
 });
});