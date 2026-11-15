-- Admin product catalogue management and safe public media delivery.
-- This migration matches the reconciled production products schema:
-- products(name, description, image_path, category, status).
-- Product records remain drafts until an administrator explicitly publishes them.

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('product-media','product-media',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists product_media_public_read on storage.objects;
create policy product_media_public_read on storage.objects
for select to anon,authenticated using(bucket_id='product-media');

drop policy if exists product_media_admin_insert on storage.objects;
create policy product_media_admin_insert on storage.objects
for insert to authenticated
with check(bucket_id='product-media' and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin');

drop policy if exists product_media_admin_update on storage.objects;
create policy product_media_admin_update on storage.objects
for update to authenticated
using(bucket_id='product-media' and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin')
with check(bucket_id='product-media' and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin');

drop policy if exists product_media_admin_delete on storage.objects;
create policy product_media_admin_delete on storage.objects
for delete to authenticated
using(bucket_id='product-media' and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin');

create or replace function public.admin_list_auction_products()
returns table(product_id uuid,name text,description text,image_path text,category text,status text)
language plpgsql stable security definer set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return query select p.id,p.name,p.description,p.image_path,p.category,p.status
 from public.products p order by p.created_at desc;
end; $$;

create or replace function public.admin_save_product_draft(
 p_product_id uuid,p_name text,p_description text,p_image_path text,p_category text
) returns uuid
language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if length(trim(coalesce(p_name,''))) < 2 or length(trim(p_name)) > 160 then
  raise exception 'Product name must be 2 to 160 characters' using errcode='22023';
 end if;
 if length(coalesce(p_description,'')) > 5000 or length(coalesce(p_image_path,'')) > 2048
    or length(coalesce(p_category,'')) > 100 then
  raise exception 'Product details exceed allowed length' using errcode='22023';
 end if;
 if p_product_id is null then
  insert into public.products(name,description,image_path,category,status)
  values(trim(p_name),nullif(trim(coalesce(p_description,'')),''),nullif(trim(coalesce(p_image_path,'')),''),nullif(trim(coalesce(p_category,'')),''),'draft')
  returning id into v_id;
 else
  update public.products set name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),
   image_path=nullif(trim(coalesce(p_image_path,'')),''),category=nullif(trim(coalesce(p_category,'')),''),
   updated_at=now()
   where id=p_product_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'Only existing draft products can be edited' using errcode='22023'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_product_id is null then 'product.draft_created' else 'product.draft_updated' end,
 'product',v_id,jsonb_build_object('name',trim(p_name)));
 return v_id;
end; $$;

create or replace function public.admin_set_product_active(p_product_id uuid,p_is_active boolean)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_name text; v_status text;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_is_active is null then raise exception 'Publication status is required' using errcode='22023'; end if;
 update public.products set status=case when p_is_active then 'published' else 'draft' end,updated_at=now()
 where id=p_product_id returning name,status into v_name,v_status;
 if v_name is null then raise exception 'Product not found' using errcode='P0002'; end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_is_active then 'product.published' else 'product.unpublished' end,
 'product',p_product_id,jsonb_build_object('name',v_name,'status',v_status));
 return jsonb_build_object('success',true,'product_id',p_product_id,'status',v_status);
end; $$;

revoke all on function public.admin_list_auction_products() from public,anon;
grant execute on function public.admin_list_auction_products() to authenticated;
revoke all on function public.admin_save_product_draft(uuid,text,text,text,text) from public,anon;
grant execute on function public.admin_save_product_draft(uuid,text,text,text,text) to authenticated;
revoke all on function public.admin_set_product_active(uuid,boolean) from public,anon;
grant execute on function public.admin_set_product_active(uuid,boolean) to authenticated;
