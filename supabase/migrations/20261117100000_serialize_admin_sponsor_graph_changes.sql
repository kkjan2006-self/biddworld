-- Serialize administrator sponsor graph changes before checking the referral tree.
-- The transaction-scoped advisory lock prevents two concurrent sponsor edits
-- from both passing a cycle check against the same pre-update graph.
create or replace function public.admin_set_member_sponsor(p_member_code text, p_sponsor_code text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_member_id uuid;
  v_sponsor_id uuid;
  v_old_sponsor uuid;
  v_code text;
begin
  if v_uid is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
    raise exception 'Administrator access required';
  end if;

  -- One graph-wide lock is intentionally conservative: sponsor changes are
  -- low-frequency administrative operations and must serialize safely.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('biddworld.admin_set_member_sponsor', 0)
  );

  select id into v_member_id from public.member_ids
   where upper(member_code)=upper(trim(p_member_code)) and id_type='main';
  if v_member_id is null then raise exception 'Member Main ID not found'; end if;

  select id,member_code into v_sponsor_id,v_code from public.member_ids
   where upper(member_code)=upper(trim(p_sponsor_code)) and id_type='main' and status='active';
  if v_sponsor_id is null then raise exception 'Active Sponsor Main ID not found'; end if;
  if v_member_id=v_sponsor_id then raise exception 'A member cannot sponsor themselves'; end if;

  if exists (
    with recursive descendants(member_id,path) as (
      select r.referred_member_id, array[v_member_id,r.referred_member_id]
      from public.referrals r where r.referrer_member_id=v_member_id
      union all
      select r.referred_member_id, d.path || r.referred_member_id
      from descendants d
      join public.referrals r on r.referrer_member_id=d.member_id
      where not r.referred_member_id=any(d.path)
    )
    select 1 from descendants where member_id=v_sponsor_id
  ) then
    raise exception 'The selected sponsor is already in this member downline; circular referral is not allowed';
  end if;

  select referrer_member_id into v_old_sponsor
  from public.referrals where referred_member_id=v_member_id;

  insert into public.referrals(referred_member_id,referrer_member_id,source_member_id)
  values(v_member_id,v_sponsor_id,v_sponsor_id)
  on conflict(referred_member_id) do update
    set referrer_member_id=excluded.referrer_member_id,source_member_id=excluded.source_member_id;

  insert into public.audit_logs(actor_user_id,action,entity_type,entity_id,details)
  values(v_uid,'member_sponsor_changed','member_ids',v_member_id,
    jsonb_build_object('old_sponsor_member_id',v_old_sponsor,'new_sponsor_member_id',v_sponsor_id,'new_sponsor_code',v_code));
end;
$function$;

revoke all on function public.admin_set_member_sponsor(text,text) from public, anon;
grant execute on function public.admin_set_member_sponsor(text,text) to authenticated;
