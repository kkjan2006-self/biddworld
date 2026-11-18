-- Enforce the member payout-detail contract at the database boundary.
-- The UI is not a security boundary; accept only the two supported payout methods
-- and only their exact fields. Payout credentials are never copied to audit logs.
-- Source-only. Replay only on the isolated TEST database during final testing.

create or replace function public.member_create_withdrawal_request(
  p_amount numeric,
  p_payout_details jsonb
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_member uuid;
  v_balance numeric;
  v_id uuid;
  v_minimum numeric := 0;
  v_method text;
  v_holder text;
  v_reference text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) or p_amount > 10000000 then
    raise exception 'Enter a valid withdrawal amount with no more than two decimal places' using errcode = '22023';
  end if;

  if p_payout_details is null
    or jsonb_typeof(p_payout_details) <> 'object'
    or length(p_payout_details::text) > 2000 then
    raise exception 'Valid payout details are required' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_object_keys(p_payout_details) as supplied(key)
    where supplied.key not in ('method', 'account_holder_name', 'upi_id', 'account_number')
  ) then
    raise exception 'Unsupported payout detail fields were supplied' using errcode = '22023';
  end if;

  if coalesce(jsonb_typeof(p_payout_details->'method'), 'null') <> 'string'
    or coalesce(jsonb_typeof(p_payout_details->'account_holder_name'), 'null') <> 'string' then
    raise exception 'Payout method and account holder name are required' using errcode = '22023';
  end if;

  v_method := btrim(p_payout_details->>'method');
  v_holder := btrim(p_payout_details->>'account_holder_name');

  if length(v_holder) < 2 or length(v_holder) > 100 then
    raise exception 'Account holder name must contain 2 to 100 characters' using errcode = '22023';
  end if;

  if v_method = 'UPI' then
    if p_payout_details ? 'account_number'
      or coalesce(jsonb_typeof(p_payout_details->'upi_id'), 'null') <> 'string' then
      raise exception 'Provide only a valid UPI ID for the selected payout method' using errcode = '22023';
    end if;

    v_reference := btrim(p_payout_details->>'upi_id');
    if v_reference is null or v_reference !~ '^[A-Za-z0-9._-]{2,256}@[A-Za-z0-9.-]{2,64}$' then
      raise exception 'Enter a valid UPI ID' using errcode = '22023';
    end if;
  elsif v_method = 'Bank Transfer' then
    if p_payout_details ? 'upi_id'
      or coalesce(jsonb_typeof(p_payout_details->'account_number'), 'null') <> 'string' then
      raise exception 'Provide only a valid bank account number for the selected payout method' using errcode = '22023';
    end if;

    v_reference := btrim(p_payout_details->>'account_number');
    if v_reference is null or v_reference !~ '^[0-9]{6,18}$' then
      raise exception 'Bank account number must contain 6 to 18 digits' using errcode = '22023';
    end if;
  else
    raise exception 'Choose UPI or Bank Transfer as the payout method' using errcode = '22023';
  end if;

  if coalesce((
    select (setting_value#>>'{}')::boolean
    from public.app_settings
    where setting_key = 'withdrawals_enabled'
  ), false) is not true then
    raise exception 'Withdrawals are currently disabled' using errcode = '55000';
  end if;

  select coalesce((setting_value#>>'{}')::numeric, 0)
  into v_minimum
  from public.app_settings
  where setting_key = 'minimum_withdrawal_amount';

  if p_amount < coalesce(v_minimum, 0) then
    raise exception 'Minimum withdrawal amount is ₹%',
      to_char(coalesce(v_minimum, 0), 'FM999999999990.00') using errcode = '22023';
  end if;

  select p.main_member_id
  into v_member
  from public.profiles p
  where p.id = v_uid
    and p.status = 'active';

  if v_member is null or not exists (
    select 1
    from public.member_ids m
    where m.id = v_member
      and m.owner_user_id = v_uid
      and m.id_type = 'main'
      and m.status = 'active'
  ) then
    raise exception 'An active member profile and Main ID belonging to this account are required' using errcode = '42501';
  end if;

  select balance
  into v_balance
  from public.wallet_accounts
  where member_id = v_member
    and wallet_type = 'income'
  for update;

  if v_balance is null or v_balance < p_amount then
    raise exception 'Insufficient Income Wallet balance' using errcode = '23514';
  end if;

  if exists (
    select 1
    from public.withdrawal_requests
    where member_id = v_member
      and status in ('pending', 'approved')
  ) then
    raise exception 'An open withdrawal request already exists' using errcode = '55000';
  end if;

  insert into public.withdrawal_requests(member_id, amount, currency, status, payout_details)
  values (
    v_member,
    p_amount,
    'INR',
    'pending',
    jsonb_build_object(
      'method', v_method,
      'account_holder_name', v_holder,
      case when v_method = 'UPI' then 'upi_id' else 'account_number' end,
      v_reference
    )
  )
  returning id into v_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (
    v_uid,
    'member_withdrawal_requested',
    'withdrawal_requests',
    v_id,
    jsonb_build_object('amount', p_amount, 'payout_method', v_method)
  );

  return jsonb_build_object(
    'success', true,
    'request_id', v_id,
    'status', 'pending',
    'minimum_amount', coalesce(v_minimum, 0)
  );
end;
$function$;

revoke all on function public.member_create_withdrawal_request(numeric, jsonb) from public, anon;
grant execute on function public.member_create_withdrawal_request(numeric, jsonb) to authenticated;
