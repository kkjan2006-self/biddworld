-- Align Admin-created auction drafts with the Expected Price / 48-hour lifecycle.
-- End time is system-derived only after Expected Price is reached.
-- Also handle an Admin auction whose starting price already equals its target:
-- the 48-hour clock begins when the scheduled auction actually becomes live.
create or replace function public.apply_auction_expected_price_deadline()
returns trigger language plpgsql set search_path=''
as $function$
begin
 if new.expected_price is not null
    and new.target_reached_at is null
    and new.status='live'
    and new.starts_at is not null
    and new.starts_at<=clock_timestamp()
    and new.current_price>=new.expected_price then
   new.target_reached_at:=clock_timestamp();
   new.ends_at:=new.target_reached_at+interval '48 hours';
 end if;
 return new;
end;$function$;
drop trigger if exists auctions_expected_price_deadline on public.auctions;
create trigger auctions_expected_price_deadline
before update of current_price,status on public.auctions
for each row execute function public.apply_auction_expected_price_deadline();

drop function if exists public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,timestamptz,timestamptz);
create function public.admin_save_auction_draft(
 p_auction_id uuid,p_product_id uuid,p_title text,p_description text,p_image_url text,
 p_category text,p_starting_price numeric,p_expected_price numeric,
 p_minimum_increment numeric,p_starts_at timestamptz
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_product_id is null or not exists(select 1 from public.products where id=p_product_id and status='draft') then
  raise exception 'Select a draft product' using errcode='22023';
 end if;
 if length(btrim(coalesce(p_title,'')))<3 or length(btrim(p_title))>180 then
  raise exception 'Auction title must be 3 to 180 characters' using errcode='22023';
 end if;
 if p_starting_price is null or p_starting_price<=0 or p_expected_price is null
    or p_expected_price<p_starting_price or p_minimum_increment is null or p_minimum_increment<=0 then
  raise exception 'Expected Price must be at least Starting Price; prices and increment must be positive' using errcode='22023';
 end if;
 if p_auction_id is null then
  insert into public.auctions(product_id,title,description,image_url,category,currency,
   starting_price,current_price,minimum_increment,starts_at,ends_at,expected_price,target_reached_at,status)
  values(p_product_id,btrim(p_title),nullif(btrim(coalesce(p_description,'')), ''),
   nullif(btrim(coalesce(p_image_url,'')),''),nullif(btrim(coalesce(p_category,'')),''),'INR',
   p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,null,p_expected_price,null,'draft')
  returning id into v_id;
 else
  update public.auctions set product_id=p_product_id,title=btrim(p_title),
   description=nullif(btrim(coalesce(p_description,'')),''),image_url=nullif(btrim(coalesce(p_image_url,'')),''),
   category=nullif(btrim(coalesce(p_category,'')),''),starting_price=p_starting_price,
   current_price=p_starting_price,minimum_increment=p_minimum_increment,starts_at=p_starts_at,
   ends_at=null,expected_price=p_expected_price,target_reached_at=null,updated_at=now()
   where id=p_auction_id and status='draft' returning id into v_id;
  if v_id is null then raise exception 'Only existing draft auctions can be edited' using errcode='22023';end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_auction_id is null then 'auction.draft_created' else 'auction.draft_updated' end,
  'auction',v_id,jsonb_build_object('title',btrim(p_title),'starting_price',p_starting_price,
  'expected_price',p_expected_price,'status','draft'));
 return v_id;
end;$function$;
revoke all on function public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,numeric,timestamptz) from public,anon;
grant execute on function public.admin_save_auction_draft(uuid,uuid,text,text,text,text,numeric,numeric,numeric,timestamptz) to authenticated;

drop function if exists public.admin_list_auctions();
create function public.admin_list_auctions()
returns table(auction_id uuid,product_id uuid,title text,description text,image_url text,category text,
 currency text,starting_price numeric,current_price numeric,minimum_increment numeric,starts_at timestamptz,
 ends_at timestamptz,expected_price numeric,status text,product_name text)
language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return query select a.id,a.product_id,a.title,a.description,a.image_url,a.category,a.currency::text,
  a.starting_price,a.current_price,a.minimum_increment,a.starts_at,a.ends_at,a.expected_price,a.status,p.name
 from public.auctions a join public.products p on p.id=a.product_id order by a.created_at desc;
end;$function$;
revoke all on function public.admin_list_auctions() from public,anon;
grant execute on function public.admin_list_auctions() to authenticated;
