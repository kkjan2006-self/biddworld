import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const migration=readFileSync('supabase/migrations/20261119170000_admin_open_ended_auction_status.sql','utf8');
describe('Admin open-ended auction status contract',()=>{
 it('allows scheduling without a fixed end time',()=>{
  expect(migration).toMatch(/v_auction\.starts_at is null or \(v_auction\.ends_at is not null and v_auction\.ends_at<=v_auction\.starts_at\)/);
 });
 it('allows live auctions while ends_at is null, retaining time-window checks',()=>{
  expect(migration).toMatch(/v_auction\.ends_at is null or now\(\)<v_auction\.ends_at/);
  expect(migration).toMatch(/bidding_enabled/);
 });
 it('preserves authenticated Admin-only RPC grants and cancellation refund handling',()=>{
  expect(migration).toMatch(/app_metadata'->>'role','admin'/);
  expect(migration).toMatch(/auction_bid_refund/);
  expect(migration).toMatch(/revoke all on function public\.admin_set_auction_status/);
 });
});
