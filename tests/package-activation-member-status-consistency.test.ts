import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261117140000_guard_package_activation_member_status.sql'),'utf8');

describe('Package activation Main ID/profile status consistency guard',()=>{
  it('validates new requests and verified approvals against an owning Main ID and profile',()=>{
    expect(migration).toMatch(/create or replace function private\.guard_package_activation_member_status\(\)/i);
    expect(migration).toMatch(/security definer[\s\S]*?set search_path\s*=\s*''/i);
    expect(migration).toMatch(/join public\.profiles p on p\.id\s*=\s*m\.owner_user_id/i);
    expect(migration).toMatch(/m\.id\s*=\s*new\.member_id[\s\S]*?m\.id_type\s*=\s*'main'/i);
    expect(migration).toMatch(/tg_op\s*=\s*'INSERT'[\s\S]*?new\.payment_status\s*=\s*'approved'[\s\S]*?new\.activation_status\s*=\s*'active'/i);
  });

  it('rejects missing, suspended/closed, and mismatched profile/Main ID states',()=>{
    expect(migration).toContain("if not found then");
    expect(migration).toContain("v_member_status is null");
    expect(migration).toContain("v_profile_status is null");
    expect(migration).toContain("v_member_status not in ('inactive', 'active')");
    expect(migration).toContain("v_profile_status not in ('inactive', 'active')");
    expect(migration).toContain("v_member_status is distinct from v_profile_status");
  });

  it('locks both identity rows and exposes no direct client execution of the trigger function',()=>{
    expect(migration).toMatch(/for update of m, p/i);
    expect(migration).toMatch(/revoke all on function private\.guard_package_activation_member_status\(\)[\s\S]*?from public, anon, authenticated/i);
    expect(migration).toMatch(/before insert or update of payment_status, activation_status[\s\S]*?on public\.package_activations/i);
  });
});
