import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const previous=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118220000_member_placement_tree_rpc.sql'),'utf8');
const current=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118380000_include_duplicate_ids_in_member_placement_tree.sql'),'utf8');
const ownershipGuard=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119010000_enforce_member_placement_tree_root_ownership.sql'),'utf8');

describe('Member placement tree includes Duplicate ID nodes',()=>{
 it('replaces the Main-only traversal with a bounded cycle-safe Main and Duplicate traversal',()=>{
  expect(previous).toContain("child.id_type = 'main'");
  expect(current).toContain("child.id_type in ('main','duplicate')");
  expect(current).toContain('parent.depth < 20');
  expect(current).toContain('not child.id = any(parent.path)');
 });
 it('retains authenticated ownership and identifies each node type and Main ID',()=>{
  expect(current).toContain('where p.id = v_uid');
  expect(ownershipGuard).toContain('m.owner_user_id = p.id');
  expect(ownershipGuard).toContain("m.id_type = 'main'");
  expect(ownershipGuard).toContain('where p.id = v_uid');
  expect(ownershipGuard).toContain("'id_type', mi.id_type");
  expect(ownershipGuard).toContain("'main_member_code', main.member_code");
  expect(ownershipGuard).toContain('grant execute on function public.get_my_placement_tree() to authenticated, service_role');
  expect(current).toContain("'id_type', mi.id_type");
  expect(current).toContain("'main_member_code', main.member_code");
  expect(current).toContain('grant execute on function public.get_my_placement_tree() to authenticated, service_role');
 });
});
