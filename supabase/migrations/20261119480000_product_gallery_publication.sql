-- Publish the complete approved product image gallery instead of dropping all but the first image.
alter table public.products add column if not exists image_paths text[] not null default '{}';
grant select (image_paths) on public.products to anon,authenticated;
update public.products set image_paths=array[image_path] where image_path is not null and cardinality(image_paths)=0;

create or replace function public.admin_review_product_submission_with_images(
 p_submission_id uuid,p_decision text,p_review_note text default null,p_public_image_paths text[] default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_s public.product_submissions%rowtype;v_product uuid;v_path text;
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
  update public.product_submissions set status='rejected',review_note=nullif(btrim(p_review_note),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now() where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'product.submission_rejected','product_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
 if p_public_image_paths is null or cardinality(p_public_image_paths)<1 or cardinality(p_public_image_paths)>8
    or (select count(distinct image_path) from unnest(p_public_image_paths) as paths(image_path))<>cardinality(p_public_image_paths) then
  raise exception 'Provide 1–8 unique approved public product images' using errcode='22023';
 end if;
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

drop function if exists public.public_list_active_products_page(text,integer,integer);
create function public.public_list_active_products_page(
 p_search text default null,p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,name text,description text,image_path text,image_paths text[],category text,status text,
 product_details jsonb,has_more boolean
) language plpgsql stable security invoker set search_path=''
as $function$
declare v_search text:=nullif(trim(coalesce(p_search,'')),'');v_limit integer:=coalesce(p_limit,100);v_offset integer:=coalesce(p_offset,0);v_total bigint:=0;
begin
 if v_search is not null and length(v_search)>100 then raise exception 'Search text must be at most 100 characters' using errcode='22023';end if;
 if v_limit<1 or v_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if v_offset<0 or v_offset>1000000 then raise exception 'Page offset is out of range' using errcode='22023';end if;
 select count(*) into v_total from public.products p where p.status='published'
  and (v_search is null or position(lower(v_search) in lower(coalesce(p.name,'')))>0
   or position(lower(v_search) in lower(coalesce(p.category,'')))>0
   or position(lower(v_search) in lower(coalesce(p.description,'')))>0
   or position(lower(v_search) in lower(coalesce(p.product_details::text,'')))>0);
 return query select p.id,p.name,p.description,p.image_path,p.image_paths,p.category,p.status,p.product_details,(v_offset+v_limit<v_total)
 from public.products p where p.status='published'
  and (v_search is null or position(lower(v_search) in lower(coalesce(p.name,'')))>0
   or position(lower(v_search) in lower(coalesce(p.category,'')))>0
   or position(lower(v_search) in lower(coalesce(p.description,'')))>0
   or position(lower(v_search) in lower(coalesce(p.product_details::text,'')))>0)
 order by p.name,p.id limit v_limit offset v_offset;
end;
$function$;
revoke all on function public.public_list_active_products_page(text,integer,integer) from public;
grant execute on function public.public_list_active_products_page(text,integer,integer) to anon,authenticated;
