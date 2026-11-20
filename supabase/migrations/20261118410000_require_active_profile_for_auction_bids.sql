-- Require both the owning profile and Main ID to be active before accepting an auction bid.
-- Preserve the established idempotency, wallet-first debit, ledger and RPC contracts.
-- Source-only until consolidated final testing; never apply to Production during development.

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
     or v_auction.ends_at is null
     or now() < v_auction.starts_at
     or now() >= v_auction.ends_at then
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

revoke all on function private.place_bid(uuid, text)
  from public, anon, authenticated;

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

revoke all on function public.place_bid(uuid, text) from public, anon;
grant execute on function public.place_bid(uuid, text) to authenticated;

comment on function public.place_bid(uuid, text) is
  'Authenticated bid entry point with stable client idempotency; private implementation validates auth.uid() and atomically debits wallets.';
