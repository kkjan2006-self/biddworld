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
  expect(admin).toContain('onClick={()=>{setSelectedMemberCode(m.member_code);setMemberProfileName(m.display_name||'');setMemberProfilePhone(m.phone||'');setMemberProfileMessage('');}}>View details</button>');
  expect(admin).toContain('selectedMemberCode&&(()=>{');
 });
});
