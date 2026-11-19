-- Block every new Duplicate ID row while the Admin feature switch is OFF.
-- Existing Duplicate IDs and their lifecycle/history are intentionally unaffected.
create or replace function private.enforce_duplicate_id_creation_switch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_enabled boolean := false;
begin
  if new.id_type = 'duplicate'
     and (tg_op = 'INSERT' or old.id_type is distinct from 'duplicate') then
    select coalesce((setting_value #>> '{}')::boolean, false)
      into v_enabled
      from public.app_settings
     where setting_key = 'duplicate_ids_enabled';

    if not coalesce(v_enabled, false) then
      raise exception 'Duplicate ID creation is disabled by the administrator'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$function$;

revoke all on function private.enforce_duplicate_id_creation_switch() from public, anon, authenticated;

drop trigger if exists enforce_duplicate_id_creation_switch on public.member_ids;
create trigger enforce_duplicate_id_creation_switch
before insert or update of id_type on public.member_ids
for each row execute function private.enforce_duplicate_id_creation_switch();
