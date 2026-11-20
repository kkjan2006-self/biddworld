-- Member product catalogue submissions with private media and mandatory Admin approval.
create table if not exists public.product_submissions(
 id uuid primary key default gen_random_uuid(),
 submitted_by uuid not null references auth.users(id),
 member_id uuid not null references public.member_ids(id),
 name text not null check(length(btrim(name)) between 2 and 160),
 description text not null check(length(btrim(description)) between 20 and 10000),
 category text,
 image_paths text[] not null check(cardinality(image_paths) between 1 and 8),
 optional_details jsonb not null default '{}'::jsonb,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 review_note text,
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 product_id uuid references public.products(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists product_submissions_pending_idx on public.product_submissions(status,created_at,id);
create index if not exists product_submissions_owner_idx on public.product_submissions(submitted_by,created_at desc,id desc);
alter table public.product_submissions enable row level security;
revoke all on public.product_submissions from public,anon,authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('product-submission-media','product-submission-media',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists product_submission_media_insert on storage.objects;
create policy product_submission_media_insert on storage.objects for insert to authenticated
with check(bucket_id='product-submission-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists product_submission_media_select on storage.objects;
create policy product_submission_media_select on storage.objects for select to authenticated
using(bucket_id='product-submission-media' and (
 (storage.foldername(name))[1]=(select auth.uid())::text
 or coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
));
create or replace function public.member_submit_product_listing(
 p_name text,p_description text,p_category text,p_image_paths text[],p_optional_details jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_member uuid;v_id uuid;v_path text;
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 select m.id into v_member from public.member_ids m join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active'
 order by m.created_at,m.id limit 1;
 if v_member is null then raise exception 'An active Main ID is required to submit a product' using errcode='42501';end if;
 if length(btrim(coalesce(p_name,'')))<2 or length(btrim(p_name))>160
  or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000 then
  raise exception 'Enter a product name (2–160 characters) and description (20–10000 characters)' using errcode='22023';end if;
 if p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8 then
  raise exception 'Upload between 1 and 8 product images' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_uid::text||'/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$')
   or not exists(select 1 from storage.objects o where o.bucket_id='product-submission-media' and o.name=v_path) then
   raise exception 'An image path is invalid, missing or does not belong to your account' using errcode='22023';end if;
 end loop;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000
  or exists(select 1 from jsonb_each(p_optional_details) item where jsonb_typeof(item.value)<>'string') then
  raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 insert into public.product_submissions(submitted_by,member_id,name,description,category,image_paths,optional_details)
 values(v_uid,v_member,btrim(p_name),btrim(p_description),nullif(btrim(coalesce(p_category,'')),''),p_image_paths,p_optional_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'product.submitted_for_review','product_submission',v_id,jsonb_build_object('member_id',v_member,'name',btrim(p_name),'image_count',cardinality(p_image_paths)));
 return v_id;
end;$function$;
create or replace function public.member_list_own_product_submissions()
returns setof public.product_submissions language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null then raise exception 'Sign in is required' using errcode='42501';end if;
 return query select s.* from public.product_submissions s where s.submitted_by=auth.uid() order by s.created_at desc,s.id desc;
end;$function$;
create or replace function public.admin_list_product_submissions()
returns setof public.product_submissions language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';end if;
 return query select s.* from public.product_submissions s where s.status='pending' order by s.created_at,s.id;
end;$function$;
create or replace function public.admin_review_product_submission(
 p_submission_id uuid,p_decision text,p_review_note text default null,p_public_image_path text default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_s public.product_submissions%rowtype;v_product uuid;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';end if;
 if p_decision not in ('approve','reject') or length(coalesce(p_review_note,''))>500 then
  raise exception 'Invalid review decision or note' using errcode='22023';end if;
 select * into v_s from public.product_submissions where id=p_submission_id for update;
 if not found or v_s.status<>'pending' then raise exception 'Product submission is not pending review' using errcode='55000';end if;
 if p_decision='reject' then
  update public.product_submissions set status='rejected',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now() where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'product.submission_rejected','product_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
 if p_public_image_path is null or p_public_image_path !~ '^[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$'
  or not exists(select 1 from storage.objects o where o.bucket_id='product-media' and o.name=p_public_image_path) then
  raise exception 'An approved public product image must be uploaded before publication' using errcode='22023';end if;
 insert into public.products(name,description,image_path,category,status)
 values(v_s.name,v_s.description,p_public_image_path,v_s.category,'published') returning id into v_product;
 update public.product_submissions set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),product_id=v_product,updated_at=now()
 where id=v_s.id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'product.submission_approved','product_submission',v_s.id,jsonb_build_object('product_id',v_product,'member_id',v_s.member_id));
 return jsonb_build_object('success',true,'status','approved','product_id',v_product);
end;$function$;
revoke all on function public.member_submit_product_listing(text,text,text,text[],jsonb) from public,anon;
grant execute on function public.member_submit_product_listing(text,text,text,text[],jsonb) to authenticated;
revoke all on function public.member_list_own_product_submissions() from public,anon;
grant execute on function public.member_list_own_product_submissions() to authenticated;
revoke all on function public.admin_list_product_submissions() from public,anon;
grant execute on function public.admin_list_product_submissions() to authenticated;
revoke all on function public.admin_review_product_submission(uuid,text,text,text) from public,anon;
grant execute on function public.admin_review_product_submission(uuid,text,text,text) to authenticated;
