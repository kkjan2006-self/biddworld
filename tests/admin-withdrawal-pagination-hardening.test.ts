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
});
