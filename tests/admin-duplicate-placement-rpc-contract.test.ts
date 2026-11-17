import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');
const admin = read('src/components/Admin.tsx');

describe('Duplicate ID Admin RPC contract', () => {
  it('keeps the Admin placement arguments aligned with the migration signature', () => {
    const admin = read('src/components/Admin.tsx');
    const migration = read('supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql');
    expect(admin).toContain("supabase.rpc('admin_create_duplicate_member_id',{p_main_member_code:code,p_under_member_code:under})");
    expect(migration).toContain('admin_create_duplicate_member_id(\n  p_main_member_code text,\n  p_under_member_code text');
    expect(migration).toContain('placement_parent_id,placement_position');
    expect(migration).toContain("'under_member_code',v_under.member_code");
  });

  it('does not silently revert to the obsolete one-argument creation RPC', () => {
    const migration = read('supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql');
    expect(migration).toContain('drop function if exists public.admin_create_duplicate_member_id(text)');
    expect(migration).toContain('grant execute on function public.admin_create_duplicate_member_id(text,text) to authenticated');
  });
});


describe('Duplicate ID RPC deployment mismatch feedback',()=>{
 it('explains that duplicate creation needs the backend RPC update',()=>{
  expect(admin).toContain('isRpcContractUnavailable(e)?');
  expect(admin).toContain('database RPC update has not been installed');
 });
});
