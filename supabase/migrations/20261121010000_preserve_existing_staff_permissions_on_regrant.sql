-- Preserve explicitly assigned permissions when an existing restricted Staff member is re-granted.
-- A repeated grant must not silently remove the separately assigned Support review scope.
create or replace function public.admin_set_payment_review_staff(
 p_email text,p_enabled boolean,p_reason text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();v_target_id uuid;v_target_email text;v_metadata jsonb;
 v_permissions jsonb:='[]'::jsonb;v_was_staff boolean:=false;
begin
 if v_uid is null
  or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'
  or lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com' then
  raise exception 'Only the designated Primary Admin can manage payment-review staff' using errcode='42501';
 end if;
 if p_enabled is null or length(trim(coalesce(p_email,'')))<5 or length(p_email)>254
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
 if lower(v_target_email)='kkjan2006@gmail.com' then
  raise exception 'The Primary Admin account cannot be changed to staff' using errcode='55000';
 end if;
 if coalesce(v_metadata->>'role','')='admin' then
  raise exception 'An Admin account cannot also be assigned the restricted staff role' using errcode='55000';
 end if;
 v_was_staff:=coalesce(v_metadata->>'role','')='admin_staff';
 if p_enabled then
  if v_was_staff and jsonb_typeof(v_metadata->'permissions')='array' then
   select coalesce(jsonb_agg(permission order by permission),'[]'::jsonb)
   into v_permissions
   from jsonb_array_elements_text(v_metadata->'permissions') as item(permission)
   where permission in ('package_activation_review','wallet_funding_review','auction_submission_review','support_ticket_review');
  end if;
  if jsonb_array_length(v_permissions)=0 then
   v_permissions:='["package_activation_review","wallet_funding_review","auction_submission_review"]'::jsonb;
  end if;
  update auth.users set raw_app_meta_data=jsonb_set(
   jsonb_set(coalesce(raw_app_meta_data,'{}'::jsonb),'{role}','"admin_staff"'::jsonb,true),
   '{permissions}',v_permissions,true)
  where id=v_target_id;
 else
  update auth.users set raw_app_meta_data=coalesce(raw_app_meta_data,'{}'::jsonb)-'role'-'permissions'
  where id=v_target_id and coalesce(raw_app_meta_data->>'role','')='admin_staff';
  if not found then raise exception 'This account does not currently have the restricted payment-review staff role' using errcode='55000'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,case when p_enabled then 'payment_review_staff.granted' else 'payment_review_staff.revoked' end,
  'auth.users',v_target_id,jsonb_build_object('target_email',v_target_email,
   'permissions',v_permissions,'previous_role',v_metadata->>'role','previous_permissions',coalesce(v_metadata->'permissions','[]'::jsonb),
   'reason',trim(p_reason)));
 return jsonb_build_object('success',true,'email',v_target_email,
  'app_role',case when p_enabled then 'admin_staff' else 'member' end,
  'permissions',v_permissions,
  'note','The target user must sign out and sign in again to refresh role claims.');
end;
$function$;
revoke all on function public.admin_set_payment_review_staff(text,boolean,text) from public,anon;
grant execute on function public.admin_set_payment_review_staff(text,boolean,text) to authenticated;
