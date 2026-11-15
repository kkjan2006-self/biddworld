import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const readMigration = (name: string) =>
  readFileSync(resolve(process.cwd(), 'supabase/migrations', name), 'utf8');

describe('package activation migration contract', () => {
  const submission = readMigration('20261115010000_submit_package_activation_request.sql');
  const review = readMigration('20261115020000_admin_package_activation_review.sql');
  const reconciliation = readMigration('20261115074500_reconcile_mlm_dashboard_statuses.sql');
  const bidWrapper = readMigration('20261115090000_secure_place_bid_wrapper.sql');

  it('uses a narrow authenticated wrapper while the private function validates the caller', () => {
    expect(submission).toMatch(/create or replace function private\.submit_package_activation/i);
    expect(submission).toMatch(/v_uid(?:\s+uuid)?\s*:=\s*auth\.uid\(\)/i);
    expect(submission).toMatch(/if v_uid is null then[\s\S]*?Authentication required/i);
    expect(submission).toMatch(/create or replace function public\.submit_package_activation\([\s\S]*?security definer/i);
    expect(submission).toMatch(/revoke all on function public\.submit_package_activation\(uuid, text\)[\s\S]*?from public, anon/i);
    expect(submission).toMatch(/grant execute on function public\.submit_package_activation\(uuid, text\)[\s\S]*?to authenticated/i);
  });

  it('does not activate or credit a wallet when a member submits a payment reference', () => {
    const privateBody = submission.split('create or replace function public.submit_package_activation')[0];
    expect(privateBody).toContain("'pending', 'pending'");
    expect(privateBody).not.toMatch(/update public\.wallet_accounts/i);
    expect(privateBody).not.toMatch(/insert into public\.wallet_transactions/i);
  });

  it('snapshots Bid Wallet credit and restricts review RPCs to administrators', () => {
    expect(review).toMatch(/add column if not exists bid_wallet_credit/i);
    expect(review).toMatch(/coalesce\(auth\.jwt\(\)->'app_metadata'->>'role',''\)\s*<>\s*'admin'/i);
    expect(review).toMatch(/payment_status\s*=\s*'approved'/i);
    expect(review).toMatch(/idempotency_key/i);
    expect(review).toMatch(/revoke all on function public\.admin_review_package_activation\(uuid, boolean\)[\s\S]*?from public, anon/i);
  });

  it('uses only valid production commission status values in dashboard aggregates', () => {
    expect(review).not.toMatch(/status\s+in\s*\(\s*'credited'\s*,\s*'paid'\s*\)/i);
    expect(review).toMatch(/status\s*=\s*'credited'/i);
  });
  it('exposes bidding only through an authenticated definer wrapper with a fixed search path', () => {
    expect(bidWrapper).toMatch(/create or replace function public\.place_bid\(p_auction_id uuid\)[\s\S]*?security definer/i);
    expect(bidWrapper).toMatch(/set search_path = pg_catalog, public, private/i);
    expect(bidWrapper).toMatch(/select private\.place_bid\(p_auction_id\)/i);
    expect(bidWrapper).toMatch(/revoke all on function public\.place_bid\(uuid\) from public, anon/i);
    expect(bidWrapper).toMatch(/grant execute on function public\.place_bid\(uuid\) to authenticated/i);
    expect(bidWrapper).toMatch(/revoke all on function private\.place_bid\(uuid\) from public, anon, authenticated/i);
  });

  it('keeps the production MLM dashboard aligned with canonical database statuses', () => {
    expect(reconciliation).toMatch(/payment_status\s*=\s*'approved'/i);
    expect(reconciliation).toMatch(/status\s*=\s*'credited'/i);
    expect(reconciliation).not.toMatch(/payment_status\s*=\s*'verified'/i);
    expect(reconciliation).not.toMatch(/status\s+in\s*\(\s*'credited'\s*,\s*'paid'\s*\)/i);
    expect(reconciliation).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'/i);
  });
  
  it('exposes only whitelisted boolean feature switches through audited admin RPCs', () => {
    const features = readMigration('20261115130000_admin_feature_settings.sql');
    expect(features).toMatch(/create or replace function public\.admin_get_feature_settings\(\)/i);
    expect(features).toMatch(/create or replace function public\.admin_set_feature_setting\([\s\S]*?p_enabled boolean/i);
    expect(features).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'[\s\S]*?'admin'/i);
    expect(features).toMatch(/p_setting_key <> all\(array\[/i);
    expect(features).toMatch(/insert into public\.audit_logs[\s\S]*?feature_setting_changed/i);
    expect(features).toMatch(/revoke all on function public\.admin_set_feature_setting\(text,boolean\) from public,anon/i);
    expect(features).toMatch(/grant execute on function public\.admin_set_feature_setting\(text,boolean\) to authenticated/i);
    expect(features).toMatch(/'bidding_enabled','false'::jsonb/i);
    expect(features).toMatch(/'duplicate_ids_enabled','false'::jsonb/i);
  });
});
