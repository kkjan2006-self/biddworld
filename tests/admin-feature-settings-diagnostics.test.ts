import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const admin = readFileSync(resolve(process.cwd(), 'src/components/Admin.tsx'), 'utf8');
const migration = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261119240000_admin_email_verification_feature_setting.sql'), 'utf8');

describe('Admin feature settings diagnostics and enablement', () => {
  it('does not silently coerce an incomplete settings payload to false', () => {
    expect(admin).toMatch(/Feature settings response is incomplete/);
    expect(admin).toContain("typeof record[key]!=='boolean'");
    expect(admin).toMatch(/Retry Settings/);
    expect(admin).toMatch(/setFeatureSettingsLoaded\(false\);setFeatureSettingsLoadError\(''\)/);
  });

  it('allows only implemented or server-condition-checked settings in the frontend', () => {
    expect(admin).toContain("featureEnableReadyKeys=new Set(['registration_enabled','email_verification_required','sponsor_referrals_enabled','duplicate_ids_enabled','package_activations_enabled','referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled','winning_payment_enabled','delivery_tracking_enabled','notifications_enabled'])");
    expect(admin).toMatch(/disabled=\{!featureSettingsLoaded\|\|savingFeature!==''\|\|\(!enabled&&!canEnable\)\}/);
    expect(admin).toMatch(/Server condition checked when saving/);
    expect(admin).toMatch(/Backend workflow pending/);
  });

  it('exposes email verification through the Admin RPC while preserving server-side gates', () => {
    expect(migration).toMatch(/'registration_enabled','email_verification_required','sponsor_referrals_enabled'/);
    expect(migration).toMatch(/'registration_enabled','email_verification_required','sponsor_referrals_enabled',[\s\S]*?'delivery_tracking_enabled'/);
    expect(migration).toMatch(/if p_enabled and not \(p_setting_key=any\(v_enabled_keys\)\)/);
    expect(migration).toMatch(/financial_model_approved/);
    expect(migration).toMatch(/audit_logs/);
  });

  it('keeps server rejection visible without optimistically changing the switch', () => {
    expect(admin).toMatch(/if\(data\?\.success!==true\)throw new Error/);
    expect(admin).toMatch(/setFeatureSettings\(current=>\(\{\.\.\.current,\[key\]:enabled\}\)\)/);
  });

  it('gates in-app notification delivery behind the Admin feature switch', () => {
    const notificationMigration = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261119250000_enable_in_app_notifications_feature.sql'), 'utf8');
    expect(admin).toMatch(/Enable in-app member notifications/);
    expect(admin).toMatch(/backendPendingFeatureKeys=new Set\(\['automatic_placement_enabled','winner_selection_configured'\]\)/);
    expect(notificationMigration).toMatch(/'delivery_tracking_enabled','notifications_enabled'/);
    expect(notificationMigration).toMatch(/In-app notifications are disabled in Platform Settings/);
    expect(notificationMigration).toMatch(/notify_member_on_support_ticket_update/);
    expect(notificationMigration).toMatch(/if not coalesce\(v_notifications_enabled,false\) then\s+return new;/);
    expect(notificationMigration).toMatch(/notification.sent/);
  });


  it('routes existing workflows through the server-side enablement condition', () => {
    const workflowMigration = readFileSync(resolve(process.cwd(), 'supabase/migrations/20261119260000_enable_existing_feature_workflow_switches.sql'), 'utf8');
    expect(admin).toMatch(/serverConditionFeatureKeys=new Set\(\['duplicate_ids_enabled','package_activations_enabled','referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled','winning_payment_enabled'\]\)/);
    expect(workflowMigration).toMatch(/'registration_enabled','email_verification_required','sponsor_referrals_enabled',[\s\S]*?'winning_payment_enabled',[\s\S]*?'delivery_tracking_enabled','notifications_enabled'/);
    expect(workflowMigration).toMatch(/v_server_condition_keys text\[\]/);
    expect(workflowMigration).toMatch(/setting_key='financial_model_approved'/);
    expect(workflowMigration).toMatch(/if p_enabled and not \(p_setting_key=any\(v_enabled_keys\)\)/);
    expect(workflowMigration).toMatch(/audit_logs/);
    expect(workflowMigration).toMatch(/Cannot enable % yet/);
  });

});
