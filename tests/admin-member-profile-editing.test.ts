import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261117120000_admin_update_member_profile.sql'),'utf8');
describe('Admin member profile editing contract',()=>{
 it('uses the reviewed RPC from the selected Main ID detail panel',()=>{
  expect(admin).toContain("supabase.rpc('admin_update_member_profile',{p_member_code:selectedMemberCode,p_display_name:displayName,p_phone:phone||null})");
  expect(admin).toContain("setMemberProfileName(m.display_name||'')");
  expect(admin).toContain("setMemberProfilePhone(m.phone||'')");
 });
 it('prevents no-op saves and supports resetting unsaved profile edits',()=>{
  expect(admin).toContain('const memberProfileDirty=Boolean(selectedMemberForProfile)');
  expect(admin).toContain('disabled={memberProfileBusy||!memberProfileDirty} onClick={()=>void saveMemberProfile()}');
  expect(admin).toContain('Reset changes');
 });
 it('makes the server RPC idempotent for unchanged values and avoids unnecessary audit events',()=>{
  expect(migration).toContain('v_old_name is not distinct from v_display_name and v_old_phone is not distinct from v_phone');
  expect(migration).toContain("'changed',false");
  expect(migration).toContain("'changed',true");
  expect(migration.indexOf('if v_old_name is not distinct from')).toBeLessThan(migration.indexOf('insert into public.audit_logs'));
 });
 it('keeps editing separate from account status and ID lifecycle',()=>{
  expect(admin).toContain('Account status and ID lifecycle remain separate pending workflows.');
  expect(migration).toContain('Account status and ID lifecycle are intentionally excluded.');
 });
 it('enforces Admin authorization, Main ID resolution, row locking and audit logging',()=>{
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin'");
  expect(migration).toContain("m.id_type='main'");
  expect(migration).toContain('for update of p');
  expect(migration).toContain('insert into public.audit_logs');
  expect(migration).toContain("'member_profile_updated'");
  expect(migration).toContain('revoke all on function public.admin_update_member_profile(text,text,text) from public,anon;');
  expect(migration).toContain('grant execute on function public.admin_update_member_profile(text,text,text) to authenticated;');
 });
});
