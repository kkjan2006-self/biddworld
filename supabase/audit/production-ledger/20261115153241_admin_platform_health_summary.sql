create or replace function public.admin_get_platform_health()
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_tables int; v_rls_enabled int; v_rls_missing int; v_last_audit timestamptz; v_settings int;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 select count(*)::int,count(*) filter(where c.relrowsecurity)::int,count(*) filter(where not c.relrowsecurity)::int
 into v_tables,v_rls_enabled,v_rls_missing
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind='r';
 select max(created_at) into v_last_audit from public.audit_logs;
 select count(*)::int into v_settings from public.app_settings;
 return jsonb_build_object('public_tables',v_tables,'rls_enabled_tables',v_rls_enabled,'tables_without_rls',v_rls_missing,'settings_count',v_settings,'last_audit_at',v_last_audit,'checked_at',now());
end;
$$;
revoke all on function public.admin_get_platform_health() from public,anon;
grant execute on function public.admin_get_platform_health() to authenticated;
