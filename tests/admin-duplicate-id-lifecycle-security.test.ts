import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {describe,expect,it} from 'vitest';

const lifecycle=readFileSync(resolve(process.cwd(),'supabase/migrations/20261115150000_admin_duplicate_id_lifecycle.sql'),'utf8');
const noop=readFileSync(resolve(process.cwd(),'supabase/migrations/20261117130000_admin_duplicate_status_noop_guard.sql'),'utf8');

describe('Admin Duplicate ID lifecycle security contract',()=>{
  it('restricts lifecycle RPCs to authenticated trusted Admin role',()=>{
    for(const name of ['admin_list_duplicate_ids','admin_create_duplicate_member_id','admin_set_duplicate_id_status']){
      const start=lifecycle.indexOf(`function public.${name}`);
      expect(start).toBeGreaterThanOrEqual(0);
      const body=lifecycle.slice(start,lifecycle.indexOf('$function$;',start)+11);
      expect(body).toContain('security definer');
      expect(body).toContain("set search_path = ''");
      expect(body).toMatch(/if (?:v_uid is null|auth\.uid\(\) is null) or coalesce\(auth\.jwt\(\)->'app_metadata'->>'role',''\) <> 'admin'/);
    }
  });

  it('creates a Duplicate ID only under a locked active Main ID and existing owner',()=>{
    const start=lifecycle.indexOf('function public.admin_create_duplicate_member_id');
    const body=lifecycle.slice(start,lifecycle.indexOf('$function$;',start)+11);
    expect(body).toContain("id_type='main' and status='active'");
    expect(body).toContain('for update');
    expect(body).toContain('values(v_main.owner_user_id,v_main.id,v_code,\'duplicate\',\'pending\')');
    expect(body).not.toContain('insert into public.profiles');
    expect(body).not.toContain('insert into public.wallet_accounts');
    expect(body).toContain("'duplicate_id_created'");
  });

  it('keeps closed Duplicate IDs non-reactivatable and audits real status transitions',()=>{
    const start=lifecycle.indexOf('function public.admin_set_duplicate_id_status');
    const body=lifecycle.slice(start,lifecycle.indexOf('$function$;',start)+11);
    expect(body).toContain("where id=p_duplicate_id and id_type='duplicate'");
    expect(body).toContain('for update');
    expect(body).toContain("v_row.status='closed' and p_status<>'closed'");
    expect(body).toContain("'duplicate_id_status_changed'");
  });

  it('returns an idempotent no-op without a write or audit event for unchanged status',()=>{
    const start=noop.indexOf('function public.admin_set_duplicate_id_status');
    const body=noop.slice(start,noop.indexOf('$function$;',start)+11);
    const guard=body.indexOf('if v_old_status=p_status then');
    expect(guard).toBeGreaterThanOrEqual(0);
    const noOpBranch=body.slice(guard,body.indexOf('end if;',guard));
    expect(noOpBranch).toContain("'changed',false");
    expect(noOpBranch).not.toContain('update public.member_ids');
    expect(noOpBranch).not.toContain('insert into public.audit_logs');
    expect(body).toContain("'changed',true");
  });

  it('does not introduce an inferred Main ID to Duplicate ID cascade',()=>{
    expect(lifecycle).not.toMatch(/update public\.member_ids[\s\S]{0,300}main_member_id\s*=\s*v_row\.id/i);
    expect(lifecycle).not.toContain('admin_set_main_member_status');
    expect(noop).not.toContain('admin_set_main_member_status');
  });
});
