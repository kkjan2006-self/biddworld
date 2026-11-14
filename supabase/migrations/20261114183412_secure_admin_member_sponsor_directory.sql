-- Keep the admin member/sponsor directory limited to signed-in administrators.
create or replace function public.admin_list_members_sponsors()
returns table(member_code text, display_name text, phone text, sponsor_code text, created_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $function$
  select m.member_code, coalesce(p.display_name,''), coalesce(p.phone,''),
         coalesce(s.member_code,''), m.created_at
  from public.member_ids m
  join public.profiles p on p.id=m.owner_user_id
  left join public.referrals r on r.referred_member_id=m.id
  left join public.member_ids s on s.id=r.referrer_member_id
  where m.id_type='main'
    and auth.uid() is not null
    and coalesce(auth.jwt()->'app_metadata'->>'role','')='admin'
  order by m.created_at desc
  limit 500;
$function$;
revoke all on function public.admin_list_members_sponsors() from public, anon;
grant execute on function public.admin_list_members_sponsors() to authenticated;
