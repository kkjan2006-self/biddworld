import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Member support and inbox owner scoping', () => {
  it('filters member notification pages by the authenticated user in both initial and continuation reads', () => {
    const source = read('src/components/Notifications.tsx');
    expect(source).toContain("if(!isAdmin){const{data:{user},error:userError}=await supabase.auth.getUser()");
    expect(source.match(/request=request\.eq\('user_id',user\.id\)/g)?.length).toBe(2);
    expect(source).toContain("Please sign in again to view your notifications.");
    expect(source).toContain(" },[isAdmin]);");
    expect(source).toContain(" },[busy,hasMore,items.length,isAdmin]);");
  });

  it('filters member support pages by the authenticated user in both initial and continuation reads', () => {
    const source = read('src/components/Support.tsx');
    expect(source).toContain("if(!isAdmin){const{data:{user},error:userError}=await supabase.auth.getUser()");
    expect(source.match(/request=request\.eq\('user_id',user\.id\)/g)?.length).toBe(2);
    expect(source).toContain("Please sign in again to view your support requests.");
    expect(source).toContain(" },[isAdmin]);");
    expect(source).toContain(" },[busy,hasMore,tickets.length,isAdmin]);");
  });

  it('preserves the separate Admin queue path instead of filtering Admin reads to one member', () => {
    for (const path of ['src/components/Notifications.tsx', 'src/components/Support.tsx']) {
      const source = read(path);
      expect(source).toContain('if(!isAdmin){');
      expect(source).toContain('request=request.eq');
      expect(source).toContain("isAdmin?'");
    }
  });
});
