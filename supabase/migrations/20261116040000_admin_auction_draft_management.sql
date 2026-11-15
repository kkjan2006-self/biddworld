-- Admin-only auction draft management.
-- Mirrors the read-only reconciled Production RPC contract.
-- Every write remains a draft; this migration does not enable bidding or settlement.

create or replace function public.admin_list_auctions()
returns table(
 auction_id uuid,
 product_id uuid,
 title text,
 description text,
 image_url text,
 category text,
 currency text,
 starting_price numeric,
 current_price numeric,
 minimum_increment numeric,
 starts_at timestamptz,
 ends_at timestamptz,
 status text,
 product_name text
)
language plpgsql
stable
security definer
set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return query
 select a.id,a.product_id,a.title,a.description,a.image_url,a.category,
        a.currency::text,a.starting_price,a.current_price,a.minimum_increment,
        a.starts_at,a.ends_at,a.status,p.name
 from public.auctions a
 join public.products p on p.id=a.product_id
 order by a.created_at desc;
end;
$$;

create or replace function public.admin_save_auction_draft(
 p_auction_id uuid,
 p_product_id uuid,
 p_title text,
 p_description text,
 p_image_url text,
 p_category text,
 p_starting_price numeric,
 p_minimum_increment numeric,
 p_starts_at timestamptz,
 p_ends_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
 v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_product_id is null or not exists(
  select 1 from public.products where id=p_product_id and status='draft'
 ) then
  raise exception 'Select a draft product' using errcode='22023';
 end if;
 if length(trim(coalesce(p_title,'')))<3 or length(trim(p_title))>180 then
  raise exception 'Auction title must be 3 to 180 characters' using errcode='22023';
 end if;
 if coalesce(p_starting_price,-1)<0 or coalesce(p_minimum_increment,0)<=0 then
  raise exception 'Invalid starting price or bid increment' using errcode='22023';
 end if;
 if p_starts_at is not null and p_ends_at is not null and p_ends_at<=p_starts_at then
  raise exception 'End time must be after start time' using errcode='22023';
 end if;

 if p_auction_id is null then
  insert into public.auctions(
   product_id,title,description,image_url,category,currency,
   starting_price,current_price,minimum_increment,starts_at,ends_at,status
  )
  values(
   p_product_id,trim(p_title),nullif(trim(coalesce(p_description,'')),''),
   nullif(trim(coalesce(p_image_url,'')),''),nullif(trim(coalesce(p_category,'')),''),
   'INR',p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,p_ends_at,'draft'
  ) returning id into v_id;
 else
  update public.auctions
  set product_id=p_product_id,
      title=trim(p_title),
      description=nullif(trim(coalesce(p_description,'')),''),
      image_url=nullif(trim(coalesce(p_image_url,'')),''),
      category=nullif(trim(coalesce(p_category,'')),''),
      starting_price=p_starting_price,
      current_price=p_starting_price,
      minimum_increment=p_minimum_increment,
      starts_at=p_starts_at,
      ends_at=p_ends_at,
      updated_at=now()
  where id=p_auction_id and status='draft'
  returning id into v_id;
  if v_id is null then
   raise exception 'Only existing draft auctions can be edited' using errcode='22023';
  end if;
 end if;

 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(
  auth.uid(),
  case when p_auction_id is null then 'auction.draft_created' else 'auction.draft_updated' end,
  'auction',v_id,jsonb_build_object('title',trim(p_title),'status','draft')
 );
 return v_id;
end;
$$;

revoke all on function public.admin_list_auctions() from public,anon;
grant execute on function public.admin_list_auctions() to authenticated;
revoke all on function public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,timestamptz,timestamptz) from public,anon;
grant execute on function public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,timestamptz,timestamptz) to authenticated;
