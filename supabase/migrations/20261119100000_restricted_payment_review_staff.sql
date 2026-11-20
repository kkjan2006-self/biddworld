-- Restricted Admin Staff role: package-payment and Main Wallet top-up review only.
-- Staff grants are fixed-purpose, Primary-Admin-controlled app_metadata claims.

create or replace function public.admin_set_payment_review_staff(
 p_email text,p_enabled boolean,p_reason text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_target_id uuid; v_target_email text; v_metadata jsonb;
begin
 if v_uid is null
  or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'
  or lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com' then
  raise exception 'Only the designated Primary Admin can manage payment-review staff' using errcode='42501';
 end if;
 if p_enabled is null or length(trim(coalesce(p_email,'')))<5 or length(p_email)>254
  or p_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' then
  raise exception 'Enter a valid existing account email and role action' using errcode='22023';
 end if;
 if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Provide a reason between 5 and 500 characters' using errcode='22023';
 end if;
 select id,email,coalesce(raw_app_meta_data,'{}'::jsonb)
 into v_target_id,v_target_email,v_metadata
 from auth.users where lower(email)=lower(trim(p_email)) for update;
 if not found then raise exception 'No registered account exists with that email' using errcode='P0002'; end if;
 if lower(v_target_email)='kkjan2006@gmail.com' then
  raise exception 'The Primary Admin account cannot be changed to staff' using errcode='55000';
 end if;
 if coalesce(v_metadata->>'role','')='admin' then
  raise exception 'An Admin account cannot also be assigned the restricted staff role' using errcode='55000';
 end if;
 if p_enabled then
  update auth.users set raw_app_meta_data=jsonb_set(
   jsonb_set(coalesce(raw_app_meta_data,'{}'::jsonb),'{role}','"admin_staff"'::jsonb,true),
   '{permissions}','["package_activation_review","wallet_funding_review","auction_submission_review"]'::jsonb,true)
  where id=v_target_id;
 else
  update auth.users set raw_app_meta_data=coalesce(raw_app_meta_data,'{}'::jsonb)-'role'-'permissions'
  where id=v_target_id and coalesce(raw_app_meta_data->>'role','')='admin_staff';
  if not found then raise exception 'This account does not currently have the restricted payment-review staff role' using errcode='55000'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,case when p_enabled then 'payment_review_staff.granted' else 'payment_review_staff.revoked' end,
  'auth.users',v_target_id,jsonb_build_object('target_email',v_target_email,
   'permissions',case when p_enabled then jsonb_build_array('package_activation_review','wallet_funding_review','auction_submission_review') else '[]'::jsonb end,
   'reason',trim(p_reason)));
 return jsonb_build_object('success',true,'email',v_target_email,
  'app_role',case when p_enabled then 'admin_staff' else 'member' end,
  'permissions',case when p_enabled then jsonb_build_array('package_activation_review','wallet_funding_review') else '[]'::jsonb end,
  'note','The target user must sign out and sign in again to refresh role claims.');
end;
$function$;

create or replace function public.admin_list_payment_review_staff()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb;
begin
 if auth.uid() is null
  or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin'
  or lower(coalesce(auth.jwt()->>'email',''))<>'kkjan2006@gmail.com' then
  raise exception 'Only the designated Primary Admin can view payment-review staff' using errcode='42501';
 end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'user_id',u.id,'email',u.email,'created_at',u.created_at,
  'last_sign_in_at',u.last_sign_in_at,'permissions',u.raw_app_meta_data->'permissions'
 ) order by u.created_at),'[]'::jsonb)
 into v_result from auth.users u
 where u.raw_app_meta_data->>'role'='admin_staff';
 return v_result;
end;
$function$;

create or replace function public.admin_list_pending_activations()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb; v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
begin
 if auth.uid() is null or not (
  v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'package_activation_review')
 ) then raise exception 'Payment-review permission required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',a.id,'activation_number',a.activation_number,'member_code',m.member_code,
  'member_name',p.display_name,'package_name',pkg.name,'amount_paid',a.amount_paid,
  'currency',a.currency,'bid_wallet_credit',a.bid_wallet_credit,
  'payment_reference',a.payment_reference,'receipt_path',a.receipt_path,'submitted_at',a.submitted_at
 ) order by a.submitted_at,a.id),'[]'::jsonb)
 into v_result
 from public.package_activations a
 join public.member_ids m on m.id=a.member_id
 left join public.profiles p on p.id=m.owner_user_id
 join public.packages pkg on pkg.id=a.package_id
 where a.payment_status='pending' and a.activation_status='pending';
 return v_result;
end;
$function$;

create or replace function public.admin_review_package_activation(
 p_activation_id uuid,p_approve boolean
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_activation public.package_activations%rowtype; v_member public.member_ids%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_new_balance numeric(14,2); v_key text;
begin
 if v_uid is null or not (
  v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'package_activation_review')
 ) then raise exception 'Package payment-review permission required' using errcode='42501'; end if;
 if p_approve is null then raise exception 'Choose approve or reject' using errcode='22023'; end if;
 select * into v_activation from public.package_activations where id=p_activation_id for update;
 if not found then raise exception 'Activation request not found'; end if;
 if v_activation.payment_status<>'pending' or v_activation.activation_status<>'pending' then
  raise exception 'This activation request has already been reviewed';
 end if;
 select * into v_member from public.member_ids where id=v_activation.member_id for update;
 if not found or v_member.id_type<>'main' then raise exception 'Activation must belong to a Main ID'; end if;
 if p_approve then
  select * into v_wallet from public.wallet_accounts
   where member_id=v_member.id and wallet_type='bid' for update;
  if not found then raise exception 'Bid Wallet is unavailable'; end if;
  v_new_balance:=v_wallet.balance+v_activation.bid_wallet_credit;
  if v_activation.bid_wallet_credit>0 then
   update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
   v_key:='package-activation:'||v_activation.id::text||':bid-credit';
   insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,
    balance_after,reference_type,reference_id,idempotency_key,description)
   values(v_wallet.id,v_member.id,'package_activation_credit','credit',v_activation.bid_wallet_credit,
    v_new_balance,'package_activation',v_activation.id,v_key,'Verified package activation Bid Wallet credit');
  end if;
  update public.package_activations set payment_status='approved',activation_status='active',
   verified_at=now(),verified_by=v_uid where id=v_activation.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'package_activation_approved','package_activation',v_activation.id,
   jsonb_build_object('member_id',v_member.id,'bid_wallet_credit',v_activation.bid_wallet_credit,
    'wallet_balance_after',v_new_balance,'reviewer_role',v_role));
  return jsonb_build_object('success',true,'status','approved',
   'bid_wallet_credit',v_activation.bid_wallet_credit,'wallet_balance',v_new_balance);
 else
  update public.package_activations set payment_status='rejected',activation_status='rejected',
   verified_at=now(),verified_by=v_uid where id=v_activation.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'package_activation_rejected','package_activation',v_activation.id,
   jsonb_build_object('member_id',v_member.id,'payment_reference',v_activation.payment_reference,'reviewer_role',v_role));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
end;
$function$;

create or replace function public.admin_list_pending_wallet_fund_requests()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb; v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
begin
 if auth.uid() is null or not (
  v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review')
 ) then raise exception 'Wallet funding-review permission required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',r.id,'member_code',m.member_code,'member_name',p.display_name,'amount',r.amount,
  'currency',r.currency,'payment_reference',r.payment_reference,'receipt_path',r.receipt_path,
  'created_at',r.created_at
 ) order by r.created_at,r.id),'[]'::jsonb)
 into v_result from public.wallet_fund_requests r
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
 v_uid uuid:=auth.uid(); v_role text:=coalesce(auth.jwt()->'app_metadata'->>'role','');
 v_request public.wallet_fund_requests%rowtype; v_wallet public.wallet_accounts%rowtype;
 v_balance numeric(14,2); v_key text; v_wallet_enabled boolean:=false;
begin
 if v_uid is null or not (
  v_role='admin' or (v_role='admin_staff' and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review')
 ) then raise exception 'Wallet funding-review permission required' using errcode='42501'; end if;
 if p_approve is null then raise exception 'Choose approve or reject' using errcode='22023'; end if;
 if length(coalesce(p_review_note,''))>500 then raise exception 'Review note is too long' using errcode='22023'; end if;
 select * into v_request from public.wallet_fund_requests where id=p_request_id for update;
 if not found then raise exception 'Wallet funding request not found' using errcode='P0002'; end if;
 if v_request.status<>'pending' then raise exception 'This wallet funding request has already been reviewed' using errcode='55000'; end if;
 if p_approve then
  select coalesce((setting_value#>>'{}')::boolean,false) into v_wallet_enabled
  from public.app_settings where setting_key='income_wallet_enabled';
  if not coalesce(v_wallet_enabled,false) then raise exception 'Main Wallet funding is currently unavailable' using errcode='55000'; end if;
  select * into v_wallet from public.wallet_accounts
  where member_id=v_request.member_id and wallet_type='income' for update;
  if not found then raise exception 'Main Wallet account is unavailable' using errcode='55000'; end if;
  v_balance:=v_wallet.balance+v_request.amount;
  update public.wallet_accounts set balance=v_balance,updated_at=now() where id=v_wallet.id;
  v_key:='wallet-fund-request:'||v_request.id::text;
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,
   reference_type,reference_id,idempotency_key,description)
  values(v_wallet.id,v_request.member_id,'wallet_funding','credit',v_request.amount,v_balance,
   'wallet_fund_request',v_request.id,v_key,'Admin-approved wallet top-up · UTR '||v_request.payment_reference);
  update public.wallet_fund_requests set status='approved',reviewed_by=v_uid,reviewed_at=now(),
   review_note=nullif(btrim(coalesce(p_review_note,'')),'') where id=v_request.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'wallet_fund_request_approved','wallet_fund_request',v_request.id,
   jsonb_build_object('member_id',v_request.member_id,'wallet_type','income','amount',v_request.amount,
    'balance_after',v_balance,'payment_reference',v_request.payment_reference,'reviewer_role',v_role));
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

drop policy if exists package_receipts_select_own_or_admin on storage.objects;
create policy package_receipts_select_own_or_admin on storage.objects
for select to authenticated using(bucket_id='package-receipts' and (
 (storage.foldername(name))[1]=(select auth.uid())::text
 or coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
 or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
  and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'package_activation_review')
));

drop policy if exists wallet_funding_receipts_admin_read on storage.objects;
create policy wallet_funding_receipts_admin_read on storage.objects
for select to authenticated using(bucket_id='wallet-funding-receipts' and (
 coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
 or (coalesce(auth.jwt()->'app_metadata'->>'role','')='admin_staff'
  and coalesce(auth.jwt()->'app_metadata'->'permissions','[]'::jsonb) ? 'wallet_funding_review')
));

revoke all on function public.admin_set_payment_review_staff(text,boolean,text) from public,anon;
grant execute on function public.admin_set_payment_review_staff(text,boolean,text) to authenticated;
revoke all on function public.admin_list_payment_review_staff() from public,anon;
grant execute on function public.admin_list_payment_review_staff() to authenticated;
revoke all on function public.admin_list_pending_activations() from public,anon;
grant execute on function public.admin_list_pending_activations() to authenticated;
revoke all on function public.admin_review_package_activation(uuid,boolean) from public,anon;
grant execute on function public.admin_review_package_activation(uuid,boolean) to authenticated;
revoke all on function public.admin_list_pending_wallet_fund_requests() from public,anon;
grant execute on function public.admin_list_pending_wallet_fund_requests() to authenticated;
revoke all on function public.admin_review_wallet_fund_request(uuid,boolean,text) from public,anon;
grant execute on function public.admin_review_wallet_fund_request(uuid,boolean,text) to authenticated;
