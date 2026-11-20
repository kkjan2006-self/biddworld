import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Inactive account and package activation messaging', () => {
  it('clearly identifies inactive member identity and keeps package payment unavailable', () => {
    const account = read('src/components/Account.tsx');
    const packages = read('src/components/Packages.tsx');
    expect(account).toContain('Your member profile and Main ID must both be active to use restricted member features.');
    expect(account).toContain("const accountActivationLocked=profile?.status!=='active'||mainMemberStatus!=='active';");
    expect(account).not.toContain('submit payment for an available package');
    expect(packages).toContain('Paid package activation is not currently open.');
    expect(packages).toContain('Package activation is temporarily locked.');
    expect(packages).toContain('setActivationEnabled(!activationSettingError&&activationSetting?.setting_value===true)');
    expect(packages).toContain('{activationEnabled&&<section className="packageActivationForm">');
  });
});
