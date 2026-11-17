-- BiddWorld Production migration-recovery evidence bundle
-- READ ONLY: run in Supabase SQL Editor using a read-only database role where possible.
-- Do not paste secrets or copy member/customer rows. This script returns catalog definitions only.
-- No DDL, DML, RPC calls, or migration-history writes are performed.

-- 1) Sponsor/duplicate-ID RPC overloads and exact live definitions.
select p.oid::regprocedure::text as signature,
       pg_get_function_identity_arguments(p.oid) as identity_arguments,
       pg_get_function_result(p.oid) as return_type,
       p.prosecdef as security_definer,
       p.proconfig as function_settings,
       pg_get_userbyid(p.proowner) as owner,
       p.proacl as acl,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'admin_set_member_sponsor',
    'admin_create_duplicate_member_id',
    'lookup_sponsor',
    'admin_list_members_sponsors',
    'admin_list_members_sponsors_page'
  )
order by p.proname, p.oid::regprocedure::text;

-- 2) Relevant tables: columns, types, defaults, nullability and identity.
select c.table_name, c.ordinal_position, c.column_name, c.data_type,
       c.udt_name, c.is_nullable, c.column_default, c.is_identity
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name in ('member_ids','members','member_profiles','member_relationships',
                       'duplicate_member_ids','platform_settings','audit_logs')
order by c.table_name, c.ordinal_position;

-- 3) Constraints on the same graph/lifecycle tables.
select con.conrelid::regclass::text as table_name,
       con.conname, con.contype, pg_get_constraintdef(con.oid) as definition,
       con.convalidated
from pg_constraint con
join pg_class rel on rel.oid = con.conrelid
join pg_namespace n on n.oid = rel.relnamespace
where n.nspname = 'public'
  and rel.relname in ('member_ids','members','member_profiles','member_relationships',
                      'duplicate_member_ids','platform_settings','audit_logs')
order by table_name, con.conname;

-- 4) Policies and grants for relevant tables.
select schemaname, tablename, policyname, permissive, roles,
       cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('member_ids','members','member_profiles','member_relationships',
                    'duplicate_member_ids','platform_settings','audit_logs')
order by tablename, policyname;

select table_schema, table_name, grantee, privilege_type, is_grantable
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('member_ids','members','member_profiles','member_relationships',
                     'duplicate_member_ids','platform_settings','audit_logs')
order by table_name, grantee, privilege_type;

-- 5) Triggers and trigger function definitions for relevant tables.
select t.tgrelid::regclass::text as table_name,
       t.tgname, pg_get_triggerdef(t.oid) as trigger_definition,
       p.oid::regprocedure::text as trigger_function,
       pg_get_functiondef(p.oid) as trigger_function_definition
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
join pg_proc p on p.oid = t.tgfoid
where not t.tgisinternal
  and n.nspname = 'public'
  and c.relname in ('member_ids','members','member_profiles','member_relationships',
                    'duplicate_member_ids','platform_settings','audit_logs')
order by table_name, t.tgname;

-- 6) Index definitions for relevant graph and settings tables.
select schemaname, tablename, indexname, indexdef
from pg_indexes
where schemaname = 'public'
  and tablename in ('member_ids','members','member_profiles','member_relationships',
                    'duplicate_member_ids','platform_settings','audit_logs')
order by tablename, indexname;
