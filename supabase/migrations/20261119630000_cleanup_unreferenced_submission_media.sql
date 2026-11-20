-- Safe Storage cleanup helpers run with owner privileges so policy checks can inspect
-- submission/product rows even though those tables intentionally expose no direct SELECT.
create or replace function public.can_delete_member_submission_media(p_bucket_id text,p_name text)
returns boolean language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null or p_name is null or (storage.foldername(p_name))[1] is distinct from v_uid::text then return false;end if;
 if p_bucket_id='auction-submission-media' then
  return not exists(select 1 from public.auction_submissions s where s.submitted_by=v_uid and p_name=any(s.image_paths));
 elsif p_bucket_id='product-submission-media' then
  return not exists(select 1 from public.product_submissions s where s.submitted_by=v_uid and p_name=any(s.image_paths));
 end if;
 return false;
end;
$function$;

create or replace function public.can_delete_pending_auction_public_media(p_name text)
returns boolean language plpgsql stable security definer set search_path=''
as $function$
begin
 return coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
  and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review'
  and exists(select 1 from public.auction_submissions s
   where s.status='pending' and s.submitted_by::text=(storage.foldername(p_name))[1])
  and not exists(select 1 from public.products p where p.image_path=p_name or p_name=any(p.image_paths))
  and not exists(select 1 from public.auctions a where a.image_url=p_name);
end;
$function$;

create or replace function public.can_delete_approved_auction_source_media(p_name text)
returns boolean language plpgsql stable security definer set search_path=''
as $function$
begin
 return (
   coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
   or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
    and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')
  )
  and exists(select 1 from public.auction_submissions s
   where s.status='approved' and s.submitted_by::text=(storage.foldername(p_name))[1])
  and not exists(select 1 from public.auction_submissions s where p_name=any(s.image_paths));
end;
$function$;

revoke all on function public.can_delete_member_submission_media(text,text) from public,anon;
revoke all on function public.can_delete_pending_auction_public_media(text) from public,anon;
revoke all on function public.can_delete_approved_auction_source_media(text) from public,anon;
grant execute on function public.can_delete_member_submission_media(text,text) to authenticated;
grant execute on function public.can_delete_pending_auction_public_media(text) to authenticated;
grant execute on function public.can_delete_approved_auction_source_media(text) to authenticated;

-- Members may delete only their own unreferenced private auction/product submission objects.
drop policy if exists auction_submission_media_delete_unreferenced on storage.objects;
create policy auction_submission_media_delete_unreferenced on storage.objects
for delete to authenticated
using(bucket_id='auction-submission-media' and public.can_delete_member_submission_media(bucket_id,name));

drop policy if exists product_submission_media_delete_unreferenced on storage.objects;
create policy product_submission_media_delete_unreferenced on storage.objects
for delete to authenticated
using(bucket_id='product-submission-media' and public.can_delete_member_submission_media(bucket_id,name));

-- Restricted Auction Review Staff may clean up only newly copied, unreferenced public
-- images for a currently pending submission. Published product/auction images are protected.
drop policy if exists product_media_auction_review_staff_delete_unreferenced on storage.objects;
create policy product_media_auction_review_staff_delete_unreferenced on storage.objects
for delete to authenticated
using(bucket_id='product-media' and public.can_delete_pending_auction_public_media(name));

-- Admin and authorized Auction Review Staff may remove private source images only
-- after approval has replaced the submission's private paths with public paths.
drop policy if exists auction_submission_media_review_cleanup on storage.objects;
create policy auction_submission_media_review_cleanup on storage.objects
for delete to authenticated
using(bucket_id='auction-submission-media' and public.can_delete_approved_auction_source_media(name));
