import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const migration=readFileSync('supabase/migrations/20261119200000_seed_signup_feature_defaults.sql','utf8');

describe('Signup feature defaults',()=>{
 it('creates the registration switch as enabled when it is missing',()=>{
  expect(migration).toContain("('registration_enabled','true'::jsonb,now())");
 });
 it('keeps sponsor referrals optional by default until configured',()=>{
  expect(migration).toContain("('sponsor_referrals_enabled','false'::jsonb,now())");
 });
 it('preserves explicit administrator settings',()=>{
  expect(migration).toContain('on conflict(setting_key) do nothing');
 });
});
