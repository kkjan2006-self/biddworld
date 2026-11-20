-- Minimize member-visible withdrawal payout data.
-- Keep the RPC result shape stable for the existing member UI, but return
-- only the payout method label; never expose UPI ID or bank account details
-- through the member history endpoint.
create or replace function public.member_list_my_withdrawals()
returns table(
 request_id uuid,
 amount numeric,
 currency character,
 status text,
 payout_details jsonb,
 requested_at timestamptz,
 reviewed_at timestamptz,
 rejection_reason text
)
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 v_uid uuid:=auth.uid();
 v_member uuid;
begin
 if v_uid is null then
  raise exception 'Authentication required' using errcode='42501';
 end if;
 select main_member_id into v_member
 from public.profiles
 where id=v_uid;
 if v_member is null then return; end if;
 return query
 select w.id,w.amount,w.currency,w.status,
        case when w.payout_details ? 'method'
          then jsonb_build_object('method',w.payout_details->>'method')
          else '{}'::jsonb end,
        w.requested_at,w.reviewed_at,w.rejection_reason
 from public.withdrawal_requests w
 where w.member_id=v_member
 order by w.requested_at desc
 limit 100;
end
$function$;

revoke all on function public.member_list_my_withdrawals() from public,anon;
grant execute on function public.member_list_my_withdrawals() to authenticated;
