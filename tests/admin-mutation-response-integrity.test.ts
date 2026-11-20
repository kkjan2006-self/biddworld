import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const ui=read('src/components/Admin.tsx');
const withdrawal=read('supabase/migrations/20261118100000_admin_withdrawal_review_workflow.sql');
const role=read('supabase/migrations/20261118160000_primary_admin_role_management.sql');
const profile=read('supabase/migrations/20261117120000_admin_update_member_profile.sql');
const packagePlan=read('supabase/migrations/20261118090000_package_publication_and_referral_commission_engine.sql');

describe('Admin mutation RPC response integrity',()=>{
 it('validates withdrawal review identity and action-specific status, and names the Income Wallet correctly',()=>{
  expect(ui).toContain('result.request_id!==requestId');
  expect(ui).toContain('result.status!==expectedStatus');
  expect(ui).toContain("'Withdrawal approved and Income Wallet amount reserved.'");
  expect(withdrawal).toContain("'request_id',v_request.id");
  expect(withdrawal).toContain("'status',case when p_action='approve' then 'approved'");
  expect(withdrawal).toContain("wallet_type='income'");
 });
 it('validates Primary Admin role mutation identity and returned role',()=>{
  expect(ui).toContain('result.user_id');
  expect(ui).toContain('result.email.trim().toLowerCase()!==email.trim().toLowerCase()');
  expect(ui).toContain("result.app_role!==(grant?'admin':'member')");
  expect(role).toContain("'user_id',v_target_id");
  expect(role).toContain("'app_role',case when p_grant_admin then 'admin' else 'member' end");
 });
 it('validates Admin member profile fields and no-op result before updating local state',()=>{
  expect(ui).toContain('result.member_code.trim().toUpperCase()!==selectedMemberCode.trim().toUpperCase()');
  expect(ui).toContain('result.display_name!==displayName');
  expect(ui).toContain('result.phone!==(phone||null)');
  expect(ui).toContain("typeof result.changed!=='boolean'");
  expect(profile).toContain("'changed',false");
  expect(profile).toContain("'changed',true");
 });
 it('validates package publication and referral plan activation results',()=>{
  expect(ui).toContain('result.package_id!==item.id');
  expect(ui).toContain('result.is_active!==publish');
  expect(ui).toContain('result.plan_version_id!==plan.plan_id');
  expect(ui).toContain('result.levels<1||result.levels>20');
  expect(packagePlan).toContain("'package_id',p_package_id,'is_active',p_publish");
  expect(packagePlan).toContain("'plan_version_id',p_plan_version_id,'version_number',v_version,'levels',v_rules");
 });
});
