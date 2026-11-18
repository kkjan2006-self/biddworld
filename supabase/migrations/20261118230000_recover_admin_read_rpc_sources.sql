-- Recover verified existing Production Admin read RPCs into source control.
-- Definitions and signatures were obtained from pg_get_functiondef on Production
-- using a read-only catalogue query. Keep this migration source-only until the
-- complete historical chain is reconciled and replayed on the isolated TEST DB.

create or replace function public.admin_list_packages()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'name',p.name,'description',p.description,'price',p.price,
    'currency',p.currency,'bid_wallet_credit',p.bid_wallet_credit,
    'is_active',p.is_active,'created_at',p.created_at,'updated_at',p.updated_at
  ) order by p.created_at desc),'[]'::jsonb)
  into v_result from public.packages p;
  return v_result;
end;
$function$;

create or replace function public.admin_list_referral_plans()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_result jsonb;
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required';
 end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'package_id',p.id,'package_name',p.name,'package_active',p.is_active,
  'plan_id',v.id,'version_number',v.version_number,'plan_active',v.is_active,
  'rules',coalesce((select jsonb_agg(jsonb_build_object(
    'level',r.level_number,'reward_type',r.reward_type,
    'reward_value',r.reward_value,'eligibility_rule',r.eligibility_rule
  ) order by r.level_number) from public.referral_level_rules r where r.plan_version_id=v.id),'[]'::jsonb)
 ) order by p.created_at desc,v.version_number desc),'[]'::jsonb)
 into v_result from public.packages p
 left join public.referral_plan_versions v on v.package_id=p.id;
 return v_result;
end;
$function$;

create or replace function public.admin_list_withdrawal_requests(
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 request_id uuid, member_code text, display_name text, amount numeric,
 currency text, status text, payout_details jsonb, requested_at timestamptz,
 reviewed_at timestamptz, reviewed_by uuid, rejection_reason text
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select r.id,m.member_code,p.display_name,r.amount,r.currency::text,r.status,r.payout_details,
        r.requested_at,r.reviewed_at,r.reviewed_by,r.rejection_reason
 from public.withdrawal_requests r
 join public.member_ids m on m.id=r.member_id
 left join public.profiles p on p.id=m.owner_user_id
 order by r.requested_at desc,r.id desc
 limit p_limit offset p_offset;
end;
$function$;

-- Preserve the legacy all-wallets Admin directory overload.
create or replace function public.admin_list_wallet_accounts()
returns table(
 wallet_account_id uuid, member_id uuid, member_code text, id_type text,
 display_name text, wallet_type text, balance numeric, currency text,
 updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  return query
  select w.id, w.member_id, m.member_code, m.id_type,
         p.display_name, w.wallet_type, w.balance, w.currency::text, w.updated_at
  from public.wallet_accounts w
  join public.member_ids m on m.id = w.member_id
  left join public.profiles p on p.id = m.owner_user_id
  order by m.member_code, w.wallet_type;
end;
$function$;

create or replace function public.admin_list_wallet_accounts(
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 wallet_account_id uuid, member_id uuid, member_code text,
 wallet_type text, balance numeric, currency text, updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select wa.id,wa.member_id,mi.member_code,wa.wallet_type,wa.balance,wa.currency,wa.updated_at
 from public.wallet_accounts wa
 join public.member_ids mi on mi.id=wa.member_id
 where mi.id_type='main'
 order by wa.updated_at desc,mi.member_code
 limit greatest(1,least(coalesce(p_limit,100),500))
 offset greatest(coalesce(p_offset,0),0);
end;
$function$;

create or replace function public.admin_list_wallet_transactions(
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 transaction_id uuid, member_id uuid, member_code text, wallet_type text,
 transaction_type text, direction text, amount numeric, balance_after numeric,
 reference_type text, reference_id uuid, description text, created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select wt.id,wt.member_id,mi.member_code,wa.wallet_type,wt.transaction_type,
        wt.direction,wt.amount,wt.balance_after,wt.reference_type,wt.reference_id,
        wt.description,wt.created_at
 from public.wallet_transactions wt
 join public.member_ids mi on mi.id=wt.member_id
 left join public.wallet_accounts wa on wa.id=wt.wallet_account_id
 where mi.id_type='main'
 order by wt.created_at desc
 limit greatest(1,least(coalesce(p_limit,100),500))
 offset greatest(coalesce(p_offset,0),0);
end;
$function$;

-- Preserve the existing wallet-specific overload for callers that need it.
create or replace function public.admin_list_wallet_transactions(
 p_wallet_account_id uuid default null,
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 transaction_id uuid, wallet_account_id uuid, member_code text,
 wallet_type text, transaction_type text, direction text, amount numeric,
 balance_after numeric, description text, reference_type text,
 reference_id uuid, created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 200 or p_offset is null or p_offset < 0 or p_offset > 1000000 then
    raise exception 'Invalid pagination values' using errcode = '22023';
  end if;
  return query
  select t.id, t.wallet_account_id, m.member_code, w.wallet_type,
         t.transaction_type, t.direction, t.amount, t.balance_after,
         t.description, t.reference_type, t.reference_id, t.created_at
  from public.wallet_transactions t
  join public.wallet_accounts w on w.id = t.wallet_account_id
  join public.member_ids m on m.id = t.member_id
  where p_wallet_account_id is null or t.wallet_account_id = p_wallet_account_id
  order by t.created_at desc, t.id desc
  limit p_limit offset p_offset;
end;
$function$;

create or replace function public.admin_list_winning_item_payments(
 p_limit integer default 100,
 p_offset integer default 0
)
returns table(
 payment_id uuid, winner_member_code text, winner_name text,
 auction_title text, fixed_bid_title text, amount numeric, status text,
 paid_at timestamptz, created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select w.id,m.member_code,p.display_name,a.title,fc.title,w.amount,w.status,w.paid_at,w.created_at
 from public.winning_item_payments w
 join public.member_ids m on m.id=w.winner_member_id
 left join public.profiles p on p.id=m.owner_user_id
 left join public.auctions a on a.id=w.auction_id
 left join public.fixed_bid_campaigns fc on fc.id=w.fixed_bid_campaign_id
 order by w.created_at desc,w.id desc limit p_limit offset p_offset;
end;
$function$;

create or replace function public.admin_set_default_sponsor(p_member_code text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare v_uid uuid := auth.uid(); v_member_id uuid; v_code text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select id, member_code into v_member_id, v_code
  from public.member_ids
  where upper(member_code)=upper(trim(p_member_code))
    and id_type='main' and status='active';
  if v_member_id is null then raise exception 'Active Main Sponsor ID not found'; end if;
  insert into public.app_settings(setting_key,setting_value,updated_at)
  values ('default_sponsor_member_id',to_jsonb(v_member_id::text),now())
  on conflict(setting_key) do update set setting_value=excluded.setting_value,updated_at=now();
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'default_sponsor_changed','app_settings',v_member_id,jsonb_build_object('member_code',v_code));
end;
$function$;

revoke all on function public.admin_list_packages() from public, anon;
revoke all on function public.admin_list_referral_plans() from public, anon;
revoke all on function public.admin_list_withdrawal_requests(integer,integer) from public, anon;
revoke all on function public.admin_list_wallet_accounts() from public, anon;
revoke all on function public.admin_list_wallet_accounts(integer,integer) from public, anon;
revoke all on function public.admin_list_wallet_transactions(integer,integer) from public, anon;
revoke all on function public.admin_list_wallet_transactions(uuid,integer,integer) from public, anon;
revoke all on function public.admin_list_winning_item_payments(integer,integer) from public, anon;
revoke all on function public.admin_set_default_sponsor(text) from public, anon;

grant execute on function public.admin_list_packages() to authenticated, service_role;
grant execute on function public.admin_list_referral_plans() to authenticated, service_role;
grant execute on function public.admin_list_withdrawal_requests(integer,integer) to authenticated, service_role;
grant execute on function public.admin_list_wallet_accounts() to authenticated, service_role;
grant execute on function public.admin_list_wallet_accounts(integer,integer) to authenticated, service_role;
grant execute on function public.admin_list_wallet_transactions(integer,integer) to authenticated, service_role;
grant execute on function public.admin_list_wallet_transactions(uuid,integer,integer) to authenticated, service_role;
grant execute on function public.admin_list_winning_item_payments(integer,integer) to authenticated, service_role;
grant execute on function public.admin_set_default_sponsor(text) to authenticated, service_role;
