-- Configurable minimum withdrawal amount enforced by the database.
-- Source-only; no setting is enabled or changed in Production.

insert into public.app_settings(setting_key,setting_value,updated_at)
values('minimum_withdrawal_amount','0'::jsonb,now())
on conflict(setting_key) do nothing;

create or replace function public.admin_get_minimum_withdrawal_amount()
returns numeric
language plpgsql stable security definer set search_path=''
as $function$
declare v_amount numeric;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select coalesce((setting_value#>>'{}')::numeric,0) into v_amount
 from public.app_settings where setting_key='minimum_withdrawal_amount';
 return coalesce(v_amount,0);
end;
$function$;

create or replace function public.admin_set_minimum_withdrawal_amount(p_amount numeric)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_amount is null or p_amount<0 or p_amount>10000000 or p_amount<>round(p_amount,2) then
  raise exception 'Minimum withdrawal amount must be zero or a valid amount with up to two decimals' using errcode='22023';
 end if;
 insert into public.app_settings(setting_key,setting_value,updated_at)
 values('minimum_withdrawal_amount',to_jsonb(p_amount),now())
 on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
 insert into public.audit_logs(actor_user_id,action,entity_type,details)
 values(v_uid,'withdrawal.minimum_changed','app_settings',jsonb_build_object('minimum_amount',p_amount));
 return jsonb_build_object('success',true,'minimum_withdrawal_amount',p_amount);
end;
$function$;

create or replace function public.member_create_withdrawal_request(
 p_amount numeric,p_payout_details jsonb
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_member uuid; v_balance numeric; v_id uuid; v_minimum numeric:=0;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then
  raise exception 'Enter a valid withdrawal amount with no more than two decimal places' using errcode='22023';
 end if;
 if p_payout_details is null or jsonb_typeof(p_payout_details)<>'object' or length(p_payout_details::text)>2000 then
  raise exception 'Valid payout details are required' using errcode='22023';
 end if;
 if coalesce((select (setting_value#>>'{}')::boolean from public.app_settings where setting_key='withdrawals_enabled'),false) is not true then
  raise exception 'Withdrawals are currently disabled' using errcode='55000';
 end if;
 select coalesce((setting_value#>>'{}')::numeric,0) into v_minimum
 from public.app_settings where setting_key='minimum_withdrawal_amount';
 if p_amount<coalesce(v_minimum,0) then
  raise exception 'Minimum withdrawal amount is ₹%',to_char(coalesce(v_minimum,0),'FM999999999990.00') using errcode='22023';
 end if;
 select p.main_member_id into v_member from public.profiles p where p.id=v_uid;
 if v_member is null or not exists(
  select 1 from public.member_ids m where m.id=v_member and m.owner_user_id=v_uid and m.id_type='main' and m.status='active'
 ) then raise exception 'An active Main ID belonging to this account is required' using errcode='42501'; end if;
 select balance into v_balance from public.wallet_accounts
 where member_id=v_member and wallet_type='income' for update;
 if v_balance is null or v_balance<p_amount then raise exception 'Insufficient Income Wallet balance' using errcode='23514'; end if;
 if exists(select 1 from public.withdrawal_requests where member_id=v_member and status in ('pending','approved')) then
  raise exception 'An open withdrawal request already exists' using errcode='55000';
 end if;
 insert into public.withdrawal_requests(member_id,amount,currency,status,payout_details)
 values(v_member,p_amount,'INR','pending',p_payout_details) returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'member_withdrawal_requested','withdrawal_requests',v_id,jsonb_build_object('amount',p_amount));
 return jsonb_build_object('success',true,'request_id',v_id,'status','pending','minimum_amount',coalesce(v_minimum,0));
end;
$function$;

revoke all on function public.admin_get_minimum_withdrawal_amount() from public,anon;
grant execute on function public.admin_get_minimum_withdrawal_amount() to authenticated;
revoke all on function public.admin_set_minimum_withdrawal_amount(numeric) from public,anon;
grant execute on function public.admin_set_minimum_withdrawal_amount(numeric) to authenticated;
revoke all on function public.member_create_withdrawal_request(numeric,jsonb) from public,anon;
grant execute on function public.member_create_withdrawal_request(numeric,jsonb) to authenticated;
