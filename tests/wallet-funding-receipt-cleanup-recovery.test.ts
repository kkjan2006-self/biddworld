import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/WalletFunding.tsx','utf8');
describe('Wallet funding receipt cleanup recovery',()=>{
 it('persists only verified account-owned wallet receipt paths',()=>{
  expect(source).toContain('validWalletReceiptCleanupPath');
  expect(source).toContain("parts[1]==='wallet-funding'");
  expect(source).toContain('biddworld.wallet-funding-cleanup.v1.');
  expect(source).toContain('WALLET_RECEIPT_CLEANUP_LIMIT=20');
 });
 it('retries persisted cleanup on account revisit and through an explicit action',()=>{
  expect(source).toContain('retryReceiptCleanup(userId)');
  expect(source).toContain('Retry receipt cleanup');
  expect(source).toContain("storage.from('wallet-funding-receipts').remove(paths)");
 });
 it('validates the returned wallet funding request UUID before clearing the form',()=>{
  expect(source).toContain('typeof result.request_id!==\'string\'');
  expect(source).toContain('test(result.request_id)');
  expect(source).toContain('result.status!==\'pending\'');
 });
 it('queues only definite RPC rejections and preserves ambiguous receipt outcomes',()=>{
  expect(source).toContain('rpcDefinitelyRejected');
  expect(source).toContain('persistWalletReceiptCleanupPath');
  expect(source).toContain('if(uploadedReceiptPath&&(!rpcAttempted||rpcDefinitelyRejected))');
  expect(source).toContain('uploadedReceiptPath=path;');
 });
});
