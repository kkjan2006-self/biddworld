-- Keep public product gallery publication in exact one-to-one correspondence with
-- the private image set attached to the approved submission.
create or replace function public.admin_review_product_submission_with_images(
 p_submission_id uuid,p_decision text,p_review_note text default null,p_public_image_paths text[] default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_s public.product_submissions%rowtype;
 v_product uuid;
 v_path text;
 v_source_path text;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_decision is null or p_decision not in ('approve','reject') or length(coalesce(p_review_note,''))>500 then
  raise exception 'Invalid review decision or note' using errcode='22023';
 end if;
 if p_decision='reject' and length(btrim(coalesce(p_review_note,'')))<5 then
  raise exception 'A rejection note of at least 5 characters is required' using errcode='22023';
 end if;
 select * into v_s from public.product_submissions where id=p_submission_id for update;
 if not found or v_s.status<>'pending' then
  raise exception 'Product submission is not pending review' using errcode='55000';
 end if;
 if p_decision='reject' then
  if coalesce(cardinality(p_public_image_paths),0)>0 then
   raise exception 'Rejected submissions cannot publish product images' using errcode='22023';
  end if;
  update public.product_submissions set status='rejected',review_note=nullif(btrim(p_review_note),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now() where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'product.submission_rejected','product_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
 if v_s.image_paths is null or cardinality(v_s.image_paths)<1 or cardinality(v_s.image_paths)>8
    or p_public_image_paths is null
    or cardinality(p_public_image_paths)<>cardinality(v_s.image_paths)
    or (select count(distinct path) from unnest(v_s.image_paths) as source(path))<>cardinality(v_s.image_paths)
    or (select count(distinct path) from unnest(p_public_image_paths) as published(path))<>cardinality(p_public_image_paths) then
  raise exception 'Publish exactly one unique public image for every submitted private image' using errcode='22023';
 end if;
 foreach v_source_path in array v_s.image_paths loop
  if v_source_path !~ ('^'||v_s.submitted_by::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$')
    or not exists(select 1 from storage.objects o where o.bucket_id='product-submission-media' and o.name=v_source_path) then
   raise exception 'A submitted private product image is missing or does not belong to the submitting member' using errcode='22023';
  end if;
 end loop;
 foreach v_path in array p_public_image_paths loop
  if v_path !~ '^[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'
    or not exists(select 1 from storage.objects o where o.bucket_id='product-media' and o.name=v_path) then
   raise exception 'A public product image path is invalid or missing' using errcode='22023';
  end if;
 end loop;
 insert into public.products(name,description,image_path,image_paths,category,status,product_details)
 values(v_s.name,v_s.description,p_public_image_paths[1],p_public_image_paths,v_s.category,'published',v_s.optional_details)
 returning id into v_product;
 update public.product_submissions set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),product_id=v_product,updated_at=now() where id=v_s.id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'product.submission_approved','product_submission',v_s.id,jsonb_build_object('product_id',v_product,'member_id',v_s.member_id,'image_count',cardinality(p_public_image_paths)));
 return jsonb_build_object('success',true,'status','approved','product_id',v_product,'image_count',cardinality(p_public_image_paths));
end;
$function$;
revoke all on function public.admin_review_product_submission_with_images(uuid,text,text,text[]) from public,anon;
grant execute on function public.admin_review_product_submission_with_images(uuid,text,text,text[]) to authenticated;
