-- Package activation payment evidence is mandatory on both browser and database write paths.
create or replace function public.submit_package_activation_with_receipt(
 p_package_id uuid,p_payment_reference text,p_receipt_path text
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();v_result jsonb;v_activation_id uuid;v_enabled boolean:=false;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501';end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='package_activations_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Package activation requests are disabled' using errcode='55000';end if;
 if p_receipt_path is null or length(p_receipt_path)>300
    or (storage.foldername(p_receipt_path))[1]<>v_uid::text then
  raise exception 'Upload your payment receipt before submitting' using errcode='22023';
 end if;
 if not exists(select 1 from storage.objects where bucket_id='package-receipts' and name=p_receipt_path) then
  raise exception 'Uploaded payment receipt was not found' using errcode='22023';
 end if;
 v_result:=private.submit_package_activation(p_package_id,p_payment_reference);
 v_activation_id:=(v_result->>'activation_id')::uuid;
 update public.package_activations set receipt_path=p_receipt_path
 where id=v_activation_id and member_id=(select main_member_id from public.profiles where id=v_uid);
 if not found then raise exception 'The package activation could not be linked to its receipt' using errcode='55000';end if;
 return v_result||jsonb_build_object('receipt_path',p_receipt_path);
end;
$function$;
revoke all on function public.submit_package_activation_with_receipt(uuid,text,text) from public,anon;
grant execute on function public.submit_package_activation_with_receipt(uuid,text,text) to authenticated;
