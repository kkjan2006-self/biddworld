-- Ensure each Admin support-ticket update creates exactly one audit record.
-- The row trigger is the single audit writer; the RPC must not duplicate it.

create or replace function public.support_tickets_audit_admin_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if coalesce((select auth.jwt()->'app_metadata'->>'role'),'') = 'admin' then
    insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, details)
    values (
      auth.uid(),
      'support.ticket_updated',
      'support_tickets',
      new.id,
      jsonb_build_object(
        'old_status', old.status,
        'new_status', new.status,
        'response_updated', old.admin_response is distinct from new.admin_response,
        'member_user_id', new.user_id
      )
    );
  end if;
  return new;
end;
$function$;

create or replace function public.admin_update_support_ticket(
 p_ticket_id uuid,p_status text,p_admin_response text
) returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_ticket public.support_tickets%rowtype;
begin
 if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_status is null or p_status not in ('open','in_progress','resolved','closed') then
  raise exception 'Unsupported support ticket status' using errcode='22023';
 end if;
 if p_admin_response is not null and length(p_admin_response)>5000 then
  raise exception 'Admin response must be 5,000 characters or fewer' using errcode='22023';
 end if;
 select * into v_ticket from public.support_tickets where id=p_ticket_id for update;
 if not found then raise exception 'Support ticket not found' using errcode='P0002'; end if;
 update public.support_tickets set status=p_status,admin_response=nullif(trim(coalesce(p_admin_response,'')),'')
 where id=p_ticket_id;
 return jsonb_build_object('success',true,'ticket_id',p_ticket_id,'status',p_status);
end;
$function$;

revoke all on function public.admin_update_support_ticket(uuid,text,text) from public,anon;
grant execute on function public.admin_update_support_ticket(uuid,text,text) to authenticated;
