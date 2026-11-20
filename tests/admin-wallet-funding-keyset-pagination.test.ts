import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const migration=readFileSync('supabase/migrations/20261119390000_admin_wallet_funding_queue_keyset_pagination.sql','utf8');
const component=readFileSync('src/components/AdminWalletFundingReview.tsx','utf8');
describe('Admin Main Wallet funding queue pagination',()=>{
 it('bounds every page and validates paired stable keyset cursor values',()=>{
  expect(migration).toContain('p_limit>100');
  expect(migration).toContain('(p_cursor_created_at is null)<>(p_cursor_id is null)');
  expect(migration).toContain('(r.created_at,r.id)>(p_cursor_created_at,p_cursor_id)');
  expect(migration).toContain('limit p_limit+1');
 });
 it('retains role/permission checks and returns a continuation cursor',()=>{
  expect(migration).toContain("v_role='admin'");
  expect(migration).toContain("? 'wallet_funding_review'");
  expect(migration).toContain("'next_created_at'");
  expect(migration).toContain("'next_id'");
  expect(migration).toContain('revoke all on function public.admin_list_pending_wallet_fund_requests_page');
 });
 it('uses bounded 50-row pages, validates rows and rejects duplicate IDs before appending',()=>{
  expect(component).toContain("p_limit:50");
  expect(component).toContain('items.length>50');
  expect(component).toContain('seenIds.current.has(row.id)');
  expect(component).toContain('setRows(current=>append?[...current,...items]:items)');
  expect(component).toContain('Load more requests');
 });
 it('continues to create short-lived private receipt links and requires one to approve',()=>{
  expect(component).toContain("createSignedUrl(row.receipt_path,300)");
  expect(component).toContain("if(approve&&!urls[id])");
  expect(component).toContain("admin_review_wallet_fund_request");
 });
});
