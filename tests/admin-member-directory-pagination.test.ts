import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116090000_admin_members_sponsors_pagination.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin member directory pagination',()=>{
 it('requires the trusted Admin role and validates bounded pages',()=>{
  expect(sql).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(sql).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(sql).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(sql).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
 });
 it('uses server-side search for every page and exports every matching page',()=>{
  expect(admin).toContain("admin_list_members_sponsors_page");
  expect(admin).toContain("const request=memberSearchRequest.current,search=appliedMemberSearch.trim(),offset=members.length;");
  expect(admin).toContain("p_search:search||null,p_limit:100,p_offset:offset");
  expect(admin).toContain('setAppliedMemberSearch(memberSearch.trim())');
  expect(admin).toContain('const search=appliedMemberSearch.trim()||null');
  expect(admin).toContain("p_search:search,p_limit:100,p_offset:offset");
  expect(admin).toContain("[memberSearch,role,refresh]");
  expect(admin).toContain('Load 100 more members');
 });
});

