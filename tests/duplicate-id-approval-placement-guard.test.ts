import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const legacy=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115150000_admin_duplicate_id_lifecycle.sql'),'utf8');
const placement=readFileSync(resolve(process.cwd(),'supabase/migrations/20261117110000_serialize_admin_duplicate_id_placement.sql'),'utf8');
const main=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118140000_admin_main_member_lifecycle.sql'),'utf8');
const guard=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118270000_duplicate_id_approval_placement_guard.sql'),'utf8');
describe('Duplicate ID placement approval and legacy RPC safety',()=>{
 it('removes the obsolete one-argument creation overload',()=>{
  expect(legacy).toContain('admin_create_duplicate_member_id(p_main_member_code text)');
  expect(placement).toContain('p_under_member_code text');
  expect(guard).toContain('drop function if exists public.admin_create_duplicate_member_id(text)');
 });
 it('requires an active owner Main ID and different-owner active placement parent',()=>{
  expect(guard).toContain("id=v_row.main_member_id and id_type='main' and status='active'");
  expect(guard).toContain("id=v_row.placement_parent_id and id_type in ('main','duplicate') and status='active'");
  expect(guard).toContain('v_parent.owner_user_id is not distinct from v_row.owner_user_id');
 });
 it('serializes placement creation, approval and Main ID lifecycle changes',()=>{
  expect(placement).toContain("'biddworld.member_id_graph_mutation'");
  expect(guard).toContain("'biddworld.member_id_graph_mutation'");
  expect(main).toContain("'biddworld.member_id_graph_mutation'");
 });
 it('does not auto-reactivate a Duplicate ID below an inactive or same-owner parent',()=>{
  expect(main).toContain("parent.status='active' and parent.owner_user_id is distinct from d.owner_user_id");
 });
});
