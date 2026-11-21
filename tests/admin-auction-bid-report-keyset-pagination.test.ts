import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const component=readFileSync(resolve(process.cwd(),'src/components/AdminAuctionBidReport.tsx'),'utf8');
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119040000_admin_auction_bid_report_keyset_pagination.sql'),'utf8');

describe('Admin auction bid report keyset pagination',()=>{
 it('uses the bounded cursor RPC for page loading and complete CSV export',()=>{
  expect(component).toContain("admin_list_auction_bids_cursor_page");
  expect(component).toContain('p_after_created_at:cursor?.created_at??null');
  expect(component).toContain('p_after_id:cursor?.id??null');
  expect(component).toContain('p_limit:PAGE_SIZE+1');
  expect(component).not.toContain('p_offset:offset');
 });
 it('validates the look-ahead row count, strict page ordering and cursor boundaries',()=>{
  expect(component).toContain('value.length>PAGE_SIZE+1');
  expect(component).toContain('isStrictlyDescendingAuctionBidPage(fetched)');
  expect(component).toContain('isBeforeAuctionBidCursor(row,cursor)');
  expect(component).toContain('isStrictlyDescendingAuctionBidPage(batch)');
  expect(component).toContain('isBeforeAuctionBidCursor(row,cursor!)');
 });
 it('uses the stable descending created_at/id tuple and preserves Admin-only access',()=>{
  expect(migration).toContain('(b.created_at,b.id)<(p_after_created_at,p_after_id)');
  expect(migration).toContain('order by b.created_at desc,b.id desc');
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(migration).toContain('set search_path=\'\'');
  expect(migration).not.toContain('idempotency_key');
 });
});
