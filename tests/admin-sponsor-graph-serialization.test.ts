import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const migration = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261117100000_serialize_admin_sponsor_graph_changes.sql'),
  'utf8',
);

describe('Serialized administrator sponsor graph changes', () => {
  it('takes a transaction-scoped graph lock before reading the sponsor graph', () => {
    const lock = migration.indexOf('pg_catalog.pg_advisory_xact_lock');
    const memberRead = migration.indexOf('select id into v_member_id');
    const sponsorRead = migration.indexOf('select id,member_code into v_sponsor_id');
    const cycleCheck = migration.indexOf('with recursive descendants');
    expect(lock).toBeGreaterThan(-1);
    expect(memberRead).toBeGreaterThan(lock);
    expect(sponsorRead).toBeGreaterThan(lock);
    expect(cycleCheck).toBeGreaterThan(lock);
    expect(migration).toContain("hashtextextended('biddworld.admin_set_member_sponsor', 0)");
  });

  it('keeps the recursive downline cycle rejection and self-sponsor rejection', () => {
    expect(migration).toContain('if v_member_id=v_sponsor_id then');
    expect(migration).toContain('where member_id=v_sponsor_id');
    expect(migration).toContain('circular referral is not allowed');
  });

  it('retains the administrator-only RPC grant boundary', () => {
    expect(migration).toContain("auth.jwt()->'app_metadata'->>'role'");
    expect(migration).toContain('from public, anon');
    expect(migration).toContain('to authenticated');
    expect(migration).toContain("set search_path = ''");
  });
});
