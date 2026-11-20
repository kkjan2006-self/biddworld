-- Enforce Platform Settings in the database write path.
create or replace function private.enforce_feature_gate()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_key text; v_enabled boolean; v_wallet_type text;
begin
 if tg_table_name='member_ids' and new.id_type='duplicate' then
  v_key:='duplicate_ids_enabled';
  if new.status='active' then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'Duplicate IDs are disabled by administrator' using errcode='42501'; end if; end if;
 elsif tg_table_name='package_activations' then
  if tg_op='INSERT' then v_key:='package_activations_enabled'; elsif new.activation_status='active' and old.activation_status is distinct from new.activation_status then v_key:='package_activations_enabled'; end if;
 elsif tg_table_name='wallet_transactions' then
  select wallet_type into v_wallet_type from public.wallet_accounts where id=new.wallet_account_id;
  if new.transaction_type='package_activation_credit' then v_key:='bid_wallet_enabled'; elsif new.transaction_type='auction_bid' then if v_wallet_type='bid' then v_key:='bid_wallet_enabled'; elsif v_wallet_type='income' then v_key:='income_wallet_enabled'; end if; end if;
 elsif tg_table_name='bids' then
  v_key:='bidding_enabled'; select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'Bidding is disabled by administrator' using errcode='42501'; end if;
  if new.bid_wallet_debit>0 then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key='bid_wallet_enabled'; if not coalesce(v_enabled,false) then raise exception 'Bid Wallet is disabled' using errcode='42501'; end if; end if;
  if new.income_wallet_debit>0 then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key='income_wallet_enabled'; if not coalesce(v_enabled,false) then raise exception 'Income Wallet is disabled' using errcode='42501'; end if; end if; return new;
 elsif tg_table_name='referral_commissions' then
  if new.status='credited' then v_key:='referral_commissions_enabled'; if not exists(select 1 from public.package_activations a where a.id=new.package_activation_id and a.payment_status='approved' and a.activation_status='active') then raise exception 'Referral commission requires an approved active package activation' using errcode='23514'; end if; end if;
 elsif tg_table_name='withdrawal_requests' then v_key:='withdrawals_enabled';
 elsif tg_table_name='fixed_bid_campaigns' then if new.status in ('live','active','published') then v_key:='fixed_bid_enabled'; end if;
 elsif tg_table_name='winning_item_payments' then if new.status='paid' then v_key:='winning_payment_enabled'; end if;
 elsif tg_table_name='delivery_tracking' then v_key:='delivery_tracking_enabled';
 end if;
 if v_key is not null then select coalesce((setting_value #>> '{}')::boolean,false) into v_enabled from public.app_settings where setting_key=v_key; if not coalesce(v_enabled,false) then raise exception 'This action is disabled by the BiddWorld administrator (%)',v_key using errcode='42501'; end if; end if;
 return new;
end; $$;
drop trigger if exists enforce_duplicate_id_feature on public.member_ids;
create trigger enforce_duplicate_id_feature before insert or update of status,id_type on public.member_ids for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_package_activation_feature on public.package_activations;
create trigger enforce_package_activation_feature before insert or update of activation_status on public.package_activations for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_package_wallet_credit_feature on public.wallet_transactions;
create trigger enforce_package_wallet_credit_feature before insert on public.wallet_transactions for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_bid_wallet_and_bidding_features on public.bids;
create trigger enforce_bid_wallet_and_bidding_features before insert on public.bids for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_referral_commission_feature on public.referral_commissions;
create trigger enforce_referral_commission_feature before insert or update of status on public.referral_commissions for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_withdrawal_feature on public.withdrawal_requests;
create trigger enforce_withdrawal_feature before insert on public.withdrawal_requests for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_fixed_bid_feature on public.fixed_bid_campaigns;
create trigger enforce_fixed_bid_feature before insert or update of status on public.fixed_bid_campaigns for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_winning_payment_feature on public.winning_item_payments;
create trigger enforce_winning_payment_feature before insert or update of status on public.winning_item_payments for each row execute function private.enforce_feature_gate();
drop trigger if exists enforce_delivery_tracking_feature on public.delivery_tracking;
create trigger enforce_delivery_tracking_feature before insert or update on public.delivery_tracking for each row execute function private.enforce_feature_gate();

-- Only workflows that already have an implemented backend path may be enabled.
create or replace function public.admin_set_feature_setting(p_setting_key text,p_enabled boolean)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_uid uuid:=auth.uid(); v_enabled_keys text[]:=array['registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled','package_activations_enabled','bid_wallet_enabled','income_wallet_enabled','delivery_tracking_enabled'];
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_enabled is null then raise exception 'A true/false value is required'; end if;
 if p_setting_key is null or p_setting_key<>all(array['registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled','automatic_placement_enabled','package_activations_enabled','referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled','winner_selection_configured','winning_payment_enabled','delivery_tracking_enabled','notifications_enabled']) then raise exception 'Unsupported feature setting' using errcode='22023'; end if;
 if p_enabled and not (p_setting_key=any(v_enabled_keys)) then raise exception 'Cannot enable % yet: its complete backend workflow and verification are not implemented. It remains safely disabled.',p_setting_key using errcode='55000'; end if;
 insert into public.app_settings(setting_key,setting_value,updated_at) values(p_setting_key,to_jsonb(p_enabled),now()) on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
 insert into public.audit_logs(actor_user_id,action,entity_type,details) values(v_uid,'feature_setting_changed','app_settings',jsonb_build_object('setting_key',p_setting_key,'enabled',p_enabled));
 return jsonb_build_object('success',true,'setting_key',p_setting_key,'enabled',p_enabled);
end; $$;

-- Signup obeys registration_enabled; Sponsor relationships obey sponsor_referrals_enabled.
create or replace function private.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_member_id uuid; v_member_code text; v_sponsor_id uuid; v_sponsor_code text; v_default text; v_requested text; v_registration_enabled boolean; v_sponsor_enabled boolean;
begin
 select coalesce((setting_value #>> '{}')::boolean,false) into v_registration_enabled from public.app_settings where setting_key='registration_enabled';
 if not coalesce(v_registration_enabled,false) then raise exception 'New member registration is currently disabled' using errcode='55000'; end if;
 select coalesce((setting_value #>> '{}')::boolean,false) into v_sponsor_enabled from public.app_settings where setting_key='sponsor_referrals_enabled';
 insert into public.profiles(id,display_name,phone,status) values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),split_part(coalesce(new.email,''),'@',1)),nullif(new.raw_user_meta_data->>'phone',''),'active') on conflict(id) do update set display_name=excluded.display_name,phone=excluded.phone;
 if coalesce(v_sponsor_enabled,false) then
  v_requested:=nullif(trim(coalesce(new.raw_user_meta_data->>'sponsor_referral_id','')),'');
  if v_requested is not null then select id,member_code into v_sponsor_id,v_sponsor_code from public.member_ids where upper(member_code)=upper(v_requested) and id_type='main' and status='active'; if v_sponsor_id is null then raise exception 'Invalid Sponsor Referral ID'; end if;
  else select setting_value #>> '{}' into v_default from public.app_settings where setting_key='default_sponsor_member_id';
   if v_default is not null then v_sponsor_id:=v_default::uuid; select member_code into v_sponsor_code from public.member_ids where id=v_sponsor_id and id_type='main' and status='active'; if v_sponsor_code is null then raise exception 'Default administrator sponsor is not configured correctly'; end if;
   elsif exists(select 1 from public.member_ids where id_type='main' and status='active') then raise exception 'Default administrator sponsor has not been configured'; end if;
  end if;
 end if;
 v_member_code:='BW'||upper(substr(replace(pg_catalog.gen_random_uuid()::text,'-',''),1,10));
 insert into public.member_ids(owner_user_id,member_code,id_type,status) values(new.id,v_member_code,'main','active') on conflict do nothing returning id into v_member_id;
 if v_member_id is null then select id into v_member_id from public.member_ids where owner_user_id=new.id and id_type='main' limit 1; end if;
 if v_member_id is not null then update public.profiles set main_member_id=v_member_id where id=new.id; insert into public.wallet_accounts(member_id,wallet_type,balance) values(v_member_id,'bid',0),(v_member_id,'income',0) on conflict(member_id,wallet_type) do nothing; if v_sponsor_id is not null then insert into public.referrals(referred_member_id,referrer_member_id,source_member_id) values(v_member_id,v_sponsor_id,v_sponsor_id) on conflict(referred_member_id) do nothing; end if; end if;
 return new;
end; $$;
revoke all on function private.enforce_feature_gate() from public,anon,authenticated;
revoke all on function private.handle_new_auth_user() from public,anon,authenticated;