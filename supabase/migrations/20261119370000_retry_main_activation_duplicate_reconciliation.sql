-- Allow a repeated Main-ID activation request to reconcile linked Duplicate IDs.
-- A Duplicate ID whose placement parent was inactive during the first reactivation
-- remains main_status_managed=true; a later retry can safely restore it once its
-- parent is active, even when the Main ID itself is already active.

create or replace function public.admin_set_main_member_status(
 p_member_code text,p_status text,p_reason text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_main public.member_ids%rowtype;
 v_old_status text;
 v_duplicate_count integer:=0;
 v_main_changed boolean:=false;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_status is null or p_status not in ('active','suspended','closed') then
  raise exception 'Choose active, suspended or closed status' using errcode='22023';
 end if;
 if length(trim(coalesce(p_reason,'')))<5 or length(p_reason)>500 then
  raise exception 'Provide a reason between 5 and 500 characters' using errcode='22023';
 end if;

 perform pg_catalog.pg_advisory_xact_lock(
  pg_catalog.hashtextextended('biddworld.member_id_graph_mutation',0)
 );

 select * into v_main from public.member_ids
 where upper(member_code)=upper(trim(p_member_code)) and id_type='main'
 for update;
 if not found then raise exception 'Main Member ID not found' using errcode='P0002'; end if;

 v_old_status:=v_main.status;
 if v_old_status='closed' and p_status<>'closed' then
  raise exception 'A closed Main ID cannot be reactivated' using errcode='55000';
 end if;

 if v_old_status<>p_status then
  update public.member_ids set status=p_status where id=v_main.id;
  v_main_changed:=true;
 end if;

 if v_old_status<>p_status then
  update public.profiles set status=p_status,updated_at=now()
  where id=v_main.owner_user_id;
 elsif p_status='active' then
  -- Keep profile and Main ID status aligned while retrying child reconciliation.
  update public.profiles set status='active',updated_at=now()
  where id=v_main.owner_user_id and status is distinct from 'active';
 end if;

 if p_status='suspended' then
  update public.member_ids
     set status='suspended',main_status_managed=true
   where main_member_id=v_main.id and id_type='duplicate'
     and status='active' and not main_status_managed;
  get diagnostics v_duplicate_count=row_count;
 elsif p_status='closed' then
  update public.member_ids
     set status='closed',main_status_managed=true
   where main_member_id=v_main.id and id_type='duplicate'
     and (status in ('active','pending') or (status='suspended' and main_status_managed));
  get diagnostics v_duplicate_count=row_count;
 elsif p_status='active' then
  -- Retry this reconciliation even if the Main ID was already active.
  -- Children whose placement parent is still inactive remain managed/suspended.
  update public.member_ids d
     set status='active',main_status_managed=false
   where d.main_member_id=v_main.id and d.id_type='duplicate'
     and d.status='suspended' and d.main_status_managed
     and exists(
       select 1 from public.member_ids parent
       where parent.id=d.placement_parent_id
         and parent.status='active'
         and parent.owner_user_id is distinct from d.owner_user_id
     );
  get diagnostics v_duplicate_count=row_count;
 end if;

 if v_main_changed or v_duplicate_count>0 then
  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'member.main_status_changed','member_ids',v_main.id,
   jsonb_build_object(
    'member_code',v_main.member_code,
    'old_status',v_old_status,
    'new_status',p_status,
    'reason',trim(p_reason),
    'linked_duplicate_ids_changed',v_duplicate_count,
    'reconciliation_retry',not v_main_changed and p_status='active'
   ));
 end if;

 return jsonb_build_object(
  'success',true,
  'member_code',v_main.member_code,
  'status',p_status,
  'linked_duplicate_ids_changed',v_duplicate_count,
  'replayed',not v_main_changed and v_duplicate_count=0,
  'reconciliation_retry',not v_main_changed and p_status='active'
 );
end;
$function$;

revoke all on function public.admin_set_main_member_status(text,text,text) from public,anon;
grant execute on function public.admin_set_main_member_status(text,text,text) to authenticated;
