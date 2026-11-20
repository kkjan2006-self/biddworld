-- Let explicitly assigned Package Activation Review Staff inspect only receipts
-- attached to pending activations. Members remain unable to read private receipts.
create or replace function public.can_read_package_activation_receipt(p_name text)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and p_name is not null and (
  coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  or (
   coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
   and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'package_activation_review'
   and exists(select 1 from public.package_activations a
    where a.receipt_path=p_name and a.payment_status='pending' and a.activation_status='pending')
  )
 );
$function$;
revoke all on function public.can_read_package_activation_receipt(text) from public,anon;
grant execute on function public.can_read_package_activation_receipt(text) to authenticated;

drop policy if exists package_receipts_select_admin on storage.objects;
drop policy if exists package_receipts_select_admin_or_assigned_staff on storage.objects;
create policy package_receipts_select_admin_or_assigned_staff on storage.objects
for select to authenticated
using(bucket_id='package-receipts' and public.can_read_package_activation_receipt(name));
