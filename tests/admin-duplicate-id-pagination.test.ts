import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116110000_admin_duplicate_id_pagination.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin Duplicate ID pagination and search',()=>{
 it('requires a trusted Admin claim and bounds page size and offset',()=>{
  expect(sql).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin'");
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
  expect(admin).toContain('const offset=duplicateIds.length;');
  expect(admin).toContain('p_search:search,p_limit:50,p_offset:offset');
  expect(admin).toContain('Load More Duplicate IDs');
 });
});


describe('Duplicate ID status no-op protection',()=>{
 it('returns without updating or auditing when the requested status already matches',()=>{
  const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261117130000_admin_duplicate_status_noop_guard.sql'),'utf8');
  expect(migration).toContain('if v_old_status=p_status then');
  expect(migration).toContain("'changed',false");
  expect(migration).toContain("'changed',true");
  expect(migration.indexOf('if v_old_status=p_status then')).toBeLessThan(migration.indexOf('update public.member_ids set status=p_status'));
  expect(migration.indexOf('if v_old_status=p_status then')).toBeLessThan(migration.indexOf('insert into public.audit_logs'));
 });
 it('shows an accurate no-change message and avoids unnecessary list refresh',()=>{
  expect(admin).toContain('data?.changed===false');
  expect(admin).toContain('if(data?.changed!==false)setRefresh(v=>v+1)');
  expect(admin).toContain('No changes were needed.');
 });
 it('preserves the closed Duplicate ID no-reactivation rule and Admin authorization',()=>{
  const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261117130000_admin_duplicate_status_noop_guard.sql'),'utf8');
  expect(migration).toContain("v_row.status='closed' and p_status<>'closed'");
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin'");
  expect(migration).toContain("where id=p_duplicate_id and id_type='duplicate'");
  expect(migration).toContain('for update');
 });
});
