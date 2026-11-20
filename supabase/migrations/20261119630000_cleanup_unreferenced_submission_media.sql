-- Allow safe cleanup of failed submission uploads without allowing deletion of referenced media.
-- Members may delete only their own unreferenced private auction/product submission objects.
drop policy if exists auction_submission_media_delete_unreferenced on storage.objects;
create policy auction_submission_media_delete_unreferenced on storage.objects
for delete to authenticated
using(
 bucket_id='auction-submission-media'
 and (storage.foldername(name))[1]=(select auth.uid())::text
 and not exists(
  select 1 from public.auction_submissions s
  where s.submitted_by=(select auth.uid()) and name=any(s.image_paths)
 )
);

drop policy if exists product_submission_media_delete_unreferenced on storage.objects;
create policy product_submission_media_delete_unreferenced on storage.objects
for delete to authenticated
using(
 bucket_id='product-submission-media'
 and (storage.foldername(name))[1]=(select auth.uid())::text
 and not exists(
  select 1 from public.product_submissions s
  where s.submitted_by=(select auth.uid()) and name=any(s.image_paths)
 )
);

-- Restricted Auction Review Staff may clean up only newly copied, unreferenced public
-- images for a currently pending submission. Published product/auction images are protected.
drop policy if exists product_media_auction_review_staff_delete_unreferenced on storage.objects;
create policy product_media_auction_review_staff_delete_unreferenced on storage.objects
for delete to authenticated
using(
 bucket_id='product-media'
 and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
 and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review'
 and exists(
  select 1 from public.auction_submissions s
  where s.status='pending'
   and s.submitted_by::text=(storage.foldername(name))[1]
 )
 and not exists(select 1 from public.products p where p.image_path=name or name=any(p.image_paths))
 and not exists(select 1 from public.auctions a where a.image_url=name)
);
