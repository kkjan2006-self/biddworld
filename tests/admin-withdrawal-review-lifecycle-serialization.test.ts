import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const review=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120210000_serialize_admin_withdrawal_review_lifecycle.sql'),'utf8');
const member=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118440000_serialize_member_financial_eligibility.sql'),'utf8');
const lifecycle=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120200000_serialize_admin_main_member_lifecycle.sql'),'utf8');

describe('Admin withdrawal review lifecycle serialization',()=>{
 it('uses the same per-Main-ID lock as member financial and Admin lifecycle RPCs',()=>{
  const shared="'biddworld.main_member_lifecycle:'";
  expect(review).toContain(shared+"||v_request.member_id::text");
  expect(member).toContain(shared+" || v_member::text");
  expect(lifecycle).toContain(shared+"||v_main_id::text");
 });
 it('acquires the shared lock after identifying the request and before approval eligibility checks',()=>{
  const request=review.indexOf('select * into v_request from public.withdrawal_requests');
  const lock=review.indexOf("'biddworld.main_member_lifecycle:'||v_request.member_id::text");
  const eligibility=review.indexOf('select m.* into v_member');
  const reserve=review.indexOf("'withdrawal:'||v_request.id::text||':reserve'");
  expect(request).toBeGreaterThan(-1);
  expect(lock).toBeGreaterThan(request);
  expect(eligibility).toBeGreaterThan(lock);
  expect(reserve).toBeGreaterThan(eligibility);
 });
 it('keeps all three review actions, ledger reservation/release checks and Admin-only entry',()=>{
  for(const action of ["'approve'","'reject'","'mark_paid'"]) expect(review).toContain(action);
  expect(review).toContain("'withdrawal_reserve','debit'");
  expect(review).toContain("'withdrawal_release','credit'");
  expect(review).toContain('from public,anon');
  expect(review).toContain('to authenticated');
 });
});
