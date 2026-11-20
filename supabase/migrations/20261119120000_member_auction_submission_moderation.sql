-- Member-submitted auctions with mandatory moderation before public catalogue publication.
create table if not exists public.auction_submissions(
 id uuid primary key default gen_random_uuid(),
 submitted_by uuid not null references auth.users(id),
 member_id uuid not null references public.member_ids(id),
 title text not null check(length(btrim(title)) between 5 and 180),
 description text not null check(length(btrim(description)) between 20 and 10000),
 category text,
 image_paths text[] not null check(cardinality(image_paths) between 1 and 8),
 starting_price numeric(14,2) not null check(starting_price>0),
 minimum_increment numeric(14,2) not null default 1 check(minimum_increment>0),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 optional_details jsonb not null default '{}'::jsonb,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 review_note text,
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 auction_id uuid references public.auctions(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint auction_submission_dates check(ends_at>starts_at)
);
create index if not exists auction_submissions_pending_idx on public.auction_submissions(status,created_at,id);
create index if not exists auction_submissions_owner_idx on public.auction_submissions(submitted_by,created_at desc,id desc);
alter table public.auction_submissions enable row level security;
revoke all on public.auction_submissions from public,anon,authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('auction-submission-media','auction-submission-media',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists auction_submission_media_insert on storage.objects;
create policy auction_submission_media_insert on storage.objects for insert to authenticated
with check(bucket_id='auction-submission-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists auction_submission_media_select on storage.objects;
create policy auction_submission_media_select on storage.objects for select to authenticated
using(bucket_id='auction-submission-media' and (
 (storage.foldername(name))[1]=(select auth.uid())::text
 or coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
 or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
  and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')
));
create or replace function public.member_submit_auction(
 p_title text,p_description text,p_category text,p_image_paths text[],
 p_starting_price numeric,p_minimum_increment numeric,p_starts_at timestamptz,p_ends_at timestamptz,
 p_optional_details jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_member uuid;v_id uuid;v_path text;
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 select m.id into v_member from public.member_ids m join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active'
 order by m.created_at,m.id limit 1;
 if v_member is null then raise exception 'An active Main ID is required to place an auction' using errcode='42501';end if;
 if length(btrim(coalesce(p_title,'')))<5 or length(btrim(p_title))>180
  or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000 then
  raise exception 'Enter a title (5–180 characters) and description (20–10000 characters)' using errcode='22023';end if;
 if p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8 then
  raise exception 'Upload between 1 and 8 item images' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_uid::text||'/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$') then
   raise exception 'An image path is invalid or does not belong to your account' using errcode='22023';end if;
 end loop;
 if p_starting_price is null or p_starting_price<=0 or p_minimum_increment is null or p_minimum_increment<=0
  or p_starts_at is null or p_ends_at is null or p_ends_at<=p_starts_at or p_starts_at<now()+interval '30 minutes' then
  raise exception 'Check starting price, bid increment and future auction schedule' using errcode='22023';end if;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000 then
  raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 insert into public.auction_submissions(submitted_by,member_id,title,description,category,image_paths,starting_price,minimum_increment,starts_at,ends_at,optional_details)
 values(v_uid,v_member,btrim(p_title),btrim(p_description),nullif(btrim(coalesce(p_category,'')),''),p_image_paths,p_starting_price,p_minimum_increment,p_starts_at,p_ends_at,p_optional_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submitted_for_review','auction_submission',v_id,jsonb_build_object('member_id',v_member,'title',btrim(p_title)));
 return v_id;
end;$function$;
create or replace function public.member_list_own_auction_submissions()
returns setof public.auction_submissions language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null then raise exception 'Sign in is required' using errcode='42501';end if;
 return query select s.* from public.auction_submissions s where s.submitted_by=auth.uid() order by s.created_at desc,s.id desc;
end;$function$;
create or replace function public.admin_list_auction_submissions()
returns setof public.auction_submissions language plpgsql stable security definer set search_path=''
as $function$
declare v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
begin
 if auth.uid() is null or not(v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')) then
  raise exception 'Auction submission review permission required' using errcode='42501';end if;
 return query select s.* from public.auction_submissions s where s.status='pending' order by s.created_at,s.id;
end;$function$;
create or replace function public.admin_review_auction_submission(
 p_submission_id uuid,p_decision text,p_title text,p_description text,p_category text,
 p_image_paths text[],p_starting_price numeric,p_minimum_increment numeric,
 p_starts_at timestamptz,p_ends_at timestamptz,p_optional_details jsonb,p_review_note text default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_s public.auction_submissions%rowtype;v_product uuid;v_auction uuid;v_path text;
begin
 if v_uid is null or not(v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')) then
  raise exception 'Auction submission review permission required' using errcode='42501';end if;
 if p_decision not in ('approve','reject') or length(coalesce(p_review_note,''))>500 then raise exception 'Invalid review decision or note' using errcode='22023';end if;
 select * into v_s from public.auction_submissions where id=p_submission_id for update;
 if not found or v_s.status<>'pending' then raise exception 'Submission is not pending review' using errcode='55000';end if;
 if p_decision='reject' then
  update public.auction_submissions set status='rejected',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now() where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(v_uid,'auction.submission_rejected','auction_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
 if length(btrim(coalesce(p_title,'')))<5 or length(btrim(p_title))>180 or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000
  or p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8
  or p_starting_price is null or p_starting_price<=0 or p_minimum_increment is null or p_minimum_increment<=0
  or p_starts_at is null or p_ends_at is null or p_ends_at<=p_starts_at or p_starts_at<now()
  or p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' then
  raise exception 'Reviewed auction details are incomplete or invalid' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if not exists(select 1 from unnest(v_s.image_paths) original(path) where original.path=v_path)
   and v_path !~ ('^'||v_s.submitted_by::text||'/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$') then
   raise exception 'Reviewed image path is invalid' using errcode='22023';end if;
 end loop;
 insert into public.products(name,description,image_path,category,status)
 values(btrim(p_title),btrim(p_description),v_s.image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'published')
 returning id into v_product;
 insert into public.auctions(product_id,title,description,image_url,category,currency,starting_price,current_price,minimum_increment,starts_at,ends_at,status)
 values(v_product,btrim(p_title),btrim(p_description),v_s.image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'INR',p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,p_ends_at,
  case when p_starts_at<=now() then 'live' else 'scheduled' end)
 returning id into v_auction;
 update public.auction_submissions set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now(),auction_id=v_auction,
  title=btrim(p_title),description=btrim(p_description),category=nullif(btrim(coalesce(p_category,'')),''),image_paths=p_image_paths,
  starting_price=p_starting_price,minimum_increment=p_minimum_increment,starts_at=p_starts_at,ends_at=p_ends_at,optional_details=p_optional_details
 where id=v_s.id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submission_approved','auction_submission',v_s.id,jsonb_build_object('auction_id',v_auction,'product_id',v_product,'seller_member_id',v_s.member_id,'reviewer_role',v_role));
 return jsonb_build_object('success',true,'status','approved','auction_id',v_auction);
end;$function$;
revoke all on function public.member_submit_auction(text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb) from public,anon;
grant execute on function public.member_submit_auction(text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb) to authenticated;
revoke all on function public.member_list_own_auction_submissions() from public,anon;
grant execute on function public.member_list_own_auction_submissions() to authenticated;
revoke all on function public.admin_list_auction_submissions() from public,anon;
grant execute on function public.admin_list_auction_submissions() to authenticated;
revoke all on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb,text) from public,anon;
grant execute on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb,text) to authenticated;
