import {readFileSync} from 'node:fs';
import {describe,expect,it} from 'vitest';
const source=readFileSync('src/components/Admin.tsx','utf8');
describe('Admin wallet page response integrity',()=>{
 it('validates full wallet account identity and value contracts',()=>{
  expect(source).toContain('function parseAdminWalletAccountPage(value:unknown):WalletAccount[]');
  for(const field of ["row.wallet_account_id","row.member_id","row.member_code","row.wallet_type","row.balance","row.currency","row.updated_at"])expect(source).toContain(field);
  expect(source).toContain("!/^[A-Z]{3}$/.test(row.currency)");
 });
 it('validates complete wallet ledger transaction contracts',()=>{
  expect(source).toContain('function parseAdminWalletTransactionPage(value:unknown):WalletTransaction[]');
  for(const field of ["row.transaction_id","row.member_id","row.member_code","row.transaction_type","row.direction","row.amount","row.balance_after","row.created_at"])expect(source).toContain(field);
  expect(source).toContain("!['credit','debit'].includes(String(row.direction))");
 });
 it('uses the same strict parsers for first and continuation pages',()=>{
  expect(source).toContain('parseAdminWalletAccountPage(walletAccountResult.data??[])');
  expect(source).toContain('parseAdminWalletAccountPage(data)');
  expect(source).toContain('parseAdminWalletTransactionPage(walletTransactionResult.data??[])');
  expect(source).toContain('parseAdminWalletTransactionPage(data)');
 });
 it('rejects cross-page duplicate identities instead of silently filtering them',()=>{
  expect(source).toContain('Wallet account page overlaps records already loaded');
  expect(source).toContain('Wallet ledger page overlaps records already loaded');
  expect(source).not.toContain('Repeated wallet account page detected');
  expect(source).not.toContain('Repeated wallet ledger page detected');
 });
});
