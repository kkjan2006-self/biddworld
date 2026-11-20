-- Keep Staff package approvals atomic when Matrix auto-posting is enabled.
-- The internal posting routine is callable only by its SECURITY DEFINER callers;
-- the public manual posting RPC remains Admin-only.

create or replace function private.post_matrix_commissions_for_activation(p_activation_id uuid,p_actor_id uuid)
returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
  v_uid uuid:=p_actor_id;
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
  if v_uid is null then
    raise exception 'Authenticated activation actor required' using errcode='42501';
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


revoke all on function private.post_matrix_commissions_for_activation(uuid,uuid) from public,anon,authenticated;

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
      select parent.id,u.depth+1,u.path||parent.id
      from uplines u
      join public.member_ids current_node on current_node.id=u.member_id
      join public.member_ids parent on parent.id=current_node.placement_parent_id
      where u.depth<50
        and not parent.id=any(u.path)
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
    perform private.post_matrix_commissions_for_activation(new.id,auth.uid());
  end if;
  return new;
end;
$function$;
revoke all on function private.create_matrix_commissions_for_activation() from public,anon,authenticated;
drop trigger if exists create_matrix_commissions_after_activation on public.package_activations;
create trigger create_matrix_commissions_after_activation
after update of payment_status,activation_status on public.package_activations
for each row execute function private.create_matrix_commissions_for_activation();

