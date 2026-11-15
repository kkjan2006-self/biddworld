import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const readMigration = (name: string) =>
  readFileSync(resolve(process.cwd(), 'supabase/migrations', name), 'utf8');

describe('package activation migration contract', () => {
  const submission = readMigration('20261115010000_submit_package_activation_request.sql');
  const review = readMigration('20261115020000_admin_package_activation_review.sql');

  it('uses a narrow authenticated wrapper while the private function validates the caller', () => {
    expect(submission).toMatch(/create or replace function private\.submit_package_activation/i);
    expect(submission).toMatch(/v_uid\s*:=\s*auth\.uid\(\)/i);
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
    expect(review).toMatch(/auth\.jwt\(\)->'app_metadata'->>'role'\s*<>\s*'admin'/i);
    expect(review).toMatch(/payment_status\s*=\s*'approved'/i);
    expect(review).toMatch(/idempotency_key/i);
    expect(review).toMatch(/revoke all on function public\.admin_review_package_activation\(uuid, boolean\)[\s\S]*?from public, anon/i);
  });

  it('uses only valid production commission status values in dashboard aggregates', () => {
    expect(review).not.toMatch(/status\s+in\s*\(\s*'credited'\s*,\s*'paid'\s*\)/i);
    expect(review).toMatch(/status\s*=\s*'credited'/i);
  });
});
