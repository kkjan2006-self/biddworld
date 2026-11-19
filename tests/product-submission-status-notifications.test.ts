import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119570000_product_submission_status_notifications.sql','utf8');
describe('member product submission status notifications',()=>{
 it('notifies only the original submitting member on approval and rejection',()=>{
  expect(sql).toContain("v_title:='Product listing approved'");
  expect(sql).toContain("v_title:='Product listing needs attention'");
  expect(sql).toContain('new.submitted_by');
  expect(sql).toContain("new.status='approved'");
  expect(sql).toContain("new.status='rejected'");
 });
 it('uses a private trigger function and only fires for actual status changes',()=>{
  expect(sql).toContain('create or replace function private.notify_member_product_submission_status_change()');
  expect(sql).toContain("set search_path=''");
  expect(sql).toContain("where setting_key='notifications_enabled'");
  expect(sql).toContain('if not coalesce(v_notifications_enabled,false) then return new;end if;');
  expect(sql).toContain('revoke all on function private.notify_member_product_submission_status_change() from public,anon,authenticated');
  expect(sql).toContain('after update of status on public.product_submissions');
  expect(sql).toContain('when(old.status is distinct from new.status)');
 });
 it('uses the existing in-app inbox without external delivery side effects',()=>{
  expect(sql).toContain('insert into public.member_notifications(user_id,title,message,category)');
  expect(sql).not.toMatch(/net\.http|http_post|sendgrid|twilio/i);
 });
});
