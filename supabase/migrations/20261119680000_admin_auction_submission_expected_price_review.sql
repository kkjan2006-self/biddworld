-- Restore the Admin/Staff auction-submission approval RPC with the current Expected Price contract.
-- The previous lifecycle migration removed the fixed-end-time RPC but did not install its
-- replacement, leaving the moderation UI unable to approve any member auction submission.

do $constraint$
begin
 if not exists(
  select 1 from pg_catalog.pg_constraint
  where conrelid='public.auction_submissions'::regclass
    and conname='auction_submission_expected_price_check'
 ) then
  alter table public.auction_submissions
   add constraint auction_submission_expected_price_check
   check(expected_price is null or expected_price>=starting_price) not valid;
 end if;
 if not exists(
  select 1 from pg_catalog.pg_constraint
  where conrelid='public.auction_submissions'::regclass
    and conname='auction_submission_pending_expected_price_required'
 ) then
  alter table public.auction_submissions
   add constraint auction_submission_pending_expected_price_required
   check(status<>'pending' or expected_price is not null) not valid;
 end if;
end;
$constraint$;

-- Remove the obsolete fixed-end-time signature. New approvals have no fixed end time;
-- auctions.ends_at is populated only by the expected-price 48-hour lifecycle trigger.
drop function if exists public.admin_review_auction_submission(
 uuid,text,text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb,text
);

create or replace function public.admin_review_auction_submission(
 p_submission_id uuid,
 p_decision text,
 p_title text,
 p_description text,
 p_category text,
 p_image_paths text[],
 p_starting_price numeric,
 p_expected_price numeric,
 p_minimum_increment numeric,
 p_starts_at timestamptz,
 p_optional_details jsonb,
 p_review_note text default null
) returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_s public.auction_submissions%rowtype;
 v_product uuid;
 v_auction uuid;
 v_path text;
 v_status public.auction_status;
begin
 if v_uid is null or not(
  v_role='admin'
  or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')
 ) then
  raise exception 'Auction submission review permission required' using errcode='42501';
 end if;
 if p_decision is null or p_decision not in ('approve','reject')
  or length(coalesce(p_review_note,''))>500 then
  raise exception 'Invalid review decision or note' using errcode='22023';
 end if;

 select * into v_s
 from public.auction_submissions
 where id=p_submission_id
 for update;
 if not found or v_s.status<>'pending' then
  raise exception 'Submission is not pending review' using errcode='55000';
 end if;

 if p_decision='reject' then
  update public.auction_submissions
  set status='rejected',
      review_note=nullif(btrim(coalesce(p_review_note,'')),''),
      reviewed_by=v_uid,reviewed_at=now(),updated_at=now()
  where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'auction.submission_rejected','auction_submission',v_s.id,
   jsonb_build_object('review_note',p_review_note,'reviewer_role',v_role));
  return jsonb_build_object('success',true,'status','rejected');
 end if;

 if length(btrim(coalesce(p_title,'')))<5 or length(btrim(p_title))>180
  or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000
  or p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8
  or cardinality(p_image_paths)<>cardinality(v_s.image_paths)
  or (select count(distinct image_path) from pg_catalog.unnest(p_image_paths) as paths(image_path))<>cardinality(p_image_paths)
  or p_starting_price is null or p_starting_price<=0
  or p_expected_price is null or p_expected_price<p_starting_price
  or p_minimum_increment is null or p_minimum_increment<=0
  or p_starts_at is null or p_starts_at<now()
  or p_optional_details is null or pg_catalog.jsonb_typeof(p_optional_details)<>'object'
  or pg_catalog.octet_length(p_optional_details::text)>12000
  or exists(select 1 from pg_catalog.jsonb_each(p_optional_details) item where pg_catalog.jsonb_typeof(item.value)<>'string') then
  raise exception 'Reviewed auction details are incomplete or invalid' using errcode='22023';
 end if;

 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_s.submitted_by::text||'/[A-Za-z0-9_-]+-[A-Za-z0-9_.-]+[.](jpg|jpeg|png|webp)$')
   or not exists(
    select 1 from storage.objects o
    where o.bucket_id='product-media' and o.name=v_path
   ) then
   raise exception 'An approved public auction image path is invalid, missing or belongs to another submission' using errcode='22023';
  end if;
 end loop;

 insert into public.products(name,description,image_path,image_paths,category,status,product_details)
 values(
  btrim(p_title),btrim(p_description),p_image_paths[1],p_image_paths,
  nullif(btrim(coalesce(p_category,'')),''),'published',p_optional_details
 )
 returning id into v_product;

 v_status:=case when p_starts_at<=now() then 'live'::public.auction_status else 'scheduled'::public.auction_status end;
 insert into public.auctions(
  product_id,title,description,image_url,category,currency,
  starting_price,current_price,minimum_increment,starts_at,ends_at,
  expected_price,target_reached_at,status
 )
 values(
  v_product,btrim(p_title),btrim(p_description),p_image_paths[1],
  nullif(btrim(coalesce(p_category,'')),''),'INR',
  p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,null,
  p_expected_price,null,v_status
 )
 returning id into v_auction;

 update public.auction_submissions
 set status='approved',
     review_note=nullif(btrim(coalesce(p_review_note,'')),''),
     reviewed_by=v_uid,reviewed_at=now(),updated_at=now(),
     auction_id=v_auction,
     title=btrim(p_title),description=btrim(p_description),
     category=nullif(btrim(coalesce(p_category,'')),''),
     image_paths=p_image_paths,
     starting_price=p_starting_price,expected_price=p_expected_price,
     minimum_increment=p_minimum_increment,starts_at=p_starts_at,ends_at=null,
     optional_details=p_optional_details
 where id=v_s.id;

 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submission_approved','auction_submission',v_s.id,
  jsonb_build_object(
   'auction_id',v_auction,'product_id',v_product,
   'seller_member_id',v_s.member_id,'reviewer_role',v_role,
   'starting_price',p_starting_price,'expected_price',p_expected_price,
   'image_count',cardinality(p_image_paths)
  ));

 return jsonb_build_object(
  'success',true,'status','approved','auction_id',v_auction,
  'product_id',v_product,'expected_price',p_expected_price
 );
end;
$function$;

revoke all on function public.admin_review_auction_submission(
 uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text
) from public,anon;
grant execute on function public.admin_review_auction_submission(
 uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text
) to authenticated;

comment on function public.admin_review_auction_submission(
 uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text
) is 'Admin or explicitly authorized auction-review Staff moderation RPC; publishes verified image gallery and creates an open-ended Expected Price auction.';
