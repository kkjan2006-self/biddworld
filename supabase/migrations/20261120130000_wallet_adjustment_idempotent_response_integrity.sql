-- Preserve the complete original result for idempotent Admin wallet adjustment replays.
-- Source-only migration: do not apply to Production or TEST during development.
create or replace function public.admin_adjust_member_wallet(
 p_member_code text,p_wallet_type text,p_direction text,p_amount numeric,p_reason text,p_idempotency_key text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_member public.member_ids%rowtype;
 v_wallet public.wallet_accounts%rowtype;
 v_adjustment public.wallet_adjustments%rowtype;
 v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_new_balance numeric(14,2);
 v_member_code text;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid adjustment request key is required' using errcode='22023';
 end if;
 if p_wallet_type is null or p_wallet_type not in ('bid','income')
   or p_direction is null or p_direction not in ('credit','debit') then
  raise exception 'Choose a valid wallet and adjustment direction' using errcode='22023';
 end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>10000000 then
  raise exception 'Enter a positive amount with no more than two decimal places' using errcode='22023';
 end if;
 if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Provide an adjustment reason between 5 and 500 characters' using errcode='22023';
 end if;

 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select * into v_adjustment from public.wallet_adjustments where idempotency_key=v_key;
 if found then
  if v_adjustment.member_id is distinct from (
      select id from public.member_ids where upper(member_code)=upper(trim(p_member_code))
     )
   or v_adjustment.wallet_type is distinct from p_wallet_type
   or v_adjustment.direction is distinct from p_direction
   or v_adjustment.amount is distinct from p_amount
   or v_adjustment.reason is distinct from trim(p_reason) then
   raise exception 'This adjustment key was already used for a different request' using errcode='23505';
  end if;

  select wt.balance_after into v_new_balance
  from public.wallet_transactions wt
  where wt.idempotency_key=v_key
    and wt.reference_type='wallet_adjustment'
    and wt.reference_id=v_adjustment.id
  order by wt.created_at desc,wt.id desc
  limit 1;
  if not found or v_new_balance is null then
   raise exception 'The original wallet adjustment result is unavailable; contact an administrator before retrying' using errcode='55000';
  end if;

  select member_code into v_member_code
  from public.member_ids where id=v_adjustment.member_id;
  if not found then
   raise exception 'The original wallet adjustment member is unavailable' using errcode='55000';
  end if;

  return jsonb_build_object(
   'success',true,
   'adjustment_id',v_adjustment.id,
   'member_code',v_member_code,
   'wallet_type',v_adjustment.wallet_type,
   'direction',v_adjustment.direction,
   'amount',v_adjustment.amount,
   'balance_after',v_new_balance,
   'replayed',true
  );
 end if;

 select * into v_member from public.member_ids
 where upper(member_code)=upper(trim(p_member_code)) and id_type='main'
 for share;
 if not found then raise exception 'Main Member ID not found' using errcode='P0002'; end if;

 select * into v_wallet from public.wallet_accounts
 where member_id=v_member.id and wallet_type=p_wallet_type for update;
 if not found then raise exception 'Selected wallet account is unavailable' using errcode='55000'; end if;
 if p_direction='debit' and v_wallet.balance<p_amount then
  raise exception 'Insufficient wallet balance; no adjustment was made' using errcode='23514';
 end if;

 v_new_balance:=case when p_direction='credit' then v_wallet.balance+p_amount else v_wallet.balance-p_amount end;
 insert into public.wallet_adjustments(wallet_account_id,member_id,admin_user_id,wallet_type,direction,amount,reason,idempotency_key)
 values(v_wallet.id,v_member.id,v_uid,p_wallet_type,p_direction,p_amount,trim(p_reason),v_key)
 returning * into v_adjustment;
 update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
 insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
 values(v_wallet.id,v_member.id,'admin_adjustment',p_direction,p_amount,v_new_balance,
  'wallet_adjustment',v_adjustment.id,v_key,'Admin adjustment: '||trim(p_reason));
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'wallet.adjusted','wallet_accounts',v_wallet.id,
  jsonb_build_object('adjustment_id',v_adjustment.id,'member_code',v_member.member_code,
   'wallet_type',p_wallet_type,'direction',p_direction,'amount',p_amount,'reason',trim(p_reason),
   'balance_after',v_new_balance));
 return jsonb_build_object('success',true,'adjustment_id',v_adjustment.id,
  'member_code',v_member.member_code,'wallet_type',p_wallet_type,'direction',p_direction,
  'amount',p_amount,'balance_after',v_new_balance,'replayed',false);
end;
$function$;
revoke all on function public.admin_adjust_member_wallet(text,text,text,numeric,text,text) from public,anon;
grant execute on function public.admin_adjust_member_wallet(text,text,text,numeric,text,text) to authenticated;
