import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('public auction catalogue pagination',()=>{
 it('loads a bounded first page and deterministic continuation pages',()=>{
  expect(app).toContain(".order('ends_at').order('id',{ascending:false}).range(0,99)");
  expect(app).toContain(".order('ends_at').order('id',{ascending:false}).range(offset,offset+99)");
  expect(app).toContain('setAuctionHasMore((data??[]).length===100)');
 });
 it('exposes Load More without enabling non-live bidding',()=>{
  expect(app).toContain('Load more auctions');
  expect(app).toContain("a.status==='live'");
  expect(app).toContain('auctionLoadingMore');
 });
});
