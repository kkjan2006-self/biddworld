import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119340000_exclude_owner_ids_from_duplicate_placement.sql'),'utf8');
const approval=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118270000_duplicate_id_approval_placement_guard.sql'),'utf8');

describe('Automatic Duplicate ID placement owner guard',()=>{
 it('filters out the owner Main ID and owner-linked Duplicate IDs when choosing a parent',()=>{
  expect(migration).toContain("parent.owner_user_id is distinct from v_main.owner_user_id");
  expect(migration).toContain("parent.status='active'");
  expect(migration).toContain("child.id_type in ('main','duplicate')");
 });
 it('keeps automatic BFS placement within the owner Main ID team and never accepts a client Under ID',()=>{
  expect(migration).toContain('with recursive team(member_id,depth,path) as');
  expect(migration).toContain('where t.depth<v_plan.placement_depth');
  expect(migration).toContain('admin_create_duplicate_member_id(p_main_member_code text)');
  expect(migration).not.toContain('p_under_member_code');
 });
 it('matches the existing activation rule that the placement parent belongs to a different member',()=>{
  expect(approval).toContain('v_parent.owner_user_id is not distinct from v_row.owner_user_id');
  expect(migration).toContain('parent.owner_user_id is distinct from v_main.owner_user_id');
 });
});
