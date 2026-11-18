import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');

function handler(name: string): string {
  const start = source.indexOf(`async function ${name}(`);
  expect(start, `handler ${name} exists`).toBeGreaterThan(-1);
  const end = source.indexOf('\n', start);
  return source.slice(start, end < 0 ? undefined : end);
}

describe('Admin form validation and mutation locks', () => {
  it('validates notification template fields before acquiring its mutation lock', () => {
    const body = handler('saveNotificationTemplate');
    expect(body.indexOf('name.length<2')).toBeGreaterThan(-1);
    expect(body.indexOf('name.length<2')).toBeLessThan(body.indexOf('templateSaveInFlight.current=true'));
    expect(body.indexOf("!['in_app','email','sms'].includes(templateChannel)")).toBeLessThan(body.indexOf('templateSaveInFlight.current=true'));
    expect(body).toContain('finally{templateSaveInFlight.current=false;setTemplateBusy(false);}');
  });

  it('validates member profile fields before acquiring its mutation lock', () => {
    const body = handler('saveMemberProfile');
    expect(body.indexOf('if(!displayName)')).toBeGreaterThan(-1);
    expect(body.indexOf('if(!displayName)')).toBeLessThan(body.indexOf('memberProfileSaveInFlight.current=true'));
    expect(body.indexOf('displayName.length>120')).toBeLessThan(body.indexOf('memberProfileSaveInFlight.current=true'));
    expect(body).toContain('finally{memberProfileSaveInFlight.current=false;setMemberProfileBusy(false);}');
  });

  it('validates both sponsor Main IDs before acquiring its mutation lock', () => {
    const body = handler('changeSponsor');
    expect(body.indexOf('if(!memberCode.trim()||!sponsorCode.trim())')).toBeGreaterThan(-1);
    expect(body.indexOf('if(!memberCode.trim()||!sponsorCode.trim())')).toBeLessThan(body.indexOf('sponsorSaveInFlight.current=true'));
    expect(body).toContain("rpc('admin_set_member_sponsor'");
    expect(body).toContain('finally{sponsorSaveInFlight.current=false;setSavingSponsor(false);}');
  });
});
