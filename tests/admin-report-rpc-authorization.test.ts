import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';
const migration=readFileSync(resolve(process.cwd(),'supabase/migrations/20261116130000_restore_admin_report_rpc_authorization.sql'),'utf8');
describe('Production Admin report RPC authorization drift correction',()=>{
 for(const fn of ['admin_get_member_structure','admin_get_mlm_overview']){
  it(fn+' rejects non-admin callers and uses trusted app metadata',()=>{
   const start=migration.indexOf('create or replace function public.'+fn);
   const end=migration.indexOf('$function$;',start);
   expect(start).toBeGreaterThanOrEqual(0);
   const body=migration.slice(start,end);
   expect(body).toContain("auth.uid() is null");
   expect(body).toContain("auth.jwt()->'app_metadata'->>'role'");
   expect(body).toMatch(/<>\s*'admin'/i);
   expect(body).toContain("raise exception 'Administrator access required'");
   expect(body).toMatch(/set search_path\s*(?:=|to)\s*''/i);
  });
 }
 it('revokes PUBLIC and anon execution and grants only authenticated entry',()=>{
  for(const fn of ['admin_get_member_structure','admin_get_mlm_overview']){
   expect(migration).toContain('revoke all on function public.'+fn+'() from public, anon;');
   expect(migration).toContain('grant execute on function public.'+fn+'() to authenticated;');
  }
  expect(migration).toContain('NOT applied to Production');
 });
});
