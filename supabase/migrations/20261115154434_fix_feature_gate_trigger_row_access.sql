create or replace function private.enforce_feature_gate()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_key text; v_enabled boolean; v_wallet_type text; v_row jsonb:=to_jsonb(new); v_old jsonb:=to_jsonb(old);
begin
 if tg_table_name='member_ids' and v_row->>'id_type'='duplicate' then
  v_key:='duplicate_ids_enabled';
  if v_row->>'status'='active' then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled by administrator' using errcode='42501'; end if; end if;
 elsif tg_table_name='package_activations' then
  if tg_op='INSERT' then v_key:='package_activations_enabled'; elsif v_row->>'activation_status'='active' and v_old->>'activation_status' is distinct from v_row->>'activation_status' then v_key:='package_activations_enabled'; end if;
 elsif tg_table_name='wallet_transactions' then
  select wallet_type into v_wallet_type from public.wallet_accounts where id=(v_row->>'wallet_account_id')::uuid;
  if v_row->>'transaction_type'='package_activation_credit' then v_key:='bid_wallet_enabled'; elsif v_row->>'transaction_type'='auction_bid' then if v_wallet_type='bid' then v_key:='bid_wallet_enabled'; elsif v_wallet_type='income' then v_key:='income_wallet_enabled'; end if; end if;
 elsif tg_table_name='bids' then
  v_key:='bidding_enabled'; select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'Bidding is disabled by administrator' using errcode='42501'; end if;
  if coalesce((v_row->>'bid_wallet_debit')::numeric,0)>0 then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key='bid_wallet_enabled'; if not coalesce(v_enabled,false) then raise exception 'Bid Wallet is disabled' using errcode='42501'; end if; end if;
  if coalesce((v_row->>'income_wallet_debit')::numeric,0)>0 then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key='income_wallet_enabled'; if not coalesce(v_enabled,false) then raise exception 'Income Wallet is disabled' using errcode='42501'; end if; end if; return new;
 elsif tg_table_name='referral_commissions' then
  if v_row->>'status'='credited' then v_key:='referral_commissions_enabled'; if not exists(select 1 from public.package_activations a where a.id=(v_row->>'package_activation_id')::uuid and a.payment_status='approved' and a.activation_status='active') then raise exception 'Referral commission requires an approved active package activation' using errcode='23514'; end if; end if;
 elsif tg_table_name='withdrawal_requests' then v_key:='withdrawals_enabled';
 elsif tg_table_name='fixed_bid_campaigns' then if v_row->>'status' in ('live','active','published') then v_key:='fixed_bid_enabled'; end if;
 elsif tg_table_name='winning_item_payments' then if v_row->>'status'='paid' then v_key:='winning_payment_enabled'; end if;
 elsif tg_table_name='delivery_tracking' then v_key:='delivery_tracking_enabled';
 end if;
 if v_key is not null then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'This action is disabled by the BiddWorld administrator (%)',v_key using errcode='42501'; end if; end if;
 return new;
end; $$;