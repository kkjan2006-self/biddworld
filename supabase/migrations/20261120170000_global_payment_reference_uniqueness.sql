-- Enforce one global UTR/payment-reference namespace across Package Activation
-- and Income Wallet Add Money. Cross-table preflight checks alone are racy;
-- this BEFORE trigger serializes inserts/updates on the normalized reference.

create or replace function private.guard_global_payment_reference_uniqueness()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
begin
  if new.payment_reference is null or btrim(new.payment_reference)='' then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'biddworld.payment-reference:'||upper(btrim(new.payment_reference)),0
    )
  );

  if tg_table_name='package_activations' then
    if exists(
      select 1 from public.wallet_fund_requests r
      where upper(btrim(r.payment_reference))=upper(btrim(new.payment_reference))
    ) then
      raise exception 'This UTR / payment reference has already been submitted'
        using errcode='23505';
    end if;
  elsif tg_table_name='wallet_fund_requests' then
    if exists(
      select 1 from public.package_activations a
      where upper(btrim(a.payment_reference))=upper(btrim(new.payment_reference))
    ) then
      raise exception 'This UTR / payment reference has already been submitted'
        using errcode='23505';
    end if;
  else
    raise exception 'Unsupported payment reference table: %',tg_table_name
      using errcode='55000';
  end if;

  return new;
end;
$function$;
revoke all on function private.guard_global_payment_reference_uniqueness() from public,anon,authenticated;

drop trigger if exists guard_package_activation_global_payment_reference on public.package_activations;
create trigger guard_package_activation_global_payment_reference
before insert or update of payment_reference on public.package_activations
for each row execute function private.guard_global_payment_reference_uniqueness();

drop trigger if exists guard_wallet_funding_global_payment_reference on public.wallet_fund_requests;
create trigger guard_wallet_funding_global_payment_reference
before insert or update of payment_reference on public.wallet_fund_requests
for each row execute function private.guard_global_payment_reference_uniqueness();
