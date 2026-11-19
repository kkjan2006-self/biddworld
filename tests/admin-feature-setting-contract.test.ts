import {readFileSync} from 'node:fs';
import {describe,it,expect} from 'vitest';
const admin=readFileSync('src/components/Admin.tsx','utf8');
const sql=readFileSync('supabase/migrations/20261119530000_remove_email_verification_switch.sql','utf8');
const get=sql.slice(sql.indexOf('from public.app_settings where setting_key=any(array['),sql.indexOf(']);',sql.indexOf('from public.app_settings where setting_key=any(array[')));
const allow=sql.slice(sql.indexOf('if p_setting_key is null or p_setting_key<>all(array['),sql.indexOf(']) then',sql.indexOf('if p_setting_key is null or p_setting_key<>all(array[')));
const enabled=sql.match(/v_enabled_keys text\[\]:=array\[([\s\S]*?)\];/)?.[1]??'';
describe('Admin feature setting contract parity',()=>{
 it('returns every visible Admin switch from the settings RPC',()=>{
  for(const key of [...admin.matchAll(/key:'([a-z][a-z0-9_]+_enabled)'/g)].map(x=>x[1]))expect(get).toContain("'"+key+"'");
 });
 it('allows and marks ready every visible switch consistently',()=>{
  const ready=admin.match(/const featureEnableReadyKeys=new Set\(\[([^\]]*)\]\)/)?.[1]??'';
  for(const key of [...ready.matchAll(/'([a-z][a-z0-9_]+_enabled)'/g)].map(x=>x[1])){expect(allow).toContain("'"+key+"'");expect(enabled).toContain("'"+key+"'");}
 });
 it('does not expose removed legacy or non-actionable switches',()=>{
  expect(admin).not.toContain('email_verification_required');
  expect(admin).not.toContain('automatic_placement_enabled');
  expect(admin).not.toContain('winner_selection_configured');
  expect(sql).not.toContain("'winner_selection_configured'");
 });
});
