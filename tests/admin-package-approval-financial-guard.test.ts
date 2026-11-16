import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const review=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115020000_admin_package_activation_review.sql'),'utf8');
const guard=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116080000_financial_activity_lockdown.sql'),'utf8');
describe('Admin package approval financial interlock',()=>{
 it('keeps package review restricted to trusted Admin metadata',()=>{
  const start=review.indexOf('create or replace function public.admin_review_package_activation');
  const end=review.indexOf('$function$;',start);
  const body=review.slice(start,end);
  expect(start).toBeGreaterThanOrEqual(0);
  expect(body).toContain('auth.uid()');
  expect(body).toContain("auth.jwt()->'app_metadata'->>'role'");
  expect(body).toMatch(/<>\s*'admin'/i);
 });
 it('database triggers block wallet credit and activation approval without owner approval',()=>{
  expect(guard).toContain("where setting_key='financial_model_approved'");
  expect(guard).toContain("tg_table_name='wallet_transactions' and tg_op='INSERT'");
  expect(guard).toContain("tg_table_name='package_activations' and tg_op='UPDATE'");
  expect(guard).toContain("new.payment_status='approved' or new.activation_status='active'");
  expect(guard).toContain('before insert on public.wallet_transactions');
  expect(guard).toContain('before update of payment_status,activation_status on public.package_activations');
 });
 it('ordinary Admin feature switch checks trusted approval before enabling financial flags',()=>{
  const start=guard.indexOf('create or replace function public.admin_set_feature_setting');
  const end=guard.indexOf('$function$;',start);
  const body=guard.slice(start,end);
  expect(start).toBeGreaterThanOrEqual(0);
  expect(body).toContain("if p_enabled and p_setting_key=any(v_financial_keys)");
  expect(body).toContain("where setting_key='financial_model_approved'");
  expect(body).toContain('Financial feature % is locked until the owner approves');
  expect(body.includes("values(p_setting_key,to_jsonb(p_enabled),now())")).toBe(true);
  expect(body.includes("values('financial_model_approved'")).toBe(false);
 });
});
