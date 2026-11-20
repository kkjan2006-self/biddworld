import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const productMember=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
const auctionMember=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
const productAdmin=readFileSync('src/components/AdminProductSubmissionReview.tsx','utf8');
const auctionAdmin=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
const productSubmit=readFileSync('supabase/migrations/20261119440000_member_product_submission_moderation.sql','utf8');
const productEdit=readFileSync('supabase/migrations/20261119450000_member_product_submission_editing.sql','utf8');
const productReview=readFileSync('supabase/migrations/20261119480000_product_gallery_publication.sql','utf8');
const productMemberPage=readFileSync('supabase/migrations/20261119490000_member_product_submission_keyset_pagination.sql','utf8');
const productAdminPage=readFileSync('supabase/migrations/20261119470000_admin_product_submission_keyset_pagination.sql','utf8');
const auctionMemberPage=readFileSync('supabase/migrations/20261119580000_member_auction_submission_history_pagination.sql','utf8');
const auctionAdminPage=readFileSync('supabase/migrations/20261119400000_admin_auction_submission_keyset_pagination.sql','utf8');
const auctionEdit=readFileSync('supabase/migrations/20261119430000_member_auction_submission_editing.sql','utf8');

describe('Member/Admin submission RPC and pagination contracts',()=>{
 it('keeps Member Product create/edit calls aligned with authenticated SQL signatures',()=>{
  expect(productMember).toContain("'member_submit_product_listing'");
  expect(productMember).toContain("'member_update_product_submission'");
  expect(productSubmit.replace(/\s+/g,'')).toContain('member_submit_product_listing(text,text,text,text[],jsonb)');
  expect(productEdit.replace(/\s+/g,'')).toContain('member_update_product_submission(uuid,text,text,text,text[],jsonb)');
 });
 it('keeps Member Auction edit and history calls aligned with the Expected Price schema',()=>{
  expect(auctionMember).toContain("'member_update_own_auction_submission'");
  expect(auctionMember).toContain("'member_list_own_auction_submissions_page'");
  expect(auctionEdit.replace(/\s+/g,'')).toContain('member_update_own_auction_submission(uuid,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb)');
  expect(auctionMemberPage.replace(/\s+/g,'')).toContain('member_list_own_auction_submissions_page(integer,timestamptz,uuid)');
  expect(auctionMember).toContain('row.expected_price>=row.starting_price');
 });
 it('keeps Admin Product image publication aligned with the full-gallery RPC',()=>{
  expect(productAdmin).toContain("'admin_review_product_submission_with_images'");
  expect(productAdmin).toContain('p_public_image_paths:decision===\'approve\'?publicPaths:null');
  expect(productReview.replace(/\s+/g,'')).toContain('admin_review_product_submission_with_images(uuid,text,text,text[])');
  expect(productReview).toContain('cardinality(p_public_image_paths)');
 });
 it('keeps all four moderation queues on their declared bounded page contracts',()=>{
  expect(productAdmin).toContain("'admin_list_product_submissions_page'");
  expect(productAdminPage.replace(/\s+/g,'')).toContain('admin_list_product_submissions_page(integer,timestamptz,uuid)');
  expect(productMember).toContain("'member_list_own_product_submissions_page'");
  expect(productMemberPage.replace(/\s+/g,'')).toContain('member_list_own_product_submissions_page(integer,timestamptz,uuid)');
  expect(auctionAdmin).toContain("'admin_list_auction_submissions_page'");
  expect(auctionAdminPage.replace(/\s+/g,'')).toContain('admin_list_auction_submissions_page(integer,timestamptz,uuid)');
  expect(auctionAdmin).toContain('data.items');
  expect(auctionAdminPage).toContain("'items',v_rows,'has_more'");
  expect(productAdmin).toContain('row.has_more');
  expect(productMember).toContain('row.has_more');
 });
});
