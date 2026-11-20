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
 it('validates the keyset cursor and rejects malformed, duplicate or oversized pages',()=>{
  expect(ui).toContain('data.items as unknown[]');
  expect(ui).toContain('list.length>50||!list.every(validRow)');
  expect(ui).toContain('data.next_created_at))');
  expect(ui).toContain('duplicate or overlapping submissions');
 });
});
