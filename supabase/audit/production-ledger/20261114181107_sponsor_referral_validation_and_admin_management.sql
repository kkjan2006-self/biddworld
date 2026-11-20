create or replace function public.lookup_sponsor(p_member_code text)
returns table(member_code text, display_name text)
language sql
stable
security definer
set search_path = ''
as $$
  select m.member_code, coalesce(nullif(p.display_name,''), m.member_code)
  from public.member_ids m
  join public.profiles p on p.id = m.owner_user_id
  where upper(m.member_code) = upper(trim(p_member_code))
    and m.id_type = 'main' and m.status = 'active'
  limit 1;
$$;
revoke all on function public.lookup_sponsor(text) from public;
grant execute on function public.lookup_sponsor(text) to anon, authenticated;

create or replace function public.admin_set_default_sponsor(p_member_code text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
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
$$;
revoke all on function public.admin_set_default_sponsor(text) from public, anon;
grant execute on function public.admin_set_default_sponsor(text) to authenticated;

create or replace function public.admin_set_member_sponsor(p_member_code text,p_sponsor_code text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid; v_sponsor_id uuid;
  v_old_sponsor uuid;
  v_code text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;
  select id into v_member_id from public.member_ids
   where upper(member_code)=upper(trim(p_member_code)) and id_type='main';
  if v_member_id is null then raise exception 'Member Main ID not found'; end if;
  select id,member_code into v_sponsor_id,v_code from public.member_ids
   where upper(member_code)=upper(trim(p_sponsor_code)) and id_type='main' and status='active';
  if v_sponsor_id is null then raise exception 'Active Sponsor Main ID not found'; end if;
  if v_member_id=v_sponsor_id then raise exception 'A member cannot sponsor themselves'; end if;
  if exists(select 1 from public.referral_commissions rc
            join public.package_activations pa on pa.id=rc.package_activation_id
            where pa.member_id=v_member_id) then
    -- Existing commissions remain immutable; only the current referral relationship changes.
    null;
  end if;
  select referrer_member_id into v_old_sponsor from public.referrals where referred_member_id=v_member_id;
  insert into public.referrals(referred_member_id,referrer_member_id,source_member_id)
  values(v_member_id,v_sponsor_id,v_sponsor_id)
  on conflict(referred_member_id) do update
    set referrer_member_id=excluded.referrer_member_id,source_member_id=excluded.source_member_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'member_sponsor_changed','member_ids',v_member_id,
    jsonb_build_object('old_sponsor_member_id',v_old_sponsor,'new_sponsor_member_id',v_sponsor_id,'new_sponsor_code',v_code));
end;
$$;
revoke all on function public.admin_set_member_sponsor(text,text) from public, anon;
grant execute on function public.admin_set_member_sponsor(text,text) to authenticated;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member_id uuid;
  v_member_code text;
  v_sponsor_id uuid;
  v_sponsor_code text;
  v_default text;
  v_requested text;
begin
  insert into public.profiles (id, display_name, phone, status)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), split_part(coalesce(new.email, ''), '@', 1)),
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    'active'
  )
  on conflict (id) do update
    set display_name=excluded.display_name, phone=excluded.phone;

  v_requested := nullif(trim(coalesce(new.raw_user_meta_data ->> 'sponsor_referral_id','')), '');
  if v_requested is not null then
    select id,member_code into v_sponsor_id,v_sponsor_code
    from public.member_ids
    where upper(member_code)=upper(v_requested) and id_type='main' and status='active';
    if v_sponsor_id is null then raise exception 'Invalid Sponsor Referral ID'; end if;
  else
    select setting_value #>> '{}' into v_default
      from public.app_settings where setting_key='default_sponsor_member_id';
    if v_default is not null then
      v_sponsor_id := v_default::uuid;
      select member_code into v_sponsor_code from public.member_ids
       where id=v_sponsor_id and id_type='main' and status='active';
      if v_sponsor_code is null then raise exception 'Default administrator sponsor is not configured correctly'; end if;
    else
      -- Bootstrap exception: the first account must be created before an Admin Main ID can be assigned.
      if exists(select 1 from public.member_ids where id_type='main' and status='active') then
        raise exception 'Default administrator sponsor has not been configured';
      end if;
    end if;
  end if;

  v_member_code := 'BW' || upper(substr(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 1, 10));
  insert into public.member_ids(owner_user_id,member_code,id_type,status)
  values(new.id,v_member_code,'main','active')
  on conflict do nothing returning id into v_member_id;
  if v_member_id is null then
    select id into v_member_id from public.member_ids where owner_user_id=new.id and id_type='main' limit 1;
  end if;
  if v_member_id is not null then
    update public.profiles set main_member_id=v_member_id where id=new.id;
    insert into public.wallet_accounts(member_id,wallet_type,balance)
    values(v_member_id,'bid',0),(v_member_id,'income',0)
    on conflict(member_id,wallet_type) do nothing;
    if v_sponsor_id is not null then
      insert into public.referrals(referred_member_id,referrer_member_id,source_member_id)
      values(v_member_id,v_sponsor_id,v_sponsor_id)
      on conflict(referred_member_id) do nothing;
    end if;
  end if;
  return new;
end;
$function$;
revoke all on function private.handle_new_auth_user() from public,anon,authenticated;
