import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116110000_admin_duplicate_id_pagination.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin Duplicate ID pagination and search',()=>{
 it('requires a trusted Admin claim and bounds page size and offset',()=>{
  expect(sql).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'\) <> 'admin'/i);
  expect(sql).toContain('v_limit < 1 or v_limit > 100');
  expect(sql).toContain('v_offset < 0 or v_offset > 1000000');
 });
 it('searches all duplicate identifiers and linked member details',()=>{
  for(const field of ['d.member_code','m.member_code','p.display_name','p.phone','parent.member_code','under_profile.display_name','d.status'])expect(sql).toContain(field);
 });
 it('uses deterministic newest-first ordering and reports total/continuation',()=>{
  expect(sql).toContain('order by d.created_at desc,d.id desc');
  expect(sql).toContain('v_total,(v_offset + v_limit < v_total)');
 });
 it('restricts RPC execution to authenticated users',()=>{
  expect(sql).toMatch(/revoke all on function public\.admin_list_duplicate_ids_page\(text,integer,integer\) from public,anon/i);
  expect(sql).toMatch(/grant execute on function public\.admin_list_duplicate_ids_page\(text,integer,integer\) to authenticated/i);
 });
 it('loads the first page, preserves search for subsequent pages and exposes Load More',()=>{
  expect(admin).toContain("admin_list_duplicate_ids_page',{p_search:appliedDuplicateSearch.trim()||null,p_limit:50,p_offset:0}");
  expect(admin).toContain('p_offset:duplicateIds.length');
  expect(admin).toContain('Load More Duplicate IDs');
 });
});
