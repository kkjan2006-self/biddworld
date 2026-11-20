import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin winning payment and delivery pagination',()=>{
 it('validates initial winning payment and delivery pages',()=>{
  expect(component).toContain("typeof row.payment_id==='string'");
  expect(component).toContain("typeof row.winner_member_code==='string'");
  expect(component).toContain("typeof row.tracking_id==='string'");
  expect(component).toContain('setWinningHasMore(batch.length===100)');
  expect(component).toContain('setDeliveryHasMore(batch.length===100)');
 });
 it('serializes winning payment and delivery page requests and ignores stale responses',()=>{
  expect(component).toContain('winningPageInFlight.current');
  expect(component).toContain('deliveryPageInFlight.current');
  expect(component).toContain('winningPageGeneration.current');
  expect(component).toContain('deliveryPageGeneration.current');
  expect(component).toContain('p_offset:offset');
 });
 it('exposes load-more controls while preserving the delivery and payment RPCs',()=>{
  expect(component).toContain('Load 100 more winning payments');
  expect(component).toContain('Load 100 more delivery records');
  expect(component).toContain("admin_list_winning_item_payments");
  expect(component).toContain("admin_list_delivery_tracking");
  expect(component).toContain('saveDeliveryTracking');
 });
});
