-- Align Auction winner eligibility with Fixed Bid: only active Main IDs and active owner profiles can win.
-- Serialize finalization with Admin Main-ID lifecycle changes and fail closed on inconsistent payment replays.
-- Source-only. Do not apply to Production or TEST during development.

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
 -- Serialize winner eligibility against Admin Main-ID lifecycle changes.
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)
 );
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
 select b.* into v_bid
 from public.bids b
 join public.member_ids m
   on m.id=b.member_id and m.id_type='main' and m.status='active'
 join public.profiles p
   on p.id=m.owner_user_id and p.main_member_id=m.id and p.status='active'
 where b.auction_id=p_auction_id and b.status='accepted'
 order by b.bid_amount desc,b.created_at asc,b.id asc
 limit 1 for update of b;
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

revoke all on function public.admin_finalize_auction(uuid) from public,anon;
grant execute on function public.admin_finalize_auction(uuid) to authenticated;

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

revoke all on function public.member_pay_winning_item_payment(uuid,text) from public,anon;
grant execute on function public.member_pay_winning_item_payment(uuid,text) to authenticated;

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

revoke all on function public.member_pay_fixed_bid_winning_payment(uuid,text) from public,anon;
grant execute on function public.member_pay_fixed_bid_winning_payment(uuid,text) to authenticated;
