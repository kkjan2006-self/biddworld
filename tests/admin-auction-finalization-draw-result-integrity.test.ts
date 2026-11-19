import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin auction finalization and Fixed Bid draw result contracts',()=>{
 it('checks the Fixed Bid draw success flag, campaign identity and settlement totals',()=>{
  expect(source).toContain("result.success!==true||result.campaign_id!==c.campaign_id");
  expect(source).toContain('Number.isInteger(result.winner_count)||result.winner_count<1');
  expect(source).toContain('Number.isInteger(result.refunded_entries)||result.refunded_entries<0');
  expect(source).toContain('The Fixed Bid draw result did not match the expected campaign and settlement totals.');
 });
 it('checks auction finalization identity and consistent winner fields',()=>{
  expect(source).toContain("result.success!==true||result.auction_id!==auction.auction_id");
  expect(source).toContain('(result.winner_member_id===null)!==(result.winning_amount===null)');
  expect(source).toContain('(result.winner_member_id===null)!==(result.winning_bid_id===null)');
  expect(source).toContain('The auction finalization result did not match the expected winner record.');
 });
 it('does not coerce missing settlement fields into plausible zero values',()=>{
  expect(source).not.toContain("Number(result.winner_count??0)");
  expect(source).not.toContain("Number(result.refunded_entries??0)");
  expect(source).not.toContain("Number(result.winning_amount??0)");
 });
});
