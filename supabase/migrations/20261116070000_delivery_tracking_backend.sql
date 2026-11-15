-- Source recovery of the already-existing Production delivery workflow.
-- Additive and idempotent. NOT applied to Production by this commit.
-- Writes remain blocked by delivery_tracking_enabled until explicitly enabled.

create table if not exists public.delivery_tracking (
 id uuid primary key default gen_random_uuid(),
 winning_item_payment_id uuid not null references public.winning_item_payments(id),
 carrier text,
 tracking_number text,
 status text not null default 'pending' check(status in ('pending','packed','shipped','in_transit','delivered','returned')),
 shipped_at timestamptz,
 delivered_at timestamptz,
 updated_at timestamptz not null default now()
);
create index if not exists delivery_tracking_payment_id_idx on public.delivery_tracking(winning_item_payment_id);
create unique index if not exists delivery_tracking_one_row_per_payment_uidx on public.delivery_tracking(winning_item_payment_id);
alter table public.delivery_tracking enable row level security;
revoke all on public.delivery_tracking from public,anon,authenticated;
grant select(id,winning_item_payment_id,carrier,tracking_number,status,shipped_at,delivered_at,updated_at) on public.delivery_tracking to authenticated;
drop policy if exists delivery_tracking_select_own on public.delivery_tracking;
create policy delivery_tracking_select_own on public.delivery_tracking for select to authenticated using (
 exists(select 1 from public.winning_item_payments p join public.member_ids m on m.id=p.winner_member_id
 where p.id=delivery_tracking.winning_item_payment_id and m.owner_user_id=(select auth.uid()))
);

create or replace function public.admin_list_delivery_tracking(p_limit integer default 100,p_offset integer default 0)
returns table(tracking_id uuid,payment_id uuid,member_code text,winner_name text,item_title text,amount numeric,payment_status text,carrier text,tracking_number text,status text,shipped_at timestamptz,delivered_at timestamptz,updated_at timestamptz)
language plpgsql stable security definer set search_path='' as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Invalid pagination values' using errcode='22023'; end if;
 return query select d.id,w.id,m.member_code,p.display_name,coalesce(a.title,fc.title),w.amount,w.status,d.carrier,d.tracking_number,d.status,d.shipped_at,d.delivered_at,d.updated_at
 from public.delivery_tracking d join public.winning_item_payments w on w.id=d.winning_item_payment_id
 join public.member_ids m on m.id=w.winner_member_id left join public.profiles p on p.id=m.owner_user_id
 left join public.auctions a on a.id=w.auction_id left join public.fixed_bid_campaigns fc on fc.id=w.fixed_bid_campaign_id
 order by d.updated_at desc,d.id desc limit p_limit offset p_offset;
end; $function$;

create or replace function public.admin_save_delivery_tracking(p_tracking_id uuid,p_payment_id uuid,p_carrier text,p_tracking_number text,p_status text)
returns uuid language plpgsql security definer set search_path='' as $function$
declare v_id uuid;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_status is null or p_status not in ('pending','packed','shipped','in_transit','delivered','returned') then raise exception 'Invalid delivery status' using errcode='22023'; end if;
 if length(coalesce(p_carrier,''))>120 or length(coalesce(p_tracking_number,''))>180 then raise exception 'Carrier or tracking number is too long' using errcode='22023'; end if;
 if p_tracking_id is null then
  if p_payment_id is null then raise exception 'A winning payment is required' using errcode='22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_payment_id::text,0));
  if not exists(select 1 from public.winning_item_payments where id=p_payment_id and status='paid') then raise exception 'Delivery can only be created for a verified paid winning-item payment' using errcode='22023'; end if;
  if exists(select 1 from public.delivery_tracking where winning_item_payment_id=p_payment_id) then raise exception 'Delivery tracking already exists for this payment' using errcode='23505'; end if;
  insert into public.delivery_tracking(winning_item_payment_id,carrier,tracking_number,status,shipped_at,delivered_at)
  values(p_payment_id,nullif(trim(coalesce(p_carrier,'')),''),nullif(trim(coalesce(p_tracking_number,'')),''),p_status,
  case when p_status in ('shipped','in_transit','delivered') then now() else null end,case when p_status='delivered' then now() else null end) returning id into v_id;
 else
  perform 1 from public.delivery_tracking d join public.winning_item_payments w on w.id=d.winning_item_payment_id
  where d.id=p_tracking_id and w.status='paid' for update of d;
  if not found then raise exception 'Tracking record not found or payment is not verified paid' using errcode='22023'; end if;
  update public.delivery_tracking set carrier=nullif(trim(coalesce(p_carrier,'')),''),tracking_number=nullif(trim(coalesce(p_tracking_number,'')),''),status=p_status,
  shipped_at=case when p_status in ('shipped','in_transit','delivered') then coalesce(shipped_at,now()) else shipped_at end,
  delivered_at=case when p_status='delivered' then coalesce(delivered_at,now()) else null end,updated_at=now()
  where id=p_tracking_id returning id into v_id;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),'delivery.tracking_saved','delivery_tracking',v_id,jsonb_build_object('status',p_status,'carrier',nullif(trim(coalesce(p_carrier,'')),''),'tracking_number',nullif(trim(coalesce(p_tracking_number,'')),'')));
 return v_id;
end; $function$;

revoke all on function public.admin_list_delivery_tracking(integer,integer) from public,anon;
grant execute on function public.admin_list_delivery_tracking(integer,integer) to authenticated;
revoke all on function public.admin_save_delivery_tracking(uuid,uuid,text,text,text) from public,anon;
grant execute on function public.admin_save_delivery_tracking(uuid,uuid,text,text,text) to authenticated;
