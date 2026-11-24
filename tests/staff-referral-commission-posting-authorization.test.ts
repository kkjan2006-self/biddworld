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
 });
 it('uses a non-public internal posting routine from the Staff-capable activation trigger',()=>{
  expect(activationReview).toContain("v_role='admin_staff' and v_permissions ? 'package_activation_review'");
  expect(migration).toContain('revoke all on function private.post_referral_commissions_for_activation(uuid,uuid)');
  expect(migration).toContain('perform private.post_referral_commissions_for_activation(new.id,auth.uid())');
  expect(migration).not.toContain('perform public.admin_post_referral_commissions(new.id)');
 });
 it('preserves the financial owner-approval interlock and idempotent ledger contract',()=>{
  expect(financialLock).toContain('financial_model_approved');
  expect(migration).toContain("'referral-commission:'||v_commission.id::text||':credit'");
  expect(migration).toContain("v_existing.transaction_type is distinct from 'referral_commission'");
  expect(migration).toContain("v_existing.reference_id is distinct from v_commission.id");
  expect(migration).toContain("'referral_commissions.posted'");
  expect(referralEngine).toContain('a.depth<20');
 });
});
