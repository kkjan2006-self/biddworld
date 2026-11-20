import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const ui=readFileSync('src/components/WalletFunding.tsx','utf8');
describe('Member wallet funding history resilience',()=>{
 it('validates currency, payment reference and both timestamps',()=>{
  expect(ui).toContain("/^[A-Z]{3}$/.test(row.currency)");
  expect(ui).toContain('row.payment_reference.trim().length>=6');
  expect(ui).toContain('Number.isFinite(Date.parse(row.reviewed_at))');
 });
 it('requires consistent has-more metadata across every row in a page',()=>{
  expect(ui).toContain('row.has_more!==page[0]?.has_more');
 });
 it('prevents stale requests from clearing the current pagination lock',()=>{
  expect(ui).toContain('if(reset)pageBusy.current=false');
  expect(ui).toContain('if(seq===historyRequest.current){pageBusy.current=false;');
  expect(ui).toContain('setHistoryLoadingMore(false);return;}if(!reset&&pageBusy.current)');
 });
});
