-- Prevent one bank/UPI reference from being reused across package payments and Main Wallet top-ups.
-- A shared transaction-scoped advisory lock serializes inserts from both workflows.
create or replace function private.prevent_cross_workflow_payment_reference_reuse()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_reference text:=upper(btrim(coalesce(new.payment_reference,'')));
begin
 if v_reference='' then return new; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld-payment-reference:'||v_reference,0));
 if tg_table_name='package_activations' then
  if exists(select 1 from public.wallet_fund_requests r
    where r.payment_reference_normalized=v_reference) then
   raise exception 'This payment reference has already been used for a Main Wallet top-up'
    using errcode='23505';
  end if;
 elsif tg_table_name='wallet_fund_requests' then
  if exists(select 1 from public.package_activations a
    where upper(btrim(a.payment_reference))=v_reference) then
   raise exception 'This payment reference has already been used for a package payment'
    using errcode='23505';
  end if;
 end if;
 return new;
end;
$function$;
revoke all on function private.prevent_cross_workflow_payment_reference_reuse() from public,anon,authenticated;
drop trigger if exists prevent_package_payment_reference_reuse on public.package_activations;
create trigger prevent_package_payment_reference_reuse
before insert on public.package_activations
for each row execute function private.prevent_cross_workflow_payment_reference_reuse();
drop trigger if exists prevent_wallet_fund_payment_reference_reuse on public.wallet_fund_requests;
create trigger prevent_wallet_fund_payment_reference_reuse
before insert on public.wallet_fund_requests
for each row execute function private.prevent_cross_workflow_payment_reference_reuse();
