import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const migration=readFileSync('supabase/migrations/20261119320000_member_matrix_commission_summary.sql','utf8');
const referrals=readFileSync('src/components/Referrals.tsx','utf8');
describe('member Matrix commission summary contract',()=>{
 it('scopes totals to the authenticated owner Main ID',()=>{
  expect(migration).toContain("m.owner_user_id=v_uid and m.id_type='main'");
  expect(migration).toContain('c.credited_main_member_id=v_main_id');
  expect(migration).toContain("where p.id=v_uid");
 });
 it('keeps Matrix income distinct from Sponsor Referral income',()=>{
  expect(referrals).toContain("member_get_my_matrix_commission_summary");
  expect(referrals).toContain('Sponsor Referral Income');
  expect(referrals).toContain('Matrix Commission Income');
 });
 it('does not expose direct table access',()=>{
  expect(migration).toContain('revoke all on function public.member_get_my_matrix_commission_summary() from public,anon');
  expect(migration).toContain('grant execute on function public.member_get_my_matrix_commission_summary() to authenticated');
 });
});
