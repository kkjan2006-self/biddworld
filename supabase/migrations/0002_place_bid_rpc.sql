-- Disabled by default. SECURITY INVOKER preserves RLS; row lock serializes competing bids.
create or replace function public.place_bid(p_auction_id uuid) returns jsonb
language plpgsql security invoker set search_path=public as $$
declare uid uuid:=auth.uid(); a public.auctions%rowtype; wb public.wallet_accounts%rowtype; wi public.wallet_accounts%rowtype;
amount numeric(14,2); bd numeric(14,2); id numeric(14,2); enabled boolean;
begin
if uid is null then raise exception 'Authentication required';end if;
select coalesce((setting_value #>> '{}')::boolean,false) into enabled from public.app_settings where setting_key='bidding_enabled';
if not coalesce(enabled,false) then raise exception 'Bidding is disabled by administrator';end if;
select * into a from public.auctions where id=p_auction_id for update;
if not found or a.status<>'active' or now()<a.starts_at or now()>=a.ends_at then raise exception 'Auction is not open';end if;
amount:=a.current_price+a.minimum_increment;
select * into wb from public.wallet_accounts where user_id=uid and wallet_type='bid' for update;
select * into wi from public.wallet_accounts where user_id=uid and wallet_type='income' for update;
if wb.id is null or wi.id is null then raise exception 'Wallets unavailable';end if;
bd:=least(wb.balance,amount);id:=amount-bd;if wi.balance<id then raise exception 'Insufficient combined wallet balance';end if;
update public.wallet_accounts set balance=balance-bd,updated_at=now() where id=wb.id;
update public.wallet_accounts set balance=balance-id,updated_at=now() where id=wi.id;
if bd>0 then insert into public.wallet_transactions(user_id,wallet_account_id,transaction_type,amount,balance_after,idempotency_key,reference_type,reference_id) values(uid,wb.id,'bid_debit',bd,wb.balance-bd,gen_random_uuid()::text,'auction',p_auction_id);end if;
if id>0 then insert into public.wallet_transactions(user_id,wallet_account_id,transaction_type,amount,balance_after,idempotency_key,reference_type,reference_id) values(uid,wi.id,'bid_debit',id,wi.balance-id,gen_random_uuid()::text,'auction',p_auction_id);end if;
insert into public.bids(auction_id,user_id,amount) values(p_auction_id,uid,amount);
update public.auctions set current_price=amount where id=p_auction_id;
return jsonb_build_object('success',true,'bid_amount',amount);
end $$;
revoke all on function public.place_bid(uuid) from public,anon;
grant execute on function public.place_bid(uuid) to authenticated;
