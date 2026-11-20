import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119360000_fix_duplicate_toggle_trigger_insert_record.sql'),'utf8');

describe('Duplicate ID insert trigger OLD-record safety',()=>{
 it('branches on TG_OP before accessing OLD during an INSERT',()=>{
  expect(migration).toContain("if tg_op = 'INSERT' then");
  expect(migration).toContain("elsif tg_op = 'UPDATE' then");
  expect(migration).toContain('old.id_type is distinct from \'duplicate\'');
  expect(migration).not.toMatch(/new\.id_type\s*=\s*'duplicate'\s+and\s*\(tg_op\s*=\s*'INSERT'\s+or\s+old\.id_type/is);
 });
 it('preserves graph-lock serialization and fail-closed switch check',()=>{
  expect(migration).toContain("pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)");
  expect(migration).toContain("where setting_key='duplicate_ids_enabled'");
  expect(migration).toContain("raise exception 'Duplicate ID creation is disabled by the administrator'");
 });
 it('checks inserts and transitions into Duplicate ID, but not unrelated updates',()=>{
  expect(migration).toContain("v_requires_check := new.id_type = 'duplicate';");
  expect(migration).toContain("v_requires_check := new.id_type = 'duplicate'");
  expect(migration).toContain("and old.id_type is distinct from 'duplicate'");
 });
});
