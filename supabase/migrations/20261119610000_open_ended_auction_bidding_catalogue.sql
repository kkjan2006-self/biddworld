-- The Expected Price is the close trigger; End Time stays NULL until the target is reached.
create or replace function public.apply_auction_expected_price_deadline()
returns trigger language plpgsql set search_path=''
as $function$
declare v_target_time timestamptz;
begin
 if new.expected_price is null or new.target_reached_at is not null or new.current_price<new.expected_price then
  return new;
 end if;
 if new.status='scheduled' and new.starts_at is not null then
  -- When Starting Price already equals Expected Price, the clock begins at scheduled start.
  v_target_time:=new.starts_at;
 elsif new.status='live' and (new.starts_at is null or new.starts_at<=clock_timestamp()) then
  if tg_op='UPDATE' and (
    (old.current_price<new.expected_price and new.current_price>=new.expected_price)
    or (old.expected_price is distinct from new.expected_price and new.expected_price<=new.current_price)
  ) then
   v_target_time:=clock_timestamp();
  else
   v_target_time:=coalesce(new.starts_at,clock_timestamp());
  end if;
 else
  return new;
 end if;
 new.target_reached_at:=v_target_time;
 new.ends_at:=v_target_time+interval '48 hours';
 return new;
end;
$function$;
revoke all on function public.apply_auction_expected_price_deadline() from public,anon,authenticated;
drop trigger if exists auctions_expected_price_deadline on public.auctions;
create trigger auctions_expected_price_deadline
before insert or update of current_price,status,expected_price,starts_at on public.auctions
for each row execute function public.apply_auction_expected_price_deadline();

-- Remove the obsolete one-argument bid path; all bidding must use idempotent, eligibility-checked RPC.
drop function if exists public.place_bid(uuid);
drop function if exists private.place_bid(uuid);

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
     or v_auction.status not in ('live','scheduled')
     or v_auction.starts_at is null
     or now() < v_auction.starts_at
     or (v_auction.ends_at is not null and now() >= v_auction.ends_at) then
    raise exception 'Auction is not open' using errcode = '55000';
  end if;

  -- A scheduled auction becomes live on its first eligible bid after the scheduled start.
  -- The lifecycle trigger also starts the 48-hour clock when the target was already reached.
  if v_auction.status='scheduled' then
    update public.auctions set status='live',updated_at=now()
    where id=p_auction_id and status='scheduled';
    v_auction.status:='live';
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
create or replace function public.place_bid(
  p_auction_id uuid,
  p_idempotency_key text
) returns jsonb
language sql
security definer
set search_path = pg_catalog, public, private
as $function$
  select private.place_bid(p_auction_id, p_idempotency_key);
$function$;
-- Public catalogue activates due scheduled auctions, supports NULL End Time, and exposes Expected Price.
drop function if exists public.public_list_active_auctions_page(integer,integer);
create function public.public_list_active_auctions_page(
 p_limit integer default 100,p_offset integer default 0
) returns table(
 id uuid,title text,description text,image_url text,current_price numeric,minimum_increment numeric,
 expected_price numeric,target_reached_at timestamptz,starts_at timestamptz,ends_at timestamptz,
 status text,category text,currency text
) language plpgsql security definer set search_path=''
as $function$
begin
 if p_limit is null or p_limit<1 or p_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Page offset is out of range' using errcode='22023';
 end if;
 -- A public catalogue visit performs the scheduled-to-live transition once the start time arrives.
 -- This also invokes the expected-price trigger for targets already met at Starting Price.
 update public.auctions a set status='live',updated_at=now()
 where a.status='scheduled' and a.starts_at is not null and a.starts_at<=now()
  and exists(select 1 from public.products p where p.id=a.product_id and p.status='published');
 return query
 select a.id,a.title,a.description,a.image_url,a.current_price,a.minimum_increment,
  a.expected_price,a.target_reached_at,a.starts_at,a.ends_at,a.status,a.category,a.currency::text
 from public.auctions a join public.products p on p.id=a.product_id
 where p.status='published'
  and (a.ends_at is null or a.ends_at>now())
  and ((a.status='live' and a.starts_at is not null and a.starts_at<=now())
    or (a.status='scheduled' and a.starts_at is not null and a.starts_at>now()))
 order by a.starts_at asc,a.id desc
 limit p_limit offset p_offset;
end;
$function$;
revoke all on function public.public_list_active_auctions_page(integer,integer) from public,anon,authenticated;
grant execute on function public.public_list_active_auctions_page(integer,integer) to anon,authenticated;
