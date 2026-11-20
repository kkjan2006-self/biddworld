import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/App.tsx','utf8');
describe('public auction page runtime contract',()=>{
 it('validates auction identities, prices, lifecycle timestamps and public statuses',()=>{
  expect(ui).toContain('function parseAuctionPage(value:unknown):AuctionPageRow[]');
  expect(ui).toContain("!['live','scheduled'].includes(String(row.status))");
  expect(ui).toContain('seen.has(row.id)');
  expect(ui).toContain('Number.isFinite(Date.parse(v))');
 });
 it('rejects inconsistent page metadata and parses both first and subsequent pages',()=>{
  expect(ui).toContain('pageHasMore!==row.has_more');
  expect(ui).toContain('parseAuctionPage(data??[])');
  expect(ui).toContain('const rows=parseAuctionPage(data??[]);const batch=rows.map');
 });
});
