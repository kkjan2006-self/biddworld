-- Defense in depth for withdrawal requests: require the caller's own active Main ID.
-- This does not enable withdrawals or bypass the financial approval interlock.
-- Source-only; reconcile and obtain explicit owner approval before Production rollout.
create or replace function public.member_create_withdrawal_request(
 p_amount numeric,
 p_payout_details jsonb
) returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_member uuid;
 v_balance numeric;
 v_id uuid;
begin
 if v_uid is null then
  raise exception 'Authentication required' using errcode='42501';
 end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) then
  raise exception 'Enter a valid withdrawal amount';
 end if;
 if p_payout_details is null or jsonb_typeof(p_payout_details)<>'object' or length(p_payout_details::text)>2000 then
  raise exception 'Valid payout details are required';
 end if;
 if coalesce((select (setting_value#>>'{}')::boolean from public.app_settings where setting_key='withdrawals_enabled'),false) is not true then
  raise exception 'Withdrawals are currently disabled' using errcode='55000';
 end if;

 select p.main_member_id into v_member
 from public.profiles p where p.id=v_uid;

 if v_member is null or not exists(
  select 1 from public.member_ids m
  where m.id=v_member and m.owner_user_id=v_uid
    and m.id_type='main' and m.status='active'
 ) then
  raise exception 'An active Main ID belonging to this account is required'
    using errcode='42501';
 end if;

 select balance into v_balance
 from public.wallet_accounts
 where member_id=v_member and wallet_type='income'
 for update;
 if v_balance is null or v_balance<p_amount then
  raise exception 'Insufficient Income Wallet balance';
 end if;
 if exists(
  select 1 from public.withdrawal_requests
  where member_id=v_member and status in ('pending','approved','processing')
 ) then
  raise exception 'An open withdrawal request already exists';
 end if;
 insert into public.withdrawal_requests(member_id,amount,currency,status,payout_details)
 values(v_member,p_amount,'INR','pending',p_payout_details)
 returning id into v_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'member_withdrawal_requested','withdrawal_requests',v_id,
  jsonb_build_object('amount',p_amount));
 return jsonb_build_object('success',true,'request_id',v_id,'status','pending');
end $function$;

revoke all on function public.member_create_withdrawal_request(numeric,jsonb)
 from public,anon;
grant execute on function public.member_create_withdrawal_request(numeric,jsonb)
 to authenticated;
