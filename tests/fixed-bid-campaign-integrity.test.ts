import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118080000_fixed_bid_campaign_entry_draw_settlement.sql'),'utf8');
const secureDrawSql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118340000_secure_fixed_bid_random_draw.sql'),'utf8');
const secureDrawBody=()=>{const s=secureDrawSql.indexOf('create or replace function public.admin_draw_fixed_bid_winners(');const e=secureDrawSql.indexOf('$function$;',s)+11;return secureDrawSql.slice(s,e);};

const body=(name:string)=>{const s=sql.indexOf('create or replace function public.'+name);const e=sql.indexOf('$function$;',s)+11;return sql.slice(s,e);};

describe('Fixed Bid entry, draw and winner settlement integrity',()=>{
 it('requires an active member profile and its own active Main ID before entry',()=>{
  const s=body('member_join_fixed_bid_campaign(');
  expect(s).toContain('join public.profiles p');
  expect(s).toContain('p.main_member_id=m.id');
  expect(s).toContain("p.status='active'");
  expect(s).toContain("m.id_type='main' and m.status='active'");
 });
 it('validates both wallet debit legs before accepting an idempotent replay',()=>{
  const s=body('member_join_fixed_bid_campaign(');
  expect(s).toContain("v_existing_debit.transaction_type is distinct from 'fixed_bid_entry'");
  expect(s).toContain("v_existing_debit.direction is distinct from 'debit'");
  expect(s).toContain("v_existing_wallet.wallet_type is distinct from 'bid'");
  expect(s).toContain("v_existing_wallet.wallet_type is distinct from 'income'");
  expect(s).toContain('v_existing_debit_total<>v_existing_entry.bid_amount');
 });
 it('makes campaign draws replay-safe and selects only active Main IDs',()=>{
  const s=body('admin_draw_fixed_bid_winners(');
  expect(s).toContain('select * into v_draw from public.fixed_bid_draws where campaign_id=p_campaign_id');
  expect(s).toContain("'replayed',true");
  expect(s).toContain("m.id_type='main' and m.status='active'");
  expect(s).toContain("p.main_member_id=m.id and p.status='active'");
 });
 it('uses a seeded SHA-256 digest rather than a non-cryptographic hash for future winner ranking',()=>{
  const s=secureDrawBody();
  expect(s).toContain("extensions.digest(pg_catalog.uuid_send(v_seed)||pg_catalog.uuid_send(fb.id),'sha256')");
  expect(s).toContain('order by draw_score,member_id');
  expect(s).not.toContain('hashtextextended(fb.id::text');
 });
 it('reconciles every non-winner debit and validates pre-existing refund ledger keys',()=>{
  const s=body('admin_draw_fixed_bid_winners(');
  expect(s).toContain("v_debit.transaction_type is distinct from 'fixed_bid_entry'");
  expect(s).toContain("v_debit.reference_id is distinct from v_entry.id");
  expect(s).toContain("v_existing.transaction_type is distinct from 'fixed_bid_refund'");
  expect(s).toContain("v_existing.direction is distinct from 'credit'");
  expect(s).toContain('v_debit_total<>v_entry.bid_amount');
 });
 it('keeps both Fixed Bid and shared winner payments on the active Main ID Income Wallet',()=>{
  const specific=body('member_pay_fixed_bid_winning_payment(');
  const shared=body('member_pay_winning_item_payment(');
  for(const s of [specific,shared]){
   expect(s).toContain('join public.member_ids m');
   expect(s).toContain("p.status='active'");
   expect(s).toContain("wallet_type='income'");
   expect(s).toContain('for update');
  }
 });
});
