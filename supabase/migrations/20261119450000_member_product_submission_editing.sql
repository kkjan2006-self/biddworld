-- Allow owners to correct pending/rejected product listings and resubmit for review.
create or replace function public.member_update_product_submission(
 p_submission_id uuid,p_name text,p_description text,p_category text,p_image_paths text[],p_optional_details jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_member uuid;v_row public.product_submissions%rowtype;v_path text;
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 select * into v_row from public.product_submissions where id=p_submission_id and submitted_by=v_uid for update;
 if not found then raise exception 'Product submission not found' using errcode='P0002';end if;
 if v_row.status not in ('pending','rejected') then raise exception 'Only pending or rejected submissions can be edited' using errcode='55000';end if;
 select m.id into v_member from public.member_ids m join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active' order by m.created_at,m.id limit 1;
 if v_member is null or v_member<>v_row.member_id then raise exception 'An active submitting Main ID is required' using errcode='42501';end if;
 if length(btrim(coalesce(p_name,'')))<2 or length(btrim(p_name))>160 or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000 then
  raise exception 'Enter a product name (2–160 characters) and description (20–10000 characters)' using errcode='22023';end if;
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