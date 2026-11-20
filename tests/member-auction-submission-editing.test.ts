import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';

describe('member auction submission editing contract',()=>{
 const sql=readFileSync('supabase/migrations/20261119430000_member_auction_submission_editing.sql','utf8');
 const ui=readFileSync('src/components/MemberPlaceAuction.tsx','utf8');
 it('locks the submission to its authenticated owner and editable states',()=>{
  expect(sql).toContain('submitted_by=v_uid');
  expect(sql).toContain("v_submission.status not in ('pending','rejected')");
  expect(sql).toContain('for update');
 });
 it('revalidates the active Main ID, image ownership and expected price',()=>{
  expect(sql).toContain("m.id_type='main' and m.status='active' and p.status='active'");
  expect(sql).toContain("o.bucket_id='auction-submission-media' and o.name=v_path");
  expect(sql).toContain('p_expected_price<p_starting_price');
 });
 it('validates the returned UUID and preserves edit identity before clearing the form',()=>{
  expect(ui).toContain('submissionId');
  expect(ui).toContain('editingId&&submissionId!==editingId');
  expect(ui).toContain('The outcome may already be recorded; refresh your submission history before retrying.');
 });
 it('resets edited submissions to pending review and audits the change',()=>{
  expect(sql).toContain("status='pending',review_note=null,reviewed_by=null,reviewed_at=null");
  expect(sql).toContain("'auction.submission_edited_for_review'");
 });
 it('exposes edit and resubmit only for pending or rejected member submissions',()=>{
  expect(ui).toContain("row.status==='pending'||row.status==='rejected'");
  expect(ui).toContain("member_update_own_auction_submission");
  expect(ui).toContain('Edit & Resubmit');
 });
});
