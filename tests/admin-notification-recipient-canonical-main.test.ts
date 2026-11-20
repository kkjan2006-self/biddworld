import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const ui=readFileSync('src/components/Notifications.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261120270000_canonical_admin_notification_recipient_lookup.sql','utf8');
describe('Admin notification recipient canonical Main ID lookup',()=>{
 it('resolves only the profile-linked Main ID with matching owner and type',()=>{
  expect(migration).toContain('on m.id=p.main_member_id');
  expect(migration).toContain('m.owner_user_id=p.id');
  expect(migration).toContain("m.id_type='main'");
  expect(migration).not.toContain('join public.profiles p on p.id=m.owner_user_id');
 });
 it('retains the Admin-only bounded lookup and explicit grants',()=>{
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(migration).toContain('length(v_search)<2 or length(v_search)>120');
  expect(migration).toContain('limit 25');
  expect(migration).toContain('revoke all on function public.admin_lookup_notification_recipients(text) from public,anon;');
  expect(migration).toContain('grant execute on function public.admin_lookup_notification_recipients(text) to authenticated;');
 });
 it('rejects duplicate user UUIDs and Main ID codes in lookup responses',()=>{
  expect(ui).toContain('const seenUsers=new Set<string>(),seenMemberCodes=new Set<string>()');
  expect(ui).toContain('seenUsers.has(item.user_id)||seenMemberCodes.has(item.member_code)');
  expect(ui).toContain('seenUsers.add(item.user_id);seenMemberCodes.add(item.member_code)');
 });
});
