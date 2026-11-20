-- Require both the authenticated profile and its Main ID to remain active
-- when a member submits an Income Wallet Add Money request.
-- Lock both eligibility rows so concurrent lifecycle changes cannot race the check.

create or replace function public.member_submit_wallet_fund_request(
 p_amount numeric,p_payment_reference text,p_receipt_path text
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_member public.member_ids%rowtype;
 v_request public.wallet_fund_requests%rowtype;
 v_reference text:=btrim(coalesce(p_payment_reference,''));
 v_wallet_enabled boolean:=false;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_amount>10000000 then
  raise exception 'Enter a valid amount with up to two decimal places' using errcode='22023';
 end if;
 if length(v_reference)<6 or length(v_reference)>80 or v_reference !~ '^[A-Za-z0-9./_-]+$' then
  raise exception 'Enter a valid UTR / payment reference (6 to 80 characters)' using errcode='22023';
 end if;
 if p_receipt_path is null or length(p_receipt_path)>300
  or (storage.foldername(p_receipt_path))[1]<>v_uid::text
  or (storage.foldername(p_receipt_path))[2]<>'wallet-funding' then
  raise exception 'Upload your payment receipt before submitting' using errcode='22023';
 end if;
 if not exists(select 1 from storage.objects where bucket_id='wallet-funding-receipts' and name=p_receipt_path) then
  raise exception 'The uploaded payment receipt could not be found' using errcode='22023';
 end if;
 select coalesce((setting_value #>> '{}')::boolean,false) into v_wallet_enabled
 from public.app_settings where setting_key='income_wallet_enabled';
 if not coalesce(v_wallet_enabled,false) then raise exception 'Income Wallet funding is currently unavailable' using errcode='55000'; end if;
 if exists(select 1 from public.package_activations where upper(btrim(payment_reference))=upper(v_reference)) then
  raise exception 'This UTR / payment reference has already been submitted' using errcode='23505';
 end if;

 -- Match the eligibility contract used by other member financial actions.
 -- Lock both rows while checking; the Admin Main-ID lifecycle updates these
 -- records in the same transaction.
 select m.* into v_member
 from public.profiles p
 join public.member_ids m on m.id=p.main_member_id
 where p.id=v_uid and p.status='active'
  and m.owner_user_id=v_uid and m.id_type='main' and m.status='active'
 for update of p,m;
 if not found then raise exception 'An active Main ID and member profile are required to add funds' using errcode='55000'; end if;

 insert into public.wallet_fund_requests(member_id,submitted_by,amount,payment_reference,receipt_path)
 values(v_member.id,v_uid,p_amount,v_reference,p_receipt_path)
 returning * into v_request;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'wallet_fund_request_submitted','wallet_fund_request',v_request.id,
  jsonb_build_object('member_id',v_member.id,'member_code',v_member.member_code,
   'amount',p_amount,'currency','INR','payment_reference',v_reference));
 return jsonb_build_object('success',true,'request_id',v_request.id,'status','pending');
exception when unique_violation then
 raise exception 'This UTR / payment reference has already been submitted' using errcode='23505';
end;
$function$;
revoke all on function public.member_submit_wallet_fund_request(numeric,text,text) from public,anon;
grant execute on function public.member_submit_wallet_fund_request(numeric,text,text) to authenticated;
