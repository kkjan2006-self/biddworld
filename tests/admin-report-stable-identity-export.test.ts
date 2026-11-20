import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin complete report stable row identity',()=>{
 it('requires an explicit stable identity key for every paged export row',()=>{
  expect(source).toContain('getRowKey:(row:T)=>string');
  expect(source).toContain('const key=getRowKey(row)');
  expect(source).not.toContain('getRowKey?:(row:T)=>string');
  expect(source).not.toContain('getRowKey?getRowKey(row):JSON.stringify(row)');
 });
 it('uses immutable record IDs for all non-withdrawal complete reports',()=>{
  for(const key of ['x.payment_id','x.tracking_id','m.member_code','x.activation_id','x.id','x.commission_id','x.auction_id','x.campaign_id','String(item.id)','x.transaction_id']) expect(source).toContain(key);
 });
 it('retains the already stable withdrawal request identity',()=>{
  expect(source).toContain('x=>x.request_id);');
 });
});
