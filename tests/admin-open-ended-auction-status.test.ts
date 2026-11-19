import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const migration=readFileSync('supabase/migrations/20261119170000_admin_open_ended_auction_status.sql','utf8');
describe('Admin open-ended auction status contract',()=>{
 it('allows scheduling without a fixed end time',()=>{
  assert.match(migration,/v_auction\.starts_at is null or \(v_auction\.ends_at is not null and v_auction\.ends_at<=v_auction\.starts_at\)/);
 });
 it('allows live auctions while ends_at is null, retaining time-window checks',()=>{
  assert.match(migration,/v_auction\.ends_at is null or now\(\)<v_auction\.ends_at/);
  assert.match(migration,/bidding_enabled/);
 });
 it('preserves authenticated Admin-only RPC grants and cancellation refund handling',()=>{
  assert.match(migration,/app_metadata'->>'role','admin'/);
  assert.match(migration,/auction_bid_refund/);
  assert.match(migration,/revoke all on function public\.admin_set_auction_status/);
 });
});
