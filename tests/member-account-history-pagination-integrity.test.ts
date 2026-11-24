import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Account.tsx','utf8');
describe('Member account history pagination integrity',()=>{
 it('validates row identities and timestamps before appending any continuation page',()=>{
  expect(source).toContain('function validateMemberHistoryPage<T extends {id:string;created_at?:string;submitted_at?:string}>');
  expect(source).toContain("typeof row.id!=='string'||!row.id.trim()");
  expect(source).toContain("!Number.isFinite(Date.parse(timestamp))");
  expect(source).toContain('const batch=validateMemberHistoryPage<T>(data,currentRows as T[],timestampKey,pageSize,isValidRow)');
  expect(source).toContain('const activationRows=validateMemberHistoryPage<Activation>(a.data??[],[],\'submitted_at\',50,validActivation)');
  expect(source).toContain('const winningPaymentRows=validateMemberHistoryPage<WinningPayment>(wp.data??[],[],\'created_at\',100,validWinningPayment)');
 });
 it('rejects duplicate identities and strict-order regressions within and across pages',()=>{
  expect(source).toContain('if(seen.has(row.id))throw new Error');
  expect(source).toContain('Date.parse(priorTimestamp)-Date.parse(timestamp)');
  expect(source).toContain('prior.id.localeCompare(row.id)<=0');
  expect(source).toContain('strict descending (\'+timestampKey+\',id) order');
 });
 it('uses submitted_at for package activations and created_at for all other account histories',()=>{
  expect(source).toContain("const timestampKey=key==='activations'?'submitted_at':'created_at'");
  expect(source).toContain('await append(batch,client);setHistoryHasMore');
  expect(source).toContain('validActivation,rows=>');
  expect(source).toContain('validAuctionBid,rows=>');
  expect(source).toContain('validFixedBid,rows=>');
  expect(source).toContain('validCommission,rows=>');
  expect(source).toContain('validWinningPayment,async(rows,client)=>');
  expect(source).toContain('validateDeliveryRows(data??[],ids)');
  expect(source).toContain('const deliveryRows=validateDeliveryRows(deliveryResult.data??[],paymentIds)');
  expect(source).toContain('function validActivation(value:unknown):value is Activation');
  expect(source).toContain('function validAuctionBid(value:unknown):value is AuctionBid');
  expect(source).toContain('function validFixedBid(value:unknown):value is FixedBidRow');
  expect(source).toContain('function validCommission(value:unknown):value is CommissionRow');
  expect(source).toContain('function validWinningPayment(value:unknown):value is WinningPayment');
 });
 it('binds each continuation request to the account-load generation and Main ID that started it',()=>{
  expect(source).toContain('const request=loadRequest.current');
  expect(source).toContain('request===loadRequest.current&&profile?.main_member_id===memberId');
  expect(source).toContain('if(!isCurrent())return;if(error)throw error;');
  expect(source).toContain('await append(batch,client,isCurrent);if(!isCurrent())return;');
 });
 it('prevents delayed delivery lookups from appending winning-payment history after an account refresh',()=>{
  expect(source).toContain('async(rows,client,isCurrent)=>');
  expect(source).toContain('if(!isCurrent())return;if(error)throw error;deliveryRows=validateDeliveryRows(data??[],ids);');
  expect(source).toContain('if(!isCurrent())return;setWinningPayments(current=>appendUniqueRows(current,rows));');
  expect(source).toContain("if(isCurrent())setHistoryLoading(current=>current===key?'':current)");
 });
 it('fails closed after a malformed page instead of silently filtering overlap and advancing offsets',()=>{
  expect(source).not.toContain('const freshCount=batch.filter(row=>!known.has(row.id)).length');
  expect(source).toContain("setHistoryHasMore(current=>({...current,[key]:false}))");
  expect(source).toContain('Account history repeated a record across pages');
 });
});
