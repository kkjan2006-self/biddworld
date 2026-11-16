import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const placement=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql'),'utf8');
const lifecycle=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115150000_admin_duplicate_id_lifecycle.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Duplicate ID placement attribution',()=>{
 it('keeps Sponsor/Main ownership separate from Under ID placement',()=>{
  expect(placement).toContain('p_main_member_code text');
  expect(placement).toContain('p_under_member_code text');
  expect(placement).toContain('main_member_id,member_code,id_type,status,placement_parent_id,placement_position');
  expect(placement).toContain('v_main.id,v_code,\'duplicate\',\'pending\',v_under.id,\'under\'');
  expect(placement).toContain('Sponsor (referral attribution) from Under ID (placement attribution)');
 });
 it('requires an active external Under ID and rejects placement under the same owner',()=>{
  expect(placement).toContain("id_type in ('main','duplicate') and status='active'");
  expect(placement).toContain('v_under.owner_user_id = v_main.owner_user_id');
  expect(placement).toContain('A member cannot place their Duplicate ID under their own ID');
 });
 it('keeps newly created Duplicate IDs pending and does not post financial credits',()=>{
  expect(placement).toContain("'status','pending'");
  expect(placement).not.toMatch(/insert into public\.(wallet_transactions|referral_commissions|package_activations)/i);
 });
 it('removes the obsolete one-argument creator signature from the branch migration',()=>{
  expect(placement).toContain('drop function if exists public.admin_create_duplicate_member_id(text)');
  expect(placement).toContain('grant execute on function public.admin_create_duplicate_member_id(text,text) to authenticated');
 });
 it('does not permit reactivation of a closed Duplicate ID',()=>{
  expect(lifecycle).toContain("if v_row.status='closed' and p_status<>'closed'");
 });
 it('collects the Main ID and Under ID separately in Admin UI',()=>{
  expect(admin).toContain('Owner\'s active Main ID');
  expect(admin).toContain('Select Under / Placement ID');
  expect(admin).toContain('Sponsor attribution remains attached to the Main ID owner');
 });
});
