create or replace function public.admin_list_audit_logs_page(p_limit integer default 100, p_offset integer default 0)
returns table(
 id bigint,
 actor_user_id uuid,
 actor_name text,
 action text,
 entity_type text,
 entity_id uuid,
 details jsonb,
 created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required';
 end if;
 return query
 select a.id,a.actor_user_id,coalesce(nullif(p.display_name,''),'System'),
        a.action,a.entity_type,a.entity_id,a.details,a.created_at
 from public.audit_logs a
 left join public.profiles p on p.id=a.actor_user_id
 order by a.created_at desc,a.id desc
 limit greatest(1,least(coalesce(p_limit,100),200))
 offset greatest(0,coalesce(p_offset,0));
end;
$function$;

revoke all on function public.admin_list_audit_logs_page(integer,integer) from public, anon;
grant execute on function public.admin_list_audit_logs_page(integer,integer) to authenticated;