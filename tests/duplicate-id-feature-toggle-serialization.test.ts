import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119350000_serialize_duplicate_id_feature_toggle.sql'),'utf8');
const create=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119340000_exclude_owner_ids_from_duplicate_placement.sql'),'utf8');

describe('Duplicate ID feature-toggle serialization',()=>{
 it('takes the shared graph lock before changing the Duplicate ID switch',()=>{
  const settingWrite=migration.indexOf("if p_setting_key='duplicate_ids_enabled' then");
  const lock=migration.indexOf("pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)",settingWrite);
  const write=migration.indexOf('insert into public.app_settings',settingWrite);
  expect(settingWrite).toBeGreaterThanOrEqual(0);
  expect(lock).toBeGreaterThan(settingWrite);
  expect(write).toBeGreaterThan(lock);
 });
 it('takes the same lock before checking the switch on every database insert path',()=>{
  const trigger=migration.slice(migration.indexOf('create or replace function private.enforce_duplicate_id_creation_switch()'));
  const lock=trigger.indexOf("pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)");
  const read=trigger.indexOf("where setting_key = 'duplicate_ids_enabled'");
  expect(lock).toBeGreaterThanOrEqual(0);
  expect(read).toBeGreaterThan(lock);
  expect(trigger).toContain("raise exception 'Duplicate ID creation is disabled by the administrator'");
 });
 it('keeps automatic RPC creation on the same graph lock and still checks OFF before creating',()=>{
  expect(create).toContain("pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)");
  expect(create).toContain("if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled in Platform Settings'");
 });
});
