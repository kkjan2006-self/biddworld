import {readFileSync} from 'node:fs';
import {describe,it} from 'node:test';
import assert from 'node:assert/strict';
const admin=readFileSync('src/components/Admin.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261119160000_admin_auction_expected_price_lifecycle.sql','utf8');
describe('Admin auction expected-price lifecycle contract',()=>{
 it('requires Expected Price and removes fixed planned end-time input',()=>{
  assert.match(admin,/Expected Price \(INR\)/);
  assert.match(admin,/Number\(auctionExpectedPrice\)<Number\(auctionStartingPrice\)/);
  assert.doesNotMatch(admin,/Planned End \(optional\)/);
 });
 it('sends expected price to the Admin RPC and resets it after save',()=>{
  assert.match(admin,/p_expected_price:Number\(auctionExpectedPrice\)/);
  assert.match(admin,/setAuctionExpectedPrice\('0'\)/);
 });
 it('keeps end time derived by the 48-hour expected-price trigger',()=>{
  assert.match(migration,/expected_price=p_expected_price/);
  assert.match(migration,/ends_at=null/);
  assert.match(migration,/p_expected_price<p_starting_price/);\n  assert.match(migration,/before update of current_price,status/);\n  assert.match(migration,/new.status='live'/);
 });
});
