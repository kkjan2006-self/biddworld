import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119420000_member_workflow_status_notifications.sql','utf8');
describe('member workflow status notifications',()=>{
 it('uses one private trigger function with fixed search_path and no client execution',()=>{
  expect(sql).toContain('create or replace function private.notify_member_workflow_status_change()');
  expect(sql).toContain("set search_path = ''");
  expect(sql).toContain('revoke all on function private.notify_member_workflow_status_change() from public, anon, authenticated;');
 });
 it('notifies members for package, duplicate ID, auction submission, withdrawal and delivery changes',()=>{
  for(const name of ['notify_member_package_activation_status','notify_member_duplicate_id_status','notify_member_wallet_funding_status','notify_member_auction_submission_status','notify_member_withdrawal_status','notify_member_delivery_status']) expect(sql).toContain(name);
  expect(sql).toContain("new.payment_status = 'approved' and new.activation_status = 'active'");
  expect(sql).toContain("elsif new.id_type = 'main' then");
  expect(sql).toContain("new.id_type in ('main','duplicate')");
  expect(sql).toContain("new.status = 'approved'");
  expect(sql).toContain("new.status = 'rejected'");
  expect(sql).toContain("v_status = 'paid'");
 });
 it('writes only to the existing in-app notification inbox',()=>{
  expect(sql).toContain('insert into public.member_notifications(user_id, title, message, category)');
  expect(sql).not.toMatch(/net\.http|http_post|sendgrid|twilio/i);
 });
});
