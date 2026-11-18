import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/FixedBid.tsx'),'utf8');
describe('Fixed Bid catalogue pagination',()=>{
 it('uses bounded stable pages through the public catalogue RPC',()=>{
  expect(source).toContain('const PAGE_SIZE=50');
  expect(source).toContain("rpc('public_list_fixed_bid_campaigns_page',{p_search:searchTerm.trim()||null,p_status:status,p_limit:PAGE_SIZE,p_offset:offset})");
  expect(source).not.toContain("from('fixed_bid_campaigns').select(");
  expect(source).toContain('setHasMore(batch.length===PAGE_SIZE)');
 });
 it('offers continuation and sends participation through the idempotent server workflow',()=>{
  expect(source).toContain('Load more campaigns');
  expect(source).toContain("supabase.rpc('member_join_fixed_bid_campaign',{p_campaign_id:campaign.id,p_idempotency_key:key})");
  expect(source).toContain("const canJoin=r.status==='live'");
  expect(source).toContain('entryKeys.current.get(campaign.id)');
  expect(source).toContain('result.replayed?');
  expect(source).not.toContain('.insert(');
  expect(source).not.toContain('.update(');
  expect(source).not.toContain('.upsert(');
 });
});
describe('Fixed Bid catalogue server-side filters',()=>{
 it('sends title search and selected status before pagination',()=>{
  expect(source).toContain("type CampaignStatus='all'|'scheduled'|'live'|'ended'");
  expect(source).toContain('p_search:searchTerm.trim()||null');
  expect(source).toContain('p_status:status');
  expect(source).toContain('load(true,search,statusFilter)');
  expect(source).toContain('No campaigns match these filters.');
 });
});
describe('Fixed Bid catalogue request lifecycle',()=>{
 it('invalidates stale filter requests and ignores unmounted responses',()=>{
  expect(source).toContain('const timer=window.setTimeout(()=>void load(true,search,statusFilter)');
  expect(source).toContain('requestId.current+=1');
  expect(source).toContain('if(!mounted.current||request!==requestId.current)return');
 });
 it('prevents overlapping continuation requests and releases their lock',()=>{
  expect(source).toContain('requestInFlight.current||loadingMore||!hasMore');
  expect(source).toContain('requestInFlight.current=false');
  expect(source).toContain('if(!reset&&request===requestId.current)requestInFlight.current=false');
  expect(source).toContain('if(reset){requestInFlight.current=false;setLoading(true)');
  expect(source).toContain('setLoading(false);setLoadingMore(false)');
 });
});


const fixedBidProjection=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119000000_fixed_bid_public_rules_projection.sql'),'utf8');
describe('Fixed Bid public campaign rules projection',()=>{
 it('exposes the published entry limits and refund rule required by the Member catalogue',()=>{
  for(const key of ['entry_amount','winner_payment_amount','max_entries_per_member','max_entries_total','winner_count','starts_at','ends_at','refund_non_winners']){
   expect(fixedBidProjection).toContain(`'${key}', c.configuration->'${key}'`);
  }
  expect(fixedBidProjection).toContain("where p.status = 'published'");
  expect(fixedBidProjection).toContain("c.status in ('scheduled', 'live', 'ended')");
  expect(fixedBidProjection).toContain('limit p_limit');
  expect(fixedBidProjection).toContain('offset p_offset');
  expect(fixedBidProjection).toContain('set search_path = \'\'');
  expect(fixedBidProjection).toContain('to anon, authenticated;');
 });
});
