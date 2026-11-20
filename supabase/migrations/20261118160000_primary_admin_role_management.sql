-- Trusted primary-Admin-only role assignment for existing Auth users.
-- The primary Admin identity is fixed to the owner-designated account.
-- Role claims live in raw_app_meta_data, never user-editable metadata.

create or replace function public.admin_set_user_admin_role(p_email text,p_grant_admin boolean,p_reason text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_target_id uuid; v_target_email text; v_metadata jsonb;
 v_admin_count integer;
begin
 if v_uid is null
  or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'
  or lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com' then
  raise exception 'Only the designated Primary Admin can change Admin access' using errcode='42501';
 end if;
 if p_grant_admin is null or length(trim(coalesce(p_email,'')))<5 or length(p_email)>254
  or p_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' then
  raise exception 'Enter a valid existing account email and role action' using errcode='22023';
 end if;
 if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Provide a reason between 5 and 500 characters' using errcode='22023';
 end if;
 select id,email,coalesce(raw_app_meta_data,'{}'::jsonb)
 into v_target_id,v_target_email,v_metadata
 from auth.users where lower(email)=lower(trim(p_email)) for update;
 if not found then raise exception 'No registered account exists with that email' using errcode='P0002'; end if;
 if v_target_id=v_uid and not p_grant_admin then
  raise exception 'The Primary Admin cannot revoke their own access' using errcode='55000';
 end if;
 if p_grant_admin then
  update auth.users set raw_app_meta_data=jsonb_set(v_metadata,'{role}','"admin"'::jsonb,true)
  where id=v_target_id;
 else
  if lower(v_target_email)='kkjan2006@gmail.com' then raise exception 'Primary Admin access cannot be revoked' using errcode='55000'; end if;
  select count(*) into v_admin_count from auth.users where coalesce(raw_app_meta_data->>'role','')='admin';
  if v_admin_count<=1 then raise exception 'At least one Admin account must remain' using errcode='55000'; end if;
  update auth.users set raw_app_meta_data=v_metadata-'role' where id=v_target_id;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,case when p_grant_admin then 'admin_access.granted' else 'admin_access.revoked' end,
  'auth.users',v_target_id,jsonb_build_object('target_email',v_target_email,'reason',trim(p_reason)));
 return jsonb_build_object('success',true,'user_id',v_target_id,'email',v_target_email,
  'app_role',case when p_grant_admin then 'admin' else 'member' end,
  'note','The target user must refresh their session to receive the updated role claim.');
end;
$function$;
revoke all on function public.admin_set_user_admin_role(text,boolean,text) from public,anon;
grant execute on function public.admin_set_user_admin_role(text,boolean,text) to authenticated;
