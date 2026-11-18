import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const component=readFileSync(resolve(process.cwd(),'src/components/FixedBid.tsx'),'utf8');
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118290000_public_fixed_bid_catalogue_page.sql'),'utf8');

describe('public Fixed Bid campaign catalogue',()=>{
 it('uses the paginated public RPC instead of direct table SELECT',()=>{
  expect(component).toContain("rpc('public_list_fixed_bid_campaigns_page'");
  expect(component).toContain('p_search:searchTerm.trim()||null');
  expect(component).toContain('p_status:status');
  expect(component).toContain('p_limit:PAGE_SIZE');
  expect(component).toContain('p_offset:offset');
  expect(component).not.toContain("from('fixed_bid_campaigns').select(");
  expect(component).not.toContain('escapeLikePattern');
 });
 it('returns only published-product scheduled, live and ended campaigns with valid active time windows',()=>{
  expect(sql).toContain("p.status = 'published'");
  expect(sql).toContain("c.status in ('scheduled', 'live', 'ended')");
  expect(sql).toContain("c.status = 'ended'");
  expect(sql).toContain("c.status = 'scheduled'");
  expect(sql).toContain("c.status = 'live'");
  expect(sql).toContain("p_status not in ('all', 'scheduled', 'live', 'ended')");
  expect(sql).toContain("c.configuration->>'starts_at'");
  expect(sql).toContain("c.configuration->>'ends_at'");
 });
 it('exposes only member-facing configuration and product fields',()=>{
  expect(sql).toContain("'entry_amount'");
  expect(sql).toContain("'winner_payment_amount'");
  expect(sql).toContain("'max_entries_per_member'");
  expect(sql).toContain("'winner_count'");
  expect(sql).toContain("'image_path'");
  expect(sql).not.toContain("'refund_non_winners'");
  expect(sql).not.toContain("'max_entries_total'");
 });
 it('validates bounded search and pagination and grants only the RPC to public roles',()=>{
  expect(sql).toContain('length(v_search) > 100');
  expect(sql).toContain('p_limit > 50');
  expect(sql).toContain('p_offset > 1000000');
  expect(sql).toContain('order by c.created_at desc, c.id desc');
  expect(sql).toContain('revoke all on function public.public_list_fixed_bid_campaigns_page(text,text,integer,integer) from public, anon, authenticated');
  expect(sql).toContain('grant execute on function public.public_list_fixed_bid_campaigns_page(text,text,integer,integer) to anon, authenticated');
 });
});
