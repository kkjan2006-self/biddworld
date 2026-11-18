import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const app = readFileSync(resolve(process.cwd(), 'src/App.tsx'), 'utf8');

describe('Member registration lifecycle UI contract', () => {
  it('keeps free registration separate from package activation', () => {
    expect(app).toContain('Register for free to get started. Package activation is separate.');
  });

  it('keeps Sponsor Referral ID optional and validates it only when supplied', () => {
    expect(app).toContain('Sponsor Referral ID (Optional)');
    expect(app).toContain("if(sponsorId.trim()&&sponsorLookup!=='valid')");
    expect(app).toContain("sponsor_referral_id:sponsorId.trim()||null");
  });

  it('confirms account and Main ID creation without claiming the account is active', () => {
    expect(app).toContain('Registration successful. Your free member account and Main ID have been created.');
    expect(app).not.toContain('Registration successful. Your account is ACTIVE');
    expect(app).not.toContain('Your account remains INACTIVE until the required Admin verification process is completed.');
  });
});
