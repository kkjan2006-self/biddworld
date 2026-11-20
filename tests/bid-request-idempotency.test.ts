import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

describe('Bid request idempotency', () => {
  it('sends and retains one stable request key for a retry until success', () => {
    const app = read('src/App.tsx');
    expect(app).toContain('bidRequestKeys=useRef(new Map<string,string>())');
    expect(app).toMatch(/supabase\.rpc\('place_bid',\{p_auction_id:id,p_idempotency_key:requestKey\}\)/);
    expect(app).toContain('bidRequestKeys.current.delete(id)');
    expect(app).toContain('the same request key will be reused');
    expect(app).toContain('window.crypto.getRandomValues(bytes)');
  });

  it('serializes a key and replays an existing matching bid without another debit', () => {
    const sql = read('supabase/migrations/20261116190000_bid_request_idempotency.sql');
    expect(sql).toContain('pg_advisory_xact_lock');
    expect(sql).toMatch(/where idempotency_key = v_key/);
    expect(sql).toMatch(/'replayed', true/);
    expect(sql).toMatch(/v_existing_member is distinct from v_member_id/);
    expect(sql).toMatch(/v_existing_auction is distinct from p_auction_id/);
    expect(sql).toContain("v_key || ':bid'");
    expect(sql).toContain("v_key || ':income'");
    expect(sql).toMatch(/returning id into v_bid_id/);
    expect(sql).not.toMatch(/v_key\s*:=\s*gen_random_uuid/i);
  });

  it('removes the unsafe one-argument public RPC and exposes only the keyed signature', () => {
    const sql = read('supabase/migrations/20261116190000_bid_request_idempotency.sql');
    expect(sql).toContain('drop function if exists public.place_bid(uuid)');
    expect(sql).toContain('create or replace function public.place_bid(');
    expect(sql).toContain('p_idempotency_key text');
    expect(sql).toContain('grant execute on function public.place_bid(uuid, text) to authenticated');
    expect(sql).not.toMatch(/grant execute on function public\.place_bid\(uuid\) to authenticated/i);
  });
});
