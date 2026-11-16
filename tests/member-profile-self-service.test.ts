import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115190000_member_profile_self_service.sql'),'utf8');
describe('member profile self-service safeguards',()=>{
 it('validates the same name and phone rules before calling the RPC',()=>{
  expect(account).toContain('name.length<2||name.length>100');
  expect(account).toContain('/^\\\\+?[0-9][0-9 ()-]{7,15}$/');
  expect(account).toContain("p_display_name:name,p_phone:phone");
 });
 it('always releases the saving state and surfaces server errors',()=>{
  expect(account).toContain("finally{setProfileSaving(false);}");
  expect(account).toContain("Could not update your profile. Please retry.");
  expect(account).toContain("typeof data.display_name!=='string'");
 });
 it('keeps identity and financial fields outside the self-service update',()=>{
  expect(migration).toContain('where p.id = v_user_id');
  expect(migration).toContain('set display_name = v_name,');
  expect(migration).toContain('phone = v_phone,');
  expect(migration).not.toMatch(/update public\.(member_ids|wallet_accounts|wallet_transactions|referrals)/i);
  expect(migration).toMatch(/revoke all on function public\.member_update_my_profile\(text, text\) from public, anon/i);
 });
});
