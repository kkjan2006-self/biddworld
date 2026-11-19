import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const admin=read('src/components/Admin.tsx');
const migration=read('supabase/migrations/20261119300000_automatic_duplicate_matrix_placement.sql');

describe('Automatic Duplicate ID placement RPC contract',()=>{
 it('does not accept a manually selected Under ID from the Admin UI',()=>{
  expect(admin).toContain("supabase.rpc('admin_create_duplicate_member_id',{p_main_member_code:code})");
  expect(admin).not.toContain('duplicateUnderCode');
  expect(admin).not.toContain('p_under_member_code');
  expect(migration).toContain('admin_create_duplicate_member_id(p_main_member_code text)');
  expect(migration).toContain('drop function if exists public.admin_create_duplicate_member_id(text,text)');
 });
 it('requires the second approved active package activation and its active Matrix plan',()=>{
  expect(migration).toContain('activation_number=2');
  expect(migration).toContain("payment_status='approved' and activation_status='active'");
  expect(migration).toContain('An active Matrix plan is required for the second activated package');
 });
 it('uses breadth-first automatic placement and configured width/depth',()=>{
  expect(migration).toContain('with recursive team(member_id,depth,path)');
  expect(migration).toContain('v_plan.placement_depth');
  expect(migration).toContain('v_plan.matrix_width');
  expect(migration).toContain('order by t.depth,t.path,slot.position');
  expect(migration).toContain('placement_parent_id,placement_position');
 });
 it('keeps graph locking, feature switch, audit log and authenticated-only access',()=>{
  expect(migration).toContain("hashtextextended('biddworld.member_id_graph_mutation',0)");
  expect(migration).toContain("setting_key='duplicate_ids_enabled'");
  expect(migration).toContain('insert into public.audit_logs');
  expect(migration).toContain('grant execute on function public.admin_create_duplicate_member_id(text) to authenticated');
 });

 it('contains one complete Duplicate ID RPC definition without orphaned SQL fragments',()=>{
  expect((migration.match(/create or replace function public\\.admin_create_duplicate_member_id\\(/g)||[])).toHaveLength(1);
  expect(migration.trimEnd()).toMatch(/grant execute on function public\\.admin_create_duplicate_member_id\\(text\\) to authenticated;$/);
  expect(migration).not.toMatch(/^\\s*\\)\\)\\)/m);
  expect(migration).not.toMatch(/^\\s*order by t\\.depth,t\\.path,slot\\.position\\s*$/m);
 });
});
