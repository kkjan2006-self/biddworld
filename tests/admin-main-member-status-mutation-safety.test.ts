import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin Main ID status mutation safety',()=>{
 it('prevents overlapping status changes before React state settles',()=>{
  expect(source).toContain('memberStatusSaveInFlight=useRef(false)');
  expect(source).toContain('memberStatusBusy||memberStatusSaveInFlight.current');
  expect(source).toContain('memberStatusSaveInFlight.current=true;setMemberStatusBusy(true)');
  expect(source).toContain('memberStatusSaveInFlight.current=false;setMemberStatusBusy(false)');
 });
 it('restricts status values and binds the submitted member identity',()=>{
  expect(source).toContain("!['active','suspended','closed'].includes(memberStatusValue)");
  expect(source).toContain('const memberCodeAtSubmit=selectedMemberCode');
  expect(source).toContain('p_member_code:memberCodeAtSubmit');
 });
 it('rejects malformed server results without trusting implicit zero values',()=>{
  expect(source).toContain('The server returned an invalid Main ID status result.');
  expect(source).toContain('The server returned an invalid linked Duplicate ID count.');
  expect(source).toContain('Number.isInteger(changed)||changed<0');
 });
 it('matches the Admin lifecycle RPC status enum and visible choices',()=>{
  const migration=readFileSync('supabase/migrations/20261118140000_admin_main_member_lifecycle.sql','utf8');
  expect(source).toContain("!['active','suspended','closed'].includes(memberStatusValue)");
  expect(source).toContain('<option value="suspended">Suspended</option>');
  expect(migration).toContain("p_status not in ('active','suspended','closed')");
 });

});
