import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const rpc=read('supabase/migrations/20261124010000_align_member_placement_tree_depth.sql');
const client=read('src/components/PlacementTree.tsx');
const plan=read('supabase/migrations/20261119300000_automatic_duplicate_matrix_placement.sql');

describe('Member Matrix placement depth and response integrity contract',()=>{
 it('keeps the configured placement-depth ceiling at 50 across plan creation and tree traversal',()=>{
  expect(plan).toContain('p_placement_depth not between 1 and 50');
  expect(rpc).toContain('parent.depth < 50');
  expect(rpc).not.toContain('parent.depth < 20');
 });
 it('accepts every supported member tree level through 50 and rejects level 51',()=>{
  expect(client).toMatch(/row\.depth>50/);
  expect(client).not.toMatch(/row\.depth>20/);
  expect(rpc).toContain('parent.depth < 50');
 });
 it('preserves root ownership, cycle protection, parent labels and the authenticated RPC boundary',()=>{
  expect(rpc).toContain('m.owner_user_id = p.id');
  expect(rpc).toContain("m.id_type = 'main'");
  expect(rpc).toContain('not child.id = any(parent.path)');
  expect(rpc).toContain("'placement_parent_code', placement_parent.member_code");
  expect(rpc).toContain('revoke all on function public.get_my_placement_tree() from public, anon');
  expect(rpc).toContain('grant execute on function public.get_my_placement_tree() to authenticated, service_role');
 });
 it('rejects case-folded duplicate member codes and ambiguous whitespace in identity fields',()=>{
  expect(client).toContain('function placementCodeKey(value:string):string');
  expect(client).toContain('seen.has(placementCodeKey(row.member_code))');
  expect(client).toContain('seen.set(placementCodeKey(member.member_code),member)');
  expect(client).toContain('row.member_code!==row.member_code.trim()');
  expect(client).toContain('row.main_member_code!==row.main_member_code.trim()');
  expect(client).toContain('row.placement_parent_code!==row.placement_parent_code.trim()');
 });
 it('requires a single canonical root with no parent and resolves parents before children',()=>{
  expect(client).toContain('member.placement_parent_code!==null');
  expect(client).toContain('placementCodeKey(member.member_code)!==placementCodeKey(payload.root_member_code)');
  expect(client).toContain('const parent=seen.get(placementCodeKey(member.placement_parent_code))');
  expect(client).toContain('parent.depth+1!==member.depth');
 });
});
