import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120230000_staff_support_ticket_notifications.sql'),'utf8');
const review=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120220000_restricted_staff_support_ticket_review.sql'),'utf8');
const ui=readFileSync(resolve(process.cwd(),'src/components/Support.tsx'),'utf8');
describe('Staff Support ticket notification delivery',()=>{
 it('accepts only Admin or explicitly authorized Support Staff in the trigger',()=>{
  expect(migration).toContain("v_role='admin' or");
  expect(migration).toContain("v_role='admin_staff' and v_permissions ? 'support_ticket_review'");
  expect(migration).toContain('auth.uid() is null');
 });
 it('retains the global in-app notification feature switch and member recipient',()=>{
  expect(migration).toContain("where setting_key='notifications_enabled'");
  expect(migration).toContain('old.status is distinct from new.status');
  expect(migration).toContain('old.admin_response is distinct from new.admin_response');
  expect(migration).toContain('values(new.user_id,\'Support request updated\'');
 });
 it('keeps the Staff update path permission-scoped and uses the existing Support workspace',()=>{
  expect(review).toContain("v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'support_ticket_review'");
  expect(ui).toContain("admin_update_support_ticket");
  expect(ui).toContain('isStaffSupport');
 });
});
