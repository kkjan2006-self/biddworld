-- Ensure idempotent Matrix reversal replays identify the exact commission.

create or replace function public.admin_reverse_matrix_commission(
  p_commission_id uuid,p_reason text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_commission public.matrix_commissions%rowtype;
  v_wallet public.wallet_accounts%rowtype;
  v_credit public.wallet_transactions%rowtype;
  v_existing public.wallet_transactions%rowtype;
  v_credit_key text;
  v_reverse_key text;
  v_balance numeric(14,2);
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
    raise exception 'Provide a reversal reason between 5 and 500 characters' using errcode='22023';
  end if;
  select * into v_commission from public.matrix_commissions where id=p_commission_id for update;
  if not found then raise exception 'Matrix commission not found' using errcode='P0002'; end if;
  if v_commission.status='reversed' then
    v_credit_key:='matrix-commission:'||p_commission_id::text||':credit';
    v_reverse_key:='matrix-commission:'||p_commission_id::text||':reverse';
    select * into v_credit from public.wallet_transactions where idempotency_key=v_credit_key;
    if not found then
      if exists(select 1 from public.wallet_transactions where idempotency_key=v_reverse_key) then
        raise exception 'Matrix reversal exists without original credit; reconciliation required' using errcode='23514';
      end if;
      return jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',true);
    end if;
    select * into v_wallet from public.wallet_accounts
    where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
    if not found
      or v_credit.wallet_account_id is distinct from v_wallet.id
      or v_credit.member_id is distinct from v_commission.credited_main_member_id
      or v_credit.transaction_type is distinct from 'matrix_commission'
      or v_credit.direction is distinct from 'credit'
      or v_credit.amount is distinct from v_commission.amount
      or v_credit.reference_type is distinct from 'matrix_commission'
      or v_credit.reference_id is distinct from p_commission_id then
      raise exception 'Original Matrix credit is missing or inconsistent on reversal replay' using errcode='23514';
    end if;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_reverse_key;
    if not found or v_existing.wallet_account_id is distinct from v_wallet.id
      or v_existing.member_id is distinct from v_commission.credited_main_member_id
      or v_existing.transaction_type is distinct from 'matrix_commission_reversal'
      or v_existing.direction is distinct from 'debit'
      or v_existing.amount is distinct from v_commission.amount
      or v_existing.reference_type is distinct from 'matrix_commission'
      or v_existing.reference_id is distinct from p_commission_id then
      raise exception 'Matrix reversal ledger entry is missing or inconsistent' using errcode='23514';
    end if;
    return jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',true);
  end if;
  if v_commission.status='pending' then
    update public.matrix_commissions set status='reversed' where id=p_commission_id;
  else
    v_credit_key:='matrix-commission:'||p_commission_id::text||':credit';
    v_reverse_key:='matrix-commission:'||p_commission_id::text||':reverse';
    select * into v_wallet from public.wallet_accounts
    where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
    if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
    select * into v_credit from public.wallet_transactions where idempotency_key=v_credit_key;
    if not found or v_credit.wallet_account_id is distinct from v_wallet.id
      or v_credit.member_id is distinct from v_commission.credited_main_member_id
      or v_credit.transaction_type is distinct from 'matrix_commission'
      or v_credit.direction is distinct from 'credit'
      or v_credit.amount is distinct from v_commission.amount
      or v_credit.reference_type is distinct from 'matrix_commission'
      or v_credit.reference_id is distinct from p_commission_id then
      raise exception 'Original Matrix commission credit is missing or inconsistent' using errcode='23514';
    end if;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_reverse_key;
    if found then
      if v_existing.wallet_account_id is distinct from v_wallet.id
        or v_existing.member_id is distinct from v_commission.credited_main_member_id
        or v_existing.transaction_type is distinct from 'matrix_commission_reversal'
        or v_existing.direction is distinct from 'debit'
        or v_existing.amount is distinct from v_commission.amount
        or v_existing.reference_type is distinct from 'matrix_commission'
        or v_existing.reference_id is distinct from p_commission_id then
        raise exception 'Matrix reversal idempotency key conflicts with another transaction' using errcode='23505';
      end if;
    else
      if v_wallet.balance<v_commission.amount then
        raise exception 'Income Wallet balance is insufficient for the full reversal' using errcode='23514';
      end if;
      v_balance:=v_wallet.balance-v_commission.amount;
      update public.wallet_accounts set balance=v_balance,updated_at=now() where id=v_wallet.id;
      insert into public.wallet_transactions(
        wallet_account_id,member_id,transaction_type,direction,amount,balance_after,
        reference_type,reference_id,idempotency_key,description
      ) values(
        v_wallet.id,v_commission.credited_main_member_id,'matrix_commission_reversal','debit',
        v_commission.amount,v_balance,'matrix_commission',p_commission_id,v_reverse_key,
        'Matrix commission reversal: '||trim(p_reason)
      );
    end if;
    update public.matrix_commissions set status='reversed' where id=p_commission_id;
  end if;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'matrix_commission.reversed','matrix_commissions',p_commission_id,
    jsonb_build_object('reason',trim(p_reason),'amount',v_commission.amount,'previous_status',v_commission.status));
  return jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',false);
end;
$function$;
