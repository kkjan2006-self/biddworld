import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116090000_admin_members_sponsors_pagination.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin member directory pagination',()=>{
 it('requires the trusted Admin role and validates bounded pages',()=>{
  expect(sql).toContain("auth.jwt()->'app_metadata'->>'role'<>'admin'");
  expect(sql).toContain('p_limit>200');
  expect(sql).toContain('p_offset>1000000');
  expect(sql).toContain('order by m.created_at desc,m.id desc');
 });
 it('uses a paginated RPC and exposes continuation controls',()=>{
  expect(admin).toContain("admin_list_members_sponsors_page");
  expect(admin).toContain("p_limit:100,p_offset:members.length");
  expect(admin).toContain('Load 100 more members');
 });
});
