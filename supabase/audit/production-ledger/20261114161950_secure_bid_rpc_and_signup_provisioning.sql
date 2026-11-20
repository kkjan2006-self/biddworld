-- BiddWorld: isolate privileged bidding logic and provision free member accounts on signup.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

alter function public.place_bid(uuid) set schema private;
revoke all on function private.place_bid(uuid) from public, anon;
grant execute on function private.place_bid(uuid) to authenticated;

create or replace function public.place_bid(p_auction_id uuid)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public, private
as $$
  select private.place_bid(p_auction_id);
$$;
revoke all on function public.place_bid(uuid) from public, anon;
grant execute on function public.place_bid(uuid) to authenticated;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid;
  v_member_code text;
begin
  insert into public.profiles (id, display_name, status)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), split_part(coalesce(new.email, ''), '@', 1)),
    'active'
  )
  on conflict (id) do nothing;

  v_member_code := 'BW' || upper(substr(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.member_ids (owner_user_id, member_code, id_type, status)
  values (new.id, v_member_code, 'main', 'active')
  on conflict do nothing
  returning id into v_member_id;

  if v_member_id is null then
    select id into v_member_id
    from public.member_ids
    where owner_user_id = new.id and id_type = 'main'
    limit 1;
  end if;

  if v_member_id is not null then
    insert into public.wallet_accounts (member_id, wallet_type, balance)
    values (v_member_id, 'bid', 0), (v_member_id, 'income', 0)
    on conflict (member_id, wallet_type) do nothing;
  end if;

  return new;
end;
$$;
revoke all on function private.handle_new_auth_user() from public, anon, authenticated;

drop trigger if exists on_biddworld_auth_user_created on auth.users;
create trigger on_biddworld_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();
