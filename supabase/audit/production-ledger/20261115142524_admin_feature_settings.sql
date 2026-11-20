-- Central, auditable feature switches for the BiddWorld control centre.
-- This migration is source-only until explicitly approved for Production rollout.
-- Conservative defaults keep unfinished money-moving and auction workflows disabled.

insert into public.app_settings(setting_key, setting_value, updated_at) values
 ('registration_enabled','true'::jsonb,now()),
 ('sponsor_referrals_enabled','true'::jsonb,now()),
 ('duplicate_ids_enabled','false'::jsonb,now()),
 ('automatic_placement_enabled','false'::jsonb,now()),
 ('package_activations_enabled','true'::jsonb,now()),
 ('referral_commissions_enabled','false'::jsonb,now()),
 ('bid_wallet_enabled','true'::jsonb,now()),
 ('income_wallet_enabled','true'::jsonb,now()),
 ('withdrawals_enabled','false'::jsonb,now()),
 ('bidding_enabled','false'::jsonb,now()),
 ('fixed_bid_enabled','false'::jsonb,now()),
 ('winner_selection_configured','false'::jsonb,now()),
 ('winning_payment_enabled','false'::jsonb,now()),
 ('delivery_tracking_enabled','false'::jsonb,now()),
 ('notifications_enabled','false'::jsonb,now())
on conflict(setting_key) do nothing;

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
     'registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled',
     'automatic_placement_enabled','package_activations_enabled',
     'referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled',
     'withdrawals_enabled','bidding_enabled','fixed_bid_enabled',
     'winner_selection_configured','winning_payment_enabled',
     'delivery_tracking_enabled','notifications_enabled'
   ]);
  return v_result;
end;
$function$;

create or replace function public.admin_set_feature_setting(
  p_setting_key text,
  p_enabled boolean
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null
     or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  if p_enabled is null then raise exception 'A true/false value is required'; end if;
  if p_setting_key is null or p_setting_key <> all(array[
    'registration_enabled','sponsor_referrals_enabled','duplicate_ids_enabled',
    'automatic_placement_enabled','package_activations_enabled',
    'referral_commissions_enabled','bid_wallet_enabled','income_wallet_enabled',
    'withdrawals_enabled','bidding_enabled','fixed_bid_enabled',
    'winner_selection_configured','winning_payment_enabled',
    'delivery_tracking_enabled','notifications_enabled'
  ]) then
    raise exception 'Unsupported feature setting';
  end if;

  insert into public.app_settings(setting_key,setting_value,updated_at)
  values(p_setting_key,to_jsonb(p_enabled),now())
  on conflict(setting_key) do update
    set setting_value=excluded.setting_value,updated_at=now();

  insert into public.audit_logs(actor_user_id,action,entity_type,details)
  values(v_uid,'feature_setting_changed','app_settings',
    jsonb_build_object('setting_key',p_setting_key,'enabled',p_enabled));

  return jsonb_build_object('success',true,'setting_key',p_setting_key,'enabled',p_enabled);
end;
$function$;

revoke all on function public.admin_get_feature_settings() from public,anon;
grant execute on function public.admin_get_feature_settings() to authenticated;
revoke all on function public.admin_set_feature_setting(text,boolean) from public,anon;
grant execute on function public.admin_set_feature_setting(text,boolean) to authenticated;
