import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const admin=readFileSync('src/components/Admin.tsx','utf8');
const placement=readFileSync('supabase/migrations/20261119340000_exclude_owner_ids_from_duplicate_placement.sql','utf8');
const settings=readFileSync('supabase/migrations/20261119530000_remove_email_verification_switch.sql','utf8');
describe('Duplicate ID automatic placement controls',()=>{
 it('keeps automatic placement as the built-in duplicate creation rule, not a dead feature switch',()=>{
  expect(admin).not.toContain('automatic_placement_enabled');
  expect(admin).toContain('The system automatically assigns the next available position');
  expect(placement).toContain('with recursive team(member_id,depth,path)');
  expect(placement).toContain('order by t.depth,t.path,slot.position');
 });
 it('keeps the Admin feature RPC allowlist aligned with visible controls',()=>{
  expect(settings).not.toContain("'automatic_placement_enabled'");
  expect(settings).toContain("'matrix_commissions_enabled'");
 });
});
