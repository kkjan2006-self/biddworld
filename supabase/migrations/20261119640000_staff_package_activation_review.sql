-- Allow explicitly permissioned Staff to list and review pending package activations.
-- Bounded keyset pagination for the Admin pending package activation review queue.
-- Preserve the existing Admin-only authorization and receipt-path contract.
create or replace function public.admin_list_pending_activations_page(
 p_limit integer default 50,
 p_after_submitted_at timestamptz default null,
 p_after_id uuid default null
) returns jsonb
language plpgsql stable security definer set search_path=''
as $function$
declare
 v_items jsonb;
 v_has_more boolean:=false;
 v_next_submitted_at timestamptz;
 v_next_id uuid;
begin
 if auth.uid() is null or not(
  coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
   and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'package_activation_review')
 ) then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>100 then
  raise exception 'Page size must be between 1 and 100' using errcode='22023';
 end if;
 if (p_after_submitted_at is null)<>(p_after_id is null) then
  raise exception 'Both cursor values must be supplied together' using errcode='22023';
 end if;

 with candidates as (
  select a.id,a.activation_number,m.member_code,p.display_name as member_name,
   pkg.name as package_name,a.amount_paid,a.currency,a.bid_wallet_credit,
   a.payment_reference,a.receipt_path,a.submitted_at
  from public.package_activations a
  join public.member_ids m on m.id=a.member_id
  left join public.profiles p on p.id=m.owner_user_id
  join public.packages pkg on pkg.id=a.package_id
  where a.payment_status='pending' and a.activation_status='pending'
   and (p_after_submitted_at is null or (a.submitted_at,a.id)<(p_after_submitted_at,p_after_id))
  order by a.submitted_at desc,a.id desc
  limit p_limit+1
 ), numbered as (
  select c.*,row_number() over(order by c.submitted_at desc,c.id desc) as rn
  from candidates c
 ), kept as (
  select * from numbered where rn<=p_limit
 )
 select
  coalesce(jsonb_agg(jsonb_build_object(
   'id',id,'activation_number',activation_number,'member_code',member_code,
   'member_name',member_name,'package_name',package_name,'amount_paid',amount_paid,
   'currency',currency,'bid_wallet_credit',bid_wallet_credit,
   'payment_reference',payment_reference,'receipt_path',receipt_path,'submitted_at',submitted_at
  ) order by submitted_at desc,id desc),'[]'::jsonb),
  coalesce((select count(*)>p_limit from candidates),false),
  (array_agg(submitted_at order by rn))[p_limit],
  (array_agg(id order by rn))[p_limit]
 into v_items,v_has_more,v_next_submitted_at,v_next_id
 from kept;

 return jsonb_build_object(
  'items',v_items,'has_more',v_has_more,
  'next_submitted_at',case when v_has_more then v_next_submitted_at else null end,
  'next_id',case when v_has_more then v_next_id else null end
 );
end;
$function$;
revoke all on function public.admin_list_pending_activations_page(integer,timestamptz,uuid) from public,anon;
grant execute on function public.admin_list_pending_activations_page(integer,timestamptz,uuid) to authenticated;

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
  v_role text := coalesce(auth.jwt()->'app_metadata'->>'role','');
  v_permissions jsonb := coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb);
  v_activation public.package_activations%rowtype;
  v_member public.member_ids%rowtype;
  v_wallet public.wallet_accounts%rowtype;
  v_new_balance numeric(14,2);
  v_key text;
begin
  if v_uid is null or not(v_role='admin' or (v_role='admin_staff' and v_permissions ? 'package_activation_review')) then
    raise exception 'Package activation review permission required' using errcode='42501';
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
revoke all on function public.admin_review_package_activation(uuid,boolean) from public,anon;
grant execute on function public.admin_review_package_activation(uuid,boolean) to authenticated;
