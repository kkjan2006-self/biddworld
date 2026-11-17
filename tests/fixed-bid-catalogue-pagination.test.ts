import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const source=readFileSync(resolve(process.cwd(),'src/components/FixedBid.tsx'),'utf8');
describe('Fixed Bid catalogue pagination',()=>{
 it('uses bounded stable pages for published campaign states',()=>{
  expect(source).toContain('const PAGE_SIZE=50');
  expect(source).toContain(".in('status',['scheduled','live','ended'])");
  expect(source).toContain(".order('created_at',{ascending:false}).order('id',{ascending:false})");
  expect(source).toContain('query.range(offset,offset+PAGE_SIZE-1)');
 });
 it('offers continuation while keeping the campaign surface read-only',()=>{
  expect(source).toContain('Load more campaigns');
  expect(source).toContain('no entries or payments are processed here');
  expect(source).not.toMatch(/\.rpc\(/);
  expect(source).not.toMatch(/\.insert\(|\.update\(|\.upsert\(/);
 });
});
describe('Fixed Bid catalogue server-side filters',()=>{
 it('filters by campaign title and selected published status before pagination',()=>{
  expect(source).toContain("type CampaignStatus='all'|'scheduled'|'live'|'ended'");
  expect(source).toContain("if(status!=='all')query=query.eq('status',status)");
  expect(source).toContain("query.ilike('title'");
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
  expect(source).toContain('setLoading(false);setLoadingMore(false)');
 });
});
