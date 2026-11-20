-- Private package payment receipt uploads with member-owned Storage paths and Admin-only review.
-- Source-only until the reviewed clean-install baseline is applied to TEST.

alter table public.package_activations
 add column if not exists receipt_path text;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('package-receipts','package-receipts',false,5242880,array['image/jpeg','image/png','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=5242880,
 allowed_mime_types=array['image/jpeg','image/png','application/pdf'];

drop policy if exists package_receipts_insert_own on storage.objects;
create policy package_receipts_insert_own on storage.objects
for insert to authenticated
with check(bucket_id='package-receipts' and (storage.foldername(name))[1]=(select auth.uid())::text);

drop policy if exists package_receipts_select_own_or_admin on storage.objects;
create policy package_receipts_select_own_or_admin on storage.objects
for select to authenticated
using(bucket_id='package-receipts' and (
 (storage.foldername(name))[1]=(select auth.uid())::text
 or coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
));

-- Receipt deletion is intentionally not granted to members after upload.

create or replace function public.submit_package_activation_with_receipt(
 p_package_id uuid,p_payment_reference text,p_receipt_path text default null
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_result jsonb; v_activation_id uuid; v_enabled boolean:=false;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='package_activations_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Package activation requests are disabled' using errcode='55000'; end if;
 if p_receipt_path is not null then
  if length(p_receipt_path)>300 or (storage.foldername(p_receipt_path))[1]<>v_uid::text then
   raise exception 'Receipt path must belong to the signed-in member' using errcode='42501';
  end if;
  if not exists(select 1 from storage.objects where bucket_id='package-receipts' and name=p_receipt_path) then
   raise exception 'Uploaded payment receipt was not found' using errcode='22023';
  end if;
 end if;
 v_result:=private.submit_package_activation(p_package_id,p_payment_reference);
 v_activation_id:=(v_result->>'activation_id')::uuid;
 update public.package_activations set receipt_path=p_receipt_path
 where id=v_activation_id and member_id=(select main_member_id from public.profiles where id=v_uid);
 return v_result||jsonb_build_object('receipt_path',p_receipt_path);
end;
$function$;

create or replace function public.admin_list_pending_activations()
returns jsonb
language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',a.id,'activation_number',a.activation_number,'member_code',m.member_code,
  'member_name',p.display_name,'package_name',pkg.name,'amount_paid',a.amount_paid,
  'currency',a.currency,'bid_wallet_credit',a.bid_wallet_credit,
  'payment_reference',a.payment_reference,'receipt_path',a.receipt_path,'submitted_at',a.submitted_at
 ) order by a.submitted_at,a.id),'[]'::jsonb)
 into v_result
 from public.package_activations a
 join public.member_ids m on m.id=a.member_id
 left join public.profiles p on p.id=m.owner_user_id
 join public.packages pkg on pkg.id=a.package_id
 where a.payment_status='pending' and a.activation_status='pending';
 return v_result;
end;
$function$;

revoke all on function public.submit_package_activation_with_receipt(uuid,text,text) from public,anon;
grant execute on function public.submit_package_activation_with_receipt(uuid,text,text) to authenticated;
revoke all on function public.admin_list_pending_activations() from public,anon;
grant execute on function public.admin_list_pending_activations() to authenticated;
