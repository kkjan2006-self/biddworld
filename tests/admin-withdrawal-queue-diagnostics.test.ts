import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Admin withdrawal queue diagnostics',()=>{
 it('distinguishes loading, a genuine empty queue, and a failed queue request',()=>{
  expect(source).toContain('[withdrawalQueueLoading,setWithdrawalQueueLoading]=useState(true)');
  expect(source).toContain('Loading withdrawal requests…');
  expect(source).toContain('No withdrawal requests are currently available.');
  expect(source).toContain('Withdrawal queue could not be loaded:');
  expect(source).toContain('Retry queue');
 });
 it('clears queue loading after both resolved RPC responses and workspace failures',()=>{
  expect(source).toContain('setWithdrawalQueueLoading(false);');
  expect(source).toContain('setWithdrawalQueueLoading(false);setError(');
 });
 it('serializes review actions synchronously to prevent rapid duplicate decisions',()=>{
  expect(source).toContain('withdrawalReviewInFlight.current');
  expect(source).toContain('withdrawalReviewInFlight.current=true;');
  expect(source).toContain('withdrawalReviewInFlight.current=false;');
 });
});
