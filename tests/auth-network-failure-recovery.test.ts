import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/App.tsx'), 'utf8');

describe('Authentication network failure recovery', () => {
  it('always releases the shared busy state after sign-in or registration settles', () => {
    const start = source.indexOf('async function auth(e:FormEvent)');
    const end = source.indexOf('async function resendConfirmation()', start);
    const auth = source.slice(start, end);
    expect(auth).toContain('try{const r=signup?await supabase.auth.signUp');
    expect(auth).toContain('await supabase.auth.signInWithPassword');
    expect(auth).toContain('catch{setMsg(signup?');
    expect(auth).toContain('finally{setBusy(false)}');
    expect(auth).toContain('email:email.trim()');
    expect(auth).toContain('sponsor_referral_id:sponsorId.trim()||null');
  });

  it('handles thrown network failures and always clears resend confirmation state', () => {
    const start = source.indexOf('async function resendConfirmation()');
    const end = source.indexOf('async function saveRecoveredPassword', start);
    const resend = source.slice(start, end);
    expect(resend).toContain('catch{setMsg(');
    expect(resend).toContain('finally{setResendBusy(false)}');
  });

  it('handles password recovery and reset failures without leaving the form busy', () => {
    const recoveryStart = source.indexOf('async function saveRecoveredPassword');
    const resetStart = source.indexOf('async function sendPasswordReset', recoveryStart);
    const bidStart = source.indexOf('function newBidRequestKey()', resetStart);
    const recovery = source.slice(recoveryStart, resetStart);
    const reset = source.slice(resetStart, bidStart);
    expect(recovery).toContain('catch{setMsg(');
    expect(recovery).toContain('finally{setBusy(false)}');
    expect(reset).toContain('catch{setMsg(');
    expect(reset).toContain('finally{setBusy(false)}');
  });

  it('keeps sponsor ID validation and accurately confirms free account creation without claiming activation', () => {
    expect(source).toContain("sponsorLookup!=='valid'");
    expect(source).toContain('Registration successful. Your free member account and Main ID have been created.');
    expect(source).not.toContain('Your account remains INACTIVE until the required Admin verification process is completed.');
    expect(source).toMatch(/\/\^\\\+?\[0-9\\s\(\)-\]\{10,16\}\$\//);
  });
});
