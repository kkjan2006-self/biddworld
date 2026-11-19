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
