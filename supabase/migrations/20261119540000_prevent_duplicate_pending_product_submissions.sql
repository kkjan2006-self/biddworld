-- Prevent duplicate pending product submissions for the same member and normalized title.
create index if not exists product_submissions_owner_pending_name_idx
 on public.product_submissions(submitted_by,lower(btrim(name))) where status='pending';

create or replace function public.member_submit_product_listing(
 p_name text,p_description text,p_category text,p_image_paths text[],p_optional_details jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_member uuid;v_id uuid;v_path text;
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld.product_submission:'||v_uid::text,0));
 select m.id into v_member from public.member_ids m join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active'
 order by m.created_at,m.id limit 1;
 if v_member is null then raise exception 'An active Main ID is required to submit a product' using errcode='42501';end if;
 if length(btrim(coalesce(p_name,'')))<2 or length(btrim(p_name))>160
  or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000 then
  raise exception 'Enter a product name (2–160 characters) and description (20–10000 characters)' using errcode='22023';end if;
 if exists(select 1 from public.product_submissions s where s.submitted_by=v_uid and s.status='pending'
   and lower(btrim(s.name))=lower(btrim(p_name))) then
  raise exception 'A pending product submission with this name already exists. Edit that submission instead of creating a duplicate.' using errcode='23505';
 end if;
 if p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8 then
  raise exception 'Upload between 1 and 8 product images' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_uid::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$')
   or not exists(select 1 from storage.objects o where o.bucket_id='product-submission-media' and o.name=v_path) then
   raise exception 'An image path is invalid, missing or does not belong to your account' using errcode='22023';end if;
 end loop;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000 then
  raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 insert into public.product_submissions(submitted_by,member_id,name,description,category,image_paths,optional_details)
 values(v_uid,v_member,btrim(p_name),btrim(p_description),nullif(btrim(coalesce(p_category,'')),''),p_image_paths,p_optional_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'product.submitted_for_review','product_submission',v_id,jsonb_build_object('member_id',v_member,'name',btrim(p_name),'image_count',cardinality(p_image_paths)));
 return v_id;
end;$function$;
revoke all on function public.member_submit_product_listing(text,text,text,text[],jsonb) from public,anon;
grant execute on function public.member_submit_product_listing(text,text,text,text[],jsonb) to authenticated;

create or replace function public.member_update_product_submission(
 p_submission_id uuid,p_name text,p_description text,p_category text,p_image_paths text[],p_optional_details jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_member uuid;v_row public.product_submissions%rowtype;v_path text;
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld.product_submission:'||v_uid::text,0));
 select * into v_row from public.product_submissions where id=p_submission_id and submitted_by=v_uid for update;
 if not found then raise exception 'Product submission not found' using errcode='P0002';end if;
 if v_row.status not in ('pending','rejected') then raise exception 'Only pending or rejected submissions can be edited' using errcode='55000';end if;
 select m.id into v_member from public.member_ids m join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active' order by m.created_at,m.id limit 1;
 if v_member is null or v_member<>v_row.member_id then raise exception 'An active submitting Main ID is required' using errcode='42501';end if;
 if length(btrim(coalesce(p_name,'')))<2 or length(btrim(p_name))>160 or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000 then
  raise exception 'Enter a product name (2–160 characters) and description (20–10000 characters)' using errcode='22023';end if;
 if exists(select 1 from public.product_submissions s where s.submitted_by=v_uid and s.id<>p_submission_id and s.status='pending'
   and lower(btrim(s.name))=lower(btrim(p_name))) then
  raise exception 'Another pending product submission with this name already exists. Edit that submission instead of creating a duplicate.' using errcode='23505';
 end if;
 if p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8 then raise exception 'Keep or upload between 1 and 8 product images' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_uid::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$') or not exists(select 1 from storage.objects o where o.bucket_id='product-submission-media' and o.name=v_path) then
   raise exception 'An image path is invalid, missing or does not belong to your account' using errcode='22023';end if;
 end loop;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000 then raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 update public.product_submissions set name=btrim(p_name),description=btrim(p_description),category=nullif(btrim(coalesce(p_category,'')),''),image_paths=p_image_paths,optional_details=p_optional_details,status='pending',review_note=null,reviewed_by=null,reviewed_at=null,updated_at=now() where id=p_submission_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(v_uid,'product.edited_and_resubmitted','product_submission',p_submission_id,jsonb_build_object('member_id',v_member,'image_count',cardinality(p_image_paths)));
 return p_submission_id;
end;$function$;
revoke all on function public.member_update_product_submission(uuid,text,text,text,text[],jsonb) from public,anon;
grant execute on function public.member_update_product_submission(uuid,text,text,text,text[],jsonb) to authenticated;
