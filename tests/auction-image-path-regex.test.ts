import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119180000_fix_auction_image_path_regex.sql'),'utf8');
const lifecycle=readFileSync(resolve(process.cwd(),'supabase/migrations/20261119150000_expected_price_48_hour_auction_lifecycle.sql'),'utf8');
describe('Auction submission image path validation',()=>{
 it('repairs the doubled-backslash extension matcher in both RPC definitions',()=>{
  expect(migration).toContain('pg_get_functiondef(v_signature)');
  expect(migration).toContain("chr(92)||pg_catalog.chr(92)||'.'");
  expect(migration).toContain("v_fixed = v_definition");
  expect(migration).toContain("'[.]'");
  expect(migration).toContain("'public.member_submit_auction");
  expect(migration).toContain("'public.admin_review_auction_submission");
 });
 it('confirms the original lifecycle migration used the affected path checks',()=>{
  expect(lifecycle.match(/\\\\\./g)?.length).toBeGreaterThanOrEqual(2);
 });
});
