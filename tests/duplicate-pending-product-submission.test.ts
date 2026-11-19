import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119540000_prevent_duplicate_pending_product_submissions.sql','utf8');
const ui=readFileSync('src/components/MemberProductSubmission.tsx','utf8');
describe('duplicate pending product submission protection',()=>{
 it('serializes same-member submissions and indexes pending normalized titles',()=>{
  expect(sql).toContain('product_submissions_owner_pending_name_idx');
  expect(sql).toContain("pg_catalog.hashtextextended('biddworld.product_submission:'||v_uid::text,0)");
 });
 it('rejects an existing pending normalized title on both create and edit paths',()=>{
  expect(sql).toContain('A pending product submission with this name already exists');
  expect(sql).toContain('Another pending product submission with this name already exists');
  expect(sql).toContain('s.id<>p_submission_id');
 });
 it('keeps client-side duplicate-submit lock and editable image retention',()=>{
  expect(ui).toContain('inFlight.current');
  expect(ui).toContain('files.length?uploaded:(current?.image_paths??[])');
 });
});
