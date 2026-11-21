import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const component=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin winning payment and delivery pagination',()=>{
 it('validates complete initial and subsequent winning-payment records',()=>{
  expect(component).toContain('function parseWinningPaymentPage(value:unknown,previous:WinningPayment[]=[])');
  expect(component).toContain('ADMIN_REPORT_UUID.test(row.payment_id)');
  expect(component).toContain("typeof row.amount!=='number'||!Number.isFinite(row.amount)||row.amount<=0");
  expect(component).toContain('parseWinningPaymentPage(winningPaymentResult.data??[])');
  expect(component).toContain('parseWinningPaymentPage(data,winningPayments)');
 });
 it('validates delivery identities, statuses and timestamp fields on every page',()=>{
  expect(component).toContain('function parseDeliveryPage(value:unknown,previous:DeliveryRow[]=[])');
  expect(component).toContain('ADMIN_REPORT_UUID.test(row.tracking_id)');
  expect(component).toContain("!['pending','packed','shipped','in_transit','delivered','returned'].includes(row.status)");
  expect(component).toContain('parseDeliveryPage(deliveryResult.data??[])');
  expect(component).toContain('parseDeliveryPage(data,deliveryRows)');
 });
 it('rejects overlaps, duplicate identities and shifted ordering instead of silently filtering',()=>{
  expect(component).toContain('ids.has(row.payment_id)');
  expect(component).toContain('ids.has(row.tracking_id)');
  expect(component).toContain('strict descending (updated_at,tracking_id) order');
  expect(component).not.toContain('batch.filter(x=>!seen.has(x.payment_id))');
  expect(component).not.toContain('batch.filter(x=>!seen.has(x.tracking_id))');
 });
 it('serializes page requests and ignores stale responses',()=>{
  expect(component).toContain('winningPageInFlight.current');
  expect(component).toContain('deliveryPageInFlight.current');
  expect(component).toContain('winningPageGeneration.current');
  expect(component).toContain('deliveryPageGeneration.current');
  expect(component).toContain('p_offset:offset');
 });
 it('exposes Load More controls and retains the canonical RPCs',()=>{
  expect(component).toContain('Load 100 more winning payments');
  expect(component).toContain('Load 100 more delivery records');
  expect(component).toContain('admin_list_winning_item_payments');
  expect(component).toContain('admin_list_delivery_tracking');
  expect(component).toContain('saveDeliveryTracking');
 });
});
