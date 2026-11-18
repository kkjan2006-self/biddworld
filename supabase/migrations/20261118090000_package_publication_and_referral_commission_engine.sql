-- Package publication and versioned referral commission calculation/posting/reversal.
-- Source-only until canonical TEST baseline replay. No Production database changes.

create or replace function public.admin_activate_referral_plan(p_package_id uuid,p_plan_version_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_rules integer; v_version integer;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 perform 1 from public.packages where id=p_package_id and is_active=false for update;
 if not found then raise exception 'Referral plans can be activated only before package publication' using errcode='55000'; end if;
 select version_number into v_version from public.referral_plan_versions
 where id=p_plan_version_id and package_id=p_package_id for update;
 if not found then raise exception 'Referral plan version does not belong to this package' using errcode='22023'; end if;
 select count(*) into v_rules from public.referral_level_rules where plan_version_id=p_plan_version_id;
 if v_rules<1 or v_rules>20 then raise exception 'A referral plan must contain between 1 and 20 levels' using errcode='22023'; end if;
 if exists(
  select 1 from generate_series(1,v_rules) as expected(level)
  where not exists(select 1 from public.referral_level_rules r where r.plan_version_id=p_plan_version_id and r.level_number=expected.level)
 ) then raise exception 'Referral plan levels must be sequential from level 1' using errcode='22023'; end if;
 update public.referral_plan_versions set is_active=false where package_id=p_package_id and is_active;
 update public.referral_plan_versions set is_active=true where id=p_plan_version_id;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'referral_plan.activated','referral_plan_versions',p_plan_version_id,
  jsonb_build_object('package_id',p_package_id,'version_number',v_version,'level_count',v_rules));
 return jsonb_build_object('success',true,'plan_version_id',p_plan_version_id,'version_number',v_version,'levels',v_rules);
end;
$function$;

create or replace function public.admin_publish_package(p_package_id uuid,p_publish boolean)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_package public.packages%rowtype;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select * into v_package from public.packages where id=p_package_id for update;
 if not found then raise exception 'Package not found' using errcode='P0002'; end if;
 if p_publish is null then raise exception 'A publication state is required' using errcode='22023'; end if;
 if p_publish and not exists(select 1 from public.referral_plan_versions where package_id=p_package_id and is_active) then
  raise exception 'Activate a referral plan version before publishing this package' using errcode='55000';
 end if;
 if v_package.is_active is distinct from p_publish then
  update public.packages set is_active=p_publish,updated_at=now() where id=p_package_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,case when p_publish then 'package.published' else 'package.unpublished' end,
   'packages',p_package_id,jsonb_build_object('package_name',v_package.name,'is_active',p_publish));
 end if;
 return jsonb_build_object('success',true,'package_id',p_package_id,'is_active',p_publish);
end;
$function$;

create or replace function private.create_referral_commissions_for_activation()
returns trigger
language plpgsql security definer set search_path=''
as $function$
declare
 v_plan_id uuid; v_member_id uuid; v_rule record; v_ancestor record; v_amount numeric(14,2); v_commissions_enabled boolean:=false;
begin
 if new.payment_status<>'approved' or new.activation_status<>'active'
   or (old.payment_status='approved' and old.activation_status='active') then
  return new;
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('referral-activation:'||new.id::text,0));
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
  if not exists(select 1 from public.referral_commissions
    where package_activation_id=new.id and plan_version_id=v_plan_id and level_number=v_ancestor.depth) then
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
  perform public.admin_post_referral_commissions(new.id);
 end if;
 return new;
end;
$function$;
revoke all on function private.create_referral_commissions_for_activation() from public,anon,authenticated;
drop trigger if exists create_referral_commissions_after_activation on public.package_activations;
create trigger create_referral_commissions_after_activation
after update of payment_status,activation_status on public.package_activations
for each row execute function private.create_referral_commissions_for_activation();

create or replace function public.admin_post_referral_commissions(p_activation_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_activation public.package_activations%rowtype;
 v_commission public.referral_commissions%rowtype; v_member public.member_ids%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_key text; v_new_balance numeric(14,2);
 v_enabled boolean:=false; v_posted integer:=0; v_existing public.wallet_transactions%rowtype;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 select * into v_activation from public.package_activations where id=p_activation_id for update;
 if not found or v_activation.payment_status<>'approved' or v_activation.activation_status<>'active' then
  raise exception 'Only an approved active package activation can post commissions' using errcode='55000';
 end if;
 select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
 from public.app_settings where setting_key='referral_commissions_enabled';
 if not coalesce(v_enabled,false) then raise exception 'Referral commission posting is disabled' using errcode='55000'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('referral-activation:'||p_activation_id::text,0));
 for v_commission in select * from public.referral_commissions
  where package_activation_id=p_activation_id and status='pending'
  order by level_number,id for update
 loop
  select * into v_member from public.member_ids
  where id=v_commission.credited_main_member_id and id_type='main' and status='active' for share;
  if not found then continue; end if;
  v_key:='referral-commission:'||v_commission.id::text||':credit';
  select * into v_wallet from public.wallet_accounts
  where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
  if not found then raise exception 'Income Wallet is unavailable for Main ID %',v_member.member_code using errcode='55000'; end if;
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
   v_posted:=v_posted+1;continue;
  end if;
  v_new_balance:=v_wallet.balance+v_commission.amount;
  update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
  insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
  values(v_wallet.id,v_commission.credited_main_member_id,'referral_commission','credit',v_commission.amount,
   v_new_balance,'referral_commission',v_commission.id,v_key,'Level '||v_commission.level_number||' referral commission');
  update public.referral_commissions set status='credited' where id=v_commission.id and status='pending';
  v_posted:=v_posted+1;
 end loop;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'referral_commissions.posted','package_activations',p_activation_id,jsonb_build_object('posted_count',v_posted));
 return jsonb_build_object('success',true,'activation_id',p_activation_id,'posted_count',v_posted);
end;
$function$;

create or replace function public.admin_reverse_referral_commission(p_commission_id uuid,p_reason text)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid(); v_commission public.referral_commissions%rowtype;
 v_wallet public.wallet_accounts%rowtype; v_credit_key text; v_reverse_key text;
 v_new_balance numeric(14,2); v_credit public.wallet_transactions%rowtype;
 v_existing public.wallet_transactions%rowtype;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Provide a reversal reason between 5 and 500 characters' using errcode='22023';
 end if;
 select * into v_commission from public.referral_commissions where id=p_commission_id for update;
 if not found then raise exception 'Referral commission not found' using errcode='P0002'; end if;
 if v_commission.status='reversed' then return jsonb_build_object('success',true,'status','reversed','replayed',true); end if;
 if v_commission.status='pending' then
  update public.referral_commissions set status='reversed' where id=p_commission_id;
 else
  v_credit_key:='referral-commission:'||p_commission_id::text||':credit';
  v_reverse_key:='referral-commission:'||p_commission_id::text||':reverse';
  select * into v_wallet from public.wallet_accounts
  where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
  if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
  select * into v_credit from public.wallet_transactions where idempotency_key=v_credit_key;
  if not found
    or v_credit.wallet_account_id is distinct from v_wallet.id
    or v_credit.member_id is distinct from v_commission.credited_main_member_id
    or v_credit.transaction_type is distinct from 'referral_commission'
    or v_credit.direction is distinct from 'credit'
    or v_credit.amount is distinct from v_commission.amount
    or v_credit.reference_type is distinct from 'referral_commission'
    or v_credit.reference_id is distinct from p_commission_id then
   raise exception 'The original referral credit ledger entry is missing or inconsistent; reversal was not applied' using errcode='23514';
  end if;
  select * into v_existing from public.wallet_transactions where idempotency_key=v_reverse_key;
  if found then
   if v_existing.wallet_account_id is distinct from v_wallet.id
     or v_existing.member_id is distinct from v_commission.credited_main_member_id
     or v_existing.transaction_type is distinct from 'referral_commission_reversal'
     or v_existing.direction is distinct from 'debit'
     or v_existing.amount is distinct from v_commission.amount
     or v_existing.reference_type is distinct from 'referral_commission'
     or v_existing.reference_id is distinct from p_commission_id then
    raise exception 'Referral reversal idempotency key conflicts with a different ledger transaction' using errcode='23505';
   end if;
  else
   if v_wallet.balance<v_commission.amount then
    raise exception 'The Income Wallet balance is insufficient for this full reversal; no changes were made' using errcode='23514';
   end if;
   v_new_balance:=v_wallet.balance-v_commission.amount;
   update public.wallet_accounts set balance=v_new_balance,updated_at=now() where id=v_wallet.id;
   insert into public.wallet_transactions(wallet_account_id,member_id,transaction_type,direction,amount,balance_after,reference_type,reference_id,idempotency_key,description)
   values(v_wallet.id,v_commission.credited_main_member_id,'referral_commission_reversal','debit',v_commission.amount,
    v_new_balance,'referral_commission',p_commission_id,v_reverse_key,'Reversal: '||trim(p_reason));
  end if;
  update public.referral_commissions set status='reversed' where id=p_commission_id;
 end if;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'referral_commission.reversed','referral_commissions',p_commission_id,
  jsonb_build_object('reason',trim(p_reason),'amount',v_commission.amount,'previous_status',v_commission.status));
 return jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',false);
end;
$function$;

create or replace function public.admin_list_referral_commissions_page(
 p_limit integer default 100,p_offset integer default 0,p_status text default null,p_level integer default null
)
returns table(
 commission_id uuid,activation_id uuid,level_number integer,beneficiary_member_code text,
 beneficiary_id_type text,credited_main_member_code text,credited_main_name text,
 amount numeric,status text,created_at timestamptz,has_more boolean
)
language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 if p_status is not null and p_status not in ('pending','credited','reversed') then
  raise exception 'Invalid commission status filter' using errcode='22023';
 end if;
 if p_level is not null and (p_level<1 or p_level>20) then raise exception 'Invalid referral level' using errcode='22023'; end if;
 return query
 select c.id,c.package_activation_id,c.level_number,b.member_code,b.id_type,m.member_code,
  coalesce(nullif(p.display_name,''),'Member'),c.amount,c.status,c.created_at,
  count(*) over()>p_offset+p_limit
 from public.referral_commissions c
 join public.member_ids b on b.id=c.beneficiary_member_id
 join public.member_ids m on m.id=c.credited_main_member_id
 left join public.profiles p on p.id=m.owner_user_id
 where (p_status is null or c.status=p_status) and (p_level is null or c.level_number=p_level)
 order by c.created_at desc,c.id desc
 limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_activate_referral_plan(uuid,uuid) from public,anon;
grant execute on function public.admin_activate_referral_plan(uuid,uuid) to authenticated;
revoke all on function public.admin_publish_package(uuid,boolean) from public,anon;
grant execute on function public.admin_publish_package(uuid,boolean) to authenticated;
revoke all on function public.admin_post_referral_commissions(uuid) from public,anon;
grant execute on function public.admin_post_referral_commissions(uuid) to authenticated;
revoke all on function public.admin_reverse_referral_commission(uuid,text) from public,anon;
grant execute on function public.admin_reverse_referral_commission(uuid,text) to authenticated;
revoke all on function public.admin_list_referral_commissions_page(integer,integer,text,integer) from public,anon;
grant execute on function public.admin_list_referral_commissions_page(integer,integer,text,integer) to authenticated;
