-- Financial safety interlock: package approval must not activate members or
-- create Bid Wallet credits until the owner has approved the economics and
-- legal/compliance model through a trusted operator process.
-- This key is intentionally NOT exposed through the Admin feature-switch RPC.

insert into public.app_settings(setting_key,setting_value,updated_at)
values('financial_model_approved','false'::jsonb,now())
on conflict(setting_key) do nothing;

create or replace function private.require_financial_model_approval()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_approved boolean := false;
begin
  select coalesce((setting_value #>> '{}')::boolean,false)
    into v_approved
    from public.app_settings
   where setting_key='financial_model_approved';

  if not coalesce(v_approved,false) then
    if tg_table_name='wallet_transactions'
       and new.transaction_type='package_activation_credit' then
      raise exception 'Package activation credits are locked until the owner approves the financial and compliance model'
        using errcode='55000';
    elsif tg_table_name='package_activations'
       and (new.payment_status='approved' or new.activation_status='active') then
      raise exception 'Package activation approval is locked until the owner approves the financial and compliance model'
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
before update of payment_status,activation_status
on public.package_activations
for each row execute function private.require_financial_model_approval();

comment on function private.require_financial_model_approval() is
  'Blocks package activation approvals and Bid Wallet credits until a trusted operator records explicit owner approval of the financial and compliance model.';
