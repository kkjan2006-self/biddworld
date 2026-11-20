import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119150000_expected_price_48_hour_auction_lifecycle.sql'),'utf8');
const member=readFileSync(resolve(process.cwd(),'src/components/MemberPlaceAuction.tsx'),'utf8');
const review=readFileSync(resolve(process.cwd(),'src/components/AdminAuctionSubmissionReview.tsx'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('Expected-price auction lifecycle',()=>{
 it('requires expected price but does not require a fixed end time on submission',()=>{
  expect(migration).toContain('p_expected_price numeric');
  expect(migration).toContain('p_expected_price<p_starting_price');
  expect(migration).toContain('ends_at drop not null');
  expect(member).toContain('p_expected_price:Number(expected)');
  expect(member).not.toContain('p_ends_at');
  expect(member).not.toContain('End Date & Time');
 });
 it('validates member and reviewed image extensions using a literal dot',()=>{
  expect(migration).toContain("v_path !~ ('^'||v_uid::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)
  expect(migration).toContain("new.current_price >= new.expected_price");
  expect(migration).toContain("interval '48 hours'");
  expect(migration).toContain('v_auction.ends_at is not null and now() >= v_auction.ends_at');
  expect(migration).toContain('biddworld-auction-expected-price-lifecycle');
 });
 it('passes the expected price through moderation and public catalogue',()=>{
  expect(review).toContain('p_expected_price:Number(v.expected_price');
  expect(review).toContain('Expected Price<input');
  expect(migration).toContain('a.expected_price,a.target_reached_at,a.starts_at');
  expect(app).toContain('Expected: {a.expected_price');
  expect(app).toContain('Waiting for expected price');
  expect(app).toContain('left(a.ends_at,clockNow)');
 });
});
)");
  expect(migration).toContain("v_path !~ ('^'||v_s.submitted_by::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)
  expect(migration).toContain("new.current_price >= new.expected_price");
  expect(migration).toContain("interval '48 hours'");
  expect(migration).toContain('v_auction.ends_at is not null and now() >= v_auction.ends_at');
  expect(migration).toContain('biddworld-auction-expected-price-lifecycle');
 });
 it('passes the expected price through moderation and public catalogue',()=>{
  expect(review).toContain('p_expected_price:Number(v.expected_price');
  expect(review).toContain('Expected Price<input');
  expect(migration).toContain('a.expected_price,a.target_reached_at,a.starts_at');
  expect(app).toContain('Expected: {a.expected_price');
  expect(app).toContain('Waiting for expected price');
  expect(app).toContain('left(a.ends_at,clockNow)');
 });
});
)");
  expect(migration).not.toContain('\\\\\\\\.');
 });
 it('starts a 48-hour close timer only after the expected price is reached',()=>{
  expect(migration).toContain("new.current_price >= new.expected_price");
  expect(migration).toContain("interval '48 hours'");
  expect(migration).toContain('v_auction.ends_at is not null and now() >= v_auction.ends_at');
  expect(migration).toContain('biddworld-auction-expected-price-lifecycle');
 });
 it('passes the expected price through moderation and public catalogue',()=>{
  expect(review).toContain('p_expected_price:Number(v.expected_price');
  expect(review).toContain('Expected Price<input');
  expect(migration).toContain('a.expected_price,a.target_reached_at,a.starts_at');
  expect(app).toContain('Expected: {a.expected_price');
  expect(app).toContain('Waiting for expected price');
  expect(app).toContain('left(a.ends_at,clockNow)');
 });
});
