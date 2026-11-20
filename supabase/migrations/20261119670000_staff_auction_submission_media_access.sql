-- Limit Staff access to private auction images to pending submissions they are assigned to review.
-- Members retain access to their own private submission images; Admin retains full access.
create or replace function public.can_read_auction_submission_media(p_name text)
returns boolean language sql stable security definer set search_path=''
as $function$
 select auth.uid() is not null and p_name is not null and (
  (storage.foldername(p_name))[1]=(select auth.uid())::text
  or coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  or (
   coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
   and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review'
   and exists(select 1 from public.auction_submissions s
    where s.status='pending' and s.submitted_by::text=(storage.foldername(p_name))[1]
     and p_name=any(s.image_paths))
  )
 );
$function$;
revoke all on function public.can_read_auction_submission_media(text) from public,anon;
grant execute on function public.can_read_auction_submission_media(text) to authenticated;

drop policy if exists auction_submission_media_select on storage.objects;
create policy auction_submission_media_select on storage.objects
for select to authenticated
using(bucket_id='auction-submission-media' and public.can_read_auction_submission_media(name));
