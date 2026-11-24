import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const migration=read('supabase/migrations/20261124020000_allow_staff_triggered_referral_commission_posting.sql');
const activationReview=read('supabase/migrations/20261119640000_staff_package_activation_review.sql');
const referralEngine=read('supabase/migrations/20261118090000_package_publication_and_referral_commission_engine.sql');
const financialLock=read('supabase/migrations/20261116080000_financial_activity_lockdown.sql');

describe('Staff package activation and referral posting authorization',()=>{
 it('keeps the public manual referral posting RPC Admin-only',()=>{
  expect(migration).toContain("coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'");
  expect(migration).toContain('revoke all on function public.admin_post_referral_commissions(uuid) from public,anon');
  expect(migration).toContain('grant execute on function public.admin_post_referral_commissions(uuid) to authenticated');
  expect(migration).toContain('return private.post_referral_commissions_for_activation(p_activation_id,v_uid)');
  expect(migration).not.toContain("v_role='admin_staff'");
 });
 it('uses a non-public internal posting routine from the Staff-capable activation trigger',()=>{
  expect(activationReview).toContain("v_role='admin_staff' and v_permissions ? 'package_activation_review'");
  expect(migration).toContain('revoke all on function private.post_referral_commissions_for_activation(uuid,uuid)');
  expect(migration).toContain('perform private.post_referral_commissions_for_activation(new.id,auth.uid())');
  expect(migration).not.toContain('perform public.admin_post_referral_commissions(new.id)');
 });
 it('rejects missing actors and activations that are not approved and active',()=>{
  expect(migration).toContain("if v_uid is null then");
  expect(migration).toContain("raise exception 'Authenticated activation actor required' using errcode='42501'");
  expect(migration).toContain("v_activation.payment_status<>'approved'");
  expect(migration).toContain("v_activation.activation_status<>'active'");
 });
 it('requires the commission feature switch and serializes activation posting',()=>{
  expect(migration).toContain("setting_key='referral_commissions_enabled'");
  expect(migration).toContain("raise exception 'Referral commission posting is disabled'");
  expect(migration).toContain("'referral-activation:'||p_activation_id::text");
  expect(migration).toContain('pg_catalog.pg_advisory_xact_lock');
 });
 it('keeps ledger credits idempotent and rejects mismatched replay identities',()=>{
  expect(migration).toContain("'referral-commission:'||v_commission.id::text||':credit'");
  expect(migration).toContain("v_existing.wallet_account_id is distinct from v_wallet.id");
  expect(migration).toContain("v_existing.member_id is distinct from v_commission.credited_main_member_id");
  expect(migration).toContain("v_existing.transaction_type is distinct from 'referral_commission'");
  expect(migration).toContain("v_existing.direction is distinct from 'credit'");
  expect(migration).toContain("v_existing.amount is distinct from v_commission.amount");
  expect(migration).toContain("v_existing.reference_id is distinct from v_commission.id");
  expect(migration).toContain("update public.referral_commissions set status='credited'");
 });
 it('attributes the audit event to the activation reviewer and retains the owner-approval interlock',()=>{
  expect(migration).toContain("values(v_uid,'referral_commissions.posted','package_activations',p_activation_id");
  expect(financialLock).toContain('financial_model_approved');
  expect(referralEngine).toContain('a.depth<20');
 });
});
