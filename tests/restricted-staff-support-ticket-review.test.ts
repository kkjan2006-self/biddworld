import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120220000_restricted_staff_support_ticket_review.sql'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
const support=readFileSync(resolve(process.cwd(),'src/components/Support.tsx'),'utf8');
const staff=readFileSync(resolve(process.cwd(),'src/components/AdminPaymentReviewStaff.tsx'),'utf8');
const staffWorkspace=readFileSync(resolve(process.cwd(),'src/components/AdminStaff.tsx'),'utf8');
describe('Restricted Staff Support ticket review',()=>{
 it('allows only the Primary Admin to assign the explicit support permission',()=>{
  expect(migration).toContain("lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com'");
  expect(migration).toContain("'support_ticket_review'");
  expect(migration).toContain('payment_review_staff.permissions_updated');
 });
 it('protects Support reads with a permission-scoped RLS policy',()=>{
  expect(migration).toContain('support_tickets_select_staff_review');
  expect(migration).toContain("role','')='admin_staff'");
  expect(migration).toContain("? 'support_ticket_review'");
 });
 it('restricts Support updates to Admin or Staff with the exact permission',()=>{
  expect(migration).toContain("v_role='admin' or");
  expect(migration).toContain("v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'support_ticket_review'");
  expect(migration).toContain("'reviewer_role',v_role");
 });
 it('wires the existing Support queue into the restricted Staff UI without member submission controls',()=>{
  expect(app).toContain('isStaffSupport');
  expect(support).toContain('isStaffSupport');
  expect(support).toContain('canReview');
  expect(staff).toContain("support_ticket_review:'Support Ticket Review'");
  expect(staff).toContain('Support Ticket Review');
  expect(staffWorkspace).toContain("'support_ticket_review'].includes(p as string)");
  expect(staffWorkspace).toContain('<Support isStaffSupport/>');
  expect(staffWorkspace).toContain("type Permission='package_activation_review'|'wallet_funding_review'|'auction_submission_review'|'support_ticket_review'");
 });
 it('writes the RPC audit event only for restricted Staff because Admin is covered by the row trigger',()=>{
  expect(review).toContain("if v_role='admin_staff' then");
  expect(review).toContain('Admin updates are audited by the existing row trigger');
  expect(review).toContain("'reviewer_role',v_role");
  const auditStart=review.indexOf("if v_role='admin_staff' then");
  const auditEnd=review.indexOf("return jsonb_build_object('success',true,'ticket_id',p_ticket_id",auditStart);
  expect(auditStart).toBeGreaterThan(-1);
  expect(auditEnd).toBeGreaterThan(auditStart);
  expect(review.slice(auditStart,auditEnd)).toContain('insert into public.audit_logs');
 });

});