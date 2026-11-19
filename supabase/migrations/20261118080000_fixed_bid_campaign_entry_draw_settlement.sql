-- Fixed Bid campaign configuration, member entry, winner draw, refunds and winner settlement.
-- Source-only migration. Apply only after the canonical TEST baseline is established.
-- All member financial writes remain subject to existing feature and owner-approval guards.

create table if not exists public.fixed_bid_draws (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null unique references public.fixed_bid_campaigns(id),
  draw_seed uuid not null,
  winner_entry_ids uuid[] not null default '{}',
  winner_member_ids uuid[] not null default '{}',
  winner_count integer not null check (winner_count > 0),
  refunded_entry_count integer not null default 0 check (refunded_entry_count >= 0),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
alter table public.fixed_bid_draws enable row level security;
revoke all on public.fixed_bid_draws from public, anon, authenticated;

create or replace function public.admin_list_fixed_bid_campaigns()
returns table(
 campaign_id uuid, product_id uuid, product_name text, title text,
 description text, status text, configuration jsonb,
 created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return query
 select c.id,c.product_id,p.name,c.title,c.description,c.status,c.configuration,c.created_at,c.updated_at
 from public.fixed_bid_campaigns c
 join public.products p on p.id=c.product_id
 order by c.created_at desc,c.id desc;
end;
$function$;

create or replace function public.admin_save_fixed_bid_campaign(
 p_campaign_id uuid,
 p_product_id uuid,
 p_title text,
 p_description text,
 p_entry_amount numeric,
 p_winner_payment_amount numeric,
 p_max_entries_per_member integer,
 p_max_entries_total integer,
 p_winner_count integer,
 p_starts_at timestamptz,
 p_ends_at timestamptz,
 p_refund_non_winners boolean
) returns uuid
language plpgsql security definer set search_path=''
as $function$
declare v_id uuid; v_config jsonb;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_product_id is null or not exists(select 1 from public.products where id=p_product_id and status='draft') then
  raise exception 'Select an existing draft product' using errcode='22023';
 end if;
 if length(trim(coalesce(p_title,'')))<3 or length(trim(p_title))>180 then
  raise exception 'Campaign title must be 3 to 180 characters' using errcode='22023';
 end if;
 if p_entry_amount is null or p_entry_amount<=0 or p_entry_amount>10000000
   or p_winner_payment_amount is null or p_winner_payment_amount<=0 or p_winner_payment_amount>10000000 then
  raise exception 'Entry and winner payment amounts must be greater than zero and within the supported limit' using errcode='22023';
 end if;
 if p_max_entries_per_member is null or p_max_entries_per_member<1 or p_max_entries_per_member>1000
   or p_max_entries_total is null or p_max_entries_total<1 or p_max_entries_total>1000000
   or p_winner_count is null or p_winner_count<1 or p_winner_count>p_max_entries_total then
  raise exception 'Invalid participant, entry or winner limits' using errcode='22023';
 end if;
 if p_starts_at is null or p_ends_at is null or p_ends_at<=p_starts_at then
  raise exception 'A valid campaign start and end time is required' using errcode='22023';
 end if;
 v_config:=jsonb_build_object(
  'entry_amount',p_entry_amount,
  'winner_payment_amount',p_winner_payment_amount,
  'max_entries_per_member',p_max_entries_per_member,
  'max_entries_total',p_max_entries_total,
  'winner_count',p_winner_count,
  'starts_at',p_starts_at,
  'ends_at',p_ends_at,
  'refund_non_winners',coalesce(p_refund_non_winners,false)
 );
 if p_campaign_id is null then
  insert into public.fixed_bid_campaigns(product_id,title,description,status,configuration)
  values(p_product_id,trim(p_title),nullif(trim(coalesce(p_description,'')),''),'draft',v_config)
  returning id into v_id;
 else
  update public.fixed_bid_campaigns
  set product_id=p_product_id,title=trim(p_title),
      description=nullif(trim(coalesce(p_description,'')),''),configuration=v_config,updated_at=now()
  where id=p_campaign_id and status='draft'
    and not exists(select 1 from public.fixed_bids where campaign_id=p_campaign_id)
  returning id into v_id;
  if v_id is null then raise exception 'Only an unused draft campaign can be edited' using errcode='55000'; end if;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),case when p_campaign_id is null then 'fixed_bid.draft_created' else 'fixed_bid.draft_updated' end,
  'fixed_bid_campaigns',v_id,v_config||jsonb_build_object('title',trim(p_title),'status','draft'));
 return v_id;
end;
$function$;

create or replace function public.admin_set_fixed_bid_campaign_status(p_campaign_id uuid,p_status text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_campaign public.fixed_bid_campaigns%rowtype; v_start timestamptz; v_end timestamptz;
 v_enabled boolean:=false; v_entry record; v_debit record; v_wallet public.wallet_accounts%rowtype;
 v_existing public.wallet_transactions%rowtype;
 v_new_balance numeric(14,2); v_refunded integer:=0; v_refund_key text; v_debit_total numeric(14,2);
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_status is null or p_status not in ('scheduled','live','paused','ended','cancelled') then
  raise exception 'Unsupported Fixed Bid campaign status' using errcode='22023';
 end if;
 select * into v_campaign from public.fixed_bid_campaigns where id=p_campaign_id for update;
 if not found then raise exception 'Campaign not found' using errcode='P0002'; end if;
 v_start:=nullif(v_campaign.configuration->>'starts_at','')::timestamptz;
 v_end:=nullif(v_campaign.configuration->>'ends_at','')::timestamptz;
 if p_status in ('scheduled','live') then
  if not exists(select 1 from public.products where id=v_campaign.product_id and status='published') then
   raise exception 'Publish the linked product before scheduling a campaign' using errcode='55000';
  end if;
  if v_start is null or v_end is null or v_end<=v_start then
   raise exception 'Campaign schedule is incomplete' using errcode='22023';
  end if;
  if p_status='scheduled' and v_start<=now() then
   raise exception 'A scheduled campaign must start in the future' using errcode='22023';
  end if;
  if p_status='live' and not (now()>=v_start and now()<v_end) then
   raise exception 'A campaign can be opened only within its configured time window' using errcode='55000';
  end if;
  select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
  from public.app_settings where setting_key='fixed_bid_enabled';
  if not coalesce(v_enabled,false) then raise exception 'Fixed Bid participation is disabled in Platform Settings' using errcode='55000'; end if;
 end if;
 if p_status='ended' and v_end is not null and now()<v_end then
  raise exception 'The campaign cannot be ended before its configured close time' using errcode='55000';
 end if;
 if v_campaign.status in ('ended','cancelled') then raise exception 'A closed campaign cannot be reopened or changed' using errcode='55000'; end if;
 if p_status='cancelled' then
  if exists(select 1 from public.winning_item_payments
    where fixed_bid_campaign_id=p_campaign_id and status='paid') then
   raise exception 'A campaign with a paid winner item cannot be cancelled' using errcode='55000';
  end if;
  for v_entry in
   select id,member_id,bid_amount from public.fixed_bids
   where campaign_id=p_campaign_id and status in ('submitted','accepted')
   order by id for update
  loop
   v_debit_total:=0;
   for v_debit in
    select wallet_account_id,member_id,transaction_type,direction,amount,reference_type,reference_id
    from public.wallet_transactions
    where reference_type='fixed_bid_entry' and reference_id=v_entry.id and direction='debit'
    order by wallet_account_id
   loop
    select * into v_wallet from public.wallet_accounts where id=v_debit.wallet_account_id for update;
    if not found or v_wallet.member_id is distinct from v_entry.member_id
      or v_wallet.wallet_type not in ('bid','income')
      or v_debit.member_id is distinct from v_entry.member_id
      or v_debit.transaction_type is distinct from 'fixed_bid_entry'
      or v_debit.direction is distinct from 'debit'
      or v_debit.reference_type is distinct from 'fixed_bid_entry'
      or v_debit.reference_id is distinct from v_entry.id
      or v_debit.amount is null or v_debit.amount<=0 then
     raise exception 'Original Fixed Bid debit ledger does not match the entry owner and wallet; cancellation was rolled back' using errcode='23514';
    end if;
    v_debit_total:=v_debit_total+v_debit.amount;
    v_refund_key:='fixed-bid:'||v_entry.id::text||':refund:'||v_wallet.id::text;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_refund_key;
    if found then
     if v_existing.wallet_account_id is distinct from v_wallet.id
       or v_existing.member_id is distinct from v_entry.member_id
       or v_existing.transaction_type is distinct from 'fixed_bid_refund'
       or v_existing.direction is distinct from 'credit'
       or v_existing.amount is distinct from v_debit.amount
       or v_existing.reference_type is distinct from 'fixed_bid_entry'
       or v_existing.reference_id is distinct from v_entry.id then
      raise exception 'Fixed Bid refund idempotency key conflicts with a different ledger transaction' using errcode='23505';
     end if;
    else
     v_new_balance:=v_wallet.balance+v_debit.amount;
     update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
     insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
     values(v_wallet.id,v_entry.member_id,'fixed_bid_refund','credit',v_debit.amount,v_new_balance,
      'fixed_bid_entry',v_entry.id,v_refund_key,'Refund for cancelled Fixed Bid campaign entry');
    end if;
   end loop;
   if v_debit_total<>v_entry.bid_amount then
    raise exception 'Entry debit ledger does not reconcile to its recorded amount; cancellation was rolled back' using errcode='55000';
   end if;
   update public.fixed_bids set status='voided' where id=v_entry.id;
   v_refunded:=v_refunded+1;
  end loop;
 end if;
 update public.fixed_bid_campaigns set status=p_status,updated_at=now() where id=p_campaign_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(auth.uid(),'fixed_bid.status_changed','fixed_bid_campaigns',p_campaign_id,
  jsonb_build_object('from',v_campaign.status,'to',p_status,'refunded_entries',v_refunded));
 return jsonb_build_object('campaign_id',p_campaign_id,'status',p_status,'refunded_entries',v_refunded);
end;
$function$;

create or replace function public.member_join_fixed_bid_campaign(p_campaign_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_member_id uuid; v_campaign public.fixed_bid_campaigns%rowtype;
 v_bid_wallet public.wallet_accounts%rowtype; v_income_wallet public.wallet_accounts%rowtype;
 v_entry_id uuid; v_amount numeric(14,2); v_bid_debit numeric(14,2); v_income_debit numeric(14,2);
 v_max_member integer; v_max_total integer; v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_enabled boolean:=false;
 v_existing_entry public.fixed_bids%rowtype;
 v_existing_debit record; v_existing_wallet public.wallet_accounts%rowtype;
 v_existing_debit_total numeric(14,2):=0;
 v_existing_bid_debit numeric(14,2):=0; v_existing_income_debit numeric(14,2):=0;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid entry request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select m.id into v_member_id
 from public.member_ids m
 join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id
 where m.owner_user_id=v_uid and m.id_type='main' and m.status='active' and p.status='active'
 order by m.created_at,m.id limit 1;
 if v_member_id is null then raise exception 'An active Main ID is required' using errcode='42501'; end if;
 select * into v_campaign from public.fixed_bid_campaigns where id=p_campaign_id for update;
 if not found then raise exception 'Campaign not found' using errcode='P0002'; end if;
 select * into v_existing_entry from public.fixed_bids
 where idempotency_key=v_key for update;
 if found then
  if v_existing_entry.member_id is distinct from v_member_id
    or v_existing_entry.campaign_id is distinct from p_campaign_id
    or v_existing_entry.status not in ('submitted','accepted') then
   raise exception 'This request key was already used for a different or closed entry' using errcode='23505';
  end if;
  for v_existing_debit in
   select wallet_account_id,member_id,transaction_type,direction,amount,reference_type,reference_id,idempotency_key
   from public.wallet_transactions
   where idempotency_key in (v_key||':bid',v_key||':income')
   order by idempotency_key
  loop
   select * into v_existing_wallet from public.wallet_accounts where id=v_existing_debit.wallet_account_id;
   if not found
     or v_existing_debit.member_id is distinct from v_member_id
     or v_existing_debit.transaction_type is distinct from 'fixed_bid_entry'
     or v_existing_debit.direction is distinct from 'debit'
     or v_existing_debit.amount is null or v_existing_debit.amount<=0
     or v_existing_debit.reference_type is distinct from 'fixed_bid_entry'
     or v_existing_debit.reference_id is distinct from v_existing_entry.id
     or v_existing_wallet.member_id is distinct from v_member_id
     or (v_existing_debit.idempotency_key=v_key||':bid' and v_existing_wallet.wallet_type is distinct from 'bid')
     or (v_existing_debit.idempotency_key=v_key||':income' and v_existing_wallet.wallet_type is distinct from 'income') then
    raise exception 'Existing Fixed Bid entry ledger is missing or inconsistent; retry was not accepted' using errcode='23514';
   end if;
   v_existing_debit_total:=v_existing_debit_total+v_existing_debit.amount;
   if v_existing_debit.idempotency_key=v_key||':bid' then
    v_existing_bid_debit:=v_existing_debit.amount;
   else
    v_existing_income_debit:=v_existing_debit.amount;
   end if;
  end loop;
  if v_existing_debit_total<>v_existing_entry.bid_amount then
   raise exception 'Existing Fixed Bid entry ledger does not reconcile to the recorded amount' using errcode='23514';
  end if;
  return jsonb_build_object('success',true,'entry_id',v_existing_entry.id,
   'entry_amount',v_existing_entry.bid_amount,'bid_wallet_debit',v_existing_bid_debit,
   'income_wallet_debit',v_existing_income_debit,'replayed',true);
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='fixed_bid_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Fixed Bid participation is disabled' using errcode='55000'; end if;
 if v_campaign.status<>'live'
   or now()<nullif(v_campaign.configuration->>'starts_at','')::timestamptz
   or now()>=nullif(v_campaign.configuration->>'ends_at','')::timestamptz then
  raise exception 'This Fixed Bid campaign is not open for entries' using errcode='55000';
 end if;
 v_amount:=nullif(v_campaign.configuration->>'entry_amount','')::numeric;
 v_max_member:=coalesce(nullif(v_campaign.configuration->>'max_entries_per_member','')::integer,1);
 v_max_total:=coalesce(nullif(v_campaign.configuration->>'max_entries_total','')::integer,0);
 if v_amount is null or v_amount<=0 or v_max_member<1 or v_max_total<1 then
  raise exception 'Campaign entry rules are incomplete' using errcode='55000';
 end if;
 if (select count(*) from public.fixed_bids where campaign_id=p_campaign_id and status in ('submitted','accepted'))>=v_max_total then
  raise exception 'This campaign has reached its entry limit' using errcode='55000';
 end if;
 if (select count(*) from public.fixed_bids where campaign_id=p_campaign_id and member_id=v_member_id and status in ('submitted','accepted'))>=v_max_member then
  raise exception 'You have reached your entry limit for this campaign' using errcode='55000';
 end if;
 select * into v_bid_wallet from public.wallet_accounts where member_id=v_member_id and wallet_type='bid' for update;
 select * into v_income_wallet from public.wallet_accounts where member_id=v_member_id and wallet_type='income' for update;
 if v_bid_wallet.id is null or v_income_wallet.id is null then raise exception 'Member wallets are unavailable' using errcode='55000'; end if;
 v_bid_debit:=least(v_bid_wallet.balance,v_amount);
 v_income_debit:=v_amount-v_bid_debit;
 if v_income_wallet.balance<v_income_debit then raise exception 'Insufficient Funds – Please Add Funds' using errcode='23514'; end if;
 insert into public.fixed_bids(campaign_id,member_id,bid_amount,status,idempotency_key)
 values(p_campaign_id,v_member_id,v_amount,'accepted',v_key) returning id into v_entry_id;
 update public.wallet_accounts set balance=balance-v_bid_debit,updated_at=now() where id=v_bid_wallet.id;
 update public.wallet_accounts set balance=balance-v_income_debit,updated_at=now() where id=v_income_wallet.id;
 if v_bid_debit>0 then
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_bid_wallet.id,v_member_id,'fixed_bid_entry','debit',v_bid_debit,v_bid_wallet.balance-v_bid_debit,'fixed_bid_entry',v_entry_id,v_key||':bid','Fixed Bid entry from Bid Wallet');
 end if;
 if v_income_debit>0 then
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_income_wallet.id,v_member_id,'fixed_bid_entry','debit',v_income_debit,v_income_wallet.balance-v_income_debit,'fixed_bid_entry',v_entry_id,v_key||':income','Fixed Bid entry from Income Wallet');
 end if;
 return jsonb_build_object('success',true,'entry_id',v_entry_id,'entry_amount',v_amount,'bid_wallet_debit',v_bid_debit,'income_wallet_debit',v_income_debit,'replayed',false);
end;
$function$;

create or replace function public.admin_draw_fixed_bid_winners(p_campaign_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_campaign public.fixed_bid_campaigns%rowtype;
 v_seed uuid:=gen_random_uuid(); v_seed_key bigint; v_winner_count integer;
 v_draw public.fixed_bid_draws%rowtype;
 v_winner_entries uuid[]:='{}'; v_winner_members uuid[]:='{}';
 v_entry record; v_payment_amount numeric(14,2); v_refund boolean:=false;
 v_refund_count integer:=0; v_debit record; v_wallet public.wallet_accounts%rowtype; v_existing public.wallet_transactions%rowtype; v_refund_key text; v_new_balance numeric(14,2); v_debit_total numeric(14,2);
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select * into v_campaign from public.fixed_bid_campaigns where id=p_campaign_id for update;
 if not found then raise exception 'Campaign not found' using errcode='P0002'; end if;
 if v_campaign.status<>'ended' then raise exception 'Only an ended campaign can be drawn' using errcode='55000'; end if;
 select * into v_draw from public.fixed_bid_draws where campaign_id=p_campaign_id;
 if found then
  return jsonb_build_object('success',true,'campaign_id',p_campaign_id,'draw_id',v_draw.id,
   'winner_count',v_draw.winner_count,'winner_entry_ids',v_draw.winner_entry_ids,
   'winner_member_ids',v_draw.winner_member_ids,'replayed',true);
 end if;
 v_winner_count:=coalesce(nullif(v_campaign.configuration->>'winner_count','')::integer,0);
 v_payment_amount:=nullif(v_campaign.configuration->>'winner_payment_amount','')::numeric;
 v_refund:=coalesce((v_campaign.configuration->>'refund_non_winners')::boolean,false);
 if v_winner_count<1 or v_payment_amount is null or v_payment_amount<=0 then
  raise exception 'Winner rules are incomplete' using errcode='55000';
 end if;
 v_seed_key:=pg_catalog.hashtextextended(v_seed::text,0);
 for v_entry in
  with best_entry_per_member as (
   select distinct on (fb.member_id) fb.id,fb.member_id,
    pg_catalog.hashtextextended(fb.id::text,v_seed_key) as draw_score
   from public.fixed_bids fb
   join public.member_ids m on m.id=fb.member_id and m.id_type='main' and m.status='active'
   join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id and p.status='active'
   where fb.campaign_id=p_campaign_id and fb.status in ('submitted','accepted')
   order by fb.member_id,pg_catalog.hashtextextended(fb.id::text,v_seed_key)
  ), ranked as (
   select id,member_id,draw_score,row_number() over(order by draw_score,member_id) as position
   from best_entry_per_member
  )
  select id,member_id from ranked where position<=v_winner_count order by position
 loop
  v_winner_entries:=array_append(v_winner_entries,v_entry.id);
  v_winner_members:=array_append(v_winner_members,v_entry.member_id);
  insert into public.winning_item_payments(fixed_bid_campaign_id,winner_member_id,amount,status)
  values(p_campaign_id,v_entry.member_id,v_payment_amount,'pending');
 end loop;
 if coalesce(array_length(v_winner_members,1),0)=0 then raise exception 'No eligible entries are available for the draw' using errcode='55000'; end if;
 insert into public.fixed_bid_draws(campaign_id,draw_seed,winner_entry_ids,winner_member_ids,winner_count,created_by)
 values(p_campaign_id,v_seed,v_winner_entries,v_winner_members,array_length(v_winner_members,1),v_uid);
 if v_refund then
  for v_entry in
   select id,member_id,bid_amount,idempotency_key from public.fixed_bids
   where campaign_id=p_campaign_id and status in ('submitted','accepted')
    and not (member_id=any(v_winner_members))
   order by id
  loop
   v_debit_total:=0;
   for v_debit in
    select wallet_account_id,member_id,transaction_type,direction,amount,reference_type,reference_id,idempotency_key
    from public.wallet_transactions
    where reference_type='fixed_bid_entry' and reference_id=v_entry.id and direction='debit'
    order by created_at,wallet_account_id
   loop
    select * into v_wallet from public.wallet_accounts where id=v_debit.wallet_account_id for update;
    if not found
      or v_wallet.member_id is distinct from v_entry.member_id
      or v_wallet.wallet_type not in ('bid','income')
      or v_debit.member_id is distinct from v_entry.member_id
      or v_debit.transaction_type is distinct from 'fixed_bid_entry'
      or v_debit.direction is distinct from 'debit'
      or v_debit.reference_type is distinct from 'fixed_bid_entry'
      or v_debit.reference_id is distinct from v_entry.id
      or v_debit.idempotency_key not in (v_entry.idempotency_key||':bid',v_entry.idempotency_key||':income')
      or (v_debit.idempotency_key=v_entry.idempotency_key||':bid' and v_wallet.wallet_type is distinct from 'bid')
      or (v_debit.idempotency_key=v_entry.idempotency_key||':income' and v_wallet.wallet_type is distinct from 'income')
      or v_debit.amount is null or v_debit.amount<=0 then
     raise exception 'Original entry wallet debit is inconsistent; draw was rolled back' using errcode='23514';
    end if;
    v_debit_total:=v_debit_total+v_debit.amount;
    v_refund_key:='fixed-bid:'||v_entry.id::text||':refund:'||v_wallet.id::text;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_refund_key;
    if found then
     if v_existing.wallet_account_id is distinct from v_wallet.id
       or v_existing.member_id is distinct from v_entry.member_id
       or v_existing.transaction_type is distinct from 'fixed_bid_refund'
       or v_existing.direction is distinct from 'credit'
       or v_existing.amount is distinct from v_debit.amount
       or v_existing.reference_type is distinct from 'fixed_bid_entry'
       or v_existing.reference_id is distinct from v_entry.id then
      raise exception 'Fixed Bid refund idempotency key conflicts with a different ledger transaction' using errcode='23505';
     end if;
    else
     v_new_balance:=v_wallet.balance+v_debit.amount;
     update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
     insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
     values(v_wallet.id,v_entry.member_id,'fixed_bid_refund','credit',v_debit.amount,v_new_balance,'fixed_bid_entry',v_entry.id,
      v_refund_key,'Refund for non-winning Fixed Bid entry');
    end if;
   end loop;
   if v_debit_total<>v_entry.bid_amount then
    raise exception 'Entry debit ledger does not reconcile to its recorded amount; draw was rolled back' using errcode='55000';
   end if;
   update public.fixed_bids set status='voided' where id=v_entry.id;
   v_refund_count:=v_refund_count+1;
  end loop;
 end if;
 update public.fixed_bid_campaigns set updated_at=now() where id=p_campaign_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'fixed_bid.draw_completed','fixed_bid_campaigns',p_campaign_id,
  jsonb_build_object('draw_id',(select id from public.fixed_bid_draws where campaign_id=p_campaign_id),
   'winner_count',array_length(v_winner_members,1),'winner_member_ids',v_winner_members,
   'refunded_non_winner_entries',v_refund_count,'seed',v_seed));
 return jsonb_build_object('success',true,'campaign_id',p_campaign_id,
  'winner_count',array_length(v_winner_members,1),'refunded_entries',v_refund_count);
end;
$function$;

create or replace function public.member_pay_fixed_bid_winning_payment(p_payment_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_main uuid; v_payment public.winning_item_payments%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_tx public.wallet_transactions%rowtype;
 v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_enabled boolean:=false; v_new_balance numeric(14,2);
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then raise exception 'A valid payment request key is required' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select p.main_member_id into v_main
 from public.profiles p
 join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id
 where p.id=v_uid and p.status='active' and m.id_type='main' and m.status='active';
 if v_main is null then raise exception 'An active member profile and Main ID are required' using errcode='42501'; end if;
 select * into v_payment from public.winning_item_payments
 where id=p_payment_id and fixed_bid_campaign_id is not null and winner_member_id=v_main for update;
 if not found then raise exception 'Fixed Bid winner payment not found' using errcode='P0002'; end if;
 select * into v_tx from public.wallet_transactions where idempotency_key=v_key;
 if found then
  if v_tx.member_id is distinct from v_main
    or v_tx.transaction_type is distinct from 'winning_item_payment'
    or v_tx.direction is distinct from 'debit'
    or v_tx.amount is distinct from v_payment.amount
    or v_tx.reference_type is distinct from 'winning_item_payment'
    or v_tx.reference_id is distinct from p_payment_id
    or not exists(select 1 from public.wallet_accounts w
      where w.id=v_tx.wallet_account_id and w.member_id=v_main and w.wallet_type='income') then
   raise exception 'This payment request key conflicts with a different ledger transaction' using errcode='23505';
  end if;
  return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','replayed',true);
 end if;
 if v_payment.status<>'pending' then raise exception 'This winning payment is no longer pending' using errcode='55000'; end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='winning_payment_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Winner payment is disabled' using errcode='55000'; end if;
 select * into v_wallet from public.wallet_accounts
 where member_id=v_main and wallet_type='income' for update;
 if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
 if v_wallet.balance<v_payment.amount then raise exception 'Insufficient Funds – Please Add Funds' using errcode='23514'; end if;
 v_new_balance:=v_wallet.balance-v_payment.amount;
 update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
 insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
 values(v_wallet.id,v_main,'winning_item_payment','debit',v_payment.amount,v_new_balance,'winning_item_payment',p_payment_id,v_key,'Fixed Bid winning payment from Income Wallet');
 update public.winning_item_payments set status='paid',paid_at=now() where id=p_payment_id;
 return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','income_wallet_balance',v_new_balance,'replayed',false);
end;
$function$;

revoke all on function public.admin_list_fixed_bid_campaigns() from public,anon;
grant execute on function public.admin_list_fixed_bid_campaigns() to authenticated;
revoke all on function public.admin_save_fixed_bid_campaign(uuid,uuid,text,text,numeric,numeric,integer,integer,integer,timestamptz,timestamptz,boolean) from public,anon;
grant execute on function public.admin_save_fixed_bid_campaign(uuid,uuid,text,text,numeric,numeric,integer,integer,integer,timestamptz,timestamptz,boolean) to authenticated;
revoke all on function public.admin_set_fixed_bid_campaign_status(uuid,text) from public,anon;
grant execute on function public.admin_set_fixed_bid_campaign_status(uuid,text) to authenticated;
revoke all on function public.member_join_fixed_bid_campaign(uuid,text) from public,anon;
grant execute on function public.member_join_fixed_bid_campaign(uuid,text) to authenticated;
revoke all on function public.admin_draw_fixed_bid_winners(uuid) from public,anon;
grant execute on function public.admin_draw_fixed_bid_winners(uuid) to authenticated;
revoke all on function public.member_pay_fixed_bid_winning_payment(uuid,text) from public,anon;
grant execute on function public.member_pay_fixed_bid_winning_payment(uuid,text) to authenticated;

-- Shared winner settlement endpoint for both Auction and Fixed Bid awards.
-- The only debit source is the winner's Income Wallet.
create or replace function public.member_pay_winning_item_payment(p_payment_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_main uuid; v_payment public.winning_item_payments%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_key text:=btrim(coalesce(p_idempotency_key,''));
 v_enabled boolean:=false; v_new_balance numeric(14,2); v_tx public.wallet_transactions%rowtype;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid payment request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_key,0));
 select p.main_member_id into v_main
 from public.profiles p
 join public.member_ids m on m.id=p.main_member_id and m.owner_user_id=p.id
 where p.id=v_uid and p.status='active' and m.id_type='main' and m.status='active';
 if v_main is null then raise exception 'An active member profile and Main ID are required' using errcode='42501'; end if;
 select * into v_payment from public.winning_item_payments
 where id=p_payment_id and winner_member_id=v_main for update;
 if not found then raise exception 'Winning payment not found' using errcode='P0002'; end if;
 select * into v_tx from public.wallet_transactions where idempotency_key=v_key;
 if found then
  if v_tx.reference_type='winning_item_payment'
    and v_tx.reference_id=p_payment_id
    and v_tx.member_id=v_main
    and v_tx.transaction_type='winning_item_payment'
    and v_tx.direction='debit'
    and v_tx.amount=v_payment.amount
    and exists(select 1 from public.wallet_accounts w
      where w.id=v_tx.wallet_account_id and w.member_id=v_main and w.wallet_type='income') then
   return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','replayed',true);
  end if;
  raise exception 'This payment request key conflicts with a different ledger transaction' using errcode='23505';
 end if;
 if v_payment.status<>'pending' then raise exception 'This winning payment is no longer pending' using errcode='55000'; end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='winning_payment_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Winner payment is disabled' using errcode='55000'; end if;
 select * into v_wallet from public.wallet_accounts
 where member_id=v_main and wallet_type='income' for update;
 if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
 if v_wallet.balance<v_payment.amount then raise exception 'Insufficient Funds – Please Add Funds' using errcode='23514'; end if;
 v_new_balance:=v_wallet.balance-v_payment.amount;
 update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
 insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
 values(v_wallet.id,v_main,'winning_item_payment','debit',v_payment.amount,v_new_balance,'winning_item_payment',p_payment_id,v_key,
  case when v_payment.fixed_bid_campaign_id is not null then 'Fixed Bid winning payment from Income Wallet' else 'Auction winning payment from Income Wallet' end);
 update public.winning_item_payments set status='paid',paid_at=now() where id=p_payment_id;
 return jsonb_build_object('success',true,'payment_id',p_payment_id,'status','paid','income_wallet_balance',v_new_balance,'replayed',false);
end;
$function$;
revoke all on function public.member_pay_winning_item_payment(uuid,text) from public,anon;
grant execute on function public.member_pay_winning_item_payment(uuid,text) to authenticated;
