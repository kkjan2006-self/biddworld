-- Applied production migration: secure bidding RPC and Auth signup provisioning.
-- Keep privileged code in the non-exposed private schema. The public RPC is invoker-only.

create schema if not exists private;

create or replace function private.place_bid(p_auction_id uuid)
returns jsonb
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
  v_amount numeric(14,2);
  v_bid_debit numeric(14,2);
  v_income_debit numeric(14,2);
  v_enabled boolean := false;
  v_key text := gen_random_uuid()::text;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;

  select coalesce((setting_value #>> '{}')::boolean, false)
    into v_enabled
    from public.app_settings
   where setting_key = 'bidding_enabled';

  if not coalesce(v_enabled, false) then
    raise exception 'Bidding is disabled by administrator';
  end if;

  select id into v_member_id
    from public.member_ids
   where owner_user_id = v_uid
     and id_type = 'main'
     and status = 'active'
   limit 1;

  if v_member_id is null then
    raise exception 'An active main member ID is required';
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
    raise exception 'Auction is not open';
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
    raise exception 'Wallets unavailable';
  end if;

  v_bid_debit := least(v_bid_wallet.balance, v_amount);
  v_income_debit := v_amount - v_bid_debit;

  if v_income_wallet.balance < v_income_debit then
    raise exception 'Insufficient combined wallet balance';
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
     v_income_debit, 'accepted', v_key);

  update public.auctions
     set current_price = v_amount, updated_at = now()
   where id = p_auction_id;

  return jsonb_build_object(
    'success', true,
    'bid_amount', v_amount,
    'bid_idempotency_key', v_key
  );
end;
$function$;

revoke all on function private.place_bid(uuid) from public, anon, authenticated;

create or replace function public.place_bid(p_auction_id uuid)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public, private
as $function$
  select private.place_bid(p_auction_id);
$function$;

revoke all on function public.place_bid(uuid) from public, anon;
grant execute on function public.place_bid(uuid) to authenticated;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member_id uuid;
  v_member_code text;
begin
  insert into public.profiles (id, display_name, status)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    'active'
  )
  on conflict (id) do nothing;

  v_member_code := 'BW' || upper(substr(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.member_ids (owner_user_id, member_code, id_type, status)
  values (new.id, v_member_code, 'main', 'active')
  on conflict do nothing
  returning id into v_member_id;

  if v_member_id is null then
    select id into v_member_id
      from public.member_ids
     where owner_user_id = new.id and id_type = 'main'
     limit 1;
  end if;

  if v_member_id is not null then
    update public.profiles
       set main_member_id = v_member_id
     where id = new.id;

    insert into public.wallet_accounts (member_id, wallet_type, balance)
    values (v_member_id, 'bid', 0), (v_member_id, 'income', 0)
    on conflict (member_id, wallet_type) do nothing;
  end if;

  return new;
end;
$function$;

revoke all on function private.handle_new_auth_user() from public, anon, authenticated;

drop trigger if exists on_biddworld_auth_user_created on auth.users;
create trigger on_biddworld_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();
