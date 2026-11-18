-- Idempotent member support submissions and audited Admin response/status updates.
-- Source-only until the canonical TEST baseline is established.

alter table public.support_tickets
 add column if not exists idempotency_key text;
create unique index if not exists support_tickets_user_idempotency_uidx
 on public.support_tickets(user_id,idempotency_key)
 where idempotency_key is not null;

create or replace function public.member_submit_support_ticket(
 p_subject text,p_message text,p_idempotency_key text
) returns jsonb
language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_key text:=btrim(coalesce(p_idempotency_key,'')); v_ticket public.support_tickets%rowtype;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if length(trim(coalesce(p_subject,'')))<4 or length(p_subject)>120 then
  raise exception 'Subject must contain 4 to 120 characters' using errcode='22023';
 end if;
 if length(trim(coalesce(p_message,'')))<10 or length(p_message)>5000 then
  raise exception 'Message must contain 10 to 5,000 characters' using errcode='22023';
 end if;
 if length(v_key)<16 or length(v_key)>100 or v_key !~ '^[A-Za-z0-9:_-]+$' then
  raise exception 'A valid support request key is required' using errcode='22023';
 end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_uid::text||':'||v_key,0));
 select * into v_ticket from public.support_tickets where user_id=v_uid and idempotency_key=v_key;
 if found then
  if v_ticket.subject is distinct from trim(p_subject) or v_ticket.message is distinct from trim(p_message) then
   raise exception 'This support request key was already used for different content' using errcode='23505';
  end if;
  return jsonb_build_object('success',true,'ticket_id',v_ticket.id,'status',v_ticket.status,'replayed',true);
 end if;
 insert into public.support_tickets(user_id,subject,message,status,idempotency_key)
 values(v_uid,trim(p_subject),trim(p_message),'open',v_key)
 returning * into v_ticket;
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'support.ticket_submitted','support_tickets',v_ticket.id,jsonb_build_object('subject',v_ticket.subject));
 return jsonb_build_object('success',true,'ticket_id',v_ticket.id,'status',v_ticket.status,'replayed',false);
end;
$function$;

create or replace function public.admin_update_support_ticket(
 p_ticket_id uuid,p_status text,p_admin_response text
) returns jsonb
language plpgsql security definer set search_path=''
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
 insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
 values(v_uid,'support.ticket_updated','support_tickets',p_ticket_id,
  jsonb_build_object('old_status',v_ticket.status,'new_status',p_status,
   'response_updated',p_admin_response is not null,'member_user_id',v_ticket.user_id));
 return jsonb_build_object('success',true,'ticket_id',p_ticket_id,'status',p_status);
end;
$function$;

revoke all on function public.member_submit_support_ticket(text,text,text) from public,anon;
grant execute on function public.member_submit_support_ticket(text,text,text) to authenticated;
revoke all on function public.admin_update_support_ticket(uuid,text,text) from public,anon;
grant execute on function public.admin_update_support_ticket(uuid,text,text) to authenticated;
