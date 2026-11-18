import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261118090000_package_publication_and_referral_commission_engine.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');
const body=(name:string)=>{const s=sql.indexOf('create or replace function '+name);const e=sql.indexOf('$function$;',s)+11;return sql.slice(s,e);};

describe('Configurable referral commission engine integrity',()=>{
 it('uses an active package-specific plan version and sequential level rules up to the configured depth',()=>{
  const s=body('private.create_referral_commissions_for_activation()');
  expect(s).toContain("where package_id=new.package_id and is_active=true");
  expect(s).toContain('a.depth<20');
  expect(s).toContain('not r.referrer_member_id=any(a.path)');
  expect(s).toContain('where plan_version_id=v_plan_id and level_number=v_ancestor.depth');
  expect(s).toContain("v_rule.reward_type='fixed'");
  expect(s).toContain("v_rule.reward_type='percentage'");
 });
 it('attributes Duplicate ID beneficiaries to their Main ID Income Wallet while retaining the source ID',()=>{
  const s=body('private.create_referral_commissions_for_activation()');
  expect(s).toContain("case when source.id_type='duplicate' then source.main_member_id else source.id end");
  expect(s).toContain('v_ancestor.beneficiary_member_id');
  expect(s).toContain('v_ancestor.credited_main_member_id');
  expect(s).toContain("credited.id_type='main' and credited.status='active'");
 });
 it('creates pending commissions once per activation, plan version and level, then posts only through the enabled Admin path',()=>{
  const s=body('private.create_referral_commissions_for_activation()');
  expect(s).toContain("new.payment_status<>'approved' or new.activation_status<>'active'");
  expect(s).toContain("referral-activation:'||new.id::text");
  expect(s).toContain('package_activation_id=new.id and plan_version_id=v_plan_id and level_number=v_ancestor.depth');
  expect(s).toContain("setting_key='referral_commissions_enabled'");
  expect(s).toContain('perform public.admin_post_referral_commissions(new.id)');
 });
 it('posts commissions to Income Wallet with idempotency and validates any existing ledger row',()=>{
  const s=body('public.admin_post_referral_commissions(p_activation_id uuid)');
  expect(s).toContain("wallet_type='income'");
  expect(s).toContain("v_key:='referral-commission:'||v_commission.id::text||':credit'");
  expect(s).toContain("v_existing.transaction_type is distinct from 'referral_commission'");
  expect(s).toContain("v_existing.direction is distinct from 'credit'");
  expect(s).toContain('v_existing.reference_id is distinct from v_commission.id');
  expect(s).toContain('update public.wallet_accounts set balance=v_new_balance');
  expect(s).toContain('insert into public.wallet_transactions');
 });
 it('provides level/status-filtered complete Admin commission CSV reporting',()=>{
  expect(admin).toContain('commissionLevelFilter');
  expect(admin).toContain('Commission level');
  expect(admin).toContain("commissionStatusFilter==='all'?null:commissionStatusFilter");
  expect(admin).toContain("commissionLevelFilter==='all'?null:Number(commissionLevelFilter)");
  expect(admin).toContain("commissionRows.filter(row=>(commissionStatusFilter==='all'||row.status===commissionStatusFilter)&&(commissionLevelFilter==='all'||String(row.level_number)===commissionLevelFilter))");
  expect(admin).toContain('Export Complete Referral Commission CSV');
  expect(admin).toContain('biddworld-referral-commissions-complete.csv');
 });
 it('validates both original credit and reversal ledger entries, including replayed reversals',()=>{
  const s=body('public.admin_reverse_referral_commission(p_commission_id uuid,p_reason text)');
  expect(s).toContain("v_credit.transaction_type is distinct from 'referral_commission'");
  expect(s).toContain("v_existing.transaction_type is distinct from 'referral_commission_reversal'");
  expect(s).toContain("v_existing.direction is distinct from 'debit'");
  expect(s).toContain('The referral reversal ledger entry is missing or inconsistent; replay was not accepted');
  expect(s).toContain('The Income Wallet balance is insufficient for this full reversal');
 });
});
