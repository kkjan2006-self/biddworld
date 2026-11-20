-- Prevent direct authenticated RPC calls from opening package payment requests
-- while package activation is disabled or the owner financial/compliance approval
-- has not been recorded. This complements the UI lock and the approval/ledger triggers.
-- Source-only: reconcile against Production and test in a disposable project first.

create or replace function private.submit_package_activation(
  p_package_id uuid,
  p_payment_reference text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_package public.packages%rowtype;
  v_activation_id uuid;
  v_activation_number integer;
  v_reference text := btrim(coalesce(p_payment_reference, ''));
  v_enabled boolean := false;
  v_financial_approved boolean := false;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode='42501';
  end if;

  select coalesce((setting_value #>> '{}')::boolean,false)
    into v_enabled
    from public.app_settings where setting_key='package_activations_enabled';
  select coalesce((setting_value #>> '{}')::boolean,false)
    into v_financial_approved
    from public.app_settings where setting_key='financial_model_approved';

  if not coalesce(v_enabled,false) or not coalesce(v_financial_approved,false) then
    raise exception 'Package activation requests are locked until the owner approves the financial and compliance model and opens package activation'
      using errcode='55000';
  end if;

  if length(v_reference) < 6 or length(v_reference) > 80
     or v_reference !~ '^[A-Za-z0-9./_-]+$' then
    raise exception 'Enter a valid payment reference (6 to 80 letters or numbers)';
  end if;

  select id into v_member_id
    from public.member_ids
   where owner_user_id = v_uid and id_type = 'main'
   for update;
  if v_member_id is null then
    raise exception 'A Main ID is required to request package activation';
  end if;

  select * into v_package from public.packages
   where id = p_package_id and is_active = true for share;
  if not found then
    raise exception 'This package is not available';
  end if;

  if exists (select 1 from public.package_activations
      where lower(btrim(payment_reference)) = lower(v_reference)) then
    raise exception 'This payment reference has already been submitted';
  end if;

  select coalesce(max(activation_number), 0) + 1 into v_activation_number
    from public.package_activations where member_id = v_member_id;

  insert into public.package_activations
    (member_id, package_id, activation_number, amount_paid, currency,
     bid_wallet_credit, payment_status, activation_status, payment_reference, submitted_at)
  values
    (v_member_id, v_package.id, v_activation_number, v_package.price, v_package.currency,
     v_package.bid_wallet_credit, 'pending', 'pending', v_reference, now())
  returning id into v_activation_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
  values (v_uid, 'package_activation_submitted', 'package_activation', v_activation_id,
    jsonb_build_object('package_id', v_package.id, 'member_id', v_member_id,
      'payment_reference', v_reference, 'amount', v_package.price,
      'bid_wallet_credit', v_package.bid_wallet_credit, 'currency', v_package.currency));

  return jsonb_build_object('success', true, 'activation_id', v_activation_id,
    'activation_number', v_activation_number, 'payment_status', 'pending',
    'activation_status', 'pending');
end;
$function$;

revoke all on function private.submit_package_activation(uuid, text)
  from public, anon, authenticated;
-- The function owner retains implicit execution rights; callers use the
-- existing authenticated-only public wrapper.

-- Keep the narrow public entry point and its authenticated-only grant intact.
