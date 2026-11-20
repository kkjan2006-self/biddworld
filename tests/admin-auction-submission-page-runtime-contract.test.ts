import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/AdminAuctionSubmissionReview.tsx','utf8');
describe('Admin auction submission queue response contract',()=>{
 it('validates listing fields, all private image paths and optional details before signing URLs',()=>{
  expect(ui).toContain('function validRow(value:unknown):value is Row');
  expect(ui).toContain('row.image_paths.length>=1&&row.image_paths.length<=8');
  expect(ui).toContain('row.expected_price>=row.starting_price');
  expect(ui).toContain('row.submitted_by.trim().length>0');
 });
 it('validates continuation boundaries, full-page cursors and terminal cursor absence',()=>{
  expect(ui).toContain('if(data.has_more&&(list.length!==50');
  expect(ui).toContain('list[list.length-1].created_at!==data.next_created_at');
  expect(ui).toContain('if(after&&list.length){const first=list[0] as Row');
  expect(ui).toContain('first.id.localeCompare(after.id)<=0');
  expect(ui).toContain('did not continue strictly after the previous cursor');
  expect(ui).toContain('data.next_created_at!==null||data.next_id!==null');
 });
 it('validates the keyset cursor and rejects malformed, duplicate or oversized pages',()=>{
  expect(ui).toContain('data.items as unknown[]');
  expect(ui).toContain('list.length>50||!list.every(validRow)');
  expect(ui).toContain('data.next_created_at))');
  expect(ui).toContain('duplicate or overlapping submissions');
 });
});
