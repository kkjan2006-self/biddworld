-- Extend the owner-approval interlock to every financial ledger write,
-- withdrawal request, and winner-payment settlement.
-- Source-only until explicitly reviewed and applied by the project owner.

create or replace function private.require_financial_model_approval()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_approved boolean:=false;
begin
 select coalesce((setting_value#>>'{}')::boolean,false)
 into v_approved
 from public.app_settings
 where setting_key='financial_model_approved';

 if coalesce(v_approved,false) is not true then
  if tg_table_name='wallet_transactions' and tg_op='INSERT' then
   raise exception 'Wallet ledger writes are locked until the owner approves the financial and compliance model'
     using errcode='55000';
  elsif tg_table_name='package_activations' and tg_op='UPDATE'
    and (new.payment_status='approved' or new.activation_status='active') then
   raise exception 'Package activation approval is locked until the owner approves the financial and compliance model'
     using errcode='55000';
  elsif tg_table_name='withdrawal_requests' and (
    tg_op='INSERT' or (tg_op='UPDATE' and new.status is distinct from old.status
      and new.status in ('approved','processing','paid'))
  ) then
   raise exception 'Withdrawal processing is locked until the owner approves the financial and compliance model'
     using errcode='55000';
  elsif tg_table_name='winning_item_payments' and tg_op='UPDATE'
    and new.status='paid' and new.status is distinct from old.status then
   raise exception 'Winner payment settlement is locked until the owner approves the financial and compliance model'
     using errcode='55000';
  end if;
 end if;
 return new;
end;
$function$;

revoke all on function private.require_financial_model_approval()
 from public,anon,authenticated;

drop trigger if exists require_financial_model_approval_on_wallet_credit
 on public.wallet_transactions;
create trigger require_financial_model_approval_on_wallet_credit
before insert on public.wallet_transactions
for each row execute function private.require_financial_model_approval();

drop trigger if exists require_financial_model_approval_on_activation
 on public.package_activations;
create trigger require_financial_model_approval_on_activation
before update of payment_status,activation_status on public.package_activations
for each row execute function private.require_financial_model_approval();

drop trigger if exists require_financial_model_approval_on_withdrawal
 on public.withdrawal_requests;
create trigger require_financial_model_approval_on_withdrawal
before insert or update of status on public.withdrawal_requests
for each row execute function private.require_financial_model_approval();

drop trigger if exists require_financial_model_approval_on_winner_payment
 on public.winning_item_payments;
create trigger require_financial_model_approval_on_winner_payment
before update of status on public.winning_item_payments
for each row execute function private.require_financial_model_approval();
