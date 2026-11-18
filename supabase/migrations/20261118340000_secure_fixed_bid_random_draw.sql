-- Replace non-cryptographic Fixed Bid winner ranking with seeded SHA-256 scores.
-- Existing draw rows remain immutable; this affects future draws only.
-- Uses the already-installed pgcrypto extension in the extensions schema.

create or replace function public.admin_draw_fixed_bid_winners(p_campaign_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_campaign public.fixed_bid_campaigns%rowtype;
 v_seed uuid:=gen_random_uuid(); v_winner_count integer;
 v_draw public.fixed_bid_draws%rowtype;
 v_winner_entries uuid[]:='{}'; v_winner_members uuid[]:='{}';
 v_entry record; v_payment_amount numeric(14,2); v_refund boolean:=false;
 v_refund_count integer:=0; v_debit record; v_wallet public.wallet_accounts%rowtype; v_new_balance numeric(14,2); v_debit_total numeric(14,2);
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
 for v_entry in
  with best_entry_per_member as (
   select distinct on (fb.member_id) fb.id,fb.member_id,
    extensions.digest(pg_catalog.uuid_send(v_seed)||pg_catalog.uuid_send(fb.id),'sha256') as draw_score
   from public.fixed_bids fb
   join public.member_ids m on m.id=fb.member_id and m.id_type='main' and m.status='active'
   join public.profiles p on p.id=m.owner_user_id and p.main_member_id=m.id and p.status='active'
   where fb.campaign_id=p_campaign_id and fb.status in ('submitted','accepted')
   order by fb.member_id,extensions.digest(pg_catalog.uuid_send(v_seed)||pg_catalog.uuid_send(fb.id),'sha256')
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
