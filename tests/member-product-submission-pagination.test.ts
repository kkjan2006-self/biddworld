import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119490000_member_product_submission_keyset_pagination.sql','utf8');
const ui=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
describe('member product submission history pagination',()=>{
 it('restricts results to the authenticated owner and validates the cursor',()=>{
  expect(sql).toContain('s.submitted_by=v_uid');
  expect(sql).toContain('(p_before_created_at is null)<>(p_before_id is null)');
  expect(sql).toContain('v_limit<1 or v_limit>100');
 });
 it('uses stable descending keyset order and a has-more marker',()=>{
  expect(sql).toContain('(s.created_at,s.id)<(p_before_created_at,p_before_id)');
  expect(sql).toContain('count(*) over() as total_count');
  expect(sql).toContain('(page.total_count>v_limit)');
 });
 it('signs images page-by-page and appends without duplicate records',()=>{
  expect(ui).toContain("'member_list_own_product_submissions_page'");
  expect(ui).toContain('setRows(previous=>reset?result:[...previous,...result])');
  expect(ui).toContain('Load more submissions');
  expect(ui).toContain('createSignedUrl(path,300)');
  expect(ui).toContain('duplicate or overlapping records');
 });
});
