import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119380000_close_all_linked_duplicate_ids.sql'),'utf8');

describe('Closing a Main ID closes every linked Duplicate ID',()=>{
 it('closes every linked Duplicate ID that is not already closed, including manually suspended IDs',()=>{
  const closeBranch=migration.slice(migration.indexOf("elsif p_status='closed' then"),migration.indexOf("elsif p_status='active' then"));
  expect(closeBranch).toContain("d.id_type='duplicate'");
  expect(closeBranch).toContain("and status<>'closed'");
  expect(closeBranch).not.toContain('main_status_managed');
  expect(closeBranch).toContain("set status='closed',main_status_managed=true");
 });
 it('keeps Main-ID closure irreversible and leaves already-closed duplicates unchanged',()=>{
  expect(migration).toContain("if v_old_status='closed' and p_status<>'closed' then");
  expect(migration).toContain("and status<>'closed'");
  expect(migration).toContain('get diagnostics v_duplicate_count=row_count');
 });
});
