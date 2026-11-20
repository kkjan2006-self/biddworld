import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';

describe('public auction catalogue preview fallback', () => {
  it('distinguishes an unavailable catalogue RPC from an empty search result', () => {
    const source = readFileSync('src/App.tsx', 'utf8');
    expect(source).toContain("isRpcContractUnavailable(error)?'The live auction catalogue database update is not installed yet. Sample cards are shown for preview only.'");
    expect(source).toContain("const showingAuctionSamples=items.length===0||items.every(a=>a.id.startsWith('demo-'))");
  });
});
