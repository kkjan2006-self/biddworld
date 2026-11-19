-- Align Main Wallet funding review with the restricted Staff permission model.
-- Staff can read private funding receipts and review requests only when the
-- wallet_funding_review claim is present. Primary Admin retains full access.

drop policy if exists wallet_funding_receipts_admin_read on storage.objects;
create policy wallet_funding_receipts_admin_read on storage.objects
 for select to authenticated using(
  bucket_id='wallet-funding-receipts'
  and (
   coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
   or (
    coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
    and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review'
   )
  )
 );

create or replace function public.admin_list_pending_wallet_fund_requests()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare
 v_result jsonb;
 v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
begin
 if auth.uid() is null or not (
  v_role='admin'
  or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review')
 ) then
  raise exception 'Wallet funding review permission required' using errcode='42501';
 end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',r.id,'member_code',m.member_code,'member_name',p.display_name,
  'amount',r.amount,'currency',r.currency,'payment_reference',r.payment_reference,
  'receipt_path',r.receipt_path,'created_at',r.created_at
 ) order by r.created_at,r.id),'[]'::jsonb)
 into v_result
 from public.wallet_fund_requests r
 join public.member_ids m on m.id=r.member_id
 left join public.profiles p on p.id=r.submitted_by
 where r.status='pending';
 return v_result;
end;
$function$;

create or replace function public.admin_review_wallet_fund_request(
 p_request_id uuid,p_approve boolean,p_review_note text default null
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_request public.wallet_fund_requests%rowtype;
 v_wallet public.wallet_accounts%rowtype;
 v_balance numeric(14,2);
 v_key text;
 v_wallet_enabled boolean:=false;
begin
 if v_uid is null or not (
  v_role='admin'
  or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review')
 ) then
  raise exception 'Wallet funding review permission required' using errcode='42501';
 end if;
 if p_approve is null then raise exception 'Choose approve or reject' using errcode='22023'; end if;
 if length(coalesce(p_review_note,''))>500 then raise exception 'Review note is too long' using errcode='22023'; end if;
 select * into v_request from public.wallet_fund_requests where id=p_request_id for update;
 if not found then raise exception 'Wallet funding request not found' using errcode='P0002'; end if;
 if v_request.status<>'pending' then raise exception 'This wallet funding request has already been reviewed' using errcode='55000'; end if;
 if p_approve then
  select coalesce((setting_value #>> '{}')::boolean,false) into v_wallet_enabled
  from public.app_settings where setting_key='income_wallet_enabled';
  if not coalesce(v_wallet_enabled,false) then raise exception 'Main Wallet funding is currently unavailable' using errcode='55000'; end if;
  select * into v_wallet from public.wallet_accounts
  where member_id=v_request.member_id and wallet_type='income' for update;
  if not found then raise exception 'Main Wallet account is unavailable' using errcode='55000'; end if;
  v_balance:=v_wallet.balance+v_request.amount;
  update public.wallet_accounts set balance=v_balance,updated_at=now() where id=v_wallet.id;
  v_key:='wallet-fund-request:'||v_request.id::text;
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_wallet.id,v_request.member_id,'wallet_funding','credit',v_request.amount,v_balance,
   'wallet_fund_request',v_request.id,v_key,'Admin-approved wallet top-up · UTR '||v_request.payment_reference);
  update public.wallet_fund_requests set status='approved',reviewed_by=v_uid,reviewed_at=now(),
   review_note=nullif(btrim(coalesce(p_review_note,'')),'') where id=v_request.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'wallet_fund_request_approved','wallet_fund_request',v_request.id,
   jsonb_build_object('member_id',v_request.member_id,'wallet_type','income',
    'amount',v_request.amount,'balance_after',v_balance,'payment_reference',v_request.payment_reference,'reviewer_role',v_role));
  return jsonb_build_object('success',true,'status','approved','wallet_type','income','balance_after',v_balance);
 else
  update public.wallet_fund_requests set status='rejected',reviewed_by=v_uid,reviewed_at=now(),
   review_note=nullif(btrim(coalesce(p_review_note,'')),'') where id=v_request.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'wallet_fund_request_rejected','wallet_fund_request',v_request.id,
   jsonb_build_object('member_id',v_request.member_id,'amount',v_request.amount,
    'payment_reference',v_request.payment_reference,'review_note',nullif(btrim(coalesce(p_review_note,'')),''),'reviewer_role',v_role));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
end;
$function$;

revoke all on function public.admin_list_pending_wallet_fund_requests() from public,anon;
grant execute on function public.admin_list_pending_wallet_fund_requests() to authenticated;
revoke all on function public.admin_review_wallet_fund_request(uuid,boolean,text) from public,anon;
grant execute on function public.admin_review_wallet_fund_request(uuid,boolean,text) to authenticated;
