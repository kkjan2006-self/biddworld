import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119510000_member_wallet_funding_history_pagination.sql','utf8');
const ui=readFileSync('src/components/WalletFunding.tsx','utf8');
describe('member wallet funding history pagination',()=>{
 it('restricts history to the signed-in member Main ID',()=>{
  expect(sql).toContain('select main_member_id into v_main from public.profiles where id=v_uid');
  expect(sql).toContain('where r.member_id=v_main');
 });
 it('uses a bounded descending keyset cursor and has-more marker',()=>{
  expect(sql).toContain('v_limit<1 or v_limit>100');
  expect(sql).toContain('(r.created_at,r.id)<(p_before_created_at,p_before_id)');
  expect(sql).toContain('count(*) over() as total_count');
  expect(sql).toContain('(page.total_count>v_limit)');
 });
 it('loads and appends validated history pages without duplicates',()=>{
  expect(ui).toContain("'member_list_my_wallet_fund_requests_page'");
  expect(ui).toContain('setRows(current=>reset?page:[...current,...page])');
  expect(ui).toContain('Load more requests');
  expect(ui).toContain('duplicate or overlapping requests');
 });
});
