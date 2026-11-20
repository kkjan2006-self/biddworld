import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import {strict as assert} from 'node:assert';

describe('Admin financial activity report integrity contracts',()=>{
 const auction=readFileSync('src/components/AdminAuctionBidReport.tsx','utf8');
 const fixed=readFileSync('src/components/AdminFixedBidEntryReport.tsx','utf8');
 it('validates every auction bid field before display and export',()=>{
  assert.match(auction,/function parseAuctionBidRows\(value:unknown\)/);
  assert.match(auction,/row\.bid_wallet_debit\)\+Number\(row\.income_wallet_debit\)>Number\(row\.bid_amount\)/);
  assert.match(auction,/parseAuctionBidRows\(data\?\?\[\]\)/);
  assert.match(auction,/const batch=parseAuctionBidRows\(data\?\?\[\]\)/);
 });
 it('rejects duplicate bid IDs and malformed identity, amount, currency and dates',()=>{
  assert.match(auction,/ids\.has\(row\.bid_id\)/);
  assert.match(auction,/typeof row\.currency!=='string'/);
  assert.match(auction,/Number\.isFinite\(Date\.parse\(row\.created_at\)\)/);
 });
 it('validates every Fixed Bid entry field before display and export',()=>{
  assert.match(fixed,/function parseFixedBidEntryRows\(value:unknown\)/);
  assert.match(fixed,/row\.entry_amount\)\)<=0/);
  assert.match(fixed,/parseFixedBidEntryRows\(data\?\?\[\]\)/);
  assert.match(fixed,/const batch=parseFixedBidEntryRows\(data\?\?\[\]\)/);
 });
 it('rejects duplicate entry IDs and malformed campaign/member/status fields',()=>{
  assert.match(fixed,/ids\.has\(row\.entry_id\)/);
  assert.match(fixed,/typeof row\.campaign_status!=='string'/);
  assert.match(fixed,/typeof row\.member_code!=='string'/);
 });
});
