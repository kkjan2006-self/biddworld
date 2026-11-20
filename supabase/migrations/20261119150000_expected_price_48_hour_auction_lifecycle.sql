-- Expected-price auction lifecycle: no fixed end date until target price is reached.
alter table public.auction_submissions add column if not exists expected_price numeric(14,2);
alter table public.auction_submissions alter column ends_at drop not null;
update public.auction_submissions set expected_price=starting_price where expected_price is null and status='pending';
alter table public.auctions add column if not exists expected_price numeric(14,2);
alter table public.auctions add column if not exists target_reached_at timestamptz;
alter table public.auctions alter column ends_at drop not null;

-- Legacy listings keep their existing end time; new expected-price listings use this lifecycle.
create or replace function public.apply_auction_expected_price_deadline()
returns trigger language plpgsql set search_path=''
as $function$
begin
 if new.expected_price is not null
    and new.target_reached_at is null
    and new.current_price >= new.expected_price then
   new.target_reached_at := clock_timestamp();
   new.ends_at := new.target_reached_at + interval '48 hours';
 end if;
 return new;
end;
$function$;
drop trigger if exists auctions_expected_price_deadline on public.auctions;
create trigger auctions_expected_price_deadline
before update of current_price on public.auctions
for each row execute function public.apply_auction_expected_price_deadline();

-- Replace the member submission RPC; no end-time argument is accepted anymore.
drop function if exists public.member_submit_auction(text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb);
create or replace function public.member_submit_auction(
 p_title text,p_description text,p_category text,p_image_paths text[],
 p_starting_price numeric,p_expected_price numeric,p_minimum_increment numeric,
 p_starts_at timestamptz,p_optional_details jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_member uuid;v_id uuid;v_path text;
begin
 if v_uid is null then raise exception 'Sign in is required' using errcode='42501';end if;
 select m.id into v_member from public.member_ids m join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active'
 order by m.created_at,m.id limit 1;
 if v_member is null then raise exception 'An active Main ID is required to place an auction' using errcode='42501';end if;
 if length(btrim(coalesce(p_title,'')))<5 or length(btrim(p_title))>180
  or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000 then
  raise exception 'Enter a title (5–180 characters) and description (20–10000 characters)' using errcode='22023';end if;
 if p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8 then
  raise exception 'Upload between 1 and 8 item images' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_uid::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)
 if p_starting_price is null or p_starting_price<=0 or p_expected_price is null
  or p_expected_price<p_starting_price or p_minimum_increment is null or p_minimum_increment<=0
  or p_starts_at is null or p_starts_at<now()+interval '30 minutes' then
  raise exception 'Expected price must be at least the starting price. Check prices and future start time.' using errcode='22023';end if;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000
  or exists(select 1 from jsonb_each(p_optional_details) item where jsonb_typeof(item.value)<>'string') then
  raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 insert into public.auction_submissions(submitted_by,member_id,title,description,category,image_paths,starting_price,expected_price,minimum_increment,starts_at,ends_at,optional_details)
 values(v_uid,v_member,btrim(p_title),btrim(p_description),nullif(btrim(coalesce(p_category,'')),''),p_image_paths,p_starting_price,p_expected_price,p_minimum_increment,p_starts_at,null,p_optional_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submitted_for_review','auction_submission',v_id,jsonb_build_object('member_id',v_member,'title',btrim(p_title),'starting_price',p_starting_price,'expected_price',p_expected_price));
 return v_id;
end;$function$;
revoke all on function public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb) from public,anon;
grant execute on function public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb) to authenticated;

-- Replace review RPC. Admin/Staff may edit both prices; a fixed end-time is not accepted.
drop function if exists public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb,text);
-- Public catalogue includes target price and an open-ended running state.
drop function if exists public.public_list_active_auctions_page(integer,integer);
create function public.public_list_active_auctions_page(
 p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,title text,description text,image_url text,current_price numeric,minimum_increment numeric,
 ends_at timestamptz,status text,category text,currency text,expected_price numeric,target_reached_at timestamptz,starts_at timestamptz
) language plpgsql stable security definer set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Page offset is out of range' using errcode='22023';end if;
 return query
 select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,a.ends_at,a.status,a.category,a.currency::text,
  a.expected_price,a.target_reached_at,a.starts_at
 from public.auctions a join public.products p on p.id=a.product_id
 where p.status='published' and (a.ends_at is null or a.ends_at>now())
  and ((a.status='live' and a.starts_at is not null and a.starts_at<=now())
    or (a.status='scheduled' and a.starts_at is not null and a.starts_at>now()))
 order by coalesce(a.ends_at,'infinity'::timestamptz) asc,a.id desc
 limit p_limit offset p_offset;
end;$function$;
revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated;

-- A null end time means the auction is waiting for its expected price, not that it has ended.

-- Keep bidding open while the expected price has not yet been reached (ends_at is NULL).
create or replace function private.place_bid(
  p_auction_id uuid,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_auction public.auctions%rowtype;
  v_bid_wallet public.wallet_accounts%rowtype;
  v_income_wallet public.wallet_accounts%rowtype;
  v_existing_id uuid;
  v_existing_member uuid;
  v_existing_auction uuid;
  v_existing_amount numeric(14,2);
  v_bid_id uuid;
  v_amount numeric(14,2);
  v_bid_debit numeric(14,2);
  v_income_debit numeric(14,2);
  v_enabled boolean := false;
  v_key text := btrim(coalesce(p_idempotency_key, ''));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if length(v_key) < 16 or length(v_key) > 100
     or v_key !~ '^[A-Za-z0-9:_-]+$' then
    raise exception 'A valid bid request key is required' using errcode = '22023';
  end if;

  select m.id into v_member_id
    from public.member_ids m
    join public.profiles p
      on p.id = m.owner_user_id
     and p.main_member_id = m.id
   where m.owner_user_id = v_uid
     and m.id_type = 'main'
     and m.status = 'active'
     and p.status = 'active'
   order by m.created_at, m.id
   limit 1;
  if v_member_id is not null then
    -- Serialize eligibility with Admin suspend/close/reactivate for this Main ID,
    -- then recheck after acquiring the lock to close the read-then-deactivate race.
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_member_id::text, 0)
    );
    if not exists (
      select 1
      from public.member_ids m
      join public.profiles p
        on p.id = m.owner_user_id
       and p.main_member_id = m.id
      where m.id = v_member_id
        and m.owner_user_id = v_uid
        and m.id_type = 'main'
        and m.status = 'active'
        and p.status = 'active'
    ) then
      v_member_id := null;
    end if;
  end if;
  if v_member_id is null then
    raise exception 'An active main member ID is required' using errcode = '42501';
  end if;

  -- Serialize reuse of one key, including attempts against different auctions.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_key, 0)
  );

  select id, member_id, auction_id, bid_amount
    into v_existing_id, v_existing_member, v_existing_auction, v_existing_amount
    from public.bids
   where idempotency_key = v_key;

  if found then
    if v_existing_member is distinct from v_member_id
       or v_existing_auction is distinct from p_auction_id then
      raise exception 'This bid request key has already been used for another request'
        using errcode = '23505';
    end if;
    return jsonb_build_object(
      'success', true,
      'bid_id', v_existing_id,
      'bid_amount', v_existing_amount,
      'bid_idempotency_key', v_key,
      'replayed', true
    );
  end if;

  select coalesce((setting_value #>> '{}')::boolean, false)
    into v_enabled
    from public.app_settings
   where setting_key = 'bidding_enabled';
  if not coalesce(v_enabled, false) then
    raise exception 'Bidding is disabled by administrator' using errcode = '55000';
  end if;

  select * into v_auction
    from public.auctions
   where id = p_auction_id
   for update;
  if not found
     or v_auction.status <> 'live'
     or v_auction.starts_at is null
     or now() < v_auction.starts_at
     or (v_auction.ends_at is not null and now() >= v_auction.ends_at) then
    raise exception 'Auction is not open' using errcode = '55000';
  end if;

  v_amount := v_auction.current_price + v_auction.minimum_increment;

  select * into v_bid_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'bid'
   for update;
  select * into v_income_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'income'
   for update;

  if v_bid_wallet.id is null or v_income_wallet.id is null then
    raise exception 'Wallets unavailable' using errcode = '55000';
  end if;

  v_bid_debit := least(v_bid_wallet.balance, v_amount);
  v_income_debit := v_amount - v_bid_debit;
  if v_income_wallet.balance < v_income_debit then
    raise exception 'Insufficient combined wallet balance' using errcode = '23514';
  end if;

  update public.wallet_accounts
     set balance = balance - v_bid_debit, updated_at = now()
   where id = v_bid_wallet.id;
  update public.wallet_accounts
     set balance = balance - v_income_debit, updated_at = now()
   where id = v_income_wallet.id;

  if v_bid_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_bid_wallet.id, v_member_id, 'auction_bid', 'debit', v_bid_debit,
       v_bid_wallet.balance - v_bid_debit, 'auction', p_auction_id,
       v_key || ':bid', 'Auction bid wallet debit');
  end if;
  if v_income_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_income_wallet.id, v_member_id, 'auction_bid', 'debit', v_income_debit,
       v_income_wallet.balance - v_income_debit, 'auction', p_auction_id,
       v_key || ':income', 'Auction income wallet debit');
  end if;

  insert into public.bids
    (auction_id, member_id, bid_amount, bid_wallet_debit,
     income_wallet_debit, status, idempotency_key)
  values
    (p_auction_id, v_member_id, v_amount, v_bid_debit,
     v_income_debit, 'accepted', v_key)
  returning id into v_bid_id;

  update public.auctions
     set current_price = v_amount, updated_at = now()
   where id = p_auction_id;

  return jsonb_build_object(
    'success', true,
    'bid_id', v_bid_id,
    'bid_amount', v_amount,
    'bid_idempotency_key', v_key,
    'replayed', false
  );
end;
$function$;


revoke all on function private.place_bid(uuid,text) from public,anon,authenticated;

-- Move scheduled listings to live at their start time and close them when the 48-hour
-- deadline is reached. The bid RPC independently enforces ends_at, so a delayed cron
-- tick cannot accept bids after the deadline.
create extension if not exists pg_cron;
do $schedule$
declare v_job_id bigint;
begin
 for v_job_id in select jobid from cron.job where jobname='biddworld-auction-expected-price-lifecycle' loop
  perform cron.unschedule(v_job_id);
 end loop;
 perform cron.schedule(
  'biddworld-auction-expected-price-lifecycle',
  '* * * * *',
  $job$update public.auctions
       set status=case when ends_at is not null and ends_at<=now() then 'ended'::public.auction_status
                       when starts_at<=now() then 'live'::public.auction_status
                       else status end,
           updated_at=now()
       where status in ('scheduled','live')
         and ((status='scheduled' and starts_at<=now())
           or (status='live' and ends_at is not null and ends_at<=now()));$job$
 );
end;
$schedule$;
)
   or not exists(select 1 from storage.objects o where o.bucket_id='auction-submission-media' and o.name=v_path) then
   raise exception 'An image path is invalid, missing or does not belong to your account' using errcode='22023';end if;
 end loop;
 if p_starting_price is null or p_starting_price<=0 or p_expected_price is null
  or p_expected_price<p_starting_price or p_minimum_increment is null or p_minimum_increment<=0
  or p_starts_at is null or p_starts_at<now()+interval '30 minutes' then
  raise exception 'Expected price must be at least the starting price. Check prices and future start time.' using errcode='22023';end if;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000 then
  raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 insert into public.auction_submissions(submitted_by,member_id,title,description,category,image_paths,starting_price,expected_price,minimum_increment,starts_at,ends_at,optional_details)
 values(v_uid,v_member,btrim(p_title),btrim(p_description),nullif(btrim(coalesce(p_category,'')),''),p_image_paths,p_starting_price,p_expected_price,p_minimum_increment,p_starts_at,null,p_optional_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submitted_for_review','auction_submission',v_id,jsonb_build_object('member_id',v_member,'title',btrim(p_title),'starting_price',p_starting_price,'expected_price',p_expected_price));
 return v_id;
end;$function$;
revoke all on function public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb) from public,anon;
grant execute on function public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb) to authenticated;

-- Replace review RPC. Admin/Staff may edit both prices; a fixed end-time is not accepted.
drop function if exists public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb,text);
create or replace function public.admin_review_auction_submission(
 p_submission_id uuid,p_decision text,p_title text,p_description text,p_category text,
 p_image_paths text[],p_starting_price numeric,p_expected_price numeric,p_minimum_increment numeric,
 p_starts_at timestamptz,p_optional_details jsonb,p_review_note text default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_s public.auction_submissions%rowtype;v_product uuid;v_auction uuid;v_path text;v_reached timestamptz;v_deadline timestamptz;
begin
 if v_uid is null or not(v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')) then
  raise exception 'Auction submission review permission required' using errcode='42501';end if;
 if p_decision not in ('approve','reject') or length(coalesce(p_review_note,''))>500 then raise exception 'Invalid review decision or note' using errcode='22023';end if;
 select * into v_s from public.auction_submissions where id=p_submission_id for update;
 if not found or v_s.status<>'pending' then raise exception 'Submission is not pending review' using errcode='55000';end if;
 if p_decision='reject' then
  update public.auction_submissions set status='rejected',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now() where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(v_uid,'auction.submission_rejected','auction_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
 if length(btrim(coalesce(p_title,'')))<5 or length(btrim(p_title))>180 or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000
  or p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8
  or p_starting_price is null or p_starting_price<=0 or p_expected_price is null or p_expected_price<p_starting_price
  or p_minimum_increment is null or p_minimum_increment<=0 or p_starts_at is null or p_starts_at<now()
  or p_optional_details is null or jsonb_typeof(p_optional_details)<>'object'
  or exists(select 1 from jsonb_each(p_optional_details) item where jsonb_typeof(item.value)<>'string') then
  raise exception 'Reviewed auction details are incomplete or invalid' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_s.submitted_by::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$')
   or not exists(select 1 from storage.objects o where o.bucket_id='product-media' and o.name=v_path) then
   raise exception 'Reviewed public image path is invalid or missing' using errcode='22023';end if;
 end loop;
 if p_expected_price<=p_starting_price then v_reached:=p_starts_at;v_deadline:=p_starts_at+interval '48 hours';end if;
 insert into public.products(name,description,image_path,category,status)
 values(btrim(p_title),btrim(p_description),p_image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'published')
 returning id into v_product;
 insert into public.auctions(product_id,title,description,image_url,category,currency,starting_price,current_price,minimum_increment,starts_at,ends_at,status,expected_price,target_reached_at)
 values(v_product,btrim(p_title),btrim(p_description),p_image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'INR',p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,v_deadline,
  case when p_starts_at<=now() then 'live' else 'scheduled' end,p_expected_price,v_reached)
 returning id into v_auction;
 update public.auction_submissions set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now(),auction_id=v_auction,
  title=btrim(p_title),description=btrim(p_description),category=nullif(btrim(coalesce(p_category,'')),''),image_paths=p_image_paths,
  starting_price=p_starting_price,expected_price=p_expected_price,minimum_increment=p_minimum_increment,starts_at=p_starts_at,ends_at=v_deadline,optional_details=p_optional_details
 where id=v_s.id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submission_approved','auction_submission',v_s.id,jsonb_build_object('auction_id',v_auction,'product_id',v_product,'seller_member_id',v_s.member_id,'starting_price',p_starting_price,'expected_price',p_expected_price,'reviewer_role',v_role));
 return jsonb_build_object('success',true,'status','approved','auction_id',v_auction,'expected_price',p_expected_price,'ends_at',v_deadline);
end;$function$;
revoke all on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text) from public,anon;
grant execute on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text) to authenticated;

-- Public catalogue includes target price and an open-ended running state.
drop function if exists public.public_list_active_auctions_page(integer,integer);
create function public.public_list_active_auctions_page(
 p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,title text,description text,image_url text,current_price numeric,minimum_increment numeric,
 ends_at timestamptz,status text,category text,currency text,expected_price numeric,target_reached_at timestamptz,starts_at timestamptz
) language plpgsql stable security definer set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Page offset is out of range' using errcode='22023';end if;
 return query
 select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,a.ends_at,a.status,a.category,a.currency::text,
  a.expected_price,a.target_reached_at,a.starts_at
 from public.auctions a join public.products p on p.id=a.product_id
 where p.status='published' and (a.ends_at is null or a.ends_at>now())
  and ((a.status='live' and a.starts_at is not null and a.starts_at<=now())
    or (a.status='scheduled' and a.starts_at is not null and a.starts_at>now()))
 order by coalesce(a.ends_at,'infinity'::timestamptz) asc,a.id desc
 limit p_limit offset p_offset;
end;$function$;
revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated;

-- A null end time means the auction is waiting for its expected price, not that it has ended.

-- Keep bidding open while the expected price has not yet been reached (ends_at is NULL).
create or replace function private.place_bid(
  p_auction_id uuid,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_auction public.auctions%rowtype;
  v_bid_wallet public.wallet_accounts%rowtype;
  v_income_wallet public.wallet_accounts%rowtype;
  v_existing_id uuid;
  v_existing_member uuid;
  v_existing_auction uuid;
  v_existing_amount numeric(14,2);
  v_bid_id uuid;
  v_amount numeric(14,2);
  v_bid_debit numeric(14,2);
  v_income_debit numeric(14,2);
  v_enabled boolean := false;
  v_key text := btrim(coalesce(p_idempotency_key, ''));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if length(v_key) < 16 or length(v_key) > 100
     or v_key !~ '^[A-Za-z0-9:_-]+$' then
    raise exception 'A valid bid request key is required' using errcode = '22023';
  end if;

  select m.id into v_member_id
    from public.member_ids m
    join public.profiles p
      on p.id = m.owner_user_id
     and p.main_member_id = m.id
   where m.owner_user_id = v_uid
     and m.id_type = 'main'
     and m.status = 'active'
     and p.status = 'active'
   order by m.created_at, m.id
   limit 1;
  if v_member_id is not null then
    -- Serialize eligibility with Admin suspend/close/reactivate for this Main ID,
    -- then recheck after acquiring the lock to close the read-then-deactivate race.
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_member_id::text, 0)
    );
    if not exists (
      select 1
      from public.member_ids m
      join public.profiles p
        on p.id = m.owner_user_id
       and p.main_member_id = m.id
      where m.id = v_member_id
        and m.owner_user_id = v_uid
        and m.id_type = 'main'
        and m.status = 'active'
        and p.status = 'active'
    ) then
      v_member_id := null;
    end if;
  end if;
  if v_member_id is null then
    raise exception 'An active main member ID is required' using errcode = '42501';
  end if;

  -- Serialize reuse of one key, including attempts against different auctions.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_key, 0)
  );

  select id, member_id, auction_id, bid_amount
    into v_existing_id, v_existing_member, v_existing_auction, v_existing_amount
    from public.bids
   where idempotency_key = v_key;

  if found then
    if v_existing_member is distinct from v_member_id
       or v_existing_auction is distinct from p_auction_id then
      raise exception 'This bid request key has already been used for another request'
        using errcode = '23505';
    end if;
    return jsonb_build_object(
      'success', true,
      'bid_id', v_existing_id,
      'bid_amount', v_existing_amount,
      'bid_idempotency_key', v_key,
      'replayed', true
    );
  end if;

  select coalesce((setting_value #>> '{}')::boolean, false)
    into v_enabled
    from public.app_settings
   where setting_key = 'bidding_enabled';
  if not coalesce(v_enabled, false) then
    raise exception 'Bidding is disabled by administrator' using errcode = '55000';
  end if;

  select * into v_auction
    from public.auctions
   where id = p_auction_id
   for update;
  if not found
     or v_auction.status <> 'live'
     or v_auction.starts_at is null
     or now() < v_auction.starts_at
     or (v_auction.ends_at is not null and now() >= v_auction.ends_at) then
    raise exception 'Auction is not open' using errcode = '55000';
  end if;

  v_amount := v_auction.current_price + v_auction.minimum_increment;

  select * into v_bid_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'bid'
   for update;
  select * into v_income_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'income'
   for update;

  if v_bid_wallet.id is null or v_income_wallet.id is null then
    raise exception 'Wallets unavailable' using errcode = '55000';
  end if;

  v_bid_debit := least(v_bid_wallet.balance, v_amount);
  v_income_debit := v_amount - v_bid_debit;
  if v_income_wallet.balance < v_income_debit then
    raise exception 'Insufficient combined wallet balance' using errcode = '23514';
  end if;

  update public.wallet_accounts
     set balance = balance - v_bid_debit, updated_at = now()
   where id = v_bid_wallet.id;
  update public.wallet_accounts
     set balance = balance - v_income_debit, updated_at = now()
   where id = v_income_wallet.id;

  if v_bid_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_bid_wallet.id, v_member_id, 'auction_bid', 'debit', v_bid_debit,
       v_bid_wallet.balance - v_bid_debit, 'auction', p_auction_id,
       v_key || ':bid', 'Auction bid wallet debit');
  end if;
  if v_income_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_income_wallet.id, v_member_id, 'auction_bid', 'debit', v_income_debit,
       v_income_wallet.balance - v_income_debit, 'auction', p_auction_id,
       v_key || ':income', 'Auction income wallet debit');
  end if;

  insert into public.bids
    (auction_id, member_id, bid_amount, bid_wallet_debit,
     income_wallet_debit, status, idempotency_key)
  values
    (p_auction_id, v_member_id, v_amount, v_bid_debit,
     v_income_debit, 'accepted', v_key)
  returning id into v_bid_id;

  update public.auctions
     set current_price = v_amount, updated_at = now()
   where id = p_auction_id;

  return jsonb_build_object(
    'success', true,
    'bid_id', v_bid_id,
    'bid_amount', v_amount,
    'bid_idempotency_key', v_key,
    'replayed', false
  );
end;
$function$;


revoke all on function private.place_bid(uuid,text) from public,anon,authenticated;

-- Move scheduled listings to live at their start time and close them when the 48-hour
-- deadline is reached. The bid RPC independently enforces ends_at, so a delayed cron
-- tick cannot accept bids after the deadline.
create extension if not exists pg_cron;
do $schedule$
declare v_job_id bigint;
begin
 for v_job_id in select jobid from cron.job where jobname='biddworld-auction-expected-price-lifecycle' loop
  perform cron.unschedule(v_job_id);
 end loop;
 perform cron.schedule(
  'biddworld-auction-expected-price-lifecycle',
  '* * * * *',
  $job$update public.auctions
       set status=case when ends_at is not null and ends_at<=now() then 'ended'::public.auction_status
                       when starts_at<=now() then 'live'::public.auction_status
                       else status end,
           updated_at=now()
       where status in ('scheduled','live')
         and ((status='scheduled' and starts_at<=now())
           or (status='live' and ends_at is not null and ends_at<=now()));$job$
 );
end;
$schedule$;
)
   or not exists(select 1 from storage.objects o where o.bucket_id='product-media' and o.name=v_path) then
   raise exception 'Reviewed public image path is invalid or missing' using errcode='22023';end if;
 end loop;
 if p_expected_price<=p_starting_price then v_reached:=p_starts_at;v_deadline:=p_starts_at+interval '48 hours';end if;
 insert into public.products(name,description,image_path,category,status)
 values(btrim(p_title),btrim(p_description),p_image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'published')
 returning id into v_product;
 insert into public.auctions(product_id,title,description,image_url,category,currency,starting_price,current_price,minimum_increment,starts_at,ends_at,status,expected_price,target_reached_at)
 values(v_product,btrim(p_title),btrim(p_description),p_image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'INR',p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,v_deadline,
  case when p_starts_at<=now() then 'live' else 'scheduled' end,p_expected_price,v_reached)
 returning id into v_auction;
 update public.auction_submissions set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now(),auction_id=v_auction,
  title=btrim(p_title),description=btrim(p_description),category=nullif(btrim(coalesce(p_category,'')),''),image_paths=p_image_paths,
  starting_price=p_starting_price,expected_price=p_expected_price,minimum_increment=p_minimum_increment,starts_at=p_starts_at,ends_at=v_deadline,optional_details=p_optional_details
 where id=v_s.id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submission_approved','auction_submission',v_s.id,jsonb_build_object('auction_id',v_auction,'product_id',v_product,'seller_member_id',v_s.member_id,'starting_price',p_starting_price,'expected_price',p_expected_price,'reviewer_role',v_role));
 return jsonb_build_object('success',true,'status','approved','auction_id',v_auction,'expected_price',p_expected_price,'ends_at',v_deadline);
end;$function$;
revoke all on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text) from public,anon;
grant execute on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text) to authenticated;

-- Public catalogue includes target price and an open-ended running state.
drop function if exists public.public_list_active_auctions_page(integer,integer);
create function public.public_list_active_auctions_page(
 p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,title text,description text,image_url text,current_price numeric,minimum_increment numeric,
 ends_at timestamptz,status text,category text,currency text,expected_price numeric,target_reached_at timestamptz,starts_at timestamptz
) language plpgsql stable security definer set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Page offset is out of range' using errcode='22023';end if;
 return query
 select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,a.ends_at,a.status,a.category,a.currency::text,
  a.expected_price,a.target_reached_at,a.starts_at
 from public.auctions a join public.products p on p.id=a.product_id
 where p.status='published' and (a.ends_at is null or a.ends_at>now())
  and ((a.status='live' and a.starts_at is not null and a.starts_at<=now())
    or (a.status='scheduled' and a.starts_at is not null and a.starts_at>now()))
 order by coalesce(a.ends_at,'infinity'::timestamptz) asc,a.id desc
 limit p_limit offset p_offset;
end;$function$;
revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated;

-- A null end time means the auction is waiting for its expected price, not that it has ended.

-- Keep bidding open while the expected price has not yet been reached (ends_at is NULL).
create or replace function private.place_bid(
  p_auction_id uuid,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_auction public.auctions%rowtype;
  v_bid_wallet public.wallet_accounts%rowtype;
  v_income_wallet public.wallet_accounts%rowtype;
  v_existing_id uuid;
  v_existing_member uuid;
  v_existing_auction uuid;
  v_existing_amount numeric(14,2);
  v_bid_id uuid;
  v_amount numeric(14,2);
  v_bid_debit numeric(14,2);
  v_income_debit numeric(14,2);
  v_enabled boolean := false;
  v_key text := btrim(coalesce(p_idempotency_key, ''));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if length(v_key) < 16 or length(v_key) > 100
     or v_key !~ '^[A-Za-z0-9:_-]+$' then
    raise exception 'A valid bid request key is required' using errcode = '22023';
  end if;

  select m.id into v_member_id
    from public.member_ids m
    join public.profiles p
      on p.id = m.owner_user_id
     and p.main_member_id = m.id
   where m.owner_user_id = v_uid
     and m.id_type = 'main'
     and m.status = 'active'
     and p.status = 'active'
   order by m.created_at, m.id
   limit 1;
  if v_member_id is not null then
    -- Serialize eligibility with Admin suspend/close/reactivate for this Main ID,
    -- then recheck after acquiring the lock to close the read-then-deactivate race.
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_member_id::text, 0)
    );
    if not exists (
      select 1
      from public.member_ids m
      join public.profiles p
        on p.id = m.owner_user_id
       and p.main_member_id = m.id
      where m.id = v_member_id
        and m.owner_user_id = v_uid
        and m.id_type = 'main'
        and m.status = 'active'
        and p.status = 'active'
    ) then
      v_member_id := null;
    end if;
  end if;
  if v_member_id is null then
    raise exception 'An active main member ID is required' using errcode = '42501';
  end if;

  -- Serialize reuse of one key, including attempts against different auctions.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_key, 0)
  );

  select id, member_id, auction_id, bid_amount
    into v_existing_id, v_existing_member, v_existing_auction, v_existing_amount
    from public.bids
   where idempotency_key = v_key;

  if found then
    if v_existing_member is distinct from v_member_id
       or v_existing_auction is distinct from p_auction_id then
      raise exception 'This bid request key has already been used for another request'
        using errcode = '23505';
    end if;
    return jsonb_build_object(
      'success', true,
      'bid_id', v_existing_id,
      'bid_amount', v_existing_amount,
      'bid_idempotency_key', v_key,
      'replayed', true
    );
  end if;

  select coalesce((setting_value #>> '{}')::boolean, false)
    into v_enabled
    from public.app_settings
   where setting_key = 'bidding_enabled';
  if not coalesce(v_enabled, false) then
    raise exception 'Bidding is disabled by administrator' using errcode = '55000';
  end if;

  select * into v_auction
    from public.auctions
   where id = p_auction_id
   for update;
  if not found
     or v_auction.status <> 'live'
     or v_auction.starts_at is null
     or now() < v_auction.starts_at
     or (v_auction.ends_at is not null and now() >= v_auction.ends_at) then
    raise exception 'Auction is not open' using errcode = '55000';
  end if;

  v_amount := v_auction.current_price + v_auction.minimum_increment;

  select * into v_bid_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'bid'
   for update;
  select * into v_income_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'income'
   for update;

  if v_bid_wallet.id is null or v_income_wallet.id is null then
    raise exception 'Wallets unavailable' using errcode = '55000';
  end if;

  v_bid_debit := least(v_bid_wallet.balance, v_amount);
  v_income_debit := v_amount - v_bid_debit;
  if v_income_wallet.balance < v_income_debit then
    raise exception 'Insufficient combined wallet balance' using errcode = '23514';
  end if;

  update public.wallet_accounts
     set balance = balance - v_bid_debit, updated_at = now()
   where id = v_bid_wallet.id;
  update public.wallet_accounts
     set balance = balance - v_income_debit, updated_at = now()
   where id = v_income_wallet.id;

  if v_bid_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_bid_wallet.id, v_member_id, 'auction_bid', 'debit', v_bid_debit,
       v_bid_wallet.balance - v_bid_debit, 'auction', p_auction_id,
       v_key || ':bid', 'Auction bid wallet debit');
  end if;
  if v_income_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_income_wallet.id, v_member_id, 'auction_bid', 'debit', v_income_debit,
       v_income_wallet.balance - v_income_debit, 'auction', p_auction_id,
       v_key || ':income', 'Auction income wallet debit');
  end if;

  insert into public.bids
    (auction_id, member_id, bid_amount, bid_wallet_debit,
     income_wallet_debit, status, idempotency_key)
  values
    (p_auction_id, v_member_id, v_amount, v_bid_debit,
     v_income_debit, 'accepted', v_key)
  returning id into v_bid_id;

  update public.auctions
     set current_price = v_amount, updated_at = now()
   where id = p_auction_id;

  return jsonb_build_object(
    'success', true,
    'bid_id', v_bid_id,
    'bid_amount', v_amount,
    'bid_idempotency_key', v_key,
    'replayed', false
  );
end;
$function$;


revoke all on function private.place_bid(uuid,text) from public,anon,authenticated;

-- Move scheduled listings to live at their start time and close them when the 48-hour
-- deadline is reached. The bid RPC independently enforces ends_at, so a delayed cron
-- tick cannot accept bids after the deadline.
create extension if not exists pg_cron;
do $schedule$
declare v_job_id bigint;
begin
 for v_job_id in select jobid from cron.job where jobname='biddworld-auction-expected-price-lifecycle' loop
  perform cron.unschedule(v_job_id);
 end loop;
 perform cron.schedule(
  'biddworld-auction-expected-price-lifecycle',
  '* * * * *',
  $job$update public.auctions
       set status=case when ends_at is not null and ends_at<=now() then 'ended'::public.auction_status
                       when starts_at<=now() then 'live'::public.auction_status
                       else status end,
           updated_at=now()
       where status in ('scheduled','live')
         and ((status='scheduled' and starts_at<=now())
           or (status='live' and ends_at is not null and ends_at<=now()));$job$
 );
end;
$schedule$;
)
   or not exists(select 1 from storage.objects o where o.bucket_id='auction-submission-media' and o.name=v_path) then
   raise exception 'An image path is invalid, missing or does not belong to your account' using errcode='22023';end if;
 end loop;
 if p_starting_price is null or p_starting_price<=0 or p_expected_price is null
  or p_expected_price<p_starting_price or p_minimum_increment is null or p_minimum_increment<=0
  or p_starts_at is null or p_starts_at<now()+interval '30 minutes' then
  raise exception 'Expected price must be at least the starting price. Check prices and future start time.' using errcode='22023';end if;
 if p_optional_details is null or jsonb_typeof(p_optional_details)<>'object' or pg_catalog.octet_length(p_optional_details::text)>12000 then
  raise exception 'Optional details must be a small JSON object' using errcode='22023';end if;
 insert into public.auction_submissions(submitted_by,member_id,title,description,category,image_paths,starting_price,expected_price,minimum_increment,starts_at,ends_at,optional_details)
 values(v_uid,v_member,btrim(p_title),btrim(p_description),nullif(btrim(coalesce(p_category,'')),''),p_image_paths,p_starting_price,p_expected_price,p_minimum_increment,p_starts_at,null,p_optional_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submitted_for_review','auction_submission',v_id,jsonb_build_object('member_id',v_member,'title',btrim(p_title),'starting_price',p_starting_price,'expected_price',p_expected_price));
 return v_id;
end;$function$;
revoke all on function public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb) from public,anon;
grant execute on function public.member_submit_auction(text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb) to authenticated;

-- Replace review RPC. Admin/Staff may edit both prices; a fixed end-time is not accepted.
drop function if exists public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,timestamptz,timestamptz,jsonb,text);
create or replace function public.admin_review_auction_submission(
 p_submission_id uuid,p_decision text,p_title text,p_description text,p_category text,
 p_image_paths text[],p_starting_price numeric,p_expected_price numeric,p_minimum_increment numeric,
 p_starts_at timestamptz,p_optional_details jsonb,p_review_note text default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_s public.auction_submissions%rowtype;v_product uuid;v_auction uuid;v_path text;v_reached timestamptz;v_deadline timestamptz;
begin
 if v_uid is null or not(v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'auction_submission_review')) then
  raise exception 'Auction submission review permission required' using errcode='42501';end if;
 if p_decision not in ('approve','reject') or length(coalesce(p_review_note,''))>500 then raise exception 'Invalid review decision or note' using errcode='22023';end if;
 select * into v_s from public.auction_submissions where id=p_submission_id for update;
 if not found or v_s.status<>'pending' then raise exception 'Submission is not pending review' using errcode='55000';end if;
 if p_decision='reject' then
  update public.auction_submissions set status='rejected',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now() where id=v_s.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details) values(v_uid,'auction.submission_rejected','auction_submission',v_s.id,jsonb_build_object('review_note',p_review_note));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
 if length(btrim(coalesce(p_title,'')))<5 or length(btrim(p_title))>180 or length(btrim(coalesce(p_description,'')))<20 or length(p_description)>10000
  or p_image_paths is null or cardinality(p_image_paths)<1 or cardinality(p_image_paths)>8
  or p_starting_price is null or p_starting_price<=0 or p_expected_price is null or p_expected_price<p_starting_price
  or p_minimum_increment is null or p_minimum_increment<=0 or p_starts_at is null or p_starts_at<now()
  or p_optional_details is null or jsonb_typeof(p_optional_details)<>'object'
  or exists(select 1 from jsonb_each(p_optional_details) item where jsonb_typeof(item.value)<>'string') then
  raise exception 'Reviewed auction details are incomplete or invalid' using errcode='22023';end if;
 foreach v_path in array p_image_paths loop
  if v_path !~ ('^'||v_s.submitted_by::text||'/[A-Za-z0-9_-]+[.](jpg|jpeg|png|webp)$')
   or not exists(select 1 from storage.objects o where o.bucket_id='product-media' and o.name=v_path) then
   raise exception 'Reviewed public image path is invalid or missing' using errcode='22023';end if;
 end loop;
 if p_expected_price<=p_starting_price then v_reached:=p_starts_at;v_deadline:=p_starts_at+interval '48 hours';end if;
 insert into public.products(name,description,image_path,category,status)
 values(btrim(p_title),btrim(p_description),p_image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'published')
 returning id into v_product;
 insert into public.auctions(product_id,title,description,image_url,category,currency,starting_price,current_price,minimum_increment,starts_at,ends_at,status,expected_price,target_reached_at)
 values(v_product,btrim(p_title),btrim(p_description),p_image_paths[1],nullif(btrim(coalesce(p_category,'')),''),'INR',p_starting_price,p_starting_price,p_minimum_increment,p_starts_at,v_deadline,
  case when p_starts_at<=now() then 'live' else 'scheduled' end,p_expected_price,v_reached)
 returning id into v_auction;
 update public.auction_submissions set status='approved',review_note=nullif(btrim(coalesce(p_review_note,'')),''),reviewed_by=v_uid,reviewed_at=now(),updated_at=now(),auction_id=v_auction,
  title=btrim(p_title),description=btrim(p_description),category=nullif(btrim(coalesce(p_category,'')),''),image_paths=p_image_paths,
  starting_price=p_starting_price,expected_price=p_expected_price,minimum_increment=p_minimum_increment,starts_at=p_starts_at,ends_at=v_deadline,optional_details=p_optional_details
 where id=v_s.id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.submission_approved','auction_submission',v_s.id,jsonb_build_object('auction_id',v_auction,'product_id',v_product,'seller_member_id',v_s.member_id,'starting_price',p_starting_price,'expected_price',p_expected_price,'reviewer_role',v_role));
 return jsonb_build_object('success',true,'status','approved','auction_id',v_auction,'expected_price',p_expected_price,'ends_at',v_deadline);
end;$function$;
revoke all on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text) from public,anon;
grant execute on function public.admin_review_auction_submission(uuid,text,text,text,text,text[],numeric,numeric,numeric,timestamptz,jsonb,text) to authenticated;

-- Public catalogue includes target price and an open-ended running state.
drop function if exists public.public_list_active_auctions_page(integer,integer);
create function public.public_list_active_auctions_page(
 p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,title text,description text,image_url text,current_price numeric,minimum_increment numeric,
 ends_at timestamptz,status text,category text,currency text,expected_price numeric,target_reached_at timestamptz,starts_at timestamptz
) language plpgsql stable security definer set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>100 then raise exception 'Page size must be between 1 and 100' using errcode='22023';end if;
 if p_offset is null or p_offset<0 or p_offset>1000000 then raise exception 'Page offset is out of range' using errcode='22023';end if;
 return query
 select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,a.ends_at,a.status,a.category,a.currency::text,
  a.expected_price,a.target_reached_at,a.starts_at
 from public.auctions a join public.products p on p.id=a.product_id
 where p.status='published' and (a.ends_at is null or a.ends_at>now())
  and ((a.status='live' and a.starts_at is not null and a.starts_at<=now())
    or (a.status='scheduled' and a.starts_at is not null and a.starts_at>now()))
 order by coalesce(a.ends_at,'infinity'::timestamptz) asc,a.id desc
 limit p_limit offset p_offset;
end;$function$;
revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated;

-- A null end time means the auction is waiting for its expected price, not that it has ended.

-- Keep bidding open while the expected price has not yet been reached (ends_at is NULL).
create or replace function private.place_bid(
  p_auction_id uuid,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_auction public.auctions%rowtype;
  v_bid_wallet public.wallet_accounts%rowtype;
  v_income_wallet public.wallet_accounts%rowtype;
  v_existing_id uuid;
  v_existing_member uuid;
  v_existing_auction uuid;
  v_existing_amount numeric(14,2);
  v_bid_id uuid;
  v_amount numeric(14,2);
  v_bid_debit numeric(14,2);
  v_income_debit numeric(14,2);
  v_enabled boolean := false;
  v_key text := btrim(coalesce(p_idempotency_key, ''));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if length(v_key) < 16 or length(v_key) > 100
     or v_key !~ '^[A-Za-z0-9:_-]+$' then
    raise exception 'A valid bid request key is required' using errcode = '22023';
  end if;

  select m.id into v_member_id
    from public.member_ids m
    join public.profiles p
      on p.id = m.owner_user_id
     and p.main_member_id = m.id
   where m.owner_user_id = v_uid
     and m.id_type = 'main'
     and m.status = 'active'
     and p.status = 'active'
   order by m.created_at, m.id
   limit 1;
  if v_member_id is not null then
    -- Serialize eligibility with Admin suspend/close/reactivate for this Main ID,
    -- then recheck after acquiring the lock to close the read-then-deactivate race.
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_member_id::text, 0)
    );
    if not exists (
      select 1
      from public.member_ids m
      join public.profiles p
        on p.id = m.owner_user_id
       and p.main_member_id = m.id
      where m.id = v_member_id
        and m.owner_user_id = v_uid
        and m.id_type = 'main'
        and m.status = 'active'
        and p.status = 'active'
    ) then
      v_member_id := null;
    end if;
  end if;
  if v_member_id is null then
    raise exception 'An active main member ID is required' using errcode = '42501';
  end if;

  -- Serialize reuse of one key, including attempts against different auctions.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_key, 0)
  );

  select id, member_id, auction_id, bid_amount
    into v_existing_id, v_existing_member, v_existing_auction, v_existing_amount
    from public.bids
   where idempotency_key = v_key;

  if found then
    if v_existing_member is distinct from v_member_id
       or v_existing_auction is distinct from p_auction_id then
      raise exception 'This bid request key has already been used for another request'
        using errcode = '23505';
    end if;
    return jsonb_build_object(
      'success', true,
      'bid_id', v_existing_id,
      'bid_amount', v_existing_amount,
      'bid_idempotency_key', v_key,
      'replayed', true
    );
  end if;

  select coalesce((setting_value #>> '{}')::boolean, false)
    into v_enabled
    from public.app_settings
   where setting_key = 'bidding_enabled';
  if not coalesce(v_enabled, false) then
    raise exception 'Bidding is disabled by administrator' using errcode = '55000';
  end if;

  select * into v_auction
    from public.auctions
   where id = p_auction_id
   for update;
  if not found
     or v_auction.status <> 'live'
     or v_auction.starts_at is null
     or now() < v_auction.starts_at
     or (v_auction.ends_at is not null and now() >= v_auction.ends_at) then
    raise exception 'Auction is not open' using errcode = '55000';
  end if;

  v_amount := v_auction.current_price + v_auction.minimum_increment;

  select * into v_bid_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'bid'
   for update;
  select * into v_income_wallet
    from public.wallet_accounts
   where member_id = v_member_id and wallet_type = 'income'
   for update;

  if v_bid_wallet.id is null or v_income_wallet.id is null then
    raise exception 'Wallets unavailable' using errcode = '55000';
  end if;

  v_bid_debit := least(v_bid_wallet.balance, v_amount);
  v_income_debit := v_amount - v_bid_debit;
  if v_income_wallet.balance < v_income_debit then
    raise exception 'Insufficient combined wallet balance' using errcode = '23514';
  end if;

  update public.wallet_accounts
     set balance = balance - v_bid_debit, updated_at = now()
   where id = v_bid_wallet.id;
  update public.wallet_accounts
     set balance = balance - v_income_debit, updated_at = now()
   where id = v_income_wallet.id;

  if v_bid_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_bid_wallet.id, v_member_id, 'auction_bid', 'debit', v_bid_debit,
       v_bid_wallet.balance - v_bid_debit, 'auction', p_auction_id,
       v_key || ':bid', 'Auction bid wallet debit');
  end if;
  if v_income_debit > 0 then
    insert into public.wallet_transactions
      (wallet_account_id, member_id, transaction_type, direction, amount,
       balance_after, reference_type, reference_id, idempotency_key, description)
    values
      (v_income_wallet.id, v_member_id, 'auction_bid', 'debit', v_income_debit,
       v_income_wallet.balance - v_income_debit, 'auction', p_auction_id,
       v_key || ':income', 'Auction income wallet debit');
  end if;

  insert into public.bids
    (auction_id, member_id, bid_amount, bid_wallet_debit,
     income_wallet_debit, status, idempotency_key)
  values
    (p_auction_id, v_member_id, v_amount, v_bid_debit,
     v_income_debit, 'accepted', v_key)
  returning id into v_bid_id;

  update public.auctions
     set current_price = v_amount, updated_at = now()
   where id = p_auction_id;

  return jsonb_build_object(
    'success', true,
    'bid_id', v_bid_id,
    'bid_amount', v_amount,
    'bid_idempotency_key', v_key,
    'replayed', false
  );
end;
$function$;


revoke all on function private.place_bid(uuid,text) from public,anon,authenticated;

-- Move scheduled listings to live at their start time and close them when the 48-hour
-- deadline is reached. The bid RPC independently enforces ends_at, so a delayed cron
-- tick cannot accept bids after the deadline.
create extension if not exists pg_cron;
do $schedule$
declare v_job_id bigint;
begin
 for v_job_id in select jobid from cron.job where jobname='biddworld-auction-expected-price-lifecycle' loop
  perform cron.unschedule(v_job_id);
 end loop;
 perform cron.schedule(
  'biddworld-auction-expected-price-lifecycle',
  '* * * * *',
  $job$update public.auctions
       set status=case when ends_at is not null and ends_at<=now() then 'ended'::public.auction_status
                       when starts_at<=now() then 'live'::public.auction_status
                       else status end,
           updated_at=now()
       where status in ('scheduled','live')
         and ((status='scheduled' and starts_at<=now())
           or (status='live' and ends_at is not null and ends_at<=now()));$job$
 );
end;
$schedule$;
