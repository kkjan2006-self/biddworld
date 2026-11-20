import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const ui=read('src/components/Admin.tsx');
const fixed=read('supabase/migrations/20261118080000_fixed_bid_campaign_entry_draw_settlement.sql');
const auction=read('supabase/migrations/20261118110000_auction_lifecycle_winner_settlement.sql');
describe('Admin Auction and Fixed Bid mutation response integrity',()=>{
 it('validates the returned Fixed Bid draft ID before clearing the editor',()=>{
  expect(ui).toContain("typeof data!=='string'||!data.trim()||(wasEditing&&data!==editingFixedCampaignId)");
  expect(fixed).toContain(') returns uuid');
  expect(fixed).toContain('return v_id;');
 });
 it('validates Fixed Bid campaign status and refund count against the selected campaign',()=>{
  expect(ui).toContain('result.campaign_id!==c.campaign_id');
  expect(ui).toContain('result.status!==status');
  expect(ui).toContain('result.refunded_entries');
  expect(fixed).toContain("'campaign_id',p_campaign_id,'status',p_status,'refunded_entries',v_refunded");
 });
 it('validates Auction status identity, requested state and refunded bid count',()=>{
  expect(ui).toContain('result.auction_id!==auction.auction_id');
  expect(ui).toContain('result.refunded_bids');
  expect(auction).toContain("'success',true,'auction_id',p_auction_id,'status',p_status,'refunded_bids',v_refunded");
 });
});
