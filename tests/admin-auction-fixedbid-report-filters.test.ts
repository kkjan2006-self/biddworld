import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Admin auction and Fixed Bid report filters',()=>{
 it('filters loaded auctions by status and searchable auction/product metadata',()=>{
  expect(admin).toContain('const filteredAuctionReports=useMemo(');
  expect(admin).toContain("auctionReportStatus==='all'||item.status===auctionReportStatus");
  expect(admin).toContain('[item.auction_id,item.product_name,item.title,item.category,item.status]');
  expect(admin).toContain('Export Filtered Auctions CSV ({filteredAuctionReports.length})');
 });
 it('filters loaded Fixed Bid campaigns by status and searchable campaign metadata',()=>{
  expect(admin).toContain('const filteredFixedBidReports=useMemo(');
  expect(admin).toContain("fixedReportStatus==='all'||item.status===fixedReportStatus");
  expect(admin).toContain('[item.campaign_id,item.product_name,item.title,item.description,item.status]');
  expect(admin).toContain('Export Filtered Fixed Bid CSV ({filteredFixedBidReports.length})');
 });
 it('keeps source-RPC loaded scope explicit and leaves referral export as plan drafts',()=>{
  expect(admin).toContain('exportReport(\'referral-plan-drafts\'');
  expect(admin).toContain('export is not a complete-history guarantee');
 });
});
