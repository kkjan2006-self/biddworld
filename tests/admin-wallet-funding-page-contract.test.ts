import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/AdminWalletFundingReview.tsx','utf8');
describe('Admin wallet funding page response integrity',()=>{
 it('requires typed positive amounts and well-formed receipt/payment/currency fields',()=>{
  expect(source).toContain("typeof row.amount==='number'&&Number.isFinite(row.amount)&&row.amount>0");
  expect(source).toContain("typeof row.currency==='string'&&/^[A-Z]{3}$/.test(row.currency)");
  expect(source).toContain("row.receipt_path.trim().length>0");
  expect(source).toContain("row.payment_reference.trim().length>0");
 });
 it('requires continuation cursor to identify the final row and advance',()=>{
  expect(source).toContain('page.next_created_at!==last.created_at||page.next_id!==last.id');
  expect(source).toContain('page.next_id<=previous.id');
  expect(source).toContain('page.next_created_at!==null||page.next_id!==null');
 });
 it('serializes Load More requests',()=>{
  expect(source).toContain('if(append&&pageBusy.current)return;');
  expect(source).toContain('if(append)pageBusy.current=true;');
  expect(source).toContain('if(append)pageBusy.current=false;');
 });
});

 it('validates request UUIDs, bounded INR payment data and member-owned receipt paths',()=>{
  expect(source).toContain('FUNDING_UUID.test(row.id)');
  expect(source).toContain('isFundingReceiptPath(row.receipt_path)');
  expect(source).toContain("row.currency==='INR'");
  expect(source).toContain('row.amount<=10000000');
  expect(source).toContain('FUNDING_UUID.source.slice(1,-1)');
 });
 it('requires full continuing pages, strict order and no cursor overlap',()=>{
  expect(source).toContain('page.has_more&&items.length!==50');
  expect(source).toContain('strict ascending keyset order');
  expect(source).toContain('page overlaps or precedes its cursor');
  expect(source).toContain('page.next_id!==last.id');
 });
