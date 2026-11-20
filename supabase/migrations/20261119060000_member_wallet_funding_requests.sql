-- Member wallet top-ups: members submit UTR + private receipt; Admin review credits Main Wallet atomically.
create table if not exists public.wallet_fund_requests (
 id uuid primary key default gen_random_uuid(),
 member_id uuid not null references public.member_ids(id),
 submitted_by uuid not null references auth.users(id),
 amount numeric(14,2) not null check(amount>0 and amount=round(amount,2)),
 currency text not null default 'INR' check(currency='INR'),
 payment_reference text not null,
 payment_reference_normalized text generated always as (upper(btrim(payment_reference))) stored,
 receipt_path text not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz,
 review_note text,
 created_at timestamptz not null default now(),
 constraint wallet_fund_requests_utr_unique unique(payment_reference_normalized),
 constraint wallet_fund_requests_utr_length check(length(btrim(payment_reference)) between 6 and 80),
 constraint wallet_fund_requests_receipt_path check(length(receipt_path) between 1 and 300),
 constraint wallet_fund_requests_review_state check(
  (status='pending' and reviewed_by is null and reviewed_at is null)
  or (status in ('approved','rejected') and reviewed_by is not null and reviewed_at is not null)
 )
);
create index if not exists wallet_fund_requests_pending_idx
 on public.wallet_fund_requests(created_at desc,id desc) where status='pending';
alter table public.wallet_fund_requests enable row level security;
revoke all on public.wallet_fund_requests from public,anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('wallet-funding-receipts','wallet-funding-receipts',false,5242880,array['image/jpeg','image/png','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=5242880,
 allowed_mime_types=array['image/jpeg','image/png','application/pdf'];

drop policy if exists wallet_funding_receipts_member_insert on storage.objects;
create policy wallet_funding_receipts_member_insert on storage.objects
 for insert to authenticated with check(
  bucket_id='wallet-funding-receipts'
  and (storage.foldername(name))[1]=(select auth.uid())::text
  and (storage.foldername(name))[2]='wallet-funding'
 );
drop policy if exists wallet_funding_receipts_admin_read on storage.objects;
create policy wallet_funding_receipts_admin_read on storage.objects
 for select to authenticated using(
  bucket_id='wallet-funding-receipts'
  and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
 );

create or replace function public.member_submit_wallet_fund_request(
 p_amount numeric,p_payment_reference text,p_receipt_path text
) returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_member public.member_ids%rowtype; v_request public.wallet_fund_requests%rowtype;
 v_reference text:=btrim(coalesce(p_payment_reference,'')); v_wallet_enabled boolean:=false;
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
 if not coalesce(v_wallet_enabled,false) then raise exception 'Main Wallet funding is currently unavailable' using errcode='55000'; end if;
 if exists(select 1 from public.package_activations where upper(btrim(payment_reference))=upper(v_reference)) then
  raise exception 'This UTR / payment reference has already been submitted' using errcode='23505';
 end if;
 select m.* into v_member
 from public.profiles p join public.member_ids m on m.id=p.main_member_id
 where p.id=v_uid and m.id_type='main' and m.status='active' for update of m;
 if not found then raise exception 'An active Main ID is required to add funds' using errcode='55000'; end if;
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

create or replace function public.member_list_my_wallet_fund_requests()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_main uuid; v_result jsonb;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select main_member_id into v_main from public.profiles where id=v_uid;
 if v_main is null then return '[]'::jsonb; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',r.id,'amount',r.amount,'currency',r.currency,'payment_reference',r.payment_reference,
  'status',r.status,'review_note',r.review_note,'created_at',r.created_at,'reviewed_at',r.reviewed_at
 ) order by r.created_at desc,r.id desc),'[]'::jsonb)
 into v_result from public.wallet_fund_requests r where r.member_id=v_main;
 return v_result;
end;
$function$;

create or replace function public.admin_list_pending_wallet_fund_requests()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
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
 v_uid uuid:=auth.uid(); v_request public.wallet_fund_requests%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_balance numeric(14,2);
 v_key text; v_wallet_enabled boolean:=false;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
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
    'amount',v_request.amount,'balance_after',v_balance,'payment_reference',v_request.payment_reference));
  return jsonb_build_object('success',true,'status','approved','wallet_type','income','balance_after',v_balance);
 else
  update public.wallet_fund_requests set status='rejected',reviewed_by=v_uid,reviewed_at=now(),
   review_note=nullif(btrim(coalesce(p_review_note,'')),'') where id=v_request.id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'wallet_fund_request_rejected','wallet_fund_request',v_request.id,
   jsonb_build_object('member_id',v_request.member_id,'amount',v_request.amount,
    'payment_reference',v_request.payment_reference,'review_note',nullif(btrim(coalesce(p_review_note,'')),'')));
  return jsonb_build_object('success',true,'status','rejected');
 end if;
end;
$function$;

revoke all on function public.member_submit_wallet_fund_request(numeric,text,text) from public,anon;
grant execute on function public.member_submit_wallet_fund_request(numeric,text,text) to authenticated;
revoke all on function public.member_list_my_wallet_fund_requests() from public,anon;
grant execute on function public.member_list_my_wallet_fund_requests() to authenticated;
revoke all on function public.admin_list_pending_wallet_fund_requests() from public,anon;
grant execute on function public.admin_list_pending_wallet_fund_requests() to authenticated;
revoke all on function public.admin_review_wallet_fund_request(uuid,boolean,text) from public,anon;
grant execute on function public.admin_review_wallet_fund_request(uuid,boolean,text) to authenticated;
