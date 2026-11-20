import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119630000_cleanup_unreferenced_submission_media.sql','utf8');
const auctionUi=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
const productUi=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
const auctionReview=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
describe('safe cleanup for unreferenced submission media',()=>{
 it('allows members to remove only their own unreferenced private auction and product uploads',()=>{
  expect(sql).toContain("bucket_id='auction-submission-media'");
  expect(sql).toContain("bucket_id='product-submission-media'");
  expect(sql).toContain('s.submitted_by=(select auth.uid()) and name=any(s.image_paths)');
  expect(auctionUi).toContain("storage.from('auction-submission-media').remove(uploadedPaths)");
  expect(productUi).toContain("storage.from('product-submission-media').remove(uploaded)");
 });
 it('limits Staff public-image cleanup to pending auction submissions and unreferenced objects',()=>{
  expect(sql).toContain("? 'auction_submission_review'");
  expect(sql).toContain("s.status='approved'");
  expect(sql).toContain('not exists(select 1 from public.auction_submissions s where name=any(s.image_paths))');
  expect(sql).toContain("s.status='pending'");
  expect(sql).toContain('not exists(select 1 from public.products p where p.image_path=name or name=any(p.image_paths))');
  expect(sql).toContain('not exists(select 1 from public.auctions a where a.image_url=name)');
  expect(auctionReview).toContain("storage.from('product-media').remove(publishedPaths)");
  expect(auctionReview).toContain("storage.from('auction-submission-media').remove(r.image_paths)");
  expect(auctionUi).toContain("storage.from('auction-submission-media').remove(stale)");
  expect(productUi).toContain("storage.from('product-submission-media').remove(stale)");
 });
});
