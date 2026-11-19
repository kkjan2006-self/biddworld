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
  it('rejects malformed and duplicate wallet transaction rows before advancing the page cursor', () => {
    const text = source('src/components/WalletHistory.tsx');
    expect(text).toContain("if(!Array.isArray(data??[]))");
    expect(text).toContain("typeof row.id!=='string'");
    expect(text).toContain("typeof row.created_at!=='string'");
    expect(text).toContain('pageIds.has(row.id)||knownIds.has(row.id)');
    expect(text).toContain('The wallet history returned duplicate transaction IDs.');
  });

  it('does not replace a failed Fixed Bid catalogue with sample preview cards', () => {
    const text = source('src/components/FixedBid.tsx');
    expect(text).toContain('const showingSamples=rows.length===0&&!error');
    expect(text).toContain('const displayRows=rows.length?rows:showingSamples?sampleFixedCampaigns:[]');
    expect(text).toContain('The campaign catalogue returned duplicate campaign IDs.');
    expect(text).toContain('The campaign catalogue contains an incomplete record.');
  });

});