-- Expose the existing email-verification policy through the Admin feature settings RPC.
-- The default remains OFF; this only makes the stored policy consistently readable and configurable.
create or replace function public.admin_get_feature_settings()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null
     or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  select coalesce(jsonb_object_agg(setting_key,setting_value),'{}'::jsonb)
    into v_result
    from public.app_settings
   where setting_key = any(array[
     'registration_enabled','email_verification_required','sponsor_referrals_enabled',
     'duplicate_ids_enabled','automatic_placement_enabled','package_activations_enabled',
     'referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled',
     'withdrawals_enabled','bidding_enabled','fixed_bid_enabled',
     'winner_selection_configured','winning_payment_enabled',
     'delivery_tracking_enabled','notifications_enabled'
   ]);
  return v_result;
end;
$function$;

create or replace function public.admin_set_feature_setting(p_setting_key text,p_enabled boolean)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_enabled_keys text[]:=array[
  'registration_enabled','email_verification_required','sponsor_referrals_enabled',
  'duplicate_ids_enabled','package_activations_enabled','bid_wallet_enabled','income_wallet_enabled',
  'delivery_tracking_enabled'
 ];
 v_financial_approved boolean:=false;
 v_financial_keys text[]:=array[
  'duplicate_ids_enabled','package_activations_enabled','referral_commissions_enabled',
  'bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled',
  'bidding_enabled','fixed_bid_enabled','winning_payment_enabled'
 ];
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_enabled is null then raise exception 'A true/false value is required'; end if;
 if p_setting_key is null or p_setting_key<>all(array[
  'registration_enabled','email_verification_required','sponsor_referrals_enabled',
  'duplicate_ids_enabled','automatic_placement_enabled','package_activations_enabled',
  'referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled',
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
   raise exception 'This feature is currently locked by a server-side condition (%).',p_setting_key using errcode='55000';
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

revoke all on function public.admin_get_feature_settings() from public,anon;
grant execute on function public.admin_get_feature_settings() to authenticated;
revoke all on function public.admin_set_feature_setting(text,boolean) from public,anon;
grant execute on function public.admin_set_feature_setting(text,boolean) to authenticated;
