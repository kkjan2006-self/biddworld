import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119610000_open_ended_auction_bidding_catalogue.sql','utf8');
const ui=readFileSync('src/App.tsx','utf8');
describe('open-ended Expected Price auction lifecycle',()=>{
 it('allows bidding with a NULL End Time and activates due scheduled auctions',()=>{
  expect(sql).toContain("v_auction.status not in ('live','scheduled')");
  expect(sql).toContain('(v_auction.ends_at is not null and now() >= v_auction.ends_at)');
  expect(sql).toContain("if v_auction.status='scheduled' then");
  expect(sql).toContain("set status='live',updated_at=now()");
 });
 it('removes the obsolete non-idempotent one-argument bid overloads',()=>{
  expect(sql).toContain('drop function if exists public.place_bid(uuid)');
  expect(sql).toContain('drop function if exists private.place_bid(uuid)');
  expect(sql).toContain('public.place_bid(\n  p_auction_id uuid,\n  p_idempotency_key text');
 });
 it('starts the 48-hour clock at scheduled start when Starting Price already meets Expected Price',()=>{
  expect(sql).toContain("new.status='scheduled' and new.starts_at is not null");
  expect(sql).toContain('v_target_time:=new.starts_at');
  expect(sql).toContain("before insert or update of current_price,status,expected_price,starts_at on public.auctions");
  expect(sql).toContain("new.ends_at:=v_target_time+interval '48 hours'");
 });
 it('publishes open-ended auctions and returns the lifecycle fields required by the UI',()=>{
  expect(sql).toContain('a.ends_at is null or a.ends_at>now()');
  expect(sql).toContain('a.expected_price,a.target_reached_at,a.starts_at,a.ends_at');
  expect(sql).toContain("a.status='scheduled' and a.starts_at is not null and a.starts_at>now()");
 });
 it('shows the scheduled start and open-ended state without inventing an end time',()=>{
  expect(ui).toContain('function auctionTimeLabel');
  expect(ui).toContain('Open until expected price is reached');
  expect(ui).toContain('Starts in');
 });
});
