create or replace function public.admin_list_wallet_accounts(p_limit integer default 100,p_offset integer default 0)
returns table(wallet_account_id uuid,member_id uuid,member_code text,wallet_type text,balance numeric,currency text,updated_at timestamptz)
language plpgsql
security definer
set search_path=''
as $$
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
$$;
create or replace function public.admin_list_wallet_transactions(p_limit integer default 100,p_offset integer default 0)
returns table(transaction_id uuid,member_id uuid,member_code text,wallet_type text,transaction_type text,direction text,amount numeric,balance_after numeric,reference_type text,reference_id uuid,description text,created_at timestamptz)
language plpgsql
security definer
set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Admin access required' using errcode='42501';
 end if;
 return query
 select wt.id,wt.member_id,mi.member_code,wa.wallet_type,wt.transaction_type,wt.direction,wt.amount,wt.balance_after,wt.reference_type,wt.reference_id,wt.description,wt.created_at
 from public.wallet_transactions wt
 join public.member_ids mi on mi.id=wt.member_id
 left join public.wallet_accounts wa on wa.id=wt.wallet_account_id
 where mi.id_type='main'
 order by wt.created_at desc
 limit greatest(1,least(coalesce(p_limit,100),500))
 offset greatest(coalesce(p_offset,0),0);
end;
$$;
revoke all on function public.admin_list_wallet_accounts(integer,integer) from public,anon;
revoke all on function public.admin_list_wallet_transactions(integer,integer) from public,anon;
grant execute on function public.admin_list_wallet_accounts(integer,integer) to authenticated;
grant execute on function public.admin_list_wallet_transactions(integer,integer) to authenticated;
