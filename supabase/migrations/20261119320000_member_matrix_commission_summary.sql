-- Member-scoped Matrix commission totals. Duplicate source IDs are reported separately
-- in Admin reports, while the credited amount is summarized against the owning Main ID.
create or replace function public.member_get_my_matrix_commission_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_main_id uuid;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode='42501';
  end if;
  select p.main_member_id into v_main_id
  from public.profiles p
  join public.member_ids m on m.id=p.main_member_id
  where p.id=v_uid and m.owner_user_id=v_uid and m.id_type='main';
  if v_main_id is null then
    raise exception 'A linked Main ID is required' using errcode='42501';
  end if;
  select jsonb_build_object(
    'credited_total',coalesce(sum(c.amount) filter(where c.status='credited'),0),
    'pending_total',coalesce(sum(c.amount) filter(where c.status='pending'),0),
    'reversed_total',coalesce(sum(c.amount) filter(where c.status='reversed'),0),
    'credited_count',count(*) filter(where c.status='credited'),
    'pending_count',count(*) filter(where c.status='pending')
  ) into v_result
  from public.matrix_commissions c
  where c.credited_main_member_id=v_main_id;
  return coalesce(v_result,'{"credited_total":0,"pending_total":0,"reversed_total":0,"credited_count":0,"pending_count":0}'::jsonb);
end;
$function$;
revoke all on function public.member_get_my_matrix_commission_summary() from public,anon;
grant execute on function public.member_get_my_matrix_commission_summary() to authenticated;


-- Paginated member-facing Matrix history. The credited Main ID is always derived
-- from auth.uid(); callers cannot request another member's commission rows.
create or replace function public.member_list_my_matrix_commissions_page(
  p_limit integer default 100,p_offset integer default 0
) returns table(
  commission_id uuid,level_number integer,source_member_code text,
  source_id_type text,amount numeric,status text,created_at timestamptz
)
language plpgsql stable security definer set search_path=''
as $function$
declare
  v_uid uuid:=auth.uid();
  v_main_id uuid;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
    raise exception 'Invalid pagination values' using errcode='22023';
  end if;
  select p.main_member_id into v_main_id
  from public.profiles p
  join public.member_ids m on m.id=p.main_member_id
  where p.id=v_uid and m.owner_user_id=v_uid and m.id_type='main';
  if v_main_id is null then raise exception 'A linked Main ID is required' using errcode='42501'; end if;
  return query
  select c.id,c.level_number,source.member_code,source.id_type,c.amount,c.status,c.created_at
  from public.matrix_commissions c
  join public.member_ids source on source.id=c.source_member_id
  where c.credited_main_member_id=v_main_id
  order by c.created_at desc,c.id desc
  limit p_limit offset p_offset;
end;
$function$;
revoke all on function public.member_list_my_matrix_commissions_page(integer,integer) from public,anon;
grant execute on function public.member_list_my_matrix_commissions_page(integer,integer) to authenticated;


-- Resolve Matrix commission source attribution for wallet ledger entries.
-- A caller can only resolve commission rows credited to their own linked Main ID.
create or replace function public.member_get_my_matrix_commission_sources(p_commission_ids uuid[])
returns table(commission_id uuid,source_member_code text,source_id_type text,level_number integer)
language plpgsql stable security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid();v_main_id uuid;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if p_commission_ids is null or cardinality(p_commission_ids)>200 then raise exception 'Invalid commission ID list' using errcode='22023'; end if;
 select p.main_member_id into v_main_id from public.profiles p join public.member_ids m on m.id=p.main_member_id
 where p.id=v_uid and m.owner_user_id=v_uid and m.id_type='main';
 if v_main_id is null then raise exception 'A linked Main ID is required' using errcode='42501'; end if;
 return query select c.id,s.member_code,s.id_type,c.level_number
 from public.matrix_commissions c join public.member_ids s on s.id=c.source_member_id
 where c.credited_main_member_id=v_main_id and c.id=any(p_commission_ids);
end;
$function$;
revoke all on function public.member_get_my_matrix_commission_sources(uuid[]) from public,anon;
grant execute on function public.member_get_my_matrix_commission_sources(uuid[]) to authenticated;
