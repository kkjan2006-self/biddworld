-- Keep Staff package approvals atomic when Sponsor Referral auto-posting is enabled.
-- The trigger uses a private posting routine with the activation actor recorded
-- for audit; the public manual posting RPC remains Admin-only.
-- Source-only until the complete migration chain is reviewed and an isolated
-- TEST replay is explicitly authorized. Never apply from this source batch.

create or replace function private.post_referral_commissions_for_activation(
 p_activation_id uuid,p_actor_id uuid
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=p_actor_id;
 v_activation public.package_activations%rowtype;
 v_commission public.referral_commissions%rowtype;
 v_member public.member_ids%rowtype;
 v_wallet public.wallet_accounts%rowtype;
 v_key text;
 v_new_balance numeric(14,2);
 v_enabled boolean:=false;
 v_posted integer:=0;
 v_existing public.wallet_transactions%rowtype;
begin
 if v_uid is null then
  raise exception 'Authenticated activation actor required' using errcode='42501';
 end if;
 select * into v_activation from public.package_activations
 where id=p_activation_id for update;
 if not found or v_activation.payment_status<>'approved'
   or v_activation.activation_status<>'active' then
  raise exception 'Only an approved active package activation can post commissions' using errcode='55000';
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='referral_commissions_enabled';
 if not coalesce(v_enabled,false) then
  raise exception 'Referral commission posting is disabled' using errcode='55000';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('referral-activation:'||p_activation_id::text,0)
 );
 for v_commission in
  select * from public.referral_commissions
  where package_activation_id=p_activation_id and status='pending'
  order by level_number,id for update
 loop
  select * into v_member from public.member_ids
  where id=v_commission.credited_main_member_id and id_type='main' and status='active' for share;
  if not found then continue; end if;
  v_key:='referral-commission:'||v_commission.id::text||':credit';
  select * into v_wallet from public.wallet_accounts
  where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
  if not found then
   raise exception 'Income Wallet is unavailable for Main ID %',v_member.member_code using errcode='55000';
  end if;
  select * into v_existing from public.wallet_transactions where idempotency_key=v_key;
  if found then
   if v_existing.wallet_account_id is distinct from v_wallet.id
     or v_existing.member_id is distinct from v_commission.credited_main_member_id
     or v_existing.transaction_type is distinct from 'referral_commission'
     or v_existing.direction is distinct from 'credit'
     or v_existing.amount is distinct from v_commission.amount
     or v_existing.reference_type is distinct from 'referral_commission'
     or v_existing.reference_id is distinct from v_commission.id then
    raise exception 'Referral commission idempotency key conflicts with a different ledger transaction' using errcode='23505';
   end if;
   update public.referral_commissions set status='credited' where id=v_commission.id and status='pending';
   v_posted:=v_posted+1;
   continue;
  end if;
  v_new_balance:=v_wallet.balance+v_commission.amount;
  update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
  insert into public.wallet_transactions(
   wallet_account_id,member_id,transaction_type,direction,amount,balance_after,
   reference_type,reference_id,idempotency_key,description
  ) values(
   v_wallet.id,v_commission.credited_main_member_id,'referral_commission','credit',
   v_commission.amount,v_new_balance,'referral_commission',v_commission.id,v_key,
   'Level '||v_commission.level_number||' referral commission'
  );
  update public.referral_commissions set status='credited' where id=v_commission.id and status='pending';
  v_posted:=v_posted+1;
 end loop;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'referral_commissions.posted','package_activations',p_activation_id,
  jsonb_build_object('posted_count',v_posted));
 return jsonb_build_object('success',true,'activation_id',p_activation_id,'posted_count',v_posted);
end;
$function$;
revoke all on function private.post_referral_commissions_for_activation(uuid,uuid)
 from public,anon,authenticated;

-- Public/manual posting remains strictly Admin-only; the protected internal
-- routine is shared with the activation trigger without widening public access.
create or replace function public.admin_post_referral_commissions(p_activation_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 return private.post_referral_commissions_for_activation(p_activation_id,v_uid);
end;
$function$;
revoke all on function public.admin_post_referral_commissions(uuid) from public,anon;
grant execute on function public.admin_post_referral_commissions(uuid) to authenticated;

-- The trigger keeps the existing referral calculation, level cap, eligibility,
-- duplicate prevention and feature switch. Only the internal posting target
-- changes so an explicitly authorized Staff approval can complete atomically.
create or replace function private.create_referral_commissions_for_activation()
returns trigger
language plpgsql security definer set search_path=''
as $function$
declare
 v_plan_id uuid;
 v_member_id uuid;
 v_rule record;
 v_ancestor record;
 v_amount numeric(14,2);
 v_commissions_enabled boolean:=false;
begin
 if new.payment_status<>'approved' or new.activation_status<>'active'
   or (old.payment_status='approved' and old.activation_status='active') then
  return new;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('referral-activation:'||new.id::text,0)
 );
 select id into v_member_id from public.member_ids
 where id=new.member_id and id_type='main' and status='active';
 if v_member_id is null then return new; end if;
 select id into v_plan_id from public.referral_plan_versions
 where package_id=new.package_id and is_active=true
 order by version_number desc,id desc limit 1;
 if v_plan_id is null then return new; end if;

 for v_ancestor in
  with recursive ancestors(traversal_member_id,beneficiary_member_id,credited_main_member_id,depth,path) as (
   select r.referrer_member_id,coalesce(r.source_member_id,r.referrer_member_id),
    case when source.id_type='duplicate' then source.main_member_id else source.id end,
    1,array[v_member_id,r.referrer_member_id]
   from public.referrals r
   join public.member_ids source on source.id=coalesce(r.source_member_id,r.referrer_member_id)
   where r.referred_member_id=v_member_id and r.referrer_member_id is not null
   union all
   select r.referrer_member_id,coalesce(r.source_member_id,r.referrer_member_id),
    case when source.id_type='duplicate' then source.main_member_id else source.id end,
    a.depth+1,a.path||r.referrer_member_id
   from ancestors a
   join public.referrals r on r.referred_member_id=a.traversal_member_id
   join public.member_ids source on source.id=coalesce(r.source_member_id,r.referrer_member_id)
   where r.referrer_member_id is not null and a.depth<20
    and not r.referrer_member_id=any(a.path)
  )
  select a.*,beneficiary.id_type as beneficiary_id_type,credited.id_type as credited_id_type,
   credited.status as credited_status
  from ancestors a
  join public.member_ids beneficiary on beneficiary.id=a.beneficiary_member_id
  join public.member_ids credited on credited.id=a.credited_main_member_id
  where credited.id_type='main' and credited.status='active'
  order by a.depth
 loop
  select * into v_rule from public.referral_level_rules
  where plan_version_id=v_plan_id and level_number=v_ancestor.depth;
  if not found then continue; end if;
  if coalesce((v_rule.eligibility_rule->>'requires_active_main_id')::boolean,true)
    and v_ancestor.credited_status<>'active' then continue; end if;
  if coalesce((v_rule.eligibility_rule->>'max_depth')::integer,v_ancestor.depth)<v_ancestor.depth then continue; end if;
  v_amount:=case when v_rule.reward_type='fixed' then v_rule.reward_value
   when v_rule.reward_type='percentage' then round(new.amount_paid*v_rule.reward_value/100,2)
   else 0 end;
  if v_amount<=0 then continue; end if;
  if not exists(
   select 1 from public.referral_commissions
   where package_activation_id=new.id and plan_version_id=v_plan_id and level_number=v_ancestor.depth
  ) then
   insert into public.referral_commissions(
    package_activation_id,plan_version_id,level_number,beneficiary_member_id,
    credited_main_member_id,amount,status
   ) values(new.id,v_plan_id,v_ancestor.depth,v_ancestor.beneficiary_member_id,
    v_ancestor.credited_main_member_id,v_amount,'pending');
  end if;
 end loop;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_commissions_enabled
 from public.app_settings where setting_key='referral_commissions_enabled';
 if coalesce(v_commissions_enabled,false) then
  perform private.post_referral_commissions_for_activation(new.id,auth.uid());
 end if;
 return new;
end;
$function$;
revoke all on function private.create_referral_commissions_for_activation() from public,anon,authenticated;
