-- Serialize auction bid eligibility with Admin Main-ID suspension/closure.
-- The same per-Main-ID transaction lock is acquired by the Admin lifecycle RPC.
-- Recheck activity after acquiring the lock so a concurrent status change cannot
-- race between the initial lookup and the wallet debit.
-- Source-only. Do not apply to Production or TEST during development.

create or replace function public.admin_set_main_member_status(
 p_member_code text,p_status text,p_reason text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_main public.member_ids%rowtype; v_old_status text;
 v_duplicate_count integer:=0;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_status is null or p_status not in ('active','suspended','closed') then
  raise exception 'Choose active, suspended or closed status' using errcode='22023';
 end if;
 if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Provide a reason between 5 and 500 characters' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0));
 select * into v_main from public.member_ids
 where upper(member_code)=upper(trim(p_member_code)) and id_type='main' for update;
 if not found then raise exception 'Main Member ID not found' using errcode='P0002'; end if;
 -- Share the per-Main-ID lifecycle lock with bid placement. This prevents a bid
 -- from passing its active check concurrently with a suspend/close operation.
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_main.id::text, 0)
 );
 v_old_status:=v_main.status;
 if v_old_status='closed' and p_status<>'closed' then
  raise exception 'A closed Main ID cannot be reactivated' using errcode='55000';
 end if;
 if v_old_status=p_status then
  return jsonb_build_object('success',true,'member_code',v_main.member_code,'status',p_status,'replayed',true);
 end if;
 update public.member_ids set status=p_status where id=v_main.id;
 update public.profiles set status=p_status,updated_at=now() where id=v_main.owner_user_id;
 if p_status='suspended' then
  update public.member_ids set status='suspended',main_status_managed=true
  where main_member_id=v_main.id and id_type='duplicate' and status='active' and not main_status_managed;
  get diagnostics v_duplicate_count=row_count;
 elsif p_status='closed' then
  update public.member_ids set status='closed',main_status_managed=true
  where main_member_id=v_main.id and id_type='duplicate'
    and (status in ('active','pending') or (status='suspended' and main_status_managed));
  get diagnostics v_duplicate_count=row_count;
 elsif p_status='active' then
  update public.member_ids d set status='active',main_status_managed=false
  where d.main_member_id=v_main.id and d.id_type='duplicate' and d.status='suspended' and d.main_status_managed
    and exists(select 1 from public.member_ids parent where parent.id=d.placement_parent_id
      and parent.status='active' and parent.owner_user_id is distinct from d.owner_user_id);
  get diagnostics v_duplicate_count=row_count;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'member.main_status_changed','member_ids',v_main.id,
  jsonb_build_object('member_code',v_main.member_code,'old_status',v_old_status,
   'new_status',p_status,'reason',trim(p_reason),'linked_duplicate_ids_changed',v_duplicate_count));
 return jsonb_build_object('success',true,'member_code',v_main.member_code,'status',p_status,
  'linked_duplicate_ids_changed',v_duplicate_count,'replayed',false);
end;
$function$;
revoke all on function public.admin_set_main_member_status(text,text,text) from public,anon;
grant execute on function public.admin_set_main_member_status(text,text,text) to authenticated;

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
