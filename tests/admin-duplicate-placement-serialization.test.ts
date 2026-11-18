import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const migration = readFileSync(
  resolve(process.cwd(), 'supabase/migrations/20261117110000_serialize_admin_duplicate_id_placement.sql'),
  'utf8',
);

describe('Serialized Admin Duplicate ID placement creation', () => {
  it('takes the shared graph transaction lock before reading settings or locking placement rows', () => {
    const lock = migration.indexOf('pg_catalog.pg_advisory_xact_lock');
    const settingsRead = migration.indexOf('from public.app_settings');
    const mainLock = migration.indexOf("and id_type='main' and status='active'");
    const underLock = migration.indexOf("and id_type in ('main','duplicate') and status='active'");
    expect(lock).toBeGreaterThan(-1);
    expect(settingsRead).toBeGreaterThan(lock);
    expect(mainLock).toBeGreaterThan(lock);
    expect(underLock).toBeGreaterThan(mainLock);
    expect(migration).toContain("hashtextextended('biddworld.member_id_graph_mutation', 0)");
  });

  it('preserves the active Main / Under ID checks and cross-owner placement rule', () => {
    expect(migration).toContain("id_type='main' and status='active'");
    expect(migration).toContain("id_type in ('main','duplicate') and status='active'");
    expect(migration).toContain('if v_under.owner_user_id = v_main.owner_user_id then');
    expect(migration).toContain("raise exception 'A member cannot place their Duplicate ID under their own ID'");
    expect(migration).toContain("values (\n    v_main.owner_user_id,v_main.id,v_code,'duplicate','pending',v_under.id,'under'");
  });

  it('keeps audit logging, fixed search_path and authenticated-only execution', () => {
    expect(migration).toContain("set search_path = ''");
    expect(migration).toContain('insert into public.audit_logs');
    expect(migration).toContain('from public,anon');
    expect(migration).toContain('to authenticated');
  });
});
