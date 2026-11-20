import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const migration=readFileSync('supabase/migrations/20261119680000_admin_auction_submission_expected_price_review.sql','utf8');
const admin=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
const member=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
const lifecycle=readFileSync('supabase/migrations/20261119150000_expected_price_48_hour_auction_lifecycle.sql','utf8');

describe('Admin auction submission Expected Price RPC contract',()=>{
 it('replaces the removed fixed-end-time RPC with the exact current frontend signature',()=>{
  expect(migration).toContain('p_expected_price numeric');
  expect(migration).toContain('p_optional_details jsonb');
  expect(migration).toContain('drop function if exists public.admin_review_auction_submission');
  expect(migration.replace(/\s+/g,'')).toContain('admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text)');
  expect(lifecycle).toContain('p_starting_price numeric,p_expected_price numeric,p_minimum_increment numeric');
  expect(lifecycle).toContain('insert into public.auction_submissions');
  expect(admin).toContain('p_expected_price:expected');
  expect(admin).toContain('p_starts_at:startsAt');
  expect(admin).not.toContain('p_ends_at:');
 });
 it('requires a valid Expected Price and keeps the auction open until the target lifecycle closes it',()=>{
  expect(migration).toContain('p_expected_price is null or p_expected_price<p_starting_price');
  expect(migration).toContain('check(expected_price is null or expected_price>=starting_price) not valid');
  expect(migration).toContain("check(status<>'pending' or expected_price is not null) not valid");
  expect(migration).toContain('expected_price,target_reached_at,status');
  expect(migration).toContain('p_expected_price,v_target_reached_at,v_status');
  expect(migration).toContain('if p_expected_price<=p_starting_price then');
  expect(migration).toContain('v_target_reached_at:=greatest(p_starts_at,clock_timestamp())');
  expect(migration).toContain("v_deadline:=v_target_reached_at+interval '48 hours'");
  expect(migration).toContain('ends_at=v_deadline');
 });
 it('authorizes Admin and only Staff with the explicit auction review permission',()=>{
  expect(migration).toContain("v_role='admin'");
  expect(migration).toContain("? 'auction_submission_review'");
  expect(migration).toContain("revoke all on function public.admin_review_auction_submission");
  expect(migration).toContain('to authenticated');
 });
 it('publishes only existing unique public images owned by the submitter and keeps the full gallery',()=>{
  expect(migration).toContain("o.bucket_id='product-media' and o.name=v_path");
  expect(migration).toContain('count(distinct image_path)');
  expect(migration).toContain('cardinality(p_image_paths)<>cardinality(v_s.image_paths)');
  expect(migration).toContain('image_path,image_paths,category,status,product_details');
  expect(migration).toContain('p_image_paths[1],p_image_paths');
 });
 it('records moderation outcomes and aligns the Admin title preflight with database validation',()=>{
  expect(migration).toContain("'auction.submission_approved'");
  expect(migration).toContain("'auction.submission_rejected'");
  expect(admin).toContain('title.length<5');
  expect(admin).toContain('minLength={5} maxLength={180}');
  expect(member).toContain('p_expected_price:Number(expected)');
 });
 it('keeps adjacent helper declarations on real source lines',()=>{
  expect(admin).not.toContain(';}\\nfunction validCleanupPath');
  expect(admin).toContain('function validUuid(value:unknown):value is string');
  expect(admin).toContain('function validCleanupPath(value:unknown,bucket:PendingMediaCleanup');
 });
});