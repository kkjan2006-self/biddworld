import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');
const referrals=readFileSync(resolve(process.cwd(),'src/components/Referrals.tsx'),'utf8');
const placement=readFileSync(resolve(process.cwd(),'src/components/PlacementTree.tsx'),'utf8');
const identity=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115203000_member_identity_summary.sql'),'utf8');
const ids=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118200000_member_identity_ids_rpc.sql'),'utf8');

describe('Sponsor ID and Under ID remain separate member relationships',()=>{
 it('shows Sponsor and placement parent as separately labelled account fields',()=>{
  expect(account).toContain('profile?.sponsor_member_code');
  expect(account).toContain('Main ID Under ID / Placement Parent');
  expect(account).toContain("placement_parent_code||'Root placement'");
  expect(account).toContain('PlacementTree');
 });
 it('keeps Sponsor genealogy on referral attribution and placement tree on its own RPC',()=>{
  expect(referrals).toContain('Sponsor genealogy');
  expect(referrals).toContain('Sponsor Referral relationship');
  expect(placement).toContain("rpc('get_my_placement_tree')");
  expect(placement).toContain('Placement positions are shown separately from Sponsor Referral genealogy');
 });
 it('resolves Sponsor identity through referrals, not placement_parent_id',()=>{
  expect(identity).toContain('public.referrals r');
  expect(identity).toContain('r.referred_member_id = main_id.id');
  expect(identity).toContain('r.referrer_member_id');
  expect(identity).not.toContain('placement_parent_id');
 });
 it('returns placement_parent_code from the placement parent relationship for owned IDs',()=>{
  expect(ids).toContain('parent.member_code');
  expect(ids).toContain('m.placement_parent_id');
  expect(ids).toContain('where m.owner_user_id=(select auth.uid())');
 });
});
