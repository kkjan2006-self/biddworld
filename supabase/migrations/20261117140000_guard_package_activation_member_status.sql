-- Keep package activation requests and verified activation aligned with both
-- the Main ID and its owning profile. This is additive and source-only.
-- It prevents suspended/closed IDs and mismatched legacy status pairs from
-- entering or completing the package activation lifecycle.

create or replace function private.guard_package_activation_member_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_member_status text;
  v_profile_status text;
begin
  -- Validate every new request and every transition into approved/active.
  if tg_op = 'INSERT'
     or (new.payment_status = 'approved' and new.activation_status = 'active') then
    select m.status, p.status
      into v_member_status, v_profile_status
      from public.member_ids m
      join public.profiles p on p.id = m.owner_user_id
     where m.id = new.member_id
       and m.id_type = 'main'
     for update of m, p;

    if not found then
      raise exception 'Package activation requires a Main ID with an owning member profile'
        using errcode = '55000';
    end if;

    if v_member_status is null
       or v_profile_status is null
       or v_member_status not in ('inactive', 'active')
       or v_profile_status not in ('inactive', 'active')
       or v_member_status is distinct from v_profile_status then
      raise exception 'Package activation is unavailable because the Main ID and member profile are not in a matching eligible status'
        using errcode = '55000';
    end if;
  end if;

  return new;
end;
$function$;

revoke all on function private.guard_package_activation_member_status()
  from public, anon, authenticated;

drop trigger if exists guard_package_activation_member_status
  on public.package_activations;

create trigger guard_package_activation_member_status
before insert or update of payment_status, activation_status
on public.package_activations
for each row
execute function private.guard_package_activation_member_status();
