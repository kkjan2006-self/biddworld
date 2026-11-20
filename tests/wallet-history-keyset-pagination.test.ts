import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = readFileSync(resolve(process.cwd(), 'src/components/WalletHistory.tsx'), 'utf8');

describe('wallet history keyset pagination', () => {
  it('continues the member statement after the last loaded created_at/id pair', () => {
    expect(source).toContain("pageCursor=useRef<{created_at:string;id:string}|null>(null)");
    expect(source).toContain("created_at.lt.${cursor.created_at},and(created_at.eq.${cursor.created_at},id.lt.${cursor.id})");
    expect(source).toContain('query.limit(100)');
    expect(source).not.toContain('.range(page*100,page*100+99)');
  });

  it('exports the complete statement with the same stable composite cursor', () => {
    expect(source).toContain("let cursor:{created_at:string;id:string}|null=null");
    expect(source).toContain('if(cursor)query=query.or(');
    expect(source).toContain('query.limit(500)');
    expect(source).not.toContain('.range(offset,offset+499)');
  });

  it('resets the cursor when the authenticated Main-ID scope changes or the first page reloads', () => {
    expect(source).toContain('pageCursor.current=null;setPage(0)');
    expect(source).toContain('if(page===0){loadMoreBusy.current=false;pageCursor.current=null;');
  });
});
