import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');
const registrationMigration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261114200000_save_registration_phone.sql'),'utf8');

describe('Registration and account status messaging',()=>{
 it('does not tell newly registered users that their account is inactive when the signup trigger creates an active Main ID',()=>{
  expect(registrationMigration).toContain("'active'");
  expect(registrationMigration).toContain("'main'");
  expect(app).toContain('Your free member account and Main ID have been created.');
  expect(app).not.toContain('Your account remains INACTIVE until the required Admin verification process is completed.');
 });
 it('gives inactive existing members a neutral support instruction without unrelated review claims',()=>{
  expect(account).toContain('Contact BiddWorld support or an administrator if you believe this status is incorrect.');
  expect(account).not.toContain('financial and legal/compliance model');
  expect(account).not.toContain('Do not make any package payment.');
 });
});
