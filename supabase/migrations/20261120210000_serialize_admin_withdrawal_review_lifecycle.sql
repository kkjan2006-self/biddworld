-- Serialize Admin withdrawal review with member financial eligibility and Main-ID lifecycle changes.
-- The request row is locked first; the shared per-Main-ID advisory lock is acquired
-- before profile/Main-ID validation or any wallet reservation/release/confirmation.
-- Admin withdrawal review with Income Wallet reservation and compensating release.
-- Source-only; financial activity remains subject to the existing database interlock.

create or replace function public.admin_review_withdrawal_request(
 p_request_id uuid,p_action text,p_reason text default null
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_request public.withdrawal_requests%rowtype;
 v_member public.member_ids%rowtype; v_wallet public.wallet_accounts%rowtype;
 v_reserve_tx public.wallet_transactions%rowtype; v_release_tx public.wallet_transactions%rowtype;
 v_key text; v_new_balance numeric(14,2); v_enabled boolean:=false;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_action is null or p_action not in ('approve','reject','mark_paid') then
  raise exception 'Choose approve, reject or mark_paid' using errcode='22023';
 end if;
 if p_action='reject' and length(trim(coalesce(p_reason,'')))<5 then
  raise exception 'A rejection reason of at least 5 characters is required' using errcode='22023';
 end if;
 if p_reason is not null and length(p_reason)>500 then raise exception 'Review note is too long' using errcode='22023'; end if;
 select * into v_request from public.withdrawal_requests where id=p_request_id for update;
 if not found then raise exception 'Withdrawal request not found' using errcode='P0002'; end if;

 -- Serialize approval/release/payout confirmation with Main-ID suspension and member debits.
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.main_member_lifecycle:'||v_request.member_id::text,0)
 );
 if p_action='approve' then
  if v_request.status<>'pending' then raise exception 'Only pending requests can be approved' using errcode='55000'; end if;
  select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
  from public.app_settings where setting_key='withdrawals_enabled';
  if not coalesce(v_enabled,false) then raise exception 'Withdrawals are currently disabled' using errcode='55000'; end if;
  select m.* into v_member
  from public.member_ids m
  join public.profiles p
    on p.id=m.owner_user_id and p.main_member_id=m.id
  where m.id=v_request.member_id
    and m.id_type='main'
    and m.status='active'
    and p.status='active'
  for share of m, p;
  if not found then
   raise exception 'Withdrawal must belong to an active member profile and Main ID' using errcode='55000';
  end if;
  select * into v_wallet from public.wallet_accounts
  where member_id=v_request.member_id and wallet_type='income' for update;
  if not found or v_wallet.balance<v_request.amount then
   raise exception 'Income Wallet balance is insufficient to reserve this withdrawal' using errcode='23514';
  end if;
  v_new_balance:=v_wallet.balance-v_request.amount;
  update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
  v_key:='withdrawal:'||v_request.id::text||':reserve';
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_wallet.id,v_request.member_id,'withdrawal_reserve','debit',v_request.amount,v_new_balance,
   'withdrawal_request',v_request.id,v_key,'Income Wallet amount reserved for approved withdrawal');
  update public.withdrawal_requests set status='approved',reviewed_at=now(),reviewed_by=v_uid,rejection_reason=null
  where id=v_request.id;
 elsif p_action='reject' then
  if v_request.status not in ('pending','approved') then raise exception 'Only pending or approved requests can be rejected' using errcode='55000'; end if;
  if v_request.status='approved' then
   select * into v_wallet from public.wallet_accounts
   where member_id=v_request.member_id and wallet_type='income' for update;
   if not found then raise exception 'Income Wallet is unavailable for reservation release' using errcode='55000'; end if;
   select * into v_reserve_tx from public.wallet_transactions
   where idempotency_key='withdrawal:'||v_request.id::text||':reserve';
   if not found
     or v_reserve_tx.wallet_account_id is distinct from v_wallet.id
     or v_reserve_tx.member_id is distinct from v_request.member_id
     or v_reserve_tx.transaction_type is distinct from 'withdrawal_reserve'
     or v_reserve_tx.direction is distinct from 'debit'
     or v_reserve_tx.amount is distinct from v_request.amount
     or v_reserve_tx.reference_type is distinct from 'withdrawal_request'
     or v_reserve_tx.reference_id is distinct from v_request.id then
    raise exception 'Approved withdrawal reservation ledger entry is missing or inconsistent; rejection was not applied' using errcode='23514';
   end if;
   v_key:='withdrawal:'||v_request.id::text||':release';
   select * into v_release_tx from public.wallet_transactions where idempotency_key=v_key;
   if found then
    if v_release_tx.wallet_account_id is distinct from v_wallet.id
      or v_release_tx.member_id is distinct from v_request.member_id
      or v_release_tx.transaction_type is distinct from 'withdrawal_release'
      or v_release_tx.direction is distinct from 'credit'
      or v_release_tx.amount is distinct from v_request.amount
      or v_release_tx.reference_type is distinct from 'withdrawal_request'
      or v_release_tx.reference_id is distinct from v_request.id then
     raise exception 'Withdrawal release idempotency key conflicts with a different ledger transaction' using errcode='23505';
    end if;
   else
    v_new_balance:=v_wallet.balance+v_request.amount;
    update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
    insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
    values(v_wallet.id,v_request.member_id,'withdrawal_release','credit',v_request.amount,v_new_balance,
     'withdrawal_request',v_request.id,v_key,'Income Wallet reservation released after withdrawal rejection');
   end if;
  end if;
  update public.withdrawal_requests set status='rejected',reviewed_at=now(),reviewed_by=v_uid,rejection_reason=trim(p_reason)
  where id=v_request.id;
 else
  if v_request.status<>'approved' then raise exception 'Only an approved withdrawal can be marked paid' using errcode='55000'; end if;
  select * into v_wallet from public.wallet_accounts
  where member_id=v_request.member_id and wallet_type='income' for update;
  if not found then raise exception 'Income Wallet is unavailable for payout confirmation' using errcode='55000'; end if;
  select * into v_reserve_tx from public.wallet_transactions
  where idempotency_key='withdrawal:'||v_request.id::text||':reserve';
  if not found
    or v_reserve_tx.wallet_account_id is distinct from v_wallet.id
    or v_reserve_tx.member_id is distinct from v_request.member_id
    or v_reserve_tx.transaction_type is distinct from 'withdrawal_reserve'
    or v_reserve_tx.direction is distinct from 'debit'
    or v_reserve_tx.amount is distinct from v_request.amount
    or v_reserve_tx.reference_type is distinct from 'withdrawal_request'
    or v_reserve_tx.reference_id is distinct from v_request.id then
   raise exception 'Approved withdrawal reservation ledger entry is missing or inconsistent; payout was not confirmed' using errcode='23514';
  end if;
  update public.withdrawal_requests set status='paid',reviewed_at=now(),reviewed_by=v_uid
  where id=v_request.id;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'withdrawal.'||p_action,'withdrawal_requests',v_request.id,
  jsonb_build_object('amount',v_request.amount,'previous_status',v_request.status,
   'new_status',case when p_action='approve' then 'approved' when p_action='reject' then 'rejected' else 'paid' end,
   'reason',nullif(trim(coalesce(p_reason,'')),'')));
 return jsonb_build_object('success',true,'request_id',v_request.id,
  'status',case when p_action='approve' then 'approved' when p_action='reject' then 'rejected' else 'paid' end);
end;
$function$;
revoke all on function public.admin_review_withdrawal_request(uuid,text,text) from public,anon;
grant execute on function public.admin_review_withdrawal_request(uuid,text,text) to authenticated;
