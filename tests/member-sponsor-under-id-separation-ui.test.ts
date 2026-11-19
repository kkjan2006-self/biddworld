import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');
const referrals=readFileSync(resolve(process.cwd(),'src/components/Referrals.tsx'),'utf8');
const placement=readFileSync(resolve(process.cwd(),'src/components/PlacementTree.tsx'),'utf8');

describe('Member Sponsor ID and Under ID separation',()=>{
 it('shows Sponsor ID and Main ID Under ID as separate read-only profile fields',()=>{
  expect(account).toContain('Sponsor Member ID');
  expect(account).toContain('Main ID Under ID / Placement Parent');
  expect(account).toContain("members.find(m=>m.id_type==='main')?.placement_parent_code||'Root placement'");
 });
 it('labels Sponsor genealogy independently from placement genealogy',()=>{
  expect(referrals).toContain('Your Sponsor genealogy');
  expect(referrals).toContain('recorded Sponsor Referral relationship');
  expect(placement).toContain('Placement positions are shown separately from Sponsor Referral genealogy.');
  expect(placement).toContain('actual placement positions');
 });
 it('keeps Matrix commission history explicitly tied to the Under ID chain',()=>{
  expect(account).toContain('Matrix Commissions (Under ID Chain)');
  expect(account).toContain('Matrix commissions follow placement parent (Under ID) relationships.');
 });
});
