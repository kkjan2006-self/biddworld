import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119150000_expected_price_48_hour_auction_lifecycle.sql'),'utf8');
const editMigration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119430000_member_auction_submission_editing.sql'),'utf8');
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
 it('accepts only string-valued optional listing details in submit, edit and review RPCs',()=>{
  expect(migration).toContain("exists(select 1 from jsonb_each(p_optional_details) item where jsonb_typeof(item.value)<>'string')");
  expect(editMigration).toContain("exists(select 1 from jsonb_each(p_optional_details) item where jsonb_typeof(item.value)<>'string')");
 });
 it('validates private member images and published public image objects',()=>{
  expect(migration).toContain("o.bucket_id='auction-submission-media' and o.name=v_path");
  expect(migration).toContain("o.bucket_id='product-media' and o.name=v_path");
  expect(migration).not.toContain("not exists(select 1 from unnest(v_s.image_paths) original(path)");
  expect(migration).toContain("[.](jpg|jpeg|png|webp)$");
 });
 it('starts a 48-hour close timer only after the expected price is reached',()=>{
  expect(migration).toContain("new.current_price >= new.expected_price");
  expect(migration).toContain("interval '48 hours'");
 });
 it('passes expected price and countdown state through moderation and the public catalogue',()=>{
  expect(review).toContain('p_expected_price:Number(v.expected_price');
  expect(review).toContain('Expected Price<input');
  expect(migration).toContain('a.expected_price,a.target_reached_at,a.starts_at');
  expect(app).toContain('Expected: {a.expected_price');
  expect(app).toContain('Waiting for expected price');
  expect(app).toContain('left(a.ends_at,clockNow)');
 });
});
