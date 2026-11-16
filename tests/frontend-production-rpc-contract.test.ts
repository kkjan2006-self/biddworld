import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

const contracts = [
  { name: 'public_list_active_products_page', ui: 'src/App.tsx', migration: 'supabase/migrations/20261116120000_public_product_catalogue_search.sql' },
  { name: 'member_get_my_identity', ui: 'src/components/Account.tsx', migration: 'supabase/migrations/20261115203000_member_identity_summary.sql' },
  { name: 'member_list_my_ids', ui: 'src/components/Account.tsx', migration: 'supabase/migrations/20261115203000_member_identity_summary.sql' },
  { name: 'member_update_my_profile', ui: 'src/components/Account.tsx', migration: 'supabase/migrations/20261115190000_member_profile_self_service.sql' },
  { name: 'admin_list_members_sponsors_page', ui: 'src/components/Admin.tsx', migration: 'supabase/migrations/20261116090000_admin_members_sponsors_pagination.sql' },
  { name: 'admin_list_duplicate_ids_page', ui: 'src/components/Admin.tsx', migration: 'supabase/migrations/20261116110000_admin_duplicate_id_pagination.sql' },
  { name: 'admin_set_product_active', ui: 'src/components/Admin.tsx', migration: 'supabase/migrations/20261116020000_admin_product_management_and_media.sql' },
  { name: 'get_my_mlm_dashboard_page', ui: 'src/components/Referrals.tsx', migration: 'supabase/migrations/20261116100000_member_genealogy_pagination.sql' },
];

describe('Frontend to branch SQL RPC contract inventory', () => {
  it.each(contracts)('$name is called by its UI and defined by its source migration', ({ name, ui, migration }) => {
    expect(read(ui)).toContain(name);
    const sql = read(migration);
    expect(sql).toMatch(new RegExp('create\\s+(?:or\\s+replace\\s+)?function\\s+public\\.' + name + '\\s*\\(', 'i'));
    expect(sql).toMatch(/security\s+definer/i);
    expect(sql).toMatch(/set\s+search_path/i);
  });

  it('keeps Duplicate ID placement creation on the two-argument branch contract', () => {
    const ui = read('src/components/Admin.tsx');
    const sql = read('supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql');
    expect(ui).toContain('p_main_member_code:mainMemberCode');
    expect(ui).toContain('p_under_member_code:underMemberCode');
    expect(sql).toContain('p_main_member_code text');
    expect(sql).toContain('p_under_member_code text');
    expect(sql).toContain('drop function if exists public.admin_create_duplicate_member_id(text)');
  });

  it('records the configurable-depth branch contract without activating commissions', () => {
    const sql = read('supabase/migrations/20261116030000_admin_configurable_referral_plan_depth.sql');
    expect(sql).toContain('jsonb_array_length(p_rules)');
    expect(sql).not.toMatch(/jsonb_array_length\(p_rules\)\s*<>\s*5/i);
    expect(sql).toContain("'active', false");
    expect(sql).not.toMatch(/insert into public\.(wallet_transactions|referral_commissions)/i);
  });
});
