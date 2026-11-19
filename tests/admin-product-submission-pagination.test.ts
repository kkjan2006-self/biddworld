import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119470000_admin_product_submission_keyset_pagination.sql','utf8');
const ui=readFileSync('src/components/AdminProductSubmissionReview.tsx','utf8');
describe('Admin product submission keyset pagination',()=>{
 it('restricts the queue to Admin and validates bounded paired cursor inputs',()=>{
  expect(sql).toContain("'admin'");
  expect(sql).toContain('v_limit<1 or v_limit>100');
  expect(sql).toContain('(p_before_created_at is null)<>(p_before_id is null)');
 });
 it('uses a stable created_at/id keyset and reports whether another page exists',()=>{
  expect(sql).toContain('(s.created_at,s.id)>(p_before_created_at,p_before_id)');
  expect(sql).toContain('count(*) over() as total_count');
  expect(sql).toContain('(page.total_count>v_limit)');
 });
 it('loads and appends pages without losing existing signed image URLs',()=>{
  expect(ui).toContain("'admin_list_product_submissions_page'");
  expect(ui).toContain('setRows(previous=>reset?items:[...previous,...items])');
  expect(ui).toContain('Load more pending submissions');
 });
});
