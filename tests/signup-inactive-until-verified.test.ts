import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115220000_inactive_until_verified_package_activation.sql'),'utf8');
const signup=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116150000_enforce_inactive_signup_until_verified.sql'),'utf8');
describe('Inactive-until-verified lifecycle safety',()=>{
 it('creates new profiles and Main IDs as inactive',()=>{
  expect(migration).toMatch(/profiles\s*\(id, display_name, phone, status\)[\s\S]*?'inactive'/i);
  expect(migration).toMatch(/member_ids\s*\(owner_user_id, member_code, id_type, status\)[\s\S]*?'inactive'/i);
 });
 it('does not bulk rewrite existing Production member/profile statuses',()=>{
  expect(migration).not.toMatch(/update\s+public\.member_ids\s+m\s+set\s+status/is);
  expect(migration).not.toMatch(/update\s+public\.profiles\s+p\s+set\s+status/is);
 });
 it('only activates a member after approved and active package activation',()=>{
  expect(migration).toContain("new.payment_status = 'approved' and new.activation_status = 'active'");
  expect(migration).toContain("and status = 'inactive'");
  expect(migration).toContain('after update of payment_status, activation_status');
 });
 it('preserves registration and sponsor feature-switch enforcement in the final signup definition',()=>{
  expect(signup).toContain('registration_enabled');
  expect(signup).toContain('sponsor_referrals_enabled');
  expect(signup).toContain("'inactive'");
 });
});
