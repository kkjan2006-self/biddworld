import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119670000_staff_auction_submission_media_access.sql','utf8');
const review=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
const member=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
describe('Auction submission private media access',()=>{
 it('retains member-owned and Admin access while limiting Staff to pending owned submissions',()=>{
  expect(sql).toContain("role','')='admin'");
  expect(sql).toContain("role','')='admin_staff'");
  expect(sql).toContain("? 'auction_submission_review'");
  expect(sql).toContain("s.status='pending'");
  expect(sql).toContain('p_name=any(s.image_paths)');
  expect(sql).toContain('(storage.foldername(p_name))[1]=(select auth.uid())::text');
 });
 it('replaces the broad policy and preserves member/admin review image flows',()=>{
  expect(sql).toContain('drop policy if exists auction_submission_media_select on storage.objects');
  expect(review).toContain("storage.from('auction-submission-media').createSignedUrl(path,300)");
  expect(member).toContain("storage.from('auction-submission-media').upload(path,file");
 });
});
