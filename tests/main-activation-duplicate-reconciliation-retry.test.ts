import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119370000_retry_main_activation_duplicate_reconciliation.sql'),'utf8');

describe('Main-ID activation duplicate reconciliation retry',()=>{
 it('does not return early for an already-active Main ID before child reconciliation',()=>{
  expect(migration).not.toMatch(/if\s+v_old_status\s*=\s*p_status\s+then[\s\S]{0,180}return/i);
  expect(migration).toContain("elsif p_status='active' then");
  expect(migration).toContain('-- Retry this reconciliation even if the Main ID was already active.');
 });
 it('restores only Main-managed suspended duplicates whose placement parent is active and external',()=>{
  expect(migration).toContain("d.status='suspended' and d.main_status_managed");
  expect(migration).toContain("parent.status='active'");
  expect(migration).toContain("parent.owner_user_id is distinct from d.owner_user_id");
  expect(migration).toContain("set status='active',main_status_managed=false");
 });
 it('keeps closed Main IDs irreversible and audits actual reconciliation changes',()=>{
  expect(migration).toContain("if v_old_status='closed' and p_status<>'closed' then");
  expect(migration).toContain('if v_main_changed or v_duplicate_count>0 then');
  expect(migration).toContain("'reconciliation_retry',not v_main_changed and p_status='active'");
 });
});
