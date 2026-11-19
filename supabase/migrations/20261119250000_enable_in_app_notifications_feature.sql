-- Enable the implemented in-app notification channel through Platform Settings.
-- Email/SMS template drafts remain drafts; this switch controls in-app delivery only.

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
  'delivery_tracking_enabled','notifications_enabled'
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

create or replace function public.admin_send_member_notification(
 p_user_id uuid,p_title text,p_message text,p_category text,p_idempotency_key text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_id uuid;
 v_notifications_enabled boolean:=false;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_notifications_enabled
 from public.app_settings where setting_key='notifications_enabled';
 if not coalesce(v_notifications_enabled,false) then
  raise exception 'In-app notifications are disabled in Platform Settings' using errcode='55000';
 end if;
 if p_user_id is null or not exists(select 1 from auth.users where id=p_user_id) then
  raise exception 'Select an existing member account' using errcode='22023';
 end if;
 if length(trim(coalesce(p_title,'')))<3 or length(p_title)>120 then
  raise exception 'Notification title must contain 3 to 120 characters' using errcode='22023';
 end if;
 if length(trim(coalesce(p_message,'')))<5 or length(p_message)>2000 then
  raise exception 'Notification message must contain 5 to 2,000 characters' using errcode='22023';
 end if;
 if p_category is null or p_category not in ('general','account','support','security') then
  raise exception 'Choose a supported notification category' using errcode='22023';
 end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid notification request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text||':'||v_key,0));
 select id into v_id from public.member_notifications
 where user_id=p_user_id and idempotency_key=v_key
  and title=trim(p_title) and message=trim(p_message) and category=p_category;
 if v_id is not null then
  return jsonb_build_object('success',true,'notification_id',v_id,'replayed',true);
 end if;
 if exists(select 1 from public.member_notifications where user_id=p_user_id and idempotency_key=v_key) then
  raise exception 'This notification request key was already used for different content' using errcode='23505';
 end if;
 insert into public.member_notifications(user_id,title,message,category,idempotency_key)
 values(p_user_id,trim(p_title),trim(p_message),p_category,v_key)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'notification.sent','member_notifications',v_id,
  jsonb_build_object('target_user_id',p_user_id,'category',p_category,'title',trim(p_title)));
 return jsonb_build_object('success',true,'notification_id',v_id,'replayed',false);
end;
$function$;
revoke all on function public.admin_send_member_notification(uuid,text,text,text,text) from public,anon;
grant execute on function public.admin_send_member_notification(uuid,text,text,text,text) to authenticated;

create or replace function public.notify_member_on_support_ticket_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
 v_message text;
 v_notifications_enabled boolean:=false;
begin
 if coalesce((select auth.jwt()->'app_metadata'->>'role'), '') <> 'admin' then
  return new;
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_notifications_enabled
 from public.app_settings where setting_key='notifications_enabled';
 if not coalesce(v_notifications_enabled,false) then
  return new;
 end if;
 if old.status is distinct from new.status
    or old.admin_response is distinct from new.admin_response then
  v_message:=left(concat_ws(
   E'\n\n',
   'Your support request status is now: '||replace(new.status,'_',' '),
   case when nullif(btrim(new.admin_response),'') is not null
    then 'Support response: '||new.admin_response else null end
  ),2000);
  insert into public.member_notifications(user_id,title,message,category)
  values(new.user_id,'Support request updated',v_message,'support');
 end if;
 return new;
end;
$function$;
revoke all on function public.notify_member_on_support_ticket_update() from public,anon,authenticated;
