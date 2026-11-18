-- Complete paginated Admin package activation history report.
-- Includes pending, approved, rejected and refunded requests without exposing data to members.

create or replace function public.admin_list_package_activations_page(
 p_payment_status text default null,p_limit integer default 100,p_offset integer default 0
) returns table(
 activation_id uuid,activation_number integer,member_code text,member_name text,
 package_name text,amount_paid numeric,currency text,bid_wallet_credit numeric,
 payment_reference text,receipt_path text,payment_status text,activation_status text,
 submitted_at timestamptz,verified_at timestamptz,verified_by uuid,has_more boolean
)
language plpgsql stable security definer set search_path=''
as $function$
begin
 if auth.uid() is null or coalesce(auth.jwt()->'app_metadata'->>'role','')<>'admin' then
  raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_payment_status is not null and p_payment_status not in ('pending','approved','rejected','refunded') then
  raise exception 'Invalid package payment status filter' using errcode='22023';
 end if;
 if p_limit is null or p_limit<1 or p_limit>200 or p_offset is null or p_offset<0 or p_offset>1000000 then
  raise exception 'Invalid pagination values' using errcode='22023';
 end if;
 return query
 select a.id,a.activation_number,m.member_code,p.display_name,pkg.name,a.amount_paid,
  a.currency,a.bid_wallet_credit,a.payment_reference,a.receipt_path,a.payment_status,
  a.activation_status,a.submitted_at,a.verified_at,a.verified_by,
  count(*) over()>p_offset+p_limit
 from public.package_activations a
 join public.member_ids m on m.id=a.member_id
 left join public.profiles p on p.id=m.owner_user_id
 join public.packages pkg on pkg.id=a.package_id
 where p_payment_status is null or a.payment_status=p_payment_status
 order by a.submitted_at desc,a.id desc
 limit p_limit offset p_offset;
end;
$function$;
revoke all on function public.admin_list_package_activations_page(text,integer,integer) from public,anon;
grant execute on function public.admin_list_package_activations_page(text,integer,integer) to authenticated;
