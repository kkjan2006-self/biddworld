-- Keep the Admin pending-activation queue aligned with the private receipt
-- Storage workflow. The prior RPC omitted receipt_path, so the UI could not
-- create a signed URL even when a member had uploaded a receipt.
create or replace function public.admin_list_pending_activations()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_result jsonb;
begin
  if auth.uid() is null
     or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', a.id,
        'activation_number', a.activation_number,
        'member_code', m.member_code,
        'member_name', p.display_name,
        'package_name', pkg.name,
        'amount_paid', a.amount_paid,
        'currency', a.currency,
        'bid_wallet_credit', a.bid_wallet_credit,
        'payment_reference', a.payment_reference,
        'receipt_path', a.receipt_path,
        'submitted_at', a.submitted_at
      ) order by a.submitted_at desc, a.id desc
    ),
    '[]'::jsonb
  ) into v_result
  from public.package_activations a
  join public.member_ids m on m.id = a.member_id
  join auth.users u on u.id = m.owner_user_id
  left join public.profiles p on p.id = u.id
  join public.packages pkg on pkg.id = a.package_id
  where a.payment_status = 'pending'
    and a.activation_status = 'pending';

  return v_result;
end;
$function$;

revoke all on function public.admin_list_pending_activations() from public, anon;
grant execute on function public.admin_list_pending_activations() to authenticated;
