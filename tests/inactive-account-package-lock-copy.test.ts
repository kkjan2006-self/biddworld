import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Inactive account and package activation messaging', () => {
  it('does not tell inactive members to pay while package activation is locked', () => {
    const account = read('src/components/Account.tsx');
    const packages = read('src/components/Packages.tsx');
    expect(account).toContain('Both your member profile and Main ID must be active');
    expect(account).toContain('Package activation remains locked');
    expect(account).toContain('Do not make any package payment');
    
    expect(account).not.toContain('submit payment for an available package');
    expect(packages).toContain('Paid package activation is not currently open.');
  });
});
