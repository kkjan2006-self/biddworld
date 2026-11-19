import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119120000_member_auction_submission_moderation.sql'),'utf8');
const member=readFileSync(resolve(process.cwd(),'src/components/MemberPlaceAuction.tsx'),'utf8');
const staff=readFileSync(resolve(process.cwd(),'src/components/AdminAuctionSubmissionReview.tsx'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('Member auction submission and moderation',()=>{
 it('requires an active Main ID, images, price and valid future schedule',()=>{
  expect(sql).toContain("m.id_type='main' and m.status='active' and p.status='active'");
  expect(sql).toContain('cardinality(p_image_paths)<1');
  expect(sql).toContain('p_starts_at<now()+interval');
  expect(sql).toContain('ends_at>starts_at');
 });
 it('keeps submissions private and pending until review',()=>{
  expect(sql).toContain("status text not null default 'pending'");
  expect(sql).toContain('revoke all on public.auction_submissions');
  expect(sql).toContain("where s.status='pending'");
  expect(sql).toContain("status='approved'");
  expect(sql).toContain("status='rejected'");
 });
 it('requires Admin or explicit auction review staff permission',()=>{
  expect(sql).toContain("? 'auction_submission_review'");
  expect(sql).toContain('admin_review_auction_submission');
 });
 it('provides member submission UI and editable staff review controls',()=>{
  expect(member).toContain('Place an Auction');
  expect(member).toContain('Pending Admin Approval');
  expect(member).toContain('member_submit_auction');
  expect(staff).toContain('Approve & Publish');
  expect(staff).toContain('admin_review_auction_submission');
  expect(staff).toContain('p_title:');
  expect(app).toContain("import('./components/MemberPlaceAuction')");
 });
});
