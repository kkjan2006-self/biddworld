import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin member detail selection follows directory search',()=>{
 it('clears the selected member before the primary directory query changes',()=>{
  expect(admin).toContain('value={memberSearch} onChange={e=>{setSelectedMemberCode("");setMemberSearch(e.target.value);}} placeholder="Enter Member ID, name, mobile or Sponsor ID"');
 });
 it('clears the selected member in the sponsor directory search as well',()=>{
  expect(admin).toContain('value={memberSearch} onChange={e=>{setSelectedMemberCode("");setMemberSearch(e.target.value);}} placeholder="Search name, member ID, phone or sponsor ID"');
 });
 it('retains explicit member selection only through the View details action',()=>{
  expect(admin).toContain("setSelectedMemberCode(m.member_code);setMemberProfileName(m.display_name||'');setMemberProfilePhone(m.phone||'');setMemberProfileMessage('');setMemberStatusValue(structure.ids.find(x=>x.member_code===m.member_code&&x.id_type==='main')?.status||'active');");
  expect(admin).toContain("setMemberStatusReason('');setMemberStatusMessage('');}}>View details</button>");
  expect(admin).toContain('selectedMemberCode&&(()=>{');
 });
});

describe('Admin member views distinguish Sponsor, owner Main ID and Under ID',()=>{
 it('shows the Under ID and owner Main ID on each placement hierarchy node',()=>{
  expect(admin).toContain('Under ID: {row.placement_parent_code||\'Root placement\'}');
  expect(admin).toContain("' · Owner Main ID: '+row.main_member_code");
  expect(admin).toContain('Matrix position: {row.placement_position}');
 });
 it('shows Main ID placement parent separately from its Matrix position in details',()=>{
  expect(admin).toContain('Main ID Under ID / Placement Parent');
  expect(admin).toContain('Main ID Matrix Position');
  expect(admin).toContain('Sponsor Main ID');
 });
 it('shows placement parent and position for each linked Duplicate ID',()=>{
  expect(admin).toContain('Under ID: {x.placement_parent_code||\'Not placed\'} · Position: {x.placement_position||\'Not assigned\'}');
 });
});

describe('Admin Main-ID lifecycle guidance matches linked Duplicate-ID behavior',()=>{
 it('explains suspension, closure and conditional reactivation accurately',()=>{
  expect(admin).toContain('Suspending a Main ID suspends its active linked Duplicate IDs.');
  expect(admin).toContain('Closing a Main ID closes every linked non-closed Duplicate ID, including manually suspended IDs.');
  expect(admin).toContain('Reactivating a suspended Main ID restores only Main-managed Duplicate IDs whose placement parent is active; unresolved IDs remain suspended until eligible.');
 });
});
