import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = (path: string) => readFileSync(join(process.cwd(), path), 'utf8');

describe('member workflow retry and response guards', () => {
  it('offers an explicit retry when wallet history fails to load', () => {
    const text = source('src/components/WalletHistory.tsx');
    expect(text).toContain('Retry transaction history');
    expect(text).toContain('setRefresh(v=>v+1)');
  });

  it('offers a retry for failed Add Money request history', () => {
    const text = source('src/components/WalletFunding.tsx');
    expect(text).toContain('Retry requests');
    expect(text).toContain('onClick={()=>void load()}');
  });

  it('validates the referral page payload before appending members', () => {
    const text = source('src/components/Referrals.tsx');
    expect(text).toContain('The team dashboard returned an incomplete page.');
    expect(text).toContain('Array.isArray(page.tree)');
  });

  it('renders a single Fixed Bid load error instead of duplicating it', () => {
    const text = source('src/components/FixedBid.tsx');
    expect(text).toContain("error&&<div className=\"notice\" role=\"status\">{error}");
    expect(text).not.toContain('{error&&<div className="notice">{error}</div>}');
  });
});
