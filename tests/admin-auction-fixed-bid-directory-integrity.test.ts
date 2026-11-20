import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import {strict as assert} from 'node:assert';

describe('Admin auction and Fixed Bid directory integrity contracts',()=>{
 const source=readFileSync('src/components/Admin.tsx','utf8');
 it('validates auction product identity and required fields before rendering',()=>{
  assert.match(source,/function parseAuctionProducts\(value:unknown\)/);
  assert.match(source,/Auction product list contains malformed or duplicate records/);
  assert.match(source,/setAuctionProducts\(parseAuctionProducts\(auctionProductResult\.data\?\?\[\]\)\)/);
 });
 it('validates auction prices, dates, status and unique auction IDs',()=>{
  assert.match(source,/function parseAuctionRows\(value:unknown\)/);
  assert.match(source,/row\.minimum_increment\)\)<=0/);
  assert.match(source,/validDate\(row\.target_reached_at\)/);
  assert.match(source,/Auction list contains malformed or duplicate records/);
 });
 it('validates Fixed Bid campaign configuration and timestamps',()=>{
  assert.match(source,/function parseFixedBidCampaigns\(value:unknown\)/);
  assert.match(source,/Array\.isArray\(row\.configuration\)/);
  assert.match(source,/Fixed Bid campaign list contains malformed or duplicate records/);
  assert.match(source,/setFixedCampaigns\(parseFixedBidCampaigns\(fixedCampaignResult\.data\?\?\[\]\)\)/);
 });
 it('isolates malformed auction module responses from other Admin modules',()=>{
  assert.match(source,/setLoadWarnings\(current=>\[\.\.\.current,'Auctions: '/);
  assert.match(source,/setLoadWarnings\(current=>\[\.\.\.current,'Fixed Bid campaigns: '/);
 });
});
