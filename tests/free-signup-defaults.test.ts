import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const migration=readFileSync('supabase/migrations/20261119210000_allow_signup_when_feature_setting_missing.sql','utf8');

describe('Free signup defaults',()=>{
 it('defaults a missing registration setting to enabled',()=>{
  expect(migration).toContain("coalesce((setting_value #>> '{}')::boolean, true)");
  expect(migration).toContain('if not coalesce(v_registration_enabled, true) then');
 });
 it('keeps sponsor referral optional when the setting is missing',()=>{
  expect(migration).toContain("coalesce((setting_value #>> '{}')::boolean, false)");
  expect(migration).toContain("if coalesce(v_sponsor_enabled,false) then");
 });
 it('preserves inactive-until-activation member lifecycle and provisions wallets',()=>{
  expect(migration).toContain("'inactive'");
  expect(migration).toContain("values(v_member_id,'bid',0),(v_member_id,'income',0)");
 });
 it('does not expose the auth trigger function to client roles',()=>{
  expect(migration).toContain('revoke all on function private.handle_new_auth_user() from public,anon,authenticated');
 });
});
