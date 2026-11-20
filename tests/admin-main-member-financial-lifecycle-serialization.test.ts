import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const lifecycle=readFileSync(resolve(process.cwd(),'supabase/migrations/20261120200000_serialize_admin_main_member_lifecycle.sql'),'utf8');
const financial=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118440000_serialize_member_financial_eligibility.sql'),'utf8');

describe('Admin Main-ID lifecycle / member financial serialization',()=>{
 it('uses the exact per-Main-ID advisory lock shared by member financial RPCs',()=>{
  expect(lifecycle).toContain("'biddworld.main_member_lifecycle:'||v_main_id::text");
  expect(financial).toContain("'biddworld.main_member_lifecycle:' || v_member::text");
  expect(financial).toContain("'biddworld.main_member_lifecycle:' || v_main::text");
 });
 it('acquires the lifecycle lock before taking the Main-ID row lock or changing status',()=>{
  const lock=lifecycle.indexOf("'biddworld.main_member_lifecycle:'||v_main_id::text");
  const rowLock=lifecycle.indexOf('where id=v_main_id and id_type=\'main\' for update');
  const statusWrite=lifecycle.indexOf('update public.member_ids set status=p_status');
  expect(lock).toBeGreaterThan(-1);
  expect(rowLock).toBeGreaterThan(lock);
  expect(statusWrite).toBeGreaterThan(rowLock);
 });
 it('preserves Admin authorization, lifecycle validation, linked Duplicate-ID propagation and audit',()=>{
  expect(lifecycle).toContain("auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(lifecycle).toContain("p_status not in ('active','suspended','closed')");
  expect(lifecycle).toContain("where main_member_id=v_main.id and id_type='duplicate'");
  expect(lifecycle).toContain("'member.main_status_changed'");
  expect(lifecycle).toContain('from public,anon');
  expect(lifecycle).toContain('to authenticated');
 });
});
