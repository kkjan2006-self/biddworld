-- Separate Fixed Bid winner payment from Auction item awards.
-- Historical Auction payment rows are retained; pending Auction rows cannot be paid.
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
  if v_tx.reference_type='winning_item_payment'
    and v_tx.reference_id=p_payment_id
    and v_tx.member_id=v_main
    and v_tx.transaction_type='winning_item_payment'
    and v_tx.direction='debit'
    and v_tx.amount=v_payment.amount
    and exists(select 1 from public.wallet_accounts w
      where w.id=v_tx.wallet_account_id and w.member_id=v_main and w.wallet_type='income') then
   return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','replayed',true);
  end if;
  raise exception 'This payment request key conflicts with a different ledger transaction' using errcode='23505';
 end if;
 if v_payment.fixed_bid_campaign_id is null then
  raise exception 'Auction winners receive the item only; no separate winner payment is required' using errcode='55000';
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
