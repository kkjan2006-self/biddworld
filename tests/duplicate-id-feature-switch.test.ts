import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119270000_block_duplicate_creation_when_disabled.sql'),'utf8');
const admin=readFileSync(resolve(process.cwd(),'src/components/Admin.tsx'),'utf8');

describe('Duplicate ID feature switch enforcement',()=>{
  it('blocks every new Duplicate ID row at the database boundary while disabled',()=>{
    expect(migration).toContain("new.id_type = 'duplicate'");
    expect(migration).toContain("tg_op = 'INSERT' or old.id_type is distinct from 'duplicate'");
    expect(migration).toContain("setting_key = 'duplicate_ids_enabled'");
    expect(migration).toContain("if not coalesce(v_enabled, false) then");
    expect(migration).toContain("before insert or update of id_type on public.member_ids");
  });

  it('does not block updates to already-existing Duplicate IDs merely because creation is disabled',()=>{
    const guard=migration.slice(migration.indexOf('if new.id_type'),migration.indexOf('return new;'));
    expect(guard).toContain("tg_op = 'INSERT' or old.id_type is distinct from 'duplicate'");
    expect(guard).not.toContain('new.status');
    expect(guard).not.toContain('delete from public.member_ids');
  });

  it('keeps the Admin switch reversible and explains that OFF stops only new creation',()=>{
    expect(admin).toContain("key:'duplicate_ids_enabled'");
    expect(admin).toContain('Disable new Duplicate ID creation; existing IDs and their history remain unchanged.');
    expect(admin).toContain("p_setting_key:key,p_enabled:enabled");
  });
  it('allows Admin to turn Duplicate IDs back ON without an unrelated feature lock',()=>{
    const start=migration.indexOf('v_server_condition_keys text[]');
    const end=migration.indexOf('];',start);
    const guardedKeys=migration.slice(start,end);
    expect(guardedKeys).not.toContain("'duplicate_ids_enabled'");
    expect(migration).toContain("'duplicate_ids_enabled','package_activations_enabled'");
    expect(migration).toContain("grant execute on function public.admin_set_feature_setting(text,boolean) to authenticated;");
  });

});
