-- Serialize member-initiated Fixed Bid, withdrawal and winner-payment actions
-- with the same per-Main-ID lock used by Admin suspension/closure and auction bids.
-- Recheck eligibility after acquiring the lock so no action can pass a stale
-- active-status read while the Admin lifecycle transaction is changing that ID.
-- Source-only. Do not apply to Production or TEST during development.

create or replace function public.member_join_fixed_bid_campaign(p_campaign_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_member_id uuid; v_campaign public.fixed_bid_campaigns%rowtype;
 v_bid_wallet public.wallet_accounts%rowtype; v_income_wallet public.wallet_accounts%rowtype;
 v_entry_id uuid; v_amount numeric(14,2); v_bid_debit numeric(14,2); v_income_debit numeric(14,2);
 v_max_member integer; v_max_total integer; v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_enabled boolean:=false;
 v_existing_entry public.fixed_bids%rowtype;
 v_existing_debit record; v_existing_wallet public.wallet_accounts%rowtype;
 v_existing_debit_total numeric(14,2):=0;
 v_existing_bid_debit numeric(14,2):=0; v_existing_income_debit numeric(14,2):=0;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid entry request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select m.id into v_member_id
 from public.member_ids m
 join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active'
 order by m.created_at,m.id limit 1;
 if v_member_id is null then raise exception 'An active Main ID is required' using errcode='42501'; end if;
 -- Serialize Fixed Bid eligibility with Admin Main-ID suspend/close/reactivate.
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_member_id::text, 0)
 );
 if not exists(
  select 1 from public.member_ids m
  join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
  where m.id=v_member_id and m.owner_user_id=v_uid
   and m.id_type='main' and m.status='active' and p.status='active'
 ) then
  raise exception 'An active Main ID is required' using errcode='42501';
 end if;
 select * into v_campaign from public.fixed_bid_campaigns where id=p_campaign_id for update;
 if not found then raise exception 'Campaign not found' using errcode='P0002'; end if;
 select * into v_existing_entry from public.fixed_bids
 where idempotency_key=v_key for update;
 if found then
  if v_existing_entry.member_id is distinct from v_member_id
    or v_existing_entry.campaign_id is distinct from p_campaign_id
    or v_existing_entry.status not in ('submitted','accepted') then
   raise exception 'This request key was already used for a different or closed entry' using errcode='23505';
  end if;
  for v_existing_debit in
   select wallet_account_id,member_id,transaction_type,direction,amount,reference_type,reference_id,idempotency_key
   from public.wallet_transactions
   where idempotency_key in (v_key||':bid',v_key||':income')
   order by idempotency_key
  loop
   select * into v_existing_wallet from public.wallet_accounts where id=v_existing_debit.wallet_account_id;
   if not found
     or v_existing_debit.member_id is distinct from v_member_id
     or v_existing_debit.transaction_type is distinct from 'fixed_bid_entry'
     or v_existing_debit.direction is distinct from 'debit'
     or v_existing_debit.amount is null or v_existing_debit.amount<=0
     or v_existing_debit.reference_type is distinct from 'fixed_bid_entry'
     or v_existing_debit.reference_id is distinct from v_existing_entry.id
     or v_existing_wallet.member_id is distinct from v_member_id
     or (v_existing_debit.idempotency_key=v_key||':bid' and v_existing_wallet.wallet_type is distinct from 'bid')
     or (v_existing_debit.idempotency_key=v_key||':income' and v_existing_wallet.wallet_type is distinct from 'income') then
    raise exception 'Existing Fixed Bid entry ledger is missing or inconsistent; retry was not accepted' using errcode='23514';
   end if;
   v_existing_debit_total:=v_existing_debit_total+v_existing_debit.amount;
   if v_existing_debit.idempotency_key=v_key||':bid' then
    v_existing_bid_debit:=v_existing_debit.amount;
   else
    v_existing_income_debit:=v_existing_debit.amount;
   end if;
  end loop;
  if v_existing_debit_total<>v_existing_entry.bid_amount then
   raise exception 'Existing Fixed Bid entry ledger does not reconcile to the recorded amount' using errcode='23514';
  end if;
  return jsonb_build_object('success',true,'entry_id',v_existing_entry.id,
   'entry_amount',v_existing_entry.bid_amount,'bid_wallet_debit',v_existing_bid_debit,
   'income_wallet_debit',v_existing_income_debit,'replayed',true);
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='fixed_bid_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Fixed Bid participation is disabled' using errcode='55000'; end if;
 if v_campaign.status<>'live'
   or now()<nullif(v_campaign.configuration->>'starts_at','')::timestamptz
   or now()>=nullif(v_campaign.configuration->>'ends_at','')::timestamptz then
  raise exception 'This Fixed Bid campaign is not open for entries' using errcode='55000';
 end if;
 v_amount:=nullif(v_campaign.configuration->>'entry_amount','')::numeric;
 v_max_member:=coalesce(nullif(v_campaign.configuration->>'max_entries_per_member','')::integer,1);
 v_max_total:=coalesce(nullif(v_campaign.configuration->>'max_entries_total','')::integer,0);
 if v_amount is null or v_amount<=0 or v_max_member<1 or v_max_total<1 then
  raise exception 'Campaign entry rules are incomplete' using errcode='55000';
 end if;
 if (select count(*) from public.fixed_bids where campaign_id=p_campaign_id and status in ('submitted','accepted'))>=v_max_total then
  raise exception 'This campaign has reached its entry limit' using errcode='55000';
 end if;
 if (select count(*) from public.fixed_bids where campaign_id=p_campaign_id and member_id=v_member_id and status in ('submitted','accepted'))>=v_max_member then
  raise exception 'You have reached your entry limit for this campaign' using errcode='55000';
 end if;
 select * into v_bid_wallet from public.wallet_accounts where member_id=v_member_id and wallet_type='bid' for update;
 select * into v_income_wallet from public.wallet_accounts where member_id=v_member_id and wallet_type='income' for update;
 if v_bid_wallet.id is null or v_income_wallet.id is null then raise exception 'Member wallets are unavailable' using errcode='55000'; end if;
 v_bid_debit:=least(v_bid_wallet.balance,v_amount);
 v_income_debit:=v_amount-v_bid_debit;
 if v_income_wallet.balance<v_income_debit then raise exception 'Insufficient Funds – Please Add Funds' using errcode='23514'; end if;
 insert into public.fixed_bids(campaign_id,member_id,bid_amount,status,idempotency_key)
 values(p_campaign_id,v_member_id,v_amount,'accepted',v_key) returning id into v_entry_id;
 update public.wallet_accounts set balance=balance-v_bid_debit,updated_at=now() where id=v_bid_wallet.id;
 update public.wallet_accounts set balance=balance-v_income_debit,updated_at=now() where id=v_income_wallet.id;
 if v_bid_debit>0 then
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_bid_wallet.id,v_member_id,'fixed_bid_entry','debit',v_bid_debit,v_bid_wallet.balance-v_bid_debit,'fixed_bid_entry',v_entry_id,v_key||':bid','Fixed Bid entry from Bid Wallet');
 end if;
 if v_income_debit>0 then
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_income_wallet.id,v_member_id,'fixed_bid_entry','debit',v_income_debit,v_income_wallet.balance-v_income_debit,'fixed_bid_entry',v_entry_id,v_key||':income','Fixed Bid entry from Income Wallet');
 end if;
 return jsonb_build_object('success',true,'entry_id',v_entry_id,'entry_amount',v_amount,'bid_wallet_debit',v_bid_debit,'income_wallet_debit',v_income_debit,'replayed',false);
end;
$function$;

create or replace function public.member_create_withdrawal_request(
  p_amount numeric,
  p_payout_details jsonb
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_member uuid;
  v_balance numeric;
  v_id uuid;
  v_minimum numeric := 0;
  v_method text;
  v_holder text;
  v_reference text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) or p_amount > 10000000 then
    raise exception 'Enter a valid withdrawal amount with no more than two decimal places' using errcode = '22023';
  end if;

  if p_payout_details is null
    or jsonb_typeof(p_payout_details) <> 'object'
    or length(p_payout_details::text) > 2000 then
    raise exception 'Valid payout details are required' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_object_keys(p_payout_details) as supplied(key)
    where supplied.key not in ('method', 'account_holder_name', 'upi_id', 'account_number')
  ) then
    raise exception 'Unsupported payout detail fields were supplied' using errcode = '22023';
  end if;

  if coalesce(jsonb_typeof(p_payout_details->'method'), 'null') <> 'string'
    or coalesce(jsonb_typeof(p_payout_details->'account_holder_name'), 'null') <> 'string' then
    raise exception 'Payout method and account holder name are required' using errcode = '22023';
  end if;

  v_method := btrim(p_payout_details->>'method');
  v_holder := btrim(p_payout_details->>'account_holder_name');

  if length(v_holder) < 2 or length(v_holder) > 100 then
    raise exception 'Account holder name must contain 2 to 100 characters' using errcode = '22023';
  end if;

  if v_method = 'UPI' then
    if p_payout_details ? 'account_number'
      or coalesce(jsonb_typeof(p_payout_details->'upi_id'), 'null') <> 'string' then
      raise exception 'Provide only a valid UPI ID for the selected payout method' using errcode = '22023';
    end if;

    v_reference := btrim(p_payout_details->>'upi_id');
    if v_reference is null or v_reference !~ '^[A-Za-z0-9._-]{2,256}@[A-Za-z0-9.-]{2,64}$' then
      raise exception 'Enter a valid UPI ID' using errcode = '22023';
    end if;
  elsif v_method = 'Bank Transfer' then
    if p_payout_details ? 'upi_id'
      or coalesce(jsonb_typeof(p_payout_details->'account_number'), 'null') <> 'string' then
      raise exception 'Provide only a valid bank account number for the selected payout method' using errcode = '22023';
    end if;

    v_reference := btrim(p_payout_details->>'account_number');
    if v_reference is null or v_reference !~ '^[0-9]{6,18}$' then
      raise exception 'Bank account number must contain 6 to 18 digits' using errcode = '22023';
    end if;
  else
    raise exception 'Choose UPI or Bank Transfer as the payout method' using errcode = '22023';
  end if;

  if coalesce((
    select (setting_value#>>'{}')::boolean
    from public.app_settings
    where setting_key = 'withdrawals_enabled'
  ), false) is not true then
    raise exception 'Withdrawals are currently disabled' using errcode = '55000';
  end if;

  select coalesce((setting_value#>>'{}')::numeric, 0)
  into v_minimum
  from public.app_settings
  where setting_key = 'minimum_withdrawal_amount';

  if p_amount < coalesce(v_minimum, 0) then
    raise exception 'Minimum withdrawal amount is ₹%',
      to_char(coalesce(v_minimum, 0), 'FM999999999990.00') using errcode = '22023';
  end if;

  select p.main_member_id
  into v_member
  from public.profiles p
  where p.id = v_uid
    and p.status = 'active';

  if v_member is null or not exists (
    select 1
    from public.member_ids m
    where m.id = v_member
      and m.owner_user_id = v_uid
      and m.id_type = 'main'
      and m.status = 'active'
  ) then
    raise exception 'An active member profile and Main ID belonging to this account are required' using errcode = '42501';
  end if;

  -- Serialize withdrawal eligibility with Admin Main-ID lifecycle changes.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_member::text, 0)
  );

  if not exists (
    select 1
    from public.profiles p
    join public.member_ids m on m.id = p.main_member_id
    where p.id = v_uid
      and p.main_member_id = v_member
      and p.status = 'active'
      and m.owner_user_id = v_uid
      and m.id_type = 'main'
      and m.status = 'active'
  ) then
    raise exception 'An active member profile and Main ID belonging to this account are required' using errcode = '42501';
  end if;

  select balance
  into v_balance
  from public.wallet_accounts
  where member_id = v_member
    and wallet_type = 'income'
  for update;

  if v_balance is null or v_balance < p_amount then
    raise exception 'Insufficient Income Wallet balance' using errcode = '23514';
  end if;

  if exists (
    select 1
    from public.withdrawal_requests
    where member_id = v_member
      and status in ('pending', 'approved')
  ) then
    raise exception 'An open withdrawal request already exists' using errcode = '55000';
  end if;

  insert into public.withdrawal_requests(member_id, amount, currency, status, payout_details)
  values (
    v_member,
    p_amount,
    'INR',
    'pending',
    jsonb_build_object(
      'method', v_method,
      'account_holder_name', v_holder,
      case when v_method = 'UPI' then 'upi_id' else 'account_number' end,
      v_reference
    )
  )
  returning id into v_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (
    v_uid,
    'member_withdrawal_requested',
    'withdrawal_requests',
    v_id,
    jsonb_build_object('amount', p_amount, 'payout_method', v_method)
  );

  return jsonb_build_object(
    'success', true,
    'request_id', v_id,
    'status', 'pending',
    'minimum_amount', coalesce(v_minimum, 0)
  );
end;
$function$;

create or replace function public.member_pay_winning_item_payment(p_payment_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_main uuid; v_payment public.winning_item_payments%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_enabled boolean:=false; v_new_balance numeric(14,2); v_tx public.wallet_transactions%rowtype;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid payment request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select p.main_member_id into v_main
 from public.profiles p
 join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id
 where p.id=v_uid and p.status='active' and m.id_type='main' and m.status='active';
 if v_main is null then raise exception 'An active member profile and Main ID are required' using errcode='42501'; end if;
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_main::text, 0)
 );
 if not exists(
  select 1 from public.profiles p
  join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id
  where p.id=v_uid and p.main_member_id=v_main and p.status='active'
   and m.id_type='main' and m.status='active'
 ) then
  raise exception 'An active member profile and Main ID are required' using errcode='42501';
 end if;
 select * into v_payment from public.winning_item_payments
 where id=p_payment_id and winner_member_id=v_main for update;
 if not found then raise exception 'Winning payment not found' using errcode='P0002'; end if;
 select * into v_tx from public.wallet_transactions where idempotency_key=v_key;
 if found then
  if v_payment.status='paid' and v_payment.paid_at is not null
    and v_tx.reference_type='winning_item_payment'
    and v_tx.reference_id=p_payment_id
    and v_tx.member_id=v_main
    and v_tx.transaction_type='winning_item_payment'
    and v_tx.direction='debit'
    and v_tx.amount=v_payment.amount
    and exists(select 1 from public.wallet_accounts w
      where w.id=v_tx.wallet_account_id and w.member_id=v_main and w.wallet_type='income') then
   return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','replayed',true);
  end if;
  raise exception 'Existing payment ledger does not reconcile to a completed winning payment' using errcode='23514';
 end if;
 if v_payment.status<>'pending' then raise exception 'This winning payment is no longer pending' using errcode='55000'; end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='winning_payment_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Winner payment is disabled' using errcode='55000'; end if;
 select * into v_wallet from public.wallet_accounts
 where member_id=v_main and wallet_type='income' for update;
 if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
 if v_wallet.balance<v_payment.amount then raise exception 'Insufficient Funds – Please Add Funds' using errcode='23514'; end if;
 v_new_balance:=v_wallet.balance-v_payment.amount;
 update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
 insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
 values(v_wallet.id,v_main,'winning_item_payment','debit',v_payment.amount,v_new_balance,'winning_item_payment',p_payment_id,v_key,
  case when v_payment.fixed_bid_campaign_id is not null then 'Fixed Bid winning payment from Income Wallet' else 'Auction winning payment from Income Wallet' end);
 update public.winning_item_payments set status='paid',paid_at=now() where id=p_payment_id;
 return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','income_wallet_balance',v_new_balance,'replayed',false);
end;
$function$;

create or replace function public.member_pay_fixed_bid_winning_payment(p_payment_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_main uuid; v_payment public.winning_item_payments%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_tx public.wallet_transactions%rowtype;
 v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_enabled boolean:=false; v_new_balance numeric(14,2);
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then raise exception 'A valid payment request key is required' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select p.main_member_id into v_main
 from public.profiles p
 join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id
 where p.id=v_uid and p.status='active' and m.id_type='main' and m.status='active';
 if v_main is null then raise exception 'An active member profile and Main ID are required' using errcode='42501'; end if;
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.main_member_lifecycle:' || v_main::text, 0)
 );
 if not exists(
  select 1 from public.profiles p
  join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id
  where p.id=v_uid and p.main_member_id=v_main and p.status='active'
   and m.id_type='main' and m.status='active'
 ) then
  raise exception 'An active member profile and Main ID are required' using errcode='42501';
 end if;
 select * into v_payment from public.winning_item_payments
 where id=p_payment_id and fixed_bid_campaign_id is not null and winner_member_id=v_main for update;
 if not found then raise exception 'Fixed Bid winner payment not found' using errcode='P0002'; end if;
 select * into v_tx from public.wallet_transactions where idempotency_key=v_key;
 if found then
  if v_payment.status='paid' and v_payment.paid_at is not null
    and v_tx.member_id is not distinct from v_main
    and v_tx.transaction_type is not distinct from 'winning_item_payment'
    and v_tx.direction is not distinct from 'debit'
    and v_tx.amount is not distinct from v_payment.amount
    and v_tx.reference_type is not distinct from 'winning_item_payment'
    and v_tx.reference_id is not distinct from p_payment_id
    and exists(select 1 from public.wallet_accounts w
      where w.id=v_tx.wallet_account_id and w.member_id=v_main and w.wallet_type='income') then
   return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','replayed',true);
  end if;
  raise exception 'Existing payment ledger does not reconcile to a completed Fixed Bid winning payment' using errcode='23514';
 end if;
 if v_payment.status<>'pending' then raise exception 'This winning payment is no longer pending' using errcode='55000'; end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='winning_payment_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Winner payment is disabled' using errcode='55000'; end if;
 select * into v_wallet from public.wallet_accounts
 where member_id=v_main and wallet_type='income' for update;
 if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
 if v_wallet.balance<v_payment.amount then raise exception 'Insufficient Funds – Please Add Funds' using errcode='23514'; end if;
 v_new_balance:=v_wallet.balance-v_payment.amount;
 update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
 insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
 values(v_wallet.id,v_main,'winning_item_payment','debit',v_payment.amount,v_new_balance,'winning_item_payment',p_payment_id,v_key,'Fixed Bid winning payment from Income Wallet');
 update public.winning_item_payments set status='paid',paid_at=now() where id=p_payment_id;
 return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','income_wallet_balance',v_new_balance,'replayed',false);
end;
$function$;

revoke all on function public.member_join_fixed_bid_campaign(uuid,text) from public,anon;
grant execute on function public.member_join_fixed_bid_campaign(uuid,text) to authenticated;

revoke all on function public.member_create_withdrawal_request(numeric,jsonb) from public,anon;
grant execute on function public.member_create_withdrawal_request(numeric,jsonb) to authenticated;

revoke all on function public.member_pay_winning_item_payment(uuid,text) from public,anon;
grant execute on function public.member_pay_winning_item_payment(uuid,text) to authenticated;

revoke all on function public.member_pay_fixed_bid_winning_payment(uuid,text) from public,anon;
grant execute on function public.member_pay_fixed_bid_winning_payment(uuid,text) to authenticated;
