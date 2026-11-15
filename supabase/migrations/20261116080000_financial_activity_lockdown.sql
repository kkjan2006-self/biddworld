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
  elsif tg_table_name='referral_commissions' and tg_op in ('INSERT','UPDATE')
    and new.status='credited' then
   raise exception 'Referral commission crediting is locked until the owner approves the financial and compliance model'
     using errcode='55000';
  elsif tg_table_name='bids' and tg_op='INSERT' then
   raise exception 'Auction bidding is locked until the owner approves the financial and compliance model'
     using errcode='55000';
  elsif tg_table_name='fixed_bids' and tg_op='INSERT' then
   raise exception 'Fixed Bid entries are locked until the owner approves the financial and compliance model'
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


-- Keep Admin feature toggles fail-closed until the same trusted owner approval
-- has been recorded. Disabling a feature is always allowed; enabling financial
-- activity is not available through the ordinary Admin UI/RPC.
create or replace function public.admin_set_feature_setting(p_setting_key text,p_enabled boolean)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_enabled_keys text[]:=array['registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled','package_activations_enabled','bid_wallet_enabled','income_wallet_enabled','delivery_tracking_enabled'];
 v_financial_approved boolean:=false;
 v_financial_keys text[]:=array['duplicate_ids_enabled','package_activations_enabled','referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled','winning_payment_enabled'];
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_enabled is null then raise exception 'A true/false value is required'; end if;
 if p_setting_key is null or p_setting_key<>all(array[
  'registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled','automatic_placement_enabled',
  'package_activations_enabled','referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled',
  'withdrawals_enabled','bidding_enabled','fixed_bid_enabled','winner_selection_configured',
  'winning_payment_enabled','delivery_tracking_enabled','notifications_enabled'
 ]) then
  raise exception 'Unsupported feature setting' using errcode='22023';
 end if;
 if p_enabled and not (p_setting_key=any(v_enabled_keys)) then
  raise exception 'Cannot enable % yet: its complete backend workflow and verification are not implemented. It remains safely disabled.',p_setting_key using errcode='55000';
 end if;
 if p_enabled and p_setting_key=any(v_financial_keys) then
  select coalesce((setting_value#>>'{}')::boolean,false) into v_financial_approved
  from public.app_settings where setting_key='financial_model_approved';
  if not coalesce(v_financial_approved,false) then
   raise exception 'Financial feature % is locked until the owner approves the financial and compliance model.',p_setting_key using errcode='55000';
  end if;
 end if;
 insert into public.app_settings(setting_key,setting_value,updated_at)
 values(p_setting_key,to_jsonb(p_enabled),now())
 on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
 insert into public.audit_logs(actor_user_id,action,entity_type,details)
 values(v_uid,'feature_setting_changed','app_settings',jsonb_build_object('setting_key',p_setting_key,'enabled',p_enabled));
 return jsonb_build_object('success',true,'setting_key',p_setting_key,'enabled',p_enabled);
end;
$function$;

revoke all on function public.admin_set_feature_setting(text,boolean) from public,anon;
grant execute on function public.admin_set_feature_setting(text,boolean) to authenticated;

-- The interlock is enforced by the database even if a client bypasses the UI.
drop trigger if exists require_financial_model_approval_on_referral_commission on public.referral_commissions;
create trigger require_financial_model_approval_on_referral_commission
before insert or update of status on public.referral_commissions
for each row execute function private.require_financial_model_approval();

drop trigger if exists require_financial_model_approval_on_bid on public.bids;
create trigger require_financial_model_approval_on_bid
before insert on public.bids
for each row execute function private.require_financial_model_approval();

drop trigger if exists require_financial_model_approval_on_fixed_bid on public.fixed_bids;
create trigger require_financial_model_approval_on_fixed_bid
before insert on public.fixed_bids
for each row execute function private.require_financial_model_approval();
