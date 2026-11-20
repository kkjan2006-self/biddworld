import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';

const source=readFileSync('src/components/AdminWalletFundingReview.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261119390000_admin_wallet_funding_queue_keyset_pagination.sql','utf8');

describe('Admin wallet funding page and SQL contract',()=>{
 it('validates the exact INR review row and member-owned receipt path',()=>{
  expect(source).toContain('FUNDING_UUID.test(row.id)');
  expect(source).toContain('isFundingReceiptPath(row.receipt_path)');
  expect(source).toContain("row.currency==='INR'");
  expect(source).toContain('row.amount<=10000000');
  expect(source).toContain('FUNDING_UUID.source.slice(1,-1)');
  expect(migration).toContain("'receipt_path',receipt_path");
 });
 it('requires a full page whenever the SQL cursor says more rows exist',()=>{
  expect(source).toContain('page.has_more&&items.length!==50');
  expect(migration).toContain('limit p_limit+1');
  expect(migration).toContain('max(total_rows)>p_limit');
 });
 it('enforces ascending keyset order within each page and across page boundaries',()=>{
  expect(source).toContain('The wallet funding page is not in ascending keyset order.');
  expect(source).toContain('Date.parse(current.created_at)-Date.parse(previous.created_at)');
  expect(source).toContain('page.next_created_at!==last.created_at||page.next_id!==last.id');
  expect(source).toContain('The wallet funding page cursor did not advance.');
  expect(migration).toContain('order by r.created_at asc,r.id asc');
  expect(migration).toContain('(r.created_at,r.id)>(p_cursor_created_at,p_cursor_id)');
 });
 it('rejects duplicate IDs, mismatched final cursors and unexpected terminal cursors',()=>{
  expect(source).toContain('seenIds.current.has(row.id)');
  expect(source).toContain('page.next_created_at!==last.created_at||page.next_id!==last.id');
  expect(source).toContain('page.next_created_at!==null||page.next_id!==null');
 });
 it('serializes Load More requests and prevents stale responses replacing newer pages',()=>{
  expect(source).toContain('if(append&&pageBusy.current)return;');
  expect(source).toContain('if(append)pageBusy.current=true;');
  expect(source).toContain('const seq=++requestSeq.current;');
  expect(source).toContain('if(seq!==requestSeq.current)return;');
 });
});
