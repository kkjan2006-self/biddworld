-- Remove the obsolete one-argument Duplicate-ID creation RPC. The current
-- Admin workflow requires an explicit Under ID placement.
drop function if exists public.admin_create_duplicate_member_id(text);

-- Duplicate activation is allowed only for a correctly placed ID whose Main ID and
-- placement parent are both active. Serialize this with Main-ID and placement changes.
create or replace function public.admin_set_duplicate_id_status(p_duplicate_id uuid,p_status text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_row public.member_ids%rowtype;
  v_main public.member_ids%rowtype;
  v_parent public.member_ids%rowtype;
  v_old_status text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required' using errcode='42501';
  end if;
  if p_status is null or p_status not in ('active','suspended','closed') then
    raise exception 'Status must be active, suspended or closed' using errcode='22023';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0));
  select * into v_row from public.member_ids where id=p_duplicate_id and id_type='duplicate' for update;
  if not found then raise exception 'Duplicate ID not found' using errcode='P0002'; end if;
  if v_row.status='closed' and p_status<>'closed' then
    raise exception 'Closed Duplicate IDs cannot be reactivated; create a new Duplicate ID instead' using errcode='55000';
  end if;
  if p_status='active' then
    select * into v_main from public.member_ids
    where id=v_row.main_member_id and id_type='main' and status='active' for update;
    if not found or v_main.owner_user_id is distinct from v_row.owner_user_id then
      raise exception 'The owner Main ID must be active before its Duplicate ID can be activated' using errcode='23514';
    end if;
    if v_row.placement_parent_id is null then
      raise exception 'A Duplicate ID must have an approved placement parent before activation' using errcode='23514';
    end if;
    select * into v_parent from public.member_ids
    where id=v_row.placement_parent_id and id_type in ('main','duplicate') and status='active' for update;
    if not found or v_parent.owner_user_id is not distinct from v_row.owner_user_id then
      raise exception 'The placement parent must be active and belong to a different member' using errcode='23514';
    end if;
  end if;
  v_old_status:=v_row.status;
  if v_old_status=p_status then
    return jsonb_build_object('id',p_duplicate_id,'member_code',v_row.member_code,'old_status',v_old_status,'status',p_status,'changed',false);
  end if;
  update public.member_ids set status=p_status,main_status_managed=false where id=p_duplicate_id;
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'duplicate_id_status_changed','member_ids',p_duplicate_id,
    jsonb_build_object('member_code',v_row.member_code,'main_member_id',v_row.main_member_id,'old_status',v_old_status,'new_status',p_status));
  return jsonb_build_object('id',p_duplicate_id,'member_code',v_row.member_code,'old_status',v_old_status,'status',p_status,'changed',true);
end;
$function$;
revoke all on function public.admin_set_duplicate_id_status(uuid,text) from public,anon;
grant execute on function public.admin_set_duplicate_id_status(uuid,text) to authenticated;
