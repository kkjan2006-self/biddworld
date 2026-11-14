-- Secure administrator review for package activation requests.
-- Benefit amount is snapshotted when the member submits the request.
alter table public.package_activations
  add column if not exists bid_wallet_credit numeric(14,2) not null default 0
  check (bid_wallet_credit >= 0);

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
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if length(v_reference) < 6 or length(v_reference) > 80
     or v_reference !~ '^[A-Za-z0-9./_-]+$' then
    raise exception 'Enter a valid payment reference (6 to 80 letters or numbers)';
  end if;

  select id into v_member_id
    from public.member_ids
   where owner_user_id = v_uid and id_type = 'main' and status = 'active'
   for update;
  if v_member_id is null then
    raise exception 'An active Main ID is required to request package activation';
  end if;

  select * into v_package from public.packages
   where id = p_package_id and is_active = true for share;
  if not found then raise exception 'This package is not available'; end if;

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

-- The public entry point is a narrow SECURITY DEFINER wrapper. The private
-- implementation independently validates auth.uid() and all member inputs.
create or replace function public.submit_package_activation(
  p_package_id uuid,
  p_payment_reference text
) returns jsonb
language sql
security definer
set search_path = ''
as $function$
  select private.submit_package_activation(p_package_id, p_payment_reference);
$function$;
revoke all on function private.submit_package_activation(uuid, text) from public, anon, authenticated;
revoke all on function public.submit_package_activation(uuid, text) from public, anon;
grant execute on function public.submit_package_activation(uuid, text) to authenticated;

create or replace function public.admin_list_pending_activations()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', a.id,
    'activation_number', a.activation_number,
    'member_code', m.member_code,
    'member_name', p.display_name,
    'package_name', pkg.name,
    'amount_paid', a.amount_paid,
    'currency', a.currency,
    'bid_wallet_credit', a.bid_wallet_credit,
    'payment_reference', a.payment_reference,
    'submitted_at', a.submitted_at
  ) order by a.submitted_at), '[]'::jsonb)
  into v_result
  from public.package_activations a
  join public.member_ids m on m.id = a.member_id
  join auth.users u on u.id = m.owner_user_id
  left join public.profiles p on p.id = u.id
  join public.packages pkg on pkg.id = a.package_id
  where a.payment_status = 'pending' and a.activation_status = 'pending';

  return v_result;
end;
$function$;

create or replace function public.admin_review_package_activation(
  p_activation_id uuid,
  p_approve boolean
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_activation public.package_activations%rowtype;
  v_member public.member_ids%rowtype;
  v_wallet public.wallet_accounts%rowtype;
  v_new_balance numeric(14,2);
  v_key text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  select * into v_activation from public.package_activations
   where id = p_activation_id for update;
  if not found then raise exception 'Activation request not found'; end if;
  if v_activation.payment_status <> 'pending' or v_activation.activation_status <> 'pending' then
    raise exception 'This activation request has already been reviewed';
  end if;

  select * into v_member from public.member_ids
   where id = v_activation.member_id for update;
  if not found or v_member.id_type <> 'main' then
    raise exception 'Activation must belong to a Main ID';
  end if;

  if p_approve then
    select * into v_wallet from public.wallet_accounts
     where member_id = v_member.id and wallet_type = 'bid' for update;
    if not found then raise exception 'Bid Wallet is unavailable'; end if;

    v_new_balance := v_wallet.balance + v_activation.bid_wallet_credit;
    if v_activation.bid_wallet_credit > 0 then
      update public.wallet_accounts set balance = v_new_balance, updated_at = now()
       where id = v_wallet.id;
      v_key := 'package-activation:' || v_activation.id::text || ':bid-credit';
      insert into public.wallet_transactions
        (wallet_account_id, member_id, transaction_type, direction, amount,
         balance_after, reference_type, reference_id, idempotency_key, description)
      values
        (v_wallet.id, v_member.id, 'package_activation_credit', 'credit',
         v_activation.bid_wallet_credit, v_new_balance, 'package_activation',
         v_activation.id, v_key, 'Verified package activation Bid Wallet credit');
    end if;

    update public.package_activations
       set payment_status = 'approved', activation_status = 'active',
           verified_at = now(), verified_by = v_uid
     where id = v_activation.id;

    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
    values (v_uid, 'package_activation_approved', 'package_activation', v_activation.id,
      jsonb_build_object('member_id', v_member.id, 'bid_wallet_credit',
        v_activation.bid_wallet_credit, 'wallet_balance_after', v_new_balance));
    return jsonb_build_object('success', true, 'status', 'approved',
      'bid_wallet_credit', v_activation.bid_wallet_credit,
      'wallet_balance', v_new_balance);
  else
    update public.package_activations
       set payment_status = 'rejected', activation_status = 'rejected',
           verified_at = now(), verified_by = v_uid
     where id = v_activation.id;
    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
    values (v_uid, 'package_activation_rejected', 'package_activation', v_activation.id,
      jsonb_build_object('member_id', v_member.id, 'payment_reference', v_activation.payment_reference));
    return jsonb_build_object('success', true, 'status', 'rejected');
  end if;
end;
$function$;

revoke all on function public.admin_list_pending_activations() from public, anon;
grant execute on function public.admin_list_pending_activations() to authenticated;
revoke all on function public.admin_review_package_activation(uuid, boolean) from public, anon;
grant execute on function public.admin_review_package_activation(uuid, boolean) to authenticated;

-- Keep the dashboard's "verified" metric aligned with the canonical
-- package_activations.payment_status value: approved.
create or replace function public.admin_get_mlm_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  return jsonb_build_object(
    'total_members',(select count(*) from public.member_ids where id_type='main'),
    'active_members',(select count(*) from public.member_ids where id_type='main' and status='active'),
    'direct_relationships',(select count(*) from public.referrals),
    'pending_activations',(select count(*) from public.package_activations where payment_status='pending'),
    'verified_activations',(select count(*) from public.package_activations where payment_status='approved'),
    'commission_total',(select coalesce(sum(amount),0) from public.referral_commissions where status in ('credited','paid')),
    'withdrawal_pending',(select count(*) from public.withdrawal_requests where status='pending'),
    'tree',(select coalesce(jsonb_agg(jsonb_build_object('member_code',m.member_code,'display_name',coalesce(nullif(p.display_name,''),'Member'),'status',m.status,'created_at',m.created_at,'sponsor_code',s.member_code) order by m.created_at desc),'[]'::jsonb)
      from public.member_ids m join public.profiles p on p.id=m.owner_user_id
      left join public.referrals r on r.referred_member_id=m.id
      left join public.member_ids s on s.id=r.referrer_member_id
      where m.id_type='main' limit 500)
  );
end;
$function$;
revoke all on function public.admin_get_mlm_overview() from public, anon;
grant execute on function public.admin_get_mlm_overview() to authenticated;
