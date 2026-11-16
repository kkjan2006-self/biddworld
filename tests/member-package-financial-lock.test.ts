import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Packages.tsx'), 'utf8');

describe('member package financial lock', () => {
  it('fails closed until explicit owner financial and legal approval', () => {
    expect(source).toMatch(/const PACKAGE_ACTIVATION_LOCKED = true/);
    expect(source).toContain('owner approves the financial and legal model');
  });

  it('does not expose a payment reference form or activation RPC while locked', () => {
    expect(source).not.toContain('submit_package_activation');
    expect(source).not.toContain('payment-reference');
    expect(source).not.toContain('Payment reference / UTR');
  });

  it('clearly labels displayed wallet credits as proposed and not issued', () => {
    expect(source).toContain('Proposed Bid Wallet credit (not issued)');
    expect(source).toContain('Not accepting payments or activation requests');
  });

  it('keeps free registration available while paid activation is unavailable', () => {
    expect(source).toContain('Free member registration is available');
  });
});
