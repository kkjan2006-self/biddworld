import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const fixed=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118080000_fixed_bid_campaign_entry_draw_settlement.sql'),'utf8');
const auction=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118110000_auction_lifecycle_winner_settlement.sql'),'utf8');

describe('Auction and Fixed Bid cancellation refund ledger integrity',()=>{
 it('validates Fixed Bid source debits against the owning member and wallet',()=>{
  expect(fixed).toContain("v_wallet.member_id is distinct from v_entry.member_id");
  expect(fixed).toContain("v_debit.transaction_type is distinct from 'fixed_bid_entry'");
  expect(fixed).toContain("v_debit.reference_id is distinct from v_entry.id");
 });
 it('validates a pre-existing Fixed Bid refund key instead of treating key presence as success',()=>{
  expect(fixed).toContain("v_existing.transaction_type is distinct from 'fixed_bid_refund'");
  expect(fixed).toContain("v_existing.direction is distinct from 'credit'");
  expect(fixed).toContain("Fixed Bid refund idempotency key conflicts with a different ledger transaction");
 });
 it('validates Auction source debits and reconciles them to the recorded bid amount',()=>{
  expect(auction).toContain("v_tx.transaction_type is distinct from 'auction_bid'");
  expect(auction).toContain("v_tx.reference_id is distinct from p_auction_id");
  expect(auction).toContain('v_debit_total<>v_bid.bid_amount');
 });
 it('validates replayed Auction refund keys before skipping duplicate credits',()=>{
  expect(auction).toContain("v_existing.transaction_type is distinct from 'auction_bid_refund'");
  expect(auction).toContain("v_existing.direction is distinct from 'credit'");
  expect(auction).toContain("Auction refund idempotency key conflicts with a different ledger transaction");
 });
});
