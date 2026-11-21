import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119580000_member_auction_submission_history_pagination.sql','utf8');
const ui=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
describe('Member auction submission history pagination',()=>{
 it('scopes all pages to the signed-in submitter and bounds the page size',()=>{
  expect(sql).toContain('where s.submitted_by=v_uid');
  expect(sql).toContain('v_limit<1 or v_limit>100');
  expect(sql).toContain('(s.created_at,s.id)<(p_before_created_at,p_before_id)');
 });
 it('returns stable newest-first pages and a has-more marker',()=>{
  expect(sql).toContain('count(*) over() as total_count');
  expect(sql).toContain('(page.total_count>v_limit)');
  expect(sql).toContain('order by page.created_at desc,page.id desc');
 });
 it('validates, appends and exposes subsequent Member history pages',()=>{
  expect(ui).toContain("'member_list_own_auction_submissions_page'");
  expect(ui).toContain('function validSubmission(value:unknown)');
  expect(ui).toContain('duplicate or overlapping records');
  expect(ui).toContain('function isStrictlyDescendingSubmissionPage(rows:Submission[]):boolean');
  expect(ui).toContain('function isBeforeSubmissionCursor(row:Submission,cursor:Pick<Submission,\'created_at\'|\'id\'>):boolean');
  expect(ui).toContain('function hasConsistentSubmissionContinuation(rows:Submission[]):boolean');
  expect(ui).toContain('crossed or repeated its previous cursor');
  expect(ui).toContain('inconsistent or incomplete continuation marker');
  expect(ui).toContain('Load more submissions');
  expect(ui).toContain('onClick={()=>void load(rows.length>0)}');
  expect(ui).toContain('{rows.map(row=><article');
 });
});
