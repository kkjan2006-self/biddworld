-- Member-submitted package payment reference. This creates a pending request only;
-- it never credits wallets or activates membership.
create unique index if not exists package_activations_payment_reference_ci_uidx
  on public.package_activations (lower(btrim(payment_reference)))
  where payment_reference is not null and btrim(payment_reference) <> '';

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
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if length(v_reference) < 6 or length(v_reference) > 80
     or v_reference !~ '^[A-Za-z0-9./_-]+$' then
    raise exception 'Enter a valid payment reference (6 to 80 letters or numbers)';
  end if;

  select id into v_member_id
    from public.member_ids
   where owner_user_id = v_uid
     and id_type = 'main'
     and status = 'active'
   for update;

  if v_member_id is null then
    raise exception 'An active Main ID is required to request package activation';
  end if;

  select * into v_package
    from public.packages
   where id = p_package_id and is_active = true
   for share;

  if not found then
    raise exception 'This package is not available';
  end if;

  if exists (
    select 1 from public.package_activations
     where lower(btrim(payment_reference)) = lower(v_reference)
  ) then
    raise exception 'This payment reference has already been submitted';
  end if;

  select coalesce(max(activation_number), 0) + 1
    into v_activation_number
    from public.package_activations
   where member_id = v_member_id;

  insert into public.package_activations
    (member_id, package_id, activation_number, amount_paid, currency,
     payment_status, activation_status, payment_reference, submitted_at)
  values
    (v_member_id, v_package.id, v_activation_number, v_package.price,
     v_package.currency, 'pending', 'pending', v_reference, now())
  returning id into v_activation_id;

  insert into public.audit_logs
    (actor_user_id, action, entity_type, entity_id, details)
  values
    (v_uid, 'package_activation_submitted', 'package_activation',
     v_activation_id,
     jsonb_build_object('package_id', v_package.id,
                        'member_id', v_member_id,
                        'payment_reference', v_reference,
                        'amount', v_package.price,
                        'currency', v_package.currency));

  return jsonb_build_object(
    'success', true,
    'activation_id', v_activation_id,
    'activation_number', v_activation_number,
    'payment_status', 'pending',
    'activation_status', 'pending'
  );
end;
$function$;

revoke all on function private.submit_package_activation(uuid, text)
  from public, anon, authenticated;

create or replace function public.submit_package_activation(
  p_package_id uuid,
  p_payment_reference text
) returns jsonb
language sql
security invoker
set search_path = ''
as $function$
  select private.submit_package_activation(p_package_id, p_payment_reference);
$function$;

revoke all on function public.submit_package_activation(uuid, text)
  from public, anon;
grant execute on function public.submit_package_activation(uuid, text)
  to authenticated;
