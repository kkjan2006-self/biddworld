import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(join(process.cwd(), path), 'utf8');

describe('Admin auction and Fixed Bid report date filters', () => {
  for (const path of [
    'src/components/AdminAuctionBidReport.tsx',
    'src/components/AdminFixedBidEntryReport.tsx',
  ]) {
    it(`${path} rejects reversed date ranges before applying or exporting`, () => {
      const source = read(path);
      expect(source).toContain('From date must be on or before To date.');
      expect(source).toContain('if(from&&to&&from>to)');
      expect(source).toContain('if(applied.from&&applied.to&&applied.from>applied.to)');
      expect(source).toContain('disabled={loading||Boolean(from&&to&&from>to)}');
    });
  }
});
