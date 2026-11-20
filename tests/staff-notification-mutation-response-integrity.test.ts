import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const read=(path:string)=>readFileSync(resolve(process.cwd(),path),'utf8');
const staff=read('src/components/AdminPaymentReviewStaff.tsx');
const notifications=read('src/components/Notifications.tsx');
const staffSql=read('supabase/migrations/20261119100000_restricted_payment_review_staff.sql');
const permissionsSql=read('supabase/migrations/20261119160000_individual_payment_staff_permissions.sql');
const notificationSql=read('supabase/migrations/20261118180000_notification_delivery_idempotency.sql');
describe('Staff and notification mutation response integrity',()=>{
 it('validates Staff grant/revoke target identity, role and exact permissions',()=>{
  expect(staff).toContain('result.email.toLowerCase()!==expectedEmail');
  expect(staff).toContain('result.app_role!==expectedRole');
  expect(staff).toContain('expectedPermissions.some(permission=>!result.permissions.includes(permission))');
  expect(staffSql).toContain("'app_role',case when p_enabled then 'admin_staff' else 'member' end");
  expect(staffSql).toContain("jsonb_build_array('package_activation_review','wallet_funding_review','auction_submission_review')");
  expect(staff).toContain("const expectedPermissions=enabled?['package_activation_review','wallet_funding_review','auction_submission_review']:[]");
 });
 it('validates permission updates against the selected Staff member and exact permission set',()=>{
  expect(staff).toContain('result.email?.toString().toLowerCase()!==row.email?.toLowerCase()');
  expect(staff).toContain('selected.some(permission=>!result.permissions.includes(permission))');
  expect(permissionsSql).toContain("'permissions',to_jsonb(v_clean)");
 });
 it('retains notification idempotency key unless a valid delivery result is returned',()=>{
  expect(notifications).toContain('typeof result.notification_id!==\'string\'');
  expect(notifications).toContain('typeof result.replayed!==\'boolean\'');
  expect(notifications).toContain('sendKey.current=null;setUserId');
  expect(notificationSql).toContain("'notification_id',v_id,'replayed',false");
  expect(notificationSql).toContain("'notification_id',v_id,'replayed',true");
 });
 it('validates notification recipient lookup rows before they can be selected',()=>{
  expect(notifications).toContain('data.length>25');
  expect(notifications).toContain('item.member_code');
  expect(notifications).toContain('item.user_id');
 });
 it('validates package activation review results in the restricted Staff portal',()=>{
  const staffPortal=read('src/components/AdminStaff.tsx');
  expect(staffPortal).toContain("result.status!==(approve?'approved':'rejected')");
  expect(staffPortal).toContain('result.bid_wallet_credit');
  expect(staffPortal).toContain('result.wallet_balance');
 });

});
