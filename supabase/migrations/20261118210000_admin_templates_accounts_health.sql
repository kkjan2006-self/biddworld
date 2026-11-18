-- Admin notification template drafts, Admin account directory, and read-only platform health.
-- Templates are stored as inactive drafts only; this migration does not dispatch email or SMS.

create table if not exists public.notification_templates (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 channel text not null,
 subject text,
 body text not null,
 is_active boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint notification_templates_name_length check (char_length(btrim(name)) between 2 and 100),
 constraint notification_templates_channel_check check (channel in ('in_app','email','sms')),
 constraint notification_templates_subject_length check (subject is null or char_length(subject)<=160),
 constraint notification_templates_body_length check (char_length(btrim(body)) between 1 and 5000),
 constraint notification_templates_email_subject_check check (channel<>'email' or nullif(btrim(subject),'') is not null)
);

alter table public.notification_templates enable row level security;
revoke all on table public.notification_templates from public,anon,authenticated;

create or replace function public.admin_list_notification_templates()
returns table(
 id uuid,
 name text,
 channel text,
 subject text,
 body text,
 is_active boolean,
 created_at timestamptz,
 updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return query
 select t.id,t.name,t.channel,t.subject,t.body,t.is_active,t.created_at,t.updated_at
 from public.notification_templates t
 order by t.updated_at desc,t.id;
end;
$function$;

create or replace function public.admin_save_notification_template(
 p_id uuid,p_name text,p_channel text,p_subject text,p_body text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_id uuid;
 v_name text:=btrim(coalesce(p_name,''));
 v_subject text:=nullif(btrim(coalesce(p_subject,'')),'');
 v_body text:=btrim(coalesce(p_body,''));
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if char_length(v_name)<2 or char_length(v_name)>100 then
  raise exception 'Template name must contain 2 to 100 characters' using errcode='22023';
 end if;
 if p_channel is null or p_channel not in ('in_app','email','sms') then
  raise exception 'Choose a supported notification channel' using errcode='22023';
 end if;
 if char_length(v_body)<1 or char_length(v_body)>5000 then
  raise exception 'Template body must contain 1 to 5,000 characters' using errcode='22023';
 end if;
 if p_channel='email' and (v_subject is null or char_length(v_subject)>160) then
  raise exception 'Email templates require a subject of up to 160 characters' using errcode='22023';
 end if;
 if p_channel<>'email' then v_subject:=null; end if;

 if p_id is null then
  insert into public.notification_templates(name,channel,subject,body,is_active)
  values(v_name,p_channel,v_subject,v_body,false)
  returning id into v_id;
 else
  update public.notification_templates
  set name=v_name,channel=p_channel,subject=v_subject,body=v_body,
      is_active=false,updated_at=now()
  where id=p_id
  returning id into v_id;
  if v_id is null then
   raise exception 'Notification template was not found' using errcode='P0002';
  end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),'notification_template.saved','notification_templates',v_id,
  jsonb_build_object('name',v_name,'channel',p_channel,'active',false));
 return jsonb_build_object('success',true,'id',v_id,'is_active',false);
end;
$function$;

create or replace function public.admin_list_admin_accounts()
returns table(
 user_id uuid,
 email text,
 created_at timestamptz,
 last_sign_in_at timestamptz,
 app_role text
)
language plpgsql
stable
security definer
set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return query
 select u.id,u.email::text,u.created_at,u.last_sign_in_at,
  coalesce(u.raw_app_meta_data->>'role','member')
 from auth.users u
 where coalesce(u.raw_app_meta_data->>'role','')='admin'
 order by u.created_at,u.id;
end;
$function$;

create or replace function public.admin_get_platform_health()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_public_tables bigint:=0;
 v_rls_tables bigint:=0;
 v_tables_without_rls bigint:=0;
 v_settings_count bigint:=0;
 v_last_audit_at timestamptz;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;

 select count(*),count(*) filter(where c.relrowsecurity),
  count(*) filter(where not c.relrowsecurity)
 into v_public_tables,v_rls_tables,v_tables_without_rls
 from pg_catalog.pg_class c
 join pg_catalog.pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind in ('r','p')
  and not c.relispartition;

 if pg_catalog.to_regclass('public.app_settings') is not null then
  execute 'select count(*) from public.app_settings' into v_settings_count;
 end if;
 select max(a.created_at) into v_last_audit_at from public.audit_logs a;

 return jsonb_build_object(
  'public_tables',v_public_tables,
  'rls_enabled_tables',v_rls_tables,
  'tables_without_rls',v_tables_without_rls,
  'settings_count',v_settings_count,
  'last_audit_at',v_last_audit_at,
  'checked_at',now()
 );
end;
$function$;

revoke all on function public.admin_list_notification_templates() from public,anon;
revoke all on function public.admin_save_notification_template(uuid,text,text,text,text) from public,anon;
revoke all on function public.admin_list_admin_accounts() from public,anon;
revoke all on function public.admin_get_platform_health() from public,anon;
grant execute on function public.admin_list_notification_templates() to authenticated;
grant execute on function public.admin_save_notification_template(uuid,text,text,text,text) to authenticated;
grant execute on function public.admin_list_admin_accounts() to authenticated;
grant execute on function public.admin_get_platform_health() to authenticated;

comment on table public.notification_templates is
 'Admin-managed inactive notification template drafts. Saving a template never dispatches a message.';
