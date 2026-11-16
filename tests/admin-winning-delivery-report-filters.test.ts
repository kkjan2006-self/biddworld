import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
describe('Complete Admin winning payment and delivery report filters',()=>{
 it('filters all paginated winning payment records before CSV mapping',()=>{
  const fn=admin.slice(admin.indexOf('function exportWinningPaymentsCsv'),admin.indexOf('function exportDeliveryCsv'));
  expect(fn).toContain('admin_list_winning_item_payments');expect(fn).toContain('items.filter(x=>');
  expect(fn).toContain('winningReportStatus');expect(fn).toContain('winningReportFrom');expect(fn).toContain('winningReportTo');expect(fn).toContain('winningReportSearch');
 });
 it('filters all paginated delivery records before CSV mapping',()=>{
  const fn=admin.slice(admin.indexOf('function exportDeliveryCsv'),admin.indexOf('function exportAuctionsCsv'));
  expect(fn).toContain('admin_list_delivery_tracking');expect(fn).toContain('items.filter(x=>');
  expect(fn).toContain('deliveryReportStatus');expect(fn).toContain('deliveryReportFrom');expect(fn).toContain('deliveryReportTo');expect(fn).toContain('deliveryReportSearch');
 });
 it('keeps both report controls and exports labelled as filtered complete exports',()=>{
  expect(admin).toContain('Export Filtered Complete Winning Payments CSV');expect(admin).toContain('Export Filtered Complete Delivery CSV');
 });
});
