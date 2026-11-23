import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119620000_public_auction_catalogue_has_more.sql'),'utf8');

describe('public auction catalogue pagination',()=>{
 it('loads bounded first and continuation pages through the public RPC',()=>{
  expect(app).toContain("rpc('public_list_active_auctions_page',{p_limit:100,p_offset:0})");
  expect(app).toContain("rpc('public_list_active_auctions_page',{p_limit:100,p_offset:offset})");
  expect(app).toContain('setAuctionHasMore(rows[0]?.has_more===true)');
  expect(app).toContain('type AuctionPageRow=Auction&{has_more:boolean}');
  expect(app).not.toContain('setAuctionHasMore((data??[]).length===100)');
  expect(app).not.toContain("from('auctions').select(");
 });
 it('keeps deterministic ordering, bounded page sizes and offset validation server-side',()=>{
  expect(sql).toContain('order by a.starts_at asc,a.id desc');
  expect(sql).toContain('limit p_limit+1 offset p_offset');
  expect(sql).toContain('count(*) over()>p_limit as has_more');
  expect(sql).toContain('auctions_public_catalogue_start_idx');
  expect(sql).toContain("on public.auctions(starts_at asc,id desc)");
  expect(sql).toContain('p_limit>100');
  expect(sql).toContain('p_offset>1000000');
  expect(sql).toContain('limit p_limit;');
 });
 it('exposes only live/scheduled auctions linked to published products and valid time windows',()=>{
  expect(sql).toContain("p.status='published'");
  expect(sql).toContain("a.status='live'");
  expect(sql).toContain("a.status='scheduled'");
  expect(sql).toContain('(a.ends_at is null or a.ends_at>now())');
  expect(sql).toContain('a.starts_at<=now()');
  expect(sql).toContain('a.starts_at>now()');
 });
 it('uses a restricted SECURITY DEFINER RPC rather than anonymous table SELECT',()=>{
  expect(sql).toMatch(/security definer[\s\S]*?set search_path\s*=\s*''/i);
  expect(sql).toContain('revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated');
  expect(sql).toContain('grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated');
 });
 it('preserves race protection, Load More, accessible retry and live-only bid actions',()=>{
  expect(app).toContain('const auctionPageRequest=useRef(0)');
  expect(app).toContain('auctionPageBusy.current=true');
  expect(app).toContain('requestId!==auctionPageRequest.current');
  expect(app).toContain('Load more auctions');
  expect(app).toContain("a.status==='live'");
  expect(app).toContain('auctionLoadingMore');
  expect(app).toContain('role="alert">{auctionError}');
  expect(app).toContain('>Retry</button>');
 });
 it('fails closed on unordered, cursor-crossing or overlapping continuation pages',()=>{
  expect(app).toContain('function isStrictlyOrderedAuctionPage(rows:AuctionPageRow[]):boolean');
  expect(app).toContain('isAuctionAfter(previous,batch[0])');
  expect(app).toContain('if(batch.some(item=>known.has(item.id)))throw new Error');
  expect(app).not.toContain('duplicateFound');
  expect(app).not.toContain('fresh.filter(item=>!current.some(existing=>existing.id===item.id))');
 });
});
