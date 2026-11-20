import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const sql=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116160000_minimize_public_sponsor_lookup.sql'),'utf8');
const app=readFileSync(resolve(process.cwd(),'src/App.tsx'),'utf8');
describe('Public sponsor lookup privacy',()=>{
 it('returns only a boolean and does not disclose member code or display name',()=>{
  expect(sql).toMatch(/returns boolean/i);
  expect(sql).toMatch(/select exists\s*\(/i);
  expect(sql.replace(/--[^\n]*/g,'')).not.toMatch(/returns table/i);
 });
 it('keeps exact active Main ID matching and least-privilege grants',()=>{
  expect(sql).toContain("m.id_type = 'main'");
  expect(sql).toContain("m.status = 'active'");
  expect(sql).toContain('grant execute on function public.lookup_sponsor(text) to anon, authenticated;');
  expect(sql).toContain('revoke all on function public.lookup_sponsor(text) from public, anon, authenticated;');
 });
 it('does not trust lookup as the final sponsor validation',()=>{
  expect(app).toContain("sponsor_referral_id:sponsorId.trim()||null");
  expect(app).toContain("client.rpc('lookup_sponsor'");
 });
 it('debounces public lookup and does not send incomplete codes',()=>{
  expect(app).toContain('sponsorLookupTimer');
  expect(app).toContain('clearTimeout(sponsorLookupTimer.current)');
  expect(app).toContain('value.trim().length<12');
 });
});
