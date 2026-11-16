import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116150000_enforce_inactive_signup_until_verified.sql'),'utf8');
describe('Signup inactive-until-verified lifecycle',()=>{
 it('creates both profile and Main ID inactive',()=>{
  expect(sql).toMatch(/insert into public\.profiles[\s\S]*?'inactive'/i);
  expect(sql).toMatch(/insert into public\.member_ids[\s\S]*?'main','inactive'/i);
 });
 it('preserves registration and sponsor feature gates',()=>{
  expect(sql).toContain("setting_key='registration_enabled'");
  expect(sql).toContain("setting_key='sponsor_referrals_enabled'");
  expect(sql).toContain('New member registration is currently disabled');
 });
 it('preserves sponsor validation and default sponsor bootstrap checks',()=>{
  expect(sql).toContain("upper(member_code)=upper(v_requested)");
  expect(sql).toContain("id_type='main' and status='active'");
  expect(sql).toContain('Default administrator sponsor has not been configured');
 });
 it('does not grant direct execution of the private trigger function',()=>{
  expect(sql).toContain('revoke all on function private.handle_new_auth_user() from public,anon,authenticated;');
 });
});
