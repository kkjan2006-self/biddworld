create or replace function public.admin_list_wallet_accounts()
returns table (
  wallet_account_id uuid,
  member_id uuid,
  member_code text,
  id_type text,
  display_name text,
  wallet_type text,
  balance numeric,
  currency text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

create or replace function public.admin_list_wallet_transactions(
  p_wallet_account_id uuid default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  transaction_id uuid,
  wallet_account_id uuid,
  member_code text,
  wallet_type text,
  transaction_type text,
  direction text,
  amount numeric,
  balance_after numeric,
  description text,
  reference_type text,
  reference_id uuid,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

revoke all on function public.admin_list_wallet_accounts() from public, anon;
revoke all on function public.admin_list_wallet_transactions(uuid, integer, integer) from public, anon;
grant execute on function public.admin_list_wallet_accounts() to authenticated;
grant execute on function public.admin_list_wallet_transactions(uuid, integer, integer) to authenticated;
