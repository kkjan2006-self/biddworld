import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const admin=readFileSync('src/components/Admin.tsx','utf8');
const migration=readFileSync('supabase/migrations/20261119160000_admin_auction_expected_price_lifecycle.sql','utf8');
describe('Admin auction expected-price lifecycle contract',()=>{
 it('requires Expected Price and removes fixed planned end-time input',()=>{
  expect(admin).toMatch(/Expected Price \(INR\)/);
  expect(admin).toMatch(/Number\(auctionExpectedPrice\)<Number\(auctionStartingPrice\)/);
  expect(admin).not.toMatch(/Planned End \(optional\)/);
 });
 it('sends expected price to the Admin RPC and resets it after save',()=>{
  expect(admin).toMatch(/p_expected_price:Number\(auctionExpectedPrice\)/);
  expect(admin).toMatch(/setAuctionExpectedPrice\('0'\)/);
 });
 it('keeps end time derived by the 48-hour expected-price trigger',()=>{
  expect(migration).toMatch(/expected_price=p_expected_price/);
  expect(migration).toMatch(/ends_at=null/);
  expect(migration).toMatch(/p_expected_price<p_starting_price/);
  expect(migration).toMatch(/before update of current_price,status/);
  expect(migration).toMatch(/new.status='live'/);
  expect(migration).toMatch(/new.current_price>=new.expected_price/);
 });
});
