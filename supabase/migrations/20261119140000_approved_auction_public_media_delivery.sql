-- Public delivery for approved member-auction media only.
-- Pending uploads remain in the private submission bucket; authorized reviewers copy
-- them to product-media immediately before approving/publishing the listing.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('product-media','product-media',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists auction_review_staff_product_media_insert on storage.objects;
create policy auction_review_staff_product_media_insert on storage.objects
for insert to authenticated
with check(bucket_id='product-media' and (
 coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
 or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
  and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')
));
