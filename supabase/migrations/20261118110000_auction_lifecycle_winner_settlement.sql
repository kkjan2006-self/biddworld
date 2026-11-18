-- Auction publication, lifecycle, deterministic highest-bid winner selection and cancellation refunds.
-- Source-only until the canonical TEST baseline is replayed.

create table if not exists public.auction_winner_results (
 id uuid primary key default gen_random_uuid(),
 auction_id uuid not null unique references public.auctions(id),
 winning_bid_id uuid null references public.bids(id),
 winner_member_id uuid null references public.member_ids(id),
 winning_amount numeric(14,2) null check(winning_amount is null or winning_amount>0),
 finalized_by uuid not null references auth.users(id),
 finalized_at timestamptz not null default now()
);
alter table public.auction_winner_results enable row level security;
revoke all on public.auction_winner_results from public,anon,authenticated;

create or replace function public.admin_set_auction_status(p_auction_id uuid,p_status text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_auction public.auctions%rowtype;
 v_enabled boolean:=false; v_bid record; v_tx record; v_wallet public.wallet_accounts%rowtype;
 v_existing public.wallet_transactions%rowtype;
 v_new_balance numeric(14,2); v_refunded integer:=0; v_key text; v_debit_total numeric(14,2);
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_status is null or p_status not in ('scheduled','live','paused','ended','cancelled') then
  raise exception 'Unsupported auction status' using errcode='22023';
 end if;
 select * into v_auction from public.auctions where id=p_auction_id for update;
 if not found then raise exception 'Auction not found' using errcode='P0002'; end if;
 if v_auction.status in ('ended','cancelled') then raise exception 'A closed auction cannot be reopened or changed' using errcode='55000'; end if;
 if p_status in ('scheduled','live') then
  if not exists(select 1 from public.products where id=v_auction.product_id and status='published') then
   raise exception 'Publish the linked product before scheduling the auction' using errcode='55000';
  end if;
  if v_auction.starts_at is null or v_auction.ends_at is null or v_auction.ends_at<=v_auction.starts_at then
   raise exception 'Auction schedule is incomplete' using errcode='22023';
  end if;
  if p_status='scheduled' and v_auction.starts_at<=now() then
   raise exception 'A scheduled auction must start in the future' using errcode='22023';
  end if;
  if p_status='live' then
   if not (now()>=v_auction.starts_at and now()<v_auction.ends_at) then
    raise exception 'Auction can be opened only within its configured time window' using errcode='55000';
   end if;
   select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
   from public.app_settings where setting_key='bidding_enabled';
   if not coalesce(v_enabled,false) then raise exception 'Live bidding is disabled in Platform Settings' using errcode='55000'; end if;
  end if;
 end if;
 if p_status='ended' and v_auction.ends_at is not null and now()<v_auction.ends_at then
  raise exception 'Auction cannot end before its configured close time' using errcode='55000';
 end if;
 if p_status='cancelled' then
  if exists(select 1 from public.winning_item_payments where auction_id=p_auction_id and status='paid') then
   raise exception 'An auction with a paid winner item cannot be cancelled' using errcode='55000';
  end if;
  for v_bid in select * from public.bids where auction_id=p_auction_id and status='accepted' order by id for update
  loop
   v_debit_total:=0;
   for v_tx in select wallet_account_id,member_id,transaction_type,direction,amount,reference_type,reference_id,idempotency_key
    from public.wallet_transactions
    where idempotency_key in (v_bid.idempotency_key||':bid',v_bid.idempotency_key||':income')
      and direction='debit'
    order by wallet_account_id
   loop
    select * into v_wallet from public.wallet_accounts where id=v_tx.wallet_account_id for update;
    if not found or v_wallet.member_id is distinct from v_bid.member_id
      or (v_tx.idempotency_key=v_bid.idempotency_key||':bid' and v_wallet.wallet_type is distinct from 'bid')
      or (v_tx.idempotency_key=v_bid.idempotency_key||':income' and v_wallet.wallet_type is distinct from 'income')
      or v_tx.member_id is distinct from v_bid.member_id
      or v_tx.transaction_type is distinct from 'auction_bid'
      or v_tx.direction is distinct from 'debit'
      or v_tx.reference_type is distinct from 'auction'
      or v_tx.reference_id is distinct from p_auction_id
      or v_tx.amount is null or v_tx.amount<=0 then
     raise exception 'Original auction debit ledger does not match the bid owner and wallet; cancellation was rolled back' using errcode='23514';
    end if;
    v_debit_total:=v_debit_total+v_tx.amount;
    v_key:='auction-bid:'||v_bid.id::text||':refund:'||v_wallet.id::text;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_key;
    if found then
     if v_existing.wallet_account_id is distinct from v_wallet.id
       or v_existing.member_id is distinct from v_bid.member_id
       or v_existing.transaction_type is distinct from 'auction_bid_refund'
       or v_existing.direction is distinct from 'credit'
       or v_existing.amount is distinct from v_tx.amount
       or v_existing.reference_type is distinct from 'auction'
       or v_existing.reference_id is distinct from p_auction_id then
      raise exception 'Auction refund idempotency key conflicts with a different ledger transaction' using errcode='23505';
     end if;
    else
     v_new_balance:=v_wallet.balance+v_tx.amount;
     update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
     insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
     values(v_wallet.id,v_bid.member_id,'auction_bid_refund','credit',v_tx.amount,v_new_balance,
      'auction',p_auction_id,v_key,'Refund for cancelled auction bid');
    end if;
   end loop;
   if v_debit_total<>v_bid.bid_amount then
    raise exception 'Auction debit ledger does not reconcile to the recorded bid amount; cancellation was rolled back' using errcode='23514';
   end if;
   update public.bids set status='voided' where id=v_bid.id;
   v_refunded:=v_refunded+1;
  end loop;
 end if;
 update public.auctions set status=p_status,updated_at=now() where id=p_auction_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.status_changed','auctions',p_auction_id,
  jsonb_build_object('from',v_auction.status,'to',p_status,'refunded_bids',v_refunded));
 return jsonb_build_object('success',true,'auction_id',p_auction_id,'status',p_status,'refunded_bids',v_refunded);
end;
$function$;

create or replace function public.admin_finalize_auction(p_auction_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_auction public.auctions%rowtype; v_bid public.bids%rowtype;
 v_result public.auction_winner_results%rowtype; v_payment_id uuid;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select * into v_auction from public.auctions where id=p_auction_id for update;
 if not found then raise exception 'Auction not found' using errcode='P0002'; end if;
 if v_auction.status<>'ended' or v_auction.ends_at is null or now()<v_auction.ends_at then
  raise exception 'Only a fully ended auction can be finalized' using errcode='55000';
 end if;
 select * into v_result from public.auction_winner_results where auction_id=p_auction_id;
 if found then
  return jsonb_build_object('success',true,'auction_id',p_auction_id,'winner_member_id',v_result.winner_member_id,
   'winning_bid_id',v_result.winning_bid_id,'winning_amount',v_result.winning_amount,'replayed',true);
 end if;
 select * into v_bid from public.bids
 where auction_id=p_auction_id and status='accepted'
 order by bid_amount desc,created_at asc,id asc limit 1 for update;
 insert into public.auction_winner_results(auction_id,winning_bid_id,winner_member_id,winning_amount,finalized_by)
 values(p_auction_id,case when found then v_bid.id else null end,
  case when found then v_bid.member_id else null end,
  case when found then v_bid.bid_amount else null end,v_uid)
 returning * into v_result;
 if v_result.winner_member_id is not null then
  insert into public.winning_item_payments(auction_id,winner_member_id,amount,status)
  values(p_auction_id,v_result.winner_member_id,v_result.winning_amount,'pending')
  returning id into v_payment_id;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'auction.finalized','auctions',p_auction_id,
  jsonb_build_object('winner_member_id',v_result.winner_member_id,'winning_bid_id',v_result.winning_bid_id,
   'winning_amount',v_result.winning_amount,'winning_payment_id',v_payment_id));
 return jsonb_build_object('success',true,'auction_id',p_auction_id,'winner_member_id',v_result.winner_member_id,
  'winning_bid_id',v_result.winning_bid_id,'winning_amount',v_result.winning_amount,'winning_payment_id',v_payment_id,'replayed',false);
end;
$function$;

revoke all on function public.admin_set_auction_status(uuid,text) from public,anon;
grant execute on function public.admin_set_auction_status(uuid,text) to authenticated;
revoke all on function public.admin_finalize_auction(uuid) from public,anon;
grant execute on function public.admin_finalize_auction(uuid) to authenticated;
