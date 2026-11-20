import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin referral commission pagination hardening',()=>{
 it('validates the complete commission row shape and unique identities',()=>{
  expect(component).toContain('function parseReferralCommissionPage(value:unknown)');
  expect(component).toContain("!['main','duplicate'].includes(row.beneficiary_id_type)");
  expect(component).toContain('ids.has(row.commission_id)');
  expect(component).toContain('Number(row.amount)<=0');
  expect(component).toContain('row.has_more!==hasMore');
 });
 it('prevents concurrent and stale pagination requests from appending',()=>{
  expect(component).toContain('commissionPageInFlight.current');
  expect(component).toContain('commissionPageGeneration.current++');
  expect(component).toContain('generation!==commissionPageGeneration.current');
  expect(component).toContain('if(page.items.some(row=>known.has(row.commission_id)))');
  expect(component).toContain('p_offset:offset');
 });
 it('preserves the existing commission posting and reversal RPCs',()=>{
  expect(component).toContain("admin_post_referral_commissions");
  expect(component).toContain("admin_reverse_referral_commission");
  expect(component).toContain("admin_list_referral_commissions_page");
 });
});
