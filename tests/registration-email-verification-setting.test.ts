import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119080000_registration_email_verification_setting.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('Registration email verification setting',()=>{
 it('defaults to requiring email verification and exposes a safe public read RPC',()=>{
  expect(migration).toContain("'email_verification_required','true'::jsonb");
  expect(migration).toContain('public_get_registration_email_verification()');
  expect(migration).toContain('grant execute on function public.public_get_registration_email_verification() to anon,authenticated');
 });
 it('allows only Admin to read and change the setting with audit logging',()=>{
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(migration).toContain("'email_verification_required'");
  expect(migration).toContain("'feature_setting_changed'");
 });
 it('adds the switch to Admin registration settings',()=>{
  expect(admin).toContain("key:'email_verification_required',label:'Email Verification'");
 });
 it('uses the configured policy during signup and explains provider-level mismatch',()=>{
  expect(app).toContain("rpc('public_get_registration_email_verification')");
  expect(app).toContain('emailVerificationRequired?{emailRedirectTo:window.location.origin}:{}');
  expect(app).toContain('Supabase Auth still requires email confirmation');
 });
});
