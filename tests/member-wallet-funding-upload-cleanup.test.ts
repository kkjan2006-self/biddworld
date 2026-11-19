import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const source=readFileSync(resolve(process.cwd(),'src/components/WalletFunding.tsx'),'utf8');

describe('Member wallet funding receipt cleanup',()=>{
 it('tracks the uploaded private receipt and definite RPC rejection separately',()=>{
  expect(source).toContain('let uploadedReceiptPath:string|null=null');
  expect(source).toContain('let rpcAttempted=false');
  expect(source).toContain("rpcDefinitelyRejected=typeof (error as {code?:unknown}).code==='string'");
 });
 it('removes the receipt only after a definite submission rejection',()=>{
  expect(source).toContain('uploadedReceiptPath&&rpcAttempted&&rpcDefinitelyRejected');
  expect(source).toContain("storage.from('wallet-funding-receipts').remove([uploadedReceiptPath])");
 });
 it('retains the receipt on ambiguous RPC/network failures',()=>{
  expect(source).toContain('else setMessage(message)');
  expect(source).toContain('rpcAttempted=true');
 });
});
