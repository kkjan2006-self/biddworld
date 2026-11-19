import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const app=readFileSync('src/App.tsx','utf8');
const admin=readFileSync('src/components/Admin.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261119530000_remove_email_verification_switch.sql','utf8');
describe('registration without BiddWorld email verification',()=>{
 it('does not fetch an email verification switch or show confirmation/resend flows',()=>{
  expect(app).not.toContain('public_get_registration_email_verification');
  expect(app).not.toContain('resendConfirmation');
  expect(app).not.toContain('confirmationPending&&');
  expect(app).not.toContain('emailVerificationRequired');
 });
 it('removes the email verification setting from Admin feature controls',()=>{
  expect(admin).not.toContain('email_verification_required');
  expect(admin).not.toContain('Email Verification');
 });
 it('keeps the database feature list free of the removed switch',()=>{
  expect(sql).toContain("where setting_key='email_verification_required'");
  expect(sql).toContain('drop function if exists public.public_get_registration_email_verification()');
  expect(sql).not.toContain("'email_verification_required'");
 });
});
