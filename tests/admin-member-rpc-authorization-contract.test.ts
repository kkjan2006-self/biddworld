import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const contracts=[
 {name:'Admin Main ID structure report',path:'supabase/migrations/20261116130000_restore_admin_report_rpc_authorization.sql',fn:'admin_get_member_structure',signature:'()'},
 {name:'Admin Main ID directory',path:'supabase/migrations/20261116090000_admin_members_sponsors_pagination.sql',fn:'admin_list_members_sponsors_page',signature:'(text,integer,integer)'},
 {name:'Admin Duplicate ID directory',path:'supabase/migrations/20261116110000_admin_duplicate_id_pagination.sql',fn:'admin_list_duplicate_ids_page',signature:'(text,integer,integer)'},
 {name:'Admin member profile update',path:'supabase/migrations/20261117120000_admin_update_member_profile.sql',fn:'admin_update_member_profile',signature:'(text,text,text)'},
 {name:'Admin Duplicate ID status change',path:'supabase/migrations/20261117130000_admin_duplicate_status_noop_guard.sql',fn:'admin_set_duplicate_id_status',signature:'(uuid,text)'},
 {name:'Admin sponsor graph update',path:'supabase/migrations/20261117100000_serialize_admin_sponsor_graph_changes.sql',fn:'admin_set_member_sponsor',signature:'(text,text)'},
];

describe('Admin member-management RPC security contracts',()=>{
 for(const contract of contracts){
  const sql=readFileSync(resolve(process.cwd(),contract.path),'utf8');
  it(contract.name+' requires trusted Admin authorization and a hardened execution context',()=>{
   const start=sql.indexOf('create or replace function public.'+contract.fn);
   expect(start).toBeGreaterThanOrEqual(0);
   const end=sql.indexOf('$function$;',start);
   expect(end).toBeGreaterThan(start);
   const definition=sql.slice(start,end);
   expect(definition).toMatch(/security definer/i);
   expect(definition).toMatch(/set search_path\s*(?:=|to)\s*''/i);
   expect(definition).toContain('auth.uid()');
   expect(definition).toContain("auth.jwt()->'app_metadata'->>'role'");
   expect(definition).toMatch(/<>\s*'admin'/i);
   expect(definition).toContain('Administrator access required');
   expect(sql).toContain('revoke all on function public.'+contract.fn+contract.signature+' from public,');
   expect(sql).toContain('grant execute on function public.'+contract.fn+contract.signature+' to authenticated;');
  });
 }
});
