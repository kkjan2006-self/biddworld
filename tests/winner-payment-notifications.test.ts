import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const sql=readFileSync('supabase/migrations/20261119590000_winner_payment_notifications.sql','utf8');
describe('Auction and Fixed Bid winner notifications',()=>{
 it('notifies a winner when the pending payment is created for either workflow',()=>{
  expect(sql).toContain("if tg_op='INSERT' then");
  expect(sql).toContain("new.auction_id is not null");
  expect(sql).toContain("new.fixed_bid_campaign_id is not null");
  expect(sql).toContain("new.status<>'pending'");
 });
 it('notifies payment completion and refund status changes',()=>{
  expect(sql).toContain("new.status='paid'");
  expect(sql).toContain("new.status='refunded'");
  expect(sql).toContain('new.winner_member_id');
 });
 it('respects the Notifications feature switch and uses a private trigger',()=>{
  expect(sql).toContain("where setting_key='notifications_enabled'");
  expect(sql).toContain('if not coalesce(v_notifications_enabled,false) then return new;end if;');
  expect(sql).toContain("set search_path=''");
  expect(sql).toContain('revoke all on function private.notify_member_winning_item_payment_status() from public,anon,authenticated');
  expect(sql).toContain('after insert or update of status on public.winning_item_payments');
 });
});
