-- Avoid touching the unassigned OLD trigger record during INSERT.
-- Keep the feature switch enforcement and graph-lock serialization intact.

create or replace function private.enforce_duplicate_id_creation_switch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_requires_check boolean := false;
  v_enabled boolean := false;
begin
  if tg_op = 'INSERT' then
    v_requires_check := new.id_type = 'duplicate';
  elsif tg_op = 'UPDATE' then
    v_requires_check := new.id_type = 'duplicate'
      and old.id_type is distinct from 'duplicate';
  else
    return new;
  end if;

  if v_requires_check then
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)
    );

    select coalesce((setting_value #>> '{}')::boolean,false)
      into v_enabled
      from public.app_settings
     where setting_key='duplicate_ids_enabled';

    if not coalesce(v_enabled,false) then
      raise exception 'Duplicate ID creation is disabled by the administrator'
        using errcode='42501';
    end if;
  end if;

  return new;
end;
$function$;

revoke all on function private.enforce_duplicate_id_creation_switch() from public,anon,authenticated;
