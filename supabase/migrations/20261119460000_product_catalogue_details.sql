-- Persist and safely publish the complete member-submitted product details.
alter table public.products
  add column if not exists product_details jsonb not null default '{}'::jsonb;
grant select (product_details) on public.products to anon,authenticated;

create or replace function private.validate_product_submission_details()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_price text;
begin
  if new.optional_details is null
     or jsonb_typeof(new.optional_details)<>'object'
     or pg_catalog.octet_length(new.optional_details::text)>12000 then
    raise exception 'Product details must be a small JSON object' using errcode='22023';
  end if;
  if exists (
    select 1 from jsonb_each(new.optional_details) as detail(key,value)
    where jsonb_typeof(detail.value)<>'string'
  ) then
    raise exception 'Every product detail value must be plain text' using errcode='22023';
  end if;
  v_price:=new.optional_details->>'Price';
  if v_price is null
     or v_price !~ '^[0-9]{1,9}([.][0-9]{1,2})?$'
     or v_price::numeric<=0
     or v_price::numeric>999999999.99 then
    raise exception 'A valid product asking price is required' using errcode='22023';
  end if;
  return new;
end;
$function$;
revoke all on function private.validate_product_submission_details() from public,anon,authenticated;
drop trigger if exists validate_product_submission_details on public.product_submissions;
create trigger validate_product_submission_details
before insert or update of optional_details on public.product_submissions
for each row execute function private.validate_product_submission_details();

-- Keep the existing single-image Admin RPC compatible for clients deployed before gallery support.
create or replace function public.admin_review_product_submission(
  p_submission_id uuid,
  p_decision text,
  p_review_note text default null,
  p_public_image_path text default null
) returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_s public.product_submissions%rowtype;
  v_product uuid;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if p_decision not in ('approve','reject') or length(coalesce(p_review_note,''))>500 then
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
    update public.product_submissions
    set status='rejected',review_note=nullif(btrim(p_review_note),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now()
    where id=v_s.id;
    insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
    values(v_uid,'product.submission_rejected','product_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
    return jsonb_build_object('success',true,'status','rejected');
  end if;
  if p_public_image_path is null
     or p_public_image_path !~ '^[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$'
     or not exists(select 1 from storage.objects o where o.bucket_id='product-media' and o.name=p_public_image_path) then
    raise exception 'An approved public product image must be uploaded before publication' using errcode='22023';
  end if;
  insert into public.products(name,description,image_path,category,status,product_details)
  values(v_s.name,v_s.description,p_public_image_path,v_s.category,'published',v_s.optional_details)
  returning id into v_product;
  update public.product_submissions
  set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),product_id=v_product,updated_at=now()
  where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'product.submission_approved','product_submission',v_s.id,jsonb_build_object('product_id',v_product,'member_id',v_s.member_id));
  return jsonb_build_object('success',true,'status','approved','product_id',v_product);
end;
$function$;
revoke all on function public.admin_review_product_submission(uuid,text,text,text) from public,anon;
grant execute on function public.admin_review_product_submission(uuid,text,text,text) to authenticated;

-- Search only published products and expose their approved details.
drop function if exists public.public_list_active_products_page(text,integer,integer);
create function public.public_list_active_products_page(
  p_search text default null,
  p_limit integer default 100,
  p_offset integer default 0
) returns table(
  id uuid,
  name text,
  description text,
  image_path text,
  category text,
  status text,
  product_details jsonb,
  has_more boolean
)
language plpgsql
stable
security invoker
set search_path=''
as $function$
declare
  v_search text:=nullif(trim(coalesce(p_search,'')),'');
  v_limit integer:=coalesce(p_limit,100);
  v_offset integer:=coalesce(p_offset,0);
  v_total bigint:=0;
begin
  if v_search is not null and length(v_search)>100 then
    raise exception 'Search text must be at most 100 characters' using errcode='22023';
  end if;
  if v_limit<1 or v_limit>100 then
    raise exception 'Page size must be between 1 and 100' using errcode='22023';
  end if;
  if v_offset<0 or v_offset>1000000 then
    raise exception 'Page offset is out of range' using errcode='22023';
  end if;
  select count(*) into v_total
  from public.products p
  where p.status='published'
    and (v_search is null
      or position(lower(v_search) in lower(coalesce(p.name,'')))>0
      or position(lower(v_search) in lower(coalesce(p.category,'')))>0
      or position(lower(v_search) in lower(coalesce(p.description,'')))>0
      or position(lower(v_search) in lower(coalesce(p.product_details::text,'')))>0);
  return query
  select p.id,p.name,p.description,p.image_path,p.category,p.status,p.product_details,(v_offset+v_limit<v_total)
  from public.products p
  where p.status='published'
    and (v_search is null
      or position(lower(v_search) in lower(coalesce(p.name,'')))>0
      or position(lower(v_search) in lower(coalesce(p.category,'')))>0
      or position(lower(v_search) in lower(coalesce(p.description,'')))>0
      or position(lower(v_search) in lower(coalesce(p.product_details::text,'')))>0)
  order by p.name,p.id
  limit v_limit offset v_offset;
end;
$function$;
revoke all on function public.public_list_active_products_page(text,integer,integer) from public;
grant execute on function public.public_list_active_products_page(text,integer,integer) to anon,authenticated;
