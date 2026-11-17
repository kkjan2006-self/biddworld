import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Member account action network recovery',()=>{
 it('always clears withdrawal submission state and reports rejected requests',()=>{
  const start=account.indexOf("onSubmit={async e=>{e.preventDefault();if(!supabase||withdrawBusy||withdrawSubmitBusy.current)return;");
  const end=account.indexOf('<label>Amount (INR)',start);
  const handler=account.slice(start,end);
  expect(handler).toContain("try{const details={method:payoutMethod");
  expect(handler).toContain("catch{setWithdrawMessage('The withdrawal request could not be completed");
  expect(handler).toContain('finally{setWithdrawBusy(false);}');
  expect(handler).toContain("setWithdrawMessage('Withdrawal request submitted for Admin review.')");
 });

 it('always clears email-change loading state after Supabase errors or thrown network failures',()=>{
  const start=account.indexOf("const next=newEmail.trim().toLowerCase()");
  const end=account.indexOf('</form></div><form className="memberWithdrawalForm"',start);
  const handler=account.slice(start,end);
  expect(handler).toContain('try{const{error}=await supabase.auth.updateUser({email:next})');
  expect(handler).toContain('catch{setEmailChangeMessage(');
  expect(handler).toContain('finally{setEmailChangeBusy(false);}');
 });

 it('always clears password update and global sign-out loading states',()=>{
  const passwordStart=account.indexOf("if(newPassword.length<8)");
  const signoutStart=account.indexOf("onClick={async()=>{if(!supabase)return;setSecurityBusy(true);");
  const password=account.slice(passwordStart,signoutStart);
  const signout=account.slice(signoutStart,account.indexOf('Sign out from all devices',signoutStart));
  expect(password).toContain('catch{setSecurityMessage(');
  expect(password).toContain('finally{setSecurityBusy(false);}');
  expect(signout).toContain('catch{setSecurityMessage(');
  expect(signout).toContain('finally{setSecurityBusy(false);}');
 });
});
