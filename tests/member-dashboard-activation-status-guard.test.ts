import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Member dashboard activation status guard',()=>{
  it('requires both the profile and Main ID to be active before showing an active account state',()=>{
    expect(account).toContain("const mainMemberStatus=members.find(member=>member.id_type==='main')?.status;");
    expect(account).toContain("const accountActivationLocked=profile?.status!=='active'||mainMemberStatus!=='active';");
  });

  it('shows a clear lock notice when either status is inactive, suspended, missing or not verified',()=>{
    expect(account).toContain("activeSection==='member-overview'&&accountActivationLocked");
    expect(account).toContain('Both your member profile and Main ID must be active');
    expect(account).toContain('Do not make any package payment.');
  });

  it('does not treat the dashboard notice as a replacement for server-side financial guards',()=>{
    expect(account).not.toContain('setProfile(current=>current?{...current,status:');
    expect(account).not.toContain("from('member_ids').update");
  });
});
