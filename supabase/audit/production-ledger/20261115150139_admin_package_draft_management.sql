create or replace function public.admin_list_packages()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'name',p.name,'description',p.description,'price',p.price,
    'currency',p.currency,'bid_wallet_credit',p.bid_wallet_credit,
    'is_active',p.is_active,'created_at',p.created_at,'updated_at',p.updated_at
  ) order by p.created_at desc),'[]'::jsonb)
  into v_result from public.packages p;
  return v_result;
end;
$function$;

create or replace function public.admin_save_package_draft(
  p_package_id uuid,
  p_name text,
  p_description text,
  p_price numeric,
  p_bid_wallet_credit numeric
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare v_uid uuid := auth.uid(); v_id uuid; v_old public.packages%rowtype;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  if p_name is null or length(trim(p_name)) < 3 or length(trim(p_name)) > 120 then
    raise exception 'Package name must contain 3 to 120 characters';
  end if;
  if p_price is null or p_price <= 0 or p_price > 10000000 then
    raise exception 'Package price must be greater than zero and within the allowed limit';
  end if;
  if p_bid_wallet_credit is null or p_bid_wallet_credit < 0 or p_bid_wallet_credit > 10000000 then
    raise exception 'Bid Wallet credit must be zero or greater and within the allowed limit';
  end if;
  if p_package_id is null then
    insert into public.packages(name,description,price,currency,bid_wallet_credit,is_active)
    values(trim(p_name),nullif(trim(coalesce(p_description,'')),''),p_price,'INR',p_bid_wallet_credit,false)
    returning id into v_id;
    insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
    values(v_uid,'package_draft_created','packages',v_id,jsonb_build_object('name',trim(p_name),'price',p_price,'bid_wallet_credit',p_bid_wallet_credit,'is_active',false));
  else
    select * into v_old from public.packages where id=p_package_id for update;
    if not found then raise exception 'Package not found'; end if;
    if v_old.is_active then raise exception 'Active packages cannot be edited through the draft editor'; end if;
    update public.packages set name=trim(p_name),description=nullif(trim(coalesce(p_description,'')),''),price=p_price,bid_wallet_credit=p_bid_wallet_credit,updated_at=now()
    where id=p_package_id returning id into v_id;
    insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
    values(v_uid,'package_draft_updated','packages',v_id,jsonb_build_object('old_price',v_old.price,'new_price',p_price,'old_bid_wallet_credit',v_old.bid_wallet_credit,'new_bid_wallet_credit',p_bid_wallet_credit));
  end if;
  return (select jsonb_build_object('id',p.id,'name',p.name,'description',p.description,'price',p.price,'currency',p.currency,'bid_wallet_credit',p.bid_wallet_credit,'is_active',p.is_active) from public.packages p where p.id=v_id);
end;
$function$;

revoke all on function public.admin_list_packages() from public,anon;
grant execute on function public.admin_list_packages() to authenticated;
revoke all on function public.admin_save_package_draft(uuid,text,text,numeric,numeric) from public,anon;
grant execute on function public.admin_save_package_draft(uuid,text,text,numeric,numeric) to authenticated;
