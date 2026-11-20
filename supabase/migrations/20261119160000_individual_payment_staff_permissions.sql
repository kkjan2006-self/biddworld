-- Allow the Primary Admin to assign each restricted Staff review permission independently.
create or replace function public.admin_update_payment_review_staff_permissions(
 p_user_id uuid,p_permissions text[],p_reason text
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();v_email text;v_role text;v_current jsonb;v_clean text[];
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'
  or lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com' then
  raise exception 'Only the designated Primary Admin can manage Staff permissions' using errcode='42501';
 end if;
 if p_user_id is null or length(btrim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Select a Staff account and provide a reason of 5–500 characters' using errcode='22023';
 end if;
 if p_permissions is null then raise exception 'Choose at least one permission or revoke Staff access separately' using errcode='22023';end if;
 select array_agg(distinct x order by x) into v_clean
 from unnest(p_permissions) x
 where x in ('package_activation_review','wallet_funding_review','auction_submission_review');
 if coalesce(cardinality(v_clean),0)<>cardinality(p_permissions) or cardinality(v_clean)=0 then
  raise exception 'Select only supported Staff permissions' using errcode='22023';end if;
 select email,coalesce(raw_app_meta_data->>'role',''),coalesce(raw_app_meta_data->'permissions','[]'::jsonb)
 into v_email,v_role,v_current from auth.users where id=p_user_id for update;
 if not found then raise exception 'Staff account not found' using errcode='P0002';end if;
 if lower(coalesce(v_email,''))='kkjan2006@gmail.com' or v_role<>'admin_staff' then
  raise exception 'Only an existing restricted Staff account can be updated' using errcode='55000';end if;
 update auth.users set raw_app_meta_data=jsonb_set(coalesce(raw_app_meta_data,'{}'::jsonb),'{permissions}',to_jsonb(v_clean),true)
 where id=p_user_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'payment_review_staff.permissions_updated','auth.users',p_user_id,
  jsonb_build_object('target_email',v_email,'previous_permissions',v_current,'new_permissions',to_jsonb(v_clean),'reason',btrim(p_reason)));
 return jsonb_build_object('success',true,'email',v_email,'permissions',to_jsonb(v_clean),
  'note','The Staff member must sign out and sign in again to refresh role claims.');
end;
$function$;
revoke all on function public.admin_update_payment_review_staff_permissions(uuid,text[],text) from public,anon;
grant execute on function public.admin_update_payment_review_staff_permissions(uuid,text[],text) to authenticated;
