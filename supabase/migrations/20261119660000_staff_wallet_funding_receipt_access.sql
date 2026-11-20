-- Restrict Staff receipt reads to pending Main Wallet funding requests.
-- Primary Admin retains access to all private funding receipts.
create or replace function public.can_read_wallet_funding_receipt(p_name text)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and p_name is not null and (
  coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  or (
   coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
   and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review'
   and exists(select 1 from public.wallet_fund_requests r
    where r.receipt_path=p_name and r.status='pending')
  )
 );
$function$;
revoke all on function public.can_read_wallet_funding_receipt(text) from public,anon;
grant execute on function public.can_read_wallet_funding_receipt(text) to authenticated;

drop policy if exists wallet_funding_receipts_admin_read on storage.objects;
create policy wallet_funding_receipts_admin_read on storage.objects
for select to authenticated
using(bucket_id='wallet-funding-receipts' and public.can_read_wallet_funding_receipt(name));
