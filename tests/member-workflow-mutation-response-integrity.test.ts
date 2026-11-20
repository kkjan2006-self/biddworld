import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const account=read('src/components/Account.tsx');
const fixedBid=read('src/components/FixedBid.tsx');
const support=read('src/components/Support.tsx');
const funding=read('src/components/WalletFunding.tsx');
const fundingReview=read('src/components/AdminWalletFundingReview.tsx');
const fixedSql=read('supabase/migrations/20261118080000_fixed_bid_campaign_entry_draw_settlement.sql');
const supportSql=read('supabase/migrations/20261118170000_support_ticket_idempotency_admin_audit.sql');
const profileSql=read('supabase/migrations/20261115190000_member_profile_self_service.sql');
const withdrawalSql=read('supabase/migrations/20261116140000_require_active_main_id_for_withdrawals.sql');
const fundingSql=read('supabase/migrations/20261119060000_member_wallet_funding_requests.sql');

describe('Member and staff workflow mutation response integrity',()=>{
 it('validates Fixed Bid entry identity, amount and wallet debit split before clearing the idempotency key',()=>{
  expect(fixedBid).toContain('result.success!==true');
  expect(fixedBid).toContain('result.entry_id');
  expect(fixedBid).toContain('bidDebit+incomeDebit-entryAmount');
  expect(fixedBid).toContain("typeof result.replayed!=='boolean'");
  expect(fixedBid).toContain('entryKeys.current.delete(campaign.id)');
  expect(fixedSql).toContain("'bid_wallet_debit',v_existing_bid_debit");
  expect(fixedSql).toContain("'income_wallet_debit',v_existing_income_debit");
 });
 it('validates winning payment replay and Income Wallet settlement response',()=>{
  expect(account).toContain('result.payment_id!==paymentId');
  expect(account).toContain("result.status!=='paid'");
  expect(account).toContain('result.income_wallet_balance');
  expect(account).toContain('Pay from Income Wallet');
  expect(fixedSql).toContain("'payment_id',p_payment_id,'status','paid','replayed',true");
  expect(fixedSql).toContain("'income_wallet_balance',v_new_balance,'replayed',false");
 });
 it('validates member withdrawal request identity and status and labels the Income Wallet',()=>{
  expect(account).toContain('result.request_id');
  expect(account).toContain("result.status!=='pending'");
  expect(account).toContain('Submit a request from your Income Wallet.');
  expect(withdrawalSql).toContain("'request_id',v_id,'status','pending'");
  expect(withdrawalSql).toContain("wallet_type='income'");
 });
 it('validates member profile values and support ticket submit/update results',()=>{
  expect(account).toContain('data.display_name!==name||data.phone!==phone');
  expect(profileSql).toContain("'display_name', v_name, 'phone', v_phone");
  expect(support).toContain('result.ticket_id');
  expect(support).toContain('result.ticket_id!==id');
  expect(supportSql).toContain("'ticket_id',v_ticket.id,'status',v_ticket.status,'replayed',true");
  expect(supportSql).toContain("'ticket_id',p_ticket_id,'status',p_status");
 });
 it('validates Add Money submission and staff review results before clearing or confirming',()=>{
  expect(funding).toContain('result.request_id');
  expect(funding).toContain("result.status!=='pending'");
  expect(funding).toContain('Your Income Wallet will be credited');
  expect(fundingReview).toContain("result.status!==(approve?'approved':'rejected')");
  expect(fundingReview).toContain("result.wallet_type!=='income'");
  expect(fundingSql).toContain("'request_id',v_request.id,'status','pending'");
  expect(fundingSql).toContain("'status','approved','wallet_type','income','balance_after',v_balance");
 });
 it('uses Income Wallet terminology for all member-facing withdrawal, top-up and wallet balance surfaces',()=>{
  expect(account).toContain("type==='bid'?'Bid Wallet':'Income Wallet'");
  expect(account).toContain('Submit a request from your Income Wallet.');
  expect(account).toContain('Pay from Income Wallet');
  expect(funding).toContain('Add Money to Income Wallet');
  expect(funding).toContain('Your Income Wallet will be credited');
  expect(read('src/components/WalletHistory.tsx')).toContain('<option value="income">Income Wallet</option>');
  expect(read('src/components/AdminWalletFundingReview.tsx')).toContain('Income Wallet');
  expect(read('src/components/Admin.tsx')).toContain("label:'Income Wallet'");
 });

 it('keeps Auction item awards payment-free and limits the payment action to Fixed Bid winners',()=>{
  const account=read('src/components/Account.tsx');
  const paymentMigration=read('supabase/migrations/20261120140000_restrict_winner_payment_to_fixed_bid.sql');
  expect(account).toContain("fixed_bid_campaign_id,amount,status,paid_at,created_at");
  expect(account).toContain("x.status==='pending'&&x.fixed_bid_campaign_id&&<button");
  expect(account).toContain('Auction winners receive the item only; no separate payment is required.');
  expect(paymentMigration).toContain('if v_payment.fixed_bid_campaign_id is null then');
  expect(paymentMigration).toContain('Auction winners receive the item only; no separate winner payment is required');
 });

});
