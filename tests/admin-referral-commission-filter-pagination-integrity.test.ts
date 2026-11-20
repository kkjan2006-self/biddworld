import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261118090000_package_publication_and_referral_commission_engine.sql','utf8');
describe('Admin referral commission register integrity',()=>{
 it('uses the selected status and level filters for the initial page and every continuation page',()=>{
  expect(source).toContain("p_status:commissionStatusFilter==='all'?null:commissionStatusFilter,p_level:commissionLevelFilter==='all'?null:Number(commissionLevelFilter)");
  expect(source).toContain('},[role,refresh,appliedDuplicateSearch,commissionStatusFilter,commissionLevelFilter]);');
 });
 it('matches the authoritative server ordering and validates strict ordering across page boundaries',()=>{
  expect(migration).toContain('order by c.created_at desc,c.id desc');
  expect(source).toContain('parseReferralCommissionPage(value:unknown,previous:ReferralCommissionRow[]=[]');
  expect(source).toContain('strict descending (created_at,commission_id) order');
  expect(source).toContain('parseReferralCommissionPage(data??[],commissionRows)');
 });
 it('rejects malformed UUIDs, invalid statuses, levels, timestamps and duplicate records',()=>{
  expect(source).toContain('!/^([0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$/i.test(row.commission_id)');
  expect(source).toContain("!['pending','credited','reversed'].includes(row.status)");
  expect(source).toContain('Number(row.level_number)>20');
  expect(source).toContain('ids.has(row.commission_id)');
 });
});
