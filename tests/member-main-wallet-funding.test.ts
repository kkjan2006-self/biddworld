import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119060000_member_wallet_funding_requests.sql'),'utf8');
const member=readFileSync(resolve(process.cwd(),'src/components/WalletFunding.tsx'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/AdminWalletFundingReview.tsx'),'utf8');
const account=readFileSync(resolve(process.cwd(),'src/components/Account.tsx'),'utf8');

describe('Main Wallet Add Money workflow source contract',()=>{
 it('uses the KRFSI UPI QR and collects amount, UTR and receipt',()=>{
  expect(member).toContain('/payment/biddworld-main-wallet-qr.svg');
  expect(member).toContain('krindia@bpunity');
  expect(member).toContain('p_amount:value');
  expect(member).toContain('p_payment_reference:reference');
  expect(member).toContain('p_receipt_path:path');
  expect(member).toContain('wallet-funding-receipts');
 });
 it('keeps receipt uploads private and member-owned',()=>{
  expect(migration).toContain("values('wallet-funding-receipts','wallet-funding-receipts',false");
  expect(migration).toContain("(storage.foldername(name))[1]=(select auth.uid())::text");
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'");
 });
 it('prevents duplicate UTRs and credits only the Main Wallet on approval',()=>{
  expect(migration).toContain('unique(payment_reference_normalized)');
  expect(migration).toContain("where member_id=v_request.member_id and wallet_type='income' for update");
  expect(migration).toContain("'wallet_funding','credit'");
  expect(migration).toContain("'wallet_fund_request:'||v_request.id::text");
  expect(migration).toContain("if v_request.status<>'pending'");
 });
 it('exposes an Admin review queue and member request history',()=>{
  expect(admin).toContain("admin_list_pending_wallet_fund_requests");
  expect(admin).toContain("admin_review_wallet_fund_request");
  expect(account).toContain('<WalletFunding/>');
  expect(member).toContain('member_list_my_wallet_fund_requests');
 });
});
