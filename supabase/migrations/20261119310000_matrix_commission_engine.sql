-- Matrix commissions are independent of Sponsor Referral commissions.
-- Upline traversal uses placement_parent_id (Under ID), never referrals/referrer_member_id.
-- Source-only until TEST migration rehearsal; no database is changed by this file.

create table if not exists public.matrix_commissions (
  id uuid primary key default gen_random_uuid(),
  package_activation_id uuid not null references public.package_activations(id) on delete restrict,
  plan_version_id uuid not null references public.matrix_plan_versions(id) on delete restrict,
  level_number integer not null check(level_number between 1 and 50),
  source_member_id uuid not null references public.member_ids(id) on delete restrict,
  credited_main_member_id uuid not null references public.member_ids(id) on delete restrict,
  amount numeric(14,2) not null check(amount > 0),
  status text not null default 'pending' check(status in ('pending','credited','reversed')),
  created_at timestamptz not null default now(),
  unique(package_activation_id, source_member_id, level_number)
);
create index if not exists matrix_commissions_status_created_idx
  on public.matrix_commissions(status, created_at desc, id desc);
create index if not exists matrix_commissions_credited_main_idx
  on public.matrix_commissions(credited_main_member_id, created_at desc, id desc);
alter table public.matrix_commissions enable row level security;
revoke all on table public.matrix_commissions from public, anon, authenticated;

create or replace function private.create_matrix_commissions_for_activation()
returns trigger
language plpgsql security definer set search_path=''
as $function$
declare
  v_plan_id uuid;
  v_rule record;
  v_ancestor record;
  v_amount numeric(14,2);
  v_enabled boolean:=false;
begin
  if new.payment_status<>'approved' or new.activation_status<>'active'
     or (old.payment_status='approved' and old.activation_status='active') then
    return new;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('matrix-activation:'||new.id::text,0)
  );
  select id into v_plan_id
  from public.matrix_plan_versions
  where package_id=new.package_id and is_active=true
  order by version_number desc,id desc limit 1;
  if v_plan_id is null then return new; end if;

  -- Walk the placement/Under-ID chain. Sponsor referral records are deliberately
  -- not consulted. The activated member itself is not an upline beneficiary.
  for v_ancestor in
    with recursive uplines(member_id,depth,path) as (
      select m.placement_parent_id,1,array[new.member_id,m.placement_parent_id]
      from public.member_ids m
      where m.id=new.member_id and m.placement_parent_id is not null
      union all
      select parent.placement_parent_id,u.depth+1,u.path||parent.placement_parent_id
      from uplines u
      join public.member_ids current_node on current_node.id=u.member_id
      join public.member_ids parent on parent.id=current_node.placement_parent_id
      where parent.placement_parent_id is not null
        and u.depth<50
        and not parent.placement_parent_id=any(u.path)
    )
    select u.member_id,u.depth,source.id_type as source_id_type,
      source.member_code as source_member_code,
      case when source.id_type='duplicate' then source.main_member_id else source.id end as credited_main_id,
      credited.status as credited_status
    from uplines u
    join public.member_ids source on source.id=u.member_id
    join public.member_ids credited
      on credited.id=case when source.id_type='duplicate' then source.main_member_id else source.id end
    where source.id_type in ('main','duplicate')
      and credited.id_type='main'
    order by u.depth
  loop
    select * into v_rule
    from public.matrix_level_rules
    where plan_version_id=v_plan_id and level_number=v_ancestor.depth;
    if not found then continue; end if;
    if not v_rule.is_enabled then continue; end if;
    if coalesce((v_rule.eligibility_rule->>'requires_active_main_id')::boolean,true)
       and v_ancestor.credited_status<>'active' then continue; end if;
    if coalesce((v_rule.eligibility_rule->>'max_depth')::integer,v_ancestor.depth)<v_ancestor.depth then continue; end if;
    if v_rule.eligibility_rule ? 'allowed_source_id_types'
       and not (v_rule.eligibility_rule->'allowed_source_id_types' ? v_ancestor.source_id_type) then continue; end if;
    v_amount:=case
      when v_rule.reward_type='fixed' then round(v_rule.reward_value,2)
      when v_rule.reward_type='percentage' then round(new.amount_paid*v_rule.reward_value/100,2)
      else 0 end;
    if v_amount<=0 then continue; end if;
    insert into public.matrix_commissions(
      package_activation_id,plan_version_id,level_number,source_member_id,
      credited_main_member_id,amount,status
    ) values(
      new.id,v_plan_id,v_ancestor.depth,v_ancestor.member_id,
      v_ancestor.credited_main_id,v_amount,'pending'
    ) on conflict(package_activation_id,source_member_id,level_number) do nothing;
  end loop;

  select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
  from public.app_settings where setting_key='matrix_commissions_enabled';
  if coalesce(v_enabled,false) then
    perform public.admin_post_matrix_commissions(new.id);
  end if;
  return new;
end;
$function$;
revoke all on function private.create_matrix_commissions_for_activation() from public,anon,authenticated;
drop trigger if exists create_matrix_commissions_after_activation on public.package_activations;
create trigger create_matrix_commissions_after_activation
after update of payment_status,activation_status on public.package_activations
for each row execute function private.create_matrix_commissions_for_activation();

create or replace function public.admin_post_matrix_commissions(p_activation_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_activation public.package_activations%rowtype;
  v_commission public.matrix_commissions%rowtype;
  v_member public.member_ids%rowtype;
  v_wallet public.wallet_accounts%rowtype;
  v_existing public.wallet_transactions%rowtype;
  v_key text;
  v_balance numeric(14,2);
  v_enabled boolean:=false;
  v_posted integer:=0;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  select * into v_activation from public.package_activations
  where id=p_activation_id for update;
  if not found or v_activation.payment_status<>'approved'
     or v_activation.activation_status<>'active' then
    raise exception 'Only an approved active package activation can post Matrix commissions' using errcode='55000';
  end if;
  select coalesce((setting_value#>>'{}')::boolean,false) into v_enabled
  from public.app_settings where setting_key='matrix_commissions_enabled';
  if not coalesce(v_enabled,false) then
    raise exception 'Matrix commission posting is disabled' using errcode='55000';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('matrix-activation:'||p_activation_id::text,0)
  );
  for v_commission in
    select * from public.matrix_commissions
    where package_activation_id=p_activation_id and status='pending'
    order by level_number,id for update
  loop
    select * into v_member from public.member_ids
    where id=v_commission.credited_main_member_id
      and id_type='main' and status='active' for share;
    if not found then continue; end if;
    v_key:='matrix-commission:'||v_commission.id::text||':credit';
    select * into v_wallet from public.wallet_accounts
    where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
    if not found then
      raise exception 'Income Wallet is unavailable for credited Main ID %',v_member.member_code using errcode='55000';
    end if;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_key;
    if found then
      if v_existing.wallet_account_id is distinct from v_wallet.id
        or v_existing.member_id is distinct from v_commission.credited_main_member_id
        or v_existing.transaction_type is distinct from 'matrix_commission'
        or v_existing.direction is distinct from 'credit'
        or v_existing.amount is distinct from v_commission.amount
        or v_existing.reference_type is distinct from 'matrix_commission'
        or v_existing.reference_id is distinct from v_commission.id then
        raise exception 'Matrix commission idempotency key conflicts with another ledger transaction' using errcode='23505';
      end if;
      update public.matrix_commissions set status='credited' where id=v_commission.id and status='pending';
      v_posted:=v_posted+1;
      continue;
    end if;
    v_balance:=v_wallet.balance+v_commission.amount;
    update public.wallet_accounts set balance=v_balance,updated_at=now() where id=v_wallet.id;
    insert into public.wallet_transactions(
      wallet_account_id,member_id,transaction_type,direction,amount,balance_after,
      reference_type,reference_id,idempotency_key,description
    ) values(
      v_wallet.id,v_commission.credited_main_member_id,'matrix_commission','credit',
      v_commission.amount,v_balance,'matrix_commission',v_commission.id,v_key,
      'Level '||v_commission.level_number||' Matrix commission'
    );
    update public.matrix_commissions set status='credited' where id=v_commission.id and status='pending';
    v_posted:=v_posted+1;
  end loop;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'matrix_commissions.posted','package_activations',p_activation_id,
    jsonb_build_object('posted_count',v_posted));
  return jsonb_build_object('success',true,'activation_id',p_activation_id,'posted_count',v_posted);
end;
$function$;

create or replace function public.admin_reverse_matrix_commission(
  p_commission_id uuid,p_reason text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_commission public.matrix_commissions%rowtype;
  v_wallet public.wallet_accounts%rowtype;
  v_credit public.wallet_transactions%rowtype;
  v_existing public.wallet_transactions%rowtype;
  v_credit_key text;
  v_reverse_key text;
  v_balance numeric(14,2);
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
    raise exception 'Provide a reversal reason between 5 and 500 characters' using errcode='22023';
  end if;
  select * into v_commission from public.matrix_commissions where id=p_commission_id for update;
  if not found then raise exception 'Matrix commission not found' using errcode='P0002'; end if;
  if v_commission.status='reversed' then
    v_credit_key:='matrix-commission:'||p_commission_id::text||':credit';
    v_reverse_key:='matrix-commission:'||p_commission_id::text||':reverse';
    select * into v_credit from public.wallet_transactions where idempotency_key=v_credit_key;
    if not found then
      if exists(select 1 from public.wallet_transactions where idempotency_key=v_reverse_key) then
        raise exception 'Matrix reversal exists without original credit; reconciliation required' using errcode='23514';
      end if;
      return jsonb_build_object('success',true,'status','reversed','replayed',true);
    end if;
    select * into v_wallet from public.wallet_accounts
    where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_reverse_key;
    if not found or v_existing.wallet_account_id is distinct from v_wallet.id
      or v_existing.member_id is distinct from v_commission.credited_main_member_id
      or v_existing.transaction_type is distinct from 'matrix_commission_reversal'
      or v_existing.direction is distinct from 'debit'
      or v_existing.amount is distinct from v_commission.amount
      or v_existing.reference_type is distinct from 'matrix_commission'
      or v_existing.reference_id is distinct from p_commission_id then
      raise exception 'Matrix reversal ledger entry is missing or inconsistent' using errcode='23514';
    end if;
    return jsonb_build_object('success',true,'status','reversed','replayed',true);
  end if;
  if v_commission.status='pending' then
    update public.matrix_commissions set status='reversed' where id=p_commission_id;
  else
    v_credit_key:='matrix-commission:'||p_commission_id::text||':credit';
    v_reverse_key:='matrix-commission:'||p_commission_id::text||':reverse';
    select * into v_wallet from public.wallet_accounts
    where member_id=v_commission.credited_main_member_id and wallet_type='income' for update;
    if not found then raise exception 'Income Wallet is unavailable' using errcode='55000'; end if;
    select * into v_credit from public.wallet_transactions where idempotency_key=v_credit_key;
    if not found or v_credit.wallet_account_id is distinct from v_wallet.id
      or v_credit.member_id is distinct from v_commission.credited_main_member_id
      or v_credit.transaction_type is distinct from 'matrix_commission'
      or v_credit.direction is distinct from 'credit'
      or v_credit.amount is distinct from v_commission.amount
      or v_credit.reference_type is distinct from 'matrix_commission'
      or v_credit.reference_id is distinct from p_commission_id then
      raise exception 'Original Matrix commission credit is missing or inconsistent' using errcode='23514';
    end if;
    select * into v_existing from public.wallet_transactions where idempotency_key=v_reverse_key;
    if found then
      if v_existing.wallet_account_id is distinct from v_wallet.id
        or v_existing.member_id is distinct from v_commission.credited_main_member_id
        or v_existing.transaction_type is distinct from 'matrix_commission_reversal'
        or v_existing.direction is distinct from 'debit'
        or v_existing.amount is distinct from v_commission.amount
        or v_existing.reference_type is distinct from 'matrix_commission'
        or v_existing.reference_id is distinct from p_commission_id then
        raise exception 'Matrix reversal idempotency key conflicts with another transaction' using errcode='23505';
      end if;
    else
      if v_wallet.balance<v_commission.amount then
        raise exception 'Income Wallet balance is insufficient for the full reversal' using errcode='23514';
      end if;
      v_balance:=v_wallet.balance-v_commission.amount;
      update public.wallet_accounts set balance=v_balance,updated_at=now() where id=v_wallet.id;
      insert into public.wallet_transactions(
        wallet_account_id,member_id,transaction_type,direction,amount,balance_after,
        reference_type,reference_id,idempotency_key,description
      ) values(
        v_wallet.id,v_commission.credited_main_member_id,'matrix_commission_reversal','debit',
        v_commission.amount,v_balance,'matrix_commission',p_commission_id,v_reverse_key,
        'Matrix commission reversal: '||trim(p_reason)
      );
    end if;
    update public.matrix_commissions set status='reversed' where id=p_commission_id;
  end if;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'matrix_commission.reversed','matrix_commissions',p_commission_id,
    jsonb_build_object('reason',trim(p_reason),'amount',v_commission.amount,'previous_status',v_commission.status));
  return jsonb_build_object('success',true,'commission_id',p_commission_id,'status','reversed','replayed',false);
end;
$function$;

create or replace function public.admin_list_matrix_commissions_page(
  p_limit integer default 100,p_offset integer default 0,p_status text default null,p_level integer default null
) returns table(
  commission_id uuid,activation_id uuid,activated_member_code text,
  level_number integer,source_member_code text,source_id_type text,
  credited_main_member_code text,credited_main_name text,
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
    raise exception 'Invalid Matrix commission status filter' using errcode='22023';
  end if;
  if p_level is not null and (p_level<1 or p_level>50) then
    raise exception 'Invalid Matrix level filter' using errcode='22023';
  end if;
  return query
  select c.id,c.package_activation_id,activated.member_code,c.level_number,
    source.member_code,source.id_type,credited.member_code,
    coalesce(nullif(profile.display_name,''),'Member'),c.amount,c.status,c.created_at,
    count(*) over()>p_offset+p_limit
  from public.matrix_commissions c
  join public.package_activations activation on activation.id=c.package_activation_id
  join public.member_ids activated on activated.id=activation.member_id
  join public.member_ids source on source.id=c.source_member_id
  join public.member_ids credited on credited.id=c.credited_main_member_id
  left join public.profiles profile on profile.id=credited.owner_user_id
  where (p_status is null or c.status=p_status)
    and (p_level is null or c.level_number=p_level)
  order by c.created_at desc,c.id desc
  limit p_limit offset p_offset;
end;
$function$;

revoke all on function public.admin_post_matrix_commissions(uuid) from public,anon;
grant execute on function public.admin_post_matrix_commissions(uuid) to authenticated;
revoke all on function public.admin_reverse_matrix_commission(uuid,text) from public,anon;
grant execute on function public.admin_reverse_matrix_commission(uuid,text) to authenticated;
revoke all on function public.admin_list_matrix_commissions_page(integer,integer,text,integer) from public,anon;
grant execute on function public.admin_list_matrix_commissions_page(integer,integer,text,integer) to authenticated;


-- Keep Matrix commission posting independently switchable and safely OFF by default.
insert into public.app_settings(setting_key,setting_value,updated_at)
values('matrix_commissions_enabled','false'::jsonb,now())
on conflict(setting_key) do nothing;

create or replace function public.admin_get_feature_settings()
returns jsonb language plpgsql stable security definer set search_path=''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  select coalesce(jsonb_object_agg(setting_key,setting_value),'{}'::jsonb)
  into v_result from public.app_settings
  where setting_key=any(array[
    'registration_enabled','email_verification_required','sponsor_referrals_enabled',
    'duplicate_ids_enabled','automatic_placement_enabled','package_activations_enabled',
    'referral_commissions_enabled','matrix_commissions_enabled','bid_wallet_enabled',
    'income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled',
    'winner_selection_configured','winning_payment_enabled','delivery_tracking_enabled',
    'notifications_enabled'
  ]);
  return v_result;
end;
$function$;

create or replace function public.admin_set_feature_setting(p_setting_key text,p_enabled boolean)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_enabled_keys text[]:=array[
    'registration_enabled','email_verification_required','sponsor_referrals_enabled',
    'duplicate_ids_enabled','package_activations_enabled','referral_commissions_enabled',
    'bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled',
    'fixed_bid_enabled','winning_payment_enabled','delivery_tracking_enabled','notifications_enabled'
  ];
  v_server_condition_keys text[]:=array[
    'duplicate_ids_enabled','package_activations_enabled','referral_commissions_enabled',
    'bid_wallet_enabled','income_wallet_enabled','withdrawals_enabled','bidding_enabled',
    'fixed_bid_enabled','winning_payment_enabled'
  ];
  v_server_condition_satisfied boolean:=false;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if p_enabled is null then raise exception 'A true/false value is required' using errcode='22023'; end if;
  if p_setting_key is null or p_setting_key<>all(array[
    'registration_enabled','email_verification_required','sponsor_referrals_enabled',
    'duplicate_ids_enabled','automatic_placement_enabled','package_activations_enabled',
    'referral_commissions_enabled','matrix_commissions_enabled','bid_wallet_enabled',
    'income_wallet_enabled','withdrawals_enabled','bidding_enabled','fixed_bid_enabled',
    'winner_selection_configured','winning_payment_enabled','delivery_tracking_enabled',
    'notifications_enabled'
  ]) then
    raise exception 'Unsupported feature setting' using errcode='22023';
  end if;
  if p_enabled and not (p_setting_key=any(v_enabled_keys)) then
    raise exception 'Cannot enable % yet: its complete workflow is not marked ready. It remains safely disabled.',p_setting_key using errcode='55000';
  end if;
  if p_enabled and p_setting_key=any(v_server_condition_keys) then
    select coalesce((setting_value#>>'{}')::boolean,false) into v_server_condition_satisfied
    from public.app_settings where setting_key='financial_model_approved';
    if not coalesce(v_server_condition_satisfied,false) then
      raise exception 'This feature is currently locked by its server-side condition (%).',p_setting_key using errcode='55000';
    end if;
  end if;
  insert into public.app_settings(setting_key,setting_value,updated_at)
  values(p_setting_key,to_jsonb(p_enabled),now())
  on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
  insert into public.audit_logs(actor_user_id,action,entity_type,details)
  values(v_uid,'feature_setting_changed','app_settings',
    jsonb_build_object('setting_key',p_setting_key,'enabled',p_enabled));
  return jsonb_build_object('success',true,'setting_key',p_setting_key,'enabled',p_enabled);
end;
$function$;

revoke all on function public.admin_get_feature_settings() from public,anon;
grant execute on function public.admin_get_feature_settings() to authenticated;
revoke all on function public.admin_set_feature_setting(text,boolean) from public,anon;
grant execute on function public.admin_set_feature_setting(text,boolean) to authenticated;
