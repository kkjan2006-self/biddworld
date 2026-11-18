create or replace function public.admin_list_withdrawal_requests(p_limit integer default 100,p_offset integer default 0)
returns table(
 request_id uuid,
 member_code text,
 display_name text,
 amount numeric,
 currency text,
 status text,
 payout_details jsonb,
 requested_at timestamptz,
 reviewed_at timestamptz,
 reviewed_by uuid,
 rejection_reason text
)
language plpgsql
security definer
set search_path=''
as $$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','') <> 'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select r.id,m.member_code,p.display_name,r.amount,r.currency::text,r.status,r.payout_details,
        r.requested_at,r.reviewed_at,r.reviewed_by,r.rejection_reason
 from public.withdrawal_requests r
 join public.member_ids m on m.id=r.member_id
 left join public.profiles p on p.id=m.owner_user_id
 order by r.requested_at desc,r.id desc
 limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_list_withdrawal_requests(integer,integer) from public,anon;
grant execute on function public.admin_list_withdrawal_requests(integer,integer) to authenticated;
