import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8');

const contracts = [
  { name: 'public_list_active_products_page', ui: 'src/App.tsx', migration: 'supabase/migrations/20261116120000_public_product_catalogue_search.sql', security: 'invoker' },
  { name: 'member_get_my_identity', ui: 'src/components/Account.tsx', migration: 'supabase/migrations/20261115203000_member_identity_summary.sql', security: 'definer' },
  { name: 'member_list_my_ids', ui: 'src/components/Account.tsx', migration: 'supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql', security: 'definer' },
  { name: 'member_update_my_profile', ui: 'src/components/Account.tsx', migration: 'supabase/migrations/20261115190000_member_profile_self_service.sql', security: 'definer' },
  { name: 'admin_list_members_sponsors_page', ui: 'src/components/Admin.tsx', migration: 'supabase/migrations/20261116090000_admin_members_sponsors_pagination.sql', security: 'definer' },
  { name: 'admin_list_duplicate_ids_page', ui: 'src/components/Admin.tsx', migration: 'supabase/migrations/20261116110000_admin_duplicate_id_pagination.sql', security: 'definer' },
  { name: 'admin_set_product_active', ui: 'src/components/Admin.tsx', migration: 'supabase/migrations/20261116020000_admin_product_management_and_media.sql', security: 'definer' },
  { name: 'get_my_mlm_dashboard_page', ui: 'src/components/Referrals.tsx', migration: 'supabase/migrations/20261116100000_member_genealogy_pagination.sql', security: 'definer' },
];

describe('Frontend to branch SQL RPC contract inventory', () => {
  it.each(contracts)('$name is called by its UI and defined with the intended SQL security mode', ({ name, ui, migration, security }) => {
    expect(read(ui)).toContain(name);
    const sql = read(migration);
    expect(sql.toLowerCase()).toContain('create or replace function public.' + name);
    expect(sql).toMatch(new RegExp('security\\s+' + security, 'i'));
    expect(sql).toMatch(/set\s+search_path/i);
  });

  it('keeps Duplicate ID placement creation on the two-argument branch contract', () => {
    const ui = read('src/components/Admin.tsx');
    const sql = read('supabase/migrations/20261115230000_duplicate_under_id_placement_attribution.sql');
    expect(ui).toContain('admin_create_duplicate_member_id');
    expect(ui).toMatch(/p_main_member_code\s*:\s*code/);
    expect(ui).toMatch(/p_under_member_code\s*:\s*under/);
    expect(sql).toMatch(/p_main_member_code\s+text/i);
    expect(sql).toMatch(/p_under_member_code\s+text/i);
    expect(sql).toMatch(/drop function if exists public\.admin_create_duplicate_member_id\(text\)/i);
  });

  it('keeps configurable referral drafts inactive and free of wallet or commission writes', () => {
    const sql = read('supabase/migrations/20261116030000_admin_configurable_referral_plan_depth.sql');
    expect(sql).toContain('jsonb_array_length(p_rules)');
    expect(sql).not.toMatch(/jsonb_array_length\(p_rules\)\s*<>\s*5/i);
    expect(sql).toMatch(/insert into public\.referral_plan_versions[\s\S]*?values \(p_package_id, v_version, false, v_uid\)/i);
    expect(sql).toMatch(/'is_active', false/i);
    expect(sql).not.toMatch(/insert into public\.(wallet_transactions|referral_commissions)/i);
  });
});
