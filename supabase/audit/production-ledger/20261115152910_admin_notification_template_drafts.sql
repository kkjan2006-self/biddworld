create table if not exists public.notification_templates (
 id uuid primary key default gen_random_uuid(),
 name text not null check (length(btrim(name)) between 2 and 100),
 channel text not null check (channel in ('in_app','email','sms')),
 subject text,
 body text not null check (length(btrim(body)) between 1 and 5000),
 is_active boolean not null default false,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint notification_template_subject_check check (
  (channel='email' and subject is not null and length(btrim(subject)) between 1 and 160)
  or (channel<>'email' and subject is null)
 )
);
alter table public.notification_templates enable row level security;
revoke all on public.notification_templates from anon,authenticated;
create or replace function public.admin_list_notification_templates()
returns table(id uuid,name text,channel text,subject text,body text,is_active boolean,created_at timestamptz,updated_at timestamptz)
language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query select t.id,t.name,t.channel,t.subject,t.body,t.is_active,t.created_at,t.updated_at
 from public.notification_templates t order by t.updated_at desc;
end;
$$;
create or replace function public.admin_save_notification_template(p_id uuid,p_name text,p_channel text,p_subject text,p_body text)
returns uuid
language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 if length(btrim(coalesce(p_name,''))) not between 2 and 100
  or p_channel not in ('in_app','email','sms')
  or length(btrim(coalesce(p_body,''))) not between 1 and 5000
  or (p_channel='email' and length(btrim(coalesce(p_subject,''))) not between 1 and 160)
 then raise exception 'Invalid notification template details'; end if;
 if p_id is null then
  insert into public.notification_templates(name,channel,subject,body,is_active,created_by)
  values(btrim(p_name),p_channel,case when p_channel='email' then btrim(p_subject) else null end,btrim(p_body),false,auth.uid())
  returning id into v_id;
 else
  update public.notification_templates t set name=btrim(p_name),channel=p_channel,
   subject=case when p_channel='email' then btrim(p_subject) else null end,
   body=btrim(p_body),updated_at=now()
  where t.id=p_id returning t.id into v_id;
  if v_id is null then raise exception 'Template not found'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_id is null then 'notification_template_created' else 'notification_template_updated' end,'notification_template',v_id,
 jsonb_build_object('name',btrim(p_name),'channel',p_channel,'is_active',false));
 return v_id;
end;
$$;
revoke all on function public.admin_list_notification_templates() from public,anon;
revoke all on function public.admin_save_notification_template(uuid,text,text,text,text) from public,anon;
grant execute on function public.admin_list_notification_templates() to authenticated;
grant execute on function public.admin_save_notification_template(uuid,text,text,text,text) to authenticated;
