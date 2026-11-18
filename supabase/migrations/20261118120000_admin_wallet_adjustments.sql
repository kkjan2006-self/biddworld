-- Audited, idempotent Admin wallet adjustments through the immutable ledger.
-- Source-only; wallet ledger writes remain subject to existing database interlocks.

create table if not exists public.wallet_adjustments (
 id uuid primary key default gen_random_uuid(),
 wallet_account_id uuid not null references public.wallet_accounts(id),
 member_id uuid not null references public.member_ids(id),
 admin_user_id uuid not null references auth.users(id),
 wallet_type text not null check(wallet_type in ('bid','income')),
 direction text not null check(direction in ('credit','debit')),
 amount numeric(14,2) not null check(amount>0),
 reason text not null check(length(reason) between 5 and 500),
 idempotency_key text not null unique,
 created_at timestamptz not null default now()
);
alter table public.wallet_adjustments enable row level security;
revoke all on public.wallet_adjustments from public,anon,authenticated;

create or replace function public.admin_adjust_member_wallet(
 p_member_code text,p_wallet_type text,p_direction text,p_amount numeric,p_reason text,p_idempotency_key text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_member public.member_ids%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_adjustment public.wallet_adjustments%rowtype;
 v_key text:=btrim(coalesce(p_idempotency_key,'')); v_new_balance numeric(14,2);
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
  if v_adjustment.member_id is distinct from (select id from public.member_ids where upper(member_code)=upper(trim(p_member_code)))
   or v_adjustment.wallet_type is distinct from p_wallet_type
   or v_adjustment.direction is distinct from p_direction
   or v_adjustment.amount is distinct from p_amount then
   raise exception 'This adjustment key was already used for a different request' using errcode='23505';
  end if;
  return jsonb_build_object('success',true,'adjustment_id',v_adjustment.id,'replayed',true);
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
