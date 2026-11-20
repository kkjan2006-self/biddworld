import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119230000_registration_email_verification_off_by_default.sql'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('Registration email verification default',()=>{
 it('sets the application policy to false on clean installs and upgrades',()=>{
  expect(migration).toContain("'email_verification_required','false'::jsonb");
  expect(migration).toContain("),false);");
  expect(migration).toContain('grant execute on function public.public_get_registration_email_verification() to anon,authenticated');
 });
 it('defaults the signup client to immediate-login behavior when policy lookup is unavailable',()=>{
  expect(app).toContain('[emailVerificationRequired,setEmailVerificationRequired]=useState(false)');
  expect(app).toContain('rpc(\'public_get_registration_email_verification\')');
  expect(app).toContain('emailVerificationRequired?{emailRedirectTo:window.location.origin}:{}');
 });
});
