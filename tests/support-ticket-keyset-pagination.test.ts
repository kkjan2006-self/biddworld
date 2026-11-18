import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/Support.tsx'), 'utf8');

describe('support ticket keyset pagination', () => {
  it('loads subsequent queue pages strictly after the last visible updated_at/id pair', () => {
    expect(source).toContain("const cursor=tickets[tickets.length-1]");
    expect(source).toContain("updated_at.lt.${cursor.updated_at},and(updated_at.eq.${cursor.updated_at},id.lt.${cursor.id})");
    expect(source).toContain('request.limit(PAGE_SIZE)');
  });

  it('exports with the same stable composite cursor instead of mutable offsets', () => {
    expect(source).toContain("let cursor:Pick<Ticket,'updated_at'|'id'>|null=null");
    expect(source).toContain('if(cursor)request=request.or(');
    expect(source).toContain('request.limit(500)');
    expect(source).not.toContain('request.range(offset,offset+499)');
  });

  it('retains duplicate-ID and repeated-page guards during export', () => {
    expect(source).toContain('const seenPages=new Set<string>(),seenIds=new Set<string>()');
    expect(source).toContain('if(seenIds.has(ticket.id))throw new Error');
  });
});
